import Foundation

/// "Every hour of the week" (Time design): one row per day, 4 AM to 4 AM, each stretch of it
/// coloured by where the time went, gaps hatched.
///
/// Day, week and month show their real days. A year has a row per month instead, each that
/// month's typical day: every quarter hour takes whatever filled it most often.
///
/// Categories fold to at most seven plus "Everything else" (brief §11), chosen by the
/// period's totals, so the legend and every row agree.
public struct HourGrid: Hashable, Sendable {
    /// What a stretch of a row is.
    public enum Kind: Hashable, Sendable, Identifiable {
        case bucket(ChartBucket)
        /// No record: Dwell was asleep. Never a category, never hidden.
        case gap

        public var id: String {
            switch self {
            case .bucket(let bucket): bucket.id
            case .gap: "gap"
            }
        }

        public var name: String {
            switch self {
            case .bucket(let bucket): bucket.name
            case .gap: "Gap"
            }
        }
    }

    public struct Segment: Hashable, Sendable {
        public var kind: Kind
        /// Shares of the row, 0 at 4 AM, 1 at 4 AM the next morning.
        public var start: Double
        public var end: Double
        /// The real times, for a day's row; `nil` in a typical day.
        public var span: DateInterval?

        public init(kind: Kind, start: Double, end: Double, span: DateInterval? = nil) {
            self.kind = kind
            self.start = start
            self.end = end
            self.span = span
        }
    }

    public struct Row: Hashable, Sendable, Identifiable {
        public var id: String
        /// The day this row is, or the first day of the month a typical row stands for.
        public var day: DwellDay
        public var segments: [Segment]
        /// Time in each kind of stretch, for VoiceOver and the callout.
        public var totals: [Kind: TimeInterval]

        public var isEmpty: Bool { segments.isEmpty }
    }

    /// Typical days split the day into quarter hours.
    public static let slotsPerDay = 96

    public var period: TimePeriod
    public var rows: [Row]
    /// The legend, in order: categories by time (home last, as in "All categories"), then
    /// Gap, then Everything else. Only what the rows hold.
    public var legend: [Kind]
    /// Each row is a typical day (the year).
    public var isTypical: Bool { period.range == .year }

    /// - Parameter named: the categories to name, most important first, when the caller picks
    ///   them (the weekly wrap's weekend page names work and the weekend's own); at most seven
    ///   are named, the rest fold into Everything else. By default, the period's largest seven.
    public init(_ snapshot: PeriodSnapshot, now: Date, calendar: Calendar, named: [PlaceCategory]? = nil) {
        period = snapshot.period
        let whole = snapshot.period.interval(in: calendar)
        let totals = TimeReport.totals(snapshot.days, within: whole, now: now)
        let chosen = Set((named ?? ChartSlice.fold(totals).compactMap(\.bucket.category)).prefix(ChartBucket.maxNamedCategories))
        var bucketOf: [PlaceCategory: ChartBucket] = [:]
        for category in PlaceCategory.allCases where totals[category] ?? 0 > 0 {
            bucketOf[category] = chosen.contains(category) ? .category(category) : .everythingElse
        }
        let kind: (PlaceCategory) -> Kind = { .bucket(bucketOf[$0] ?? .everythingElse) }

        if snapshot.period.range == .year {
            rows = (1...12).map { month in
                let days = snapshot.days.filter { $0.day.month == month }
                return Self.typicalRow(
                    id: "month-\(month)", day: DwellDay(year: snapshot.period.first.year, month: month, day: 1),
                    days: days, now: now, calendar: calendar, kind: kind)
            }
        } else {
            rows = snapshot.days.map { Self.row(for: $0, now: now, kind: kind) }
        }

        let present = Set(rows.flatMap { $0.segments.map(\.kind) })
        let order = TimeReport.lines(totals: totals, usual: nil, parts: [:]).map(\.category)
        var legend: [Kind] = []
        for category in order where present.contains(.bucket(.category(category))) {
            legend.append(.bucket(.category(category)))
        }
        if present.contains(.gap) { legend.append(.gap) }
        if present.contains(.bucket(.everythingElse)) { legend.append(.bucket(.everythingElse)) }
        self.legend = legend
    }

    // MARK: A real day

    static func row(for day: DaySnapshot, now: Date, kind: (PlaceCategory) -> Kind) -> Row {
        let watched = day.elapsed(now: now)
        let length = day.interval.duration
        var pieces: [(kind: Kind, span: DateInterval)] = []
        var cursor = watched.start
        if watched.duration > 0 {
            for entry in day.entries {
                guard let span = day.span(of: entry, within: watched, now: now) else { continue }
                if span.start > cursor {
                    pieces.append((.gap, DateInterval(start: cursor, end: span.start)))
                }
                let start = max(span.start, cursor)
                guard span.end > start else { continue }
                pieces.append((entry.category.map(kind) ?? .gap, DateInterval(start: start, end: span.end)))
                cursor = span.end
            }
            if watched.end > cursor {
                pieces.append((.gap, DateInterval(start: cursor, end: watched.end)))
            }
        }

        // Neighbours of the same kind are one stretch (a night at home split at 4 AM, a gap
        // beside a stretch with no record).
        var merged: [(kind: Kind, span: DateInterval)] = []
        for piece in pieces {
            if let last = merged.last, last.kind == piece.kind, piece.span.start.timeIntervalSince(last.span.end) < 1 {
                merged[merged.count - 1].span = DateInterval(start: last.span.start, end: piece.span.end)
            } else {
                merged.append(piece)
            }
        }

        let segments = merged.map { piece in
            Segment(
                kind: piece.kind,
                start: piece.span.start.timeIntervalSince(day.interval.start) / length,
                end: piece.span.end.timeIntervalSince(day.interval.start) / length,
                span: piece.span)
        }
        var totals: [Kind: TimeInterval] = [:]
        for piece in merged { totals[piece.kind, default: 0] += piece.span.duration }
        return Row(id: "day-\(day.day.year)-\(day.day.month)-\(day.day.day)", day: day.day, segments: segments, totals: totals)
    }

