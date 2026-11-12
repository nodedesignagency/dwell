import Foundation

/// Your typical day as a shape (brief §7.3 "Rhythm", Time design "Your rhythm"): when you
/// usually arrive, break for lunch, leave and get home on a weekday; when you head out, eat and
/// get home on a weekend. Each moment is the median across the days that have it, over the
/// last four weeks. Locked until Dwell has two weeks (brief §3.1, day 14).
public struct Rhythm: Hashable, Sendable {
    public enum Kind: String, CaseIterable, Hashable, Sendable, Identifiable {
        case weekday
        case weekend

        public var id: Self { self }

        public var title: String {
            switch self {
            case .weekday: "Weekday"
            case .weekend: "Weekend"
            }
        }
    }

    /// A labelled moment under the strip.
    public enum Mark: String, Hashable, Sendable {
        /// First in at work.
        case arrive
        /// The weekend's first time out of the house.
        case out
        case lunch
        /// Last out of work.
        case leave
        case homeBy

        public var title: String {
            switch self {
            case .arrive: "Arrive"
            case .out: "Out"
            case .lunch: "Lunch"
            case .leave: "Leave"
            case .homeBy: "Home by"
            }
        }
    }

    /// A stretch of the strip, coloured by what it is.
    public enum Phase: String, Hashable, Sendable {
        case morning
        case lunch
        case afternoon
        case wayHome
    }

    public struct Moment: Hashable, Sendable {
        public var mark: Mark
        /// Minutes after the day's 4 AM start, so a late night stays after the evening.
        public var minutes: Double
    }

    public struct Stretch: Hashable, Sendable {
        public var phase: Phase
        public var start: Double
        public var end: Double
    }

    public static let daysNeeded = 14
    public static let lookback = 28

    public var kind: Kind
    public var moments: [Moment]
    public var stretches: [Stretch]
    /// How many days went into it.
    public var days: Int

    /// The rhythm of `kind` days among `days`, or `nil` when none of them has the moments.
    public static func typical(_ kind: Kind, from days: [DaySnapshot], now: Date, calendar: Calendar) -> Rhythm? {
        var picks: [Mark: [Double]] = [:]
        var lunchEnds: [Double] = []
        var counted = 0
        for day in days {
            let weekday = calendar.component(.weekday, from: day.interval.start)
            let isWeekend = weekday == 1 || weekday == 7
            guard isWeekend == (kind == .weekend), day.interval.end <= now else { continue }
            let visits = day.entries.compactMap(\.visit).filter { $0.departure != nil }
            func minutes(_ date: Date) -> Double { date.timeIntervalSince(day.interval.start) / 60 }

            let lunch = visits.first { visit in
                guard visit.category == .foodAndDrink else { return false }
                let hour = calendar.component(.hour, from: visit.arrival)
                return (11..<15).contains(hour) && day.interval.contains(visit.arrival)
            }

            switch kind {
            case .weekday:
                let work = visits.filter { $0.category == .work && day.interval.contains($0.arrival) }
                guard let first = work.first, let last = work.last, let leave = last.departure else { continue }
                picks[.arrive, default: []].append(minutes(first.arrival))
                picks[.leave, default: []].append(minutes(leave))
                if let home = visits.first(where: { $0.category == .home && $0.arrival >= leave && day.interval.contains($0.arrival) }) {
                    picks[.homeBy, default: []].append(minutes(home.arrival))
                }
            case .weekend:
                // Out: the first stop that isn't home. Home by: the last time back home.
                guard let out = visits.first(where: { $0.category != .home && day.interval.contains($0.arrival) }) else { continue }
                picks[.out, default: []].append(minutes(out.arrival))
                if let home = visits.last(where: { $0.category == .home && $0.arrival > out.arrival && day.interval.contains($0.arrival) }) {
                    picks[.homeBy, default: []].append(minutes(home.arrival))
                }
            }
            if let lunch, let end = lunch.departure {
                picks[.lunch, default: []].append(minutes(lunch.arrival))
                lunchEnds.append(minutes(end))
            }
            counted += 1
        }
        guard counted > 0 else { return nil }

        let marks: [Mark] = kind == .weekday ? [.arrive, .lunch, .leave, .homeBy] : [.out, .lunch, .homeBy]
        let moments = marks.compactMap { mark in picks[mark].flatMap(median).map { Moment(mark: mark, minutes: $0) } }
        guard moments.count >= 2 else { return nil }

        // The strip: morning to lunch, lunch itself, the afternoon, the way home.
        let at = Dictionary(uniqueKeysWithValues: moments.map { ($0.mark, $0.minutes) })
        let start = at[.arrive] ?? at[.out]
        let lunchStart = at[.lunch]
        let lunchEnd = lunchStart.flatMap { start in median(lunchEnds).map { max($0, start) } }
        let leave = at[.leave]
        let home = at[.homeBy]
        var stretches: [Stretch] = []
        func add(_ phase: Phase, _ from: Double?, _ to: Double?) {
            guard let from, let to, to > from else { return }
            stretches.append(Stretch(phase: phase, start: from, end: to))
        }
        let dayEnd = leave ?? home
        add(.morning, start, lunchStart ?? dayEnd)
        add(.lunch, lunchStart, lunchEnd)
        add(.afternoon, lunchEnd ?? lunchStart, dayEnd)
        if leave != nil { add(.wayHome, leave, home) }

        return Rhythm(kind: kind, moments: moments, stretches: stretches, days: counted)
    }

    /// The clock time a moment stands for, on `day`.
    public func date(of moment: Moment, on day: DwellDay, calendar: Calendar) -> Date {
        day.start(in: calendar).addingTimeInterval(moment.minutes * 60)
    }

    private static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        let value = sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
        return value.rounded()
    }
}