    // MARK: A typical day

    /// Each quarter hour takes the kind that filled it most across the days; quarter hours
    /// nobody watched stay empty.
    static func typicalRow(
        id: String, day first: DwellDay, days: [DaySnapshot], now: Date, calendar: Calendar, kind: (PlaceCategory) -> Kind
    ) -> Row {
        let slots = slotsPerDay
        var filled = [[Kind: TimeInterval]](repeating: [:], count: slots)
        var totals: [Kind: TimeInterval] = [:]
        for day in days {
            let row = row(for: day, now: now, kind: kind)
            for segment in row.segments {
                guard let span = segment.span else { continue }
                totals[segment.kind, default: 0] += span.duration
                let slotLength = day.interval.duration / Double(slots)
                let firstSlot = max(0, Int(segment.start * Double(slots)))
                let lastSlot = min(slots - 1, Int((segment.end * Double(slots)).rounded(.up)) - 1)
                guard firstSlot <= lastSlot else { continue }
                for slot in firstSlot...lastSlot {
                    let slotStart = day.interval.start.addingTimeInterval(Double(slot) * slotLength)
                    let overlap = min(span.end, slotStart.addingTimeInterval(slotLength)).timeIntervalSince(max(span.start, slotStart))
                    if overlap > 0 { filled[slot][segment.kind, default: 0] += overlap }
                }
            }
        }

        var segments: [Segment] = []
        for (slot, kinds) in filled.enumerated() {
            guard let winner = kinds.max(by: { ($0.value, $1.key.id) < ($1.value, $0.key.id) })?.key else { continue }
            let start = Double(slot) / Double(slots)
            let end = Double(slot + 1) / Double(slots)
            if let last = segments.last, last.kind == winner, abs(last.end - start) < 1e-9 {
                segments[segments.count - 1].end = end
            } else {
                segments.append(Segment(kind: winner, start: start, end: end))
            }
        }
        return Row(id: id, day: first, segments: segments, totals: totals)
    }

    // MARK: Layout

    /// Where each segment sits across a row `width` wide: true to its time, but never narrower
    /// than `minWidth` (a 12-minute stop stays visible), with `spacing` between neighbours that
    /// touch. Short segments widen about their middle; the room comes out of their neighbours,
    /// the wider one first. Returns one range per segment, in order.
    public static func layout(_ segments: [Segment], width: Double, minWidth: Double, spacing: Double) -> [ClosedRange<Double>] {
        guard width > 0 else { return segments.map { _ in 0...0 } }
        var spans = segments.map { (start: $0.start * width, end: $0.end * width, touches: false) }
        for index in spans.indices.dropFirst() {
            spans[index].touches = segments[index].start - segments[index - 1].end < 1e-6
        }

        // Pull touching neighbours apart by the spacing, half from each side.
        for index in spans.indices.dropFirst() where spans[index].touches {
            spans[index - 1].end -= spacing / 2
            spans[index].start += spacing / 2
        }

        // Widen what's too narrow, about its middle, inside the row.
        for index in spans.indices where spans[index].end - spans[index].start < minWidth {
            let middle = (spans[index].start + spans[index].end) / 2
            let start = min(max(0, middle - minWidth / 2), max(0, width - minWidth))
            spans[index].start = start
            spans[index].end = min(width, start + minWidth)
        }

        // Settle overlaps left to right: the wider of two neighbours gives the room up, as far
        // as it can while staying at the minimum; the other gives the rest.
        for index in spans.indices.dropFirst() {
            let previous = index - 1
            let needed = spans[previous].end + spacing - spans[index].start
            guard needed > 0 else { continue }
            let previousRoom = max(0, spans[previous].end - spans[previous].start - minWidth)
            let currentRoom = max(0, spans[index].end - spans[index].start - minWidth)
            var fromPrevious = 0.0
            var fromCurrent = 0.0
            if previousRoom >= currentRoom {
                fromPrevious = min(needed, previousRoom)
                fromCurrent = min(needed - fromPrevious, currentRoom)
            } else {
                fromCurrent = min(needed, currentRoom)
                fromPrevious = min(needed - fromCurrent, previousRoom)
            }
            // Out of room: split what's left, so neither vanishes.
            let left = needed - fromPrevious - fromCurrent
            spans[previous].end -= fromPrevious + left / 2
            spans[index].start += fromCurrent + left / 2
        }

        return spans.map { span in
            let start = min(max(0, span.start), width)
            return start...min(width, max(start, span.end))
        }
    }
}
