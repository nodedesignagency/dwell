import Foundation

/// What an insight opens into (brief A.2: "Tap → detail"; A.7: "Insight detail"): the sentence
/// with its data slotted in, the weeks behind it as bars, and up to three supporting numbers
/// (Insights design, 13 Nov: "You've spent 8% less time at the office this week.", four weeks
/// of office time, "31h this week · 41h 40m your usual · 1 day WFH").
///
/// The engine decides what each insight shows here. An insight with no detail of its own opens
/// into its sentence and its one number (`init(insight:)`).
public struct InsightDetail: Hashable, Sendable, Identifiable {
    public enum Headline: Hashable, Sendable {
        /// Data slotted into voiced words: the data in full ink with its icon, the words at 70%,
        /// as on Time's headline.
        case sentence(VoicedSentence)
        /// A line with its numbers written in, as Appendix B writes them: shown as on Today's card.
        case line(VoicedLine)
    }

    public let id: Insight.ID
    public var headline: Headline
    /// The weeks behind the insight. `nil` when a chart of weeks wouldn't say anything.
    public var trend: InsightTrend?
    /// Without weeks, the days Today's card charts, a bar a day. Empty when there are none.
    public var days: [DayValue]
    /// At most three, in the order shown. Data: they never change with the dial.
    public var stats: [InsightStat]
    public var isShareable: Bool

    public static let maxStats = 3

    public init(
        id: Insight.ID,
        headline: Headline,
        trend: InsightTrend? = nil,
        days: [DayValue] = [],
        stats: [InsightStat] = [],
        isShareable: Bool = true
    ) {
        self.id = id
        self.headline = headline
        self.trend = trend
        self.days = days
        self.stats = Array(stats.prefix(Self.maxStats))
        self.isShareable = isShareable
    }

    /// An insight with no detail of its own: its sentence, the chart from Today's card, and its
    /// one number as a tile labelled with its topic. Derived; the design shows a comparison
    /// over weeks only.
    public init(insight: Insight) {
        let stats: [InsightStat] = insight.value.map { value in
            [InsightStat(id: "value", value: .text(value), label: insight.topic ?? "", icon: .chart, tint: .accent)]
        } ?? []
        self.init(id: insight.id, headline: .line(insight.line), days: insight.week, stats: stats, isShareable: insight.isShareable)
    }
}

/// One supporting number under an insight (Insights design: "31h · this week"): a plain label,
/// never voiced, and 3D art over a glow of its tint.
public struct InsightStat: Hashable, Sendable, Identifiable {
    public enum Value: Hashable, Sendable {
        /// Written like every duration ("41h 40m") and spoken in words.
        case duration(TimeInterval)
        /// Anything else, written and spoken as given ("1 day", "3.2%").
        case text(String)
    }

    /// The tile's 3D art (Insights design: an alarm clock, the briefcase, the sunrise).
    public enum Icon: String, Hashable, Sendable {
        case alarmClock
        case briefcase
        case sunrise
        /// Rising bars, for an insight's lone number.
        case chart
    }

    /// The glow behind the art: a category's colour, yours' green or the insight accent.
    public enum Tint: Hashable, Sendable {
        case category(PlaceCategory)
        case yours
        case accent
    }

    public var id: String
    public var value: Value
    public var label: String
    public var icon: Icon
    public var tint: Tint

    public init(id: String, value: Value, label: String, icon: Icon, tint: Tint) {
        self.id = id
        self.value = value
        self.label = label
        self.icon = icon
        self.tint = tint
    }
}

/// The insight's chart range (Insights design: "4W · 3M"): a bar a week either way, so every
/// bar compares with "your usual" (the user's call, 13 Nov: 3M is thirteen weekly bars).
public enum InsightSpan: String, CaseIterable, Hashable, Sendable, Identifiable {
    case fourWeeks
    case threeMonths

    public var id: Self { self }

    public var weeks: Int {
        switch self {
        case .fourWeeks: 4
        case .threeMonths: 13
        }
    }

    /// The control's label.
    public var title: String {
        switch self {
        case .fourWeeks: "4W"
        case .threeMonths: "3M"
        }
    }

    /// What VoiceOver reads for the label.
    public var spokenTitle: String {
        switch self {
        case .fourWeeks: "4 weeks"
        case .threeMonths: "3 months"
        }
    }
}

/// The weeks behind an insight, one number each (Insights design: office time, a bar a week).
///
/// The chart shows a window of `InsightSpan.weeks` weeks. The latest window ends with the week
/// the insight is about (`focus`, drawn in full); the arrows step back a window at a time, as
/// far as the first week Dwell recorded. Weeks before recording began have no bar at all,
/// never a zero.
public struct InsightTrend: Hashable, Sendable {
    public struct Week: Hashable, Sendable, Identifiable {
        public var period: TimePeriod
        /// `nil` before Dwell was recording: no bar, not zero.
        public var value: TimeInterval?

        public var id: String { period.id }

        public init(period: TimePeriod, value: TimeInterval?) {
            self.period = period
            self.value = value
        }
    }

    /// Colours the bars, as the category's colour means the category everywhere.
    public var category: PlaceCategory?
    /// What the bars measure, for VoiceOver and the audio graph: "Time at the office".
    public var measure: String
    /// Every week from the first Dwell recorded through `focus`, oldest first.
    public var weeks: [Week]
    /// The week the insight is about.
    public var focus: TimePeriod

    public init(category: PlaceCategory?, measure: String, weeks: [Week], focus: TimePeriod) {
        self.category = category
        self.measure = measure
        self.weeks = weeks
        self.focus = focus
    }

    /// How many windows back the arrows can go: 0 when everything fits in the latest one.
    public func lastPage(_ span: InsightSpan) -> Int {
        max(0, (weeks.count - 1) / span.weeks)
    }

    /// The window `page` steps back from the latest, oldest week first. Always `span.weeks`
    /// long, so bars keep their width; weeks before the first recorded one come back with no
    /// value.
    public func window(_ span: InsightSpan, page: Int, calendar: Calendar) -> [Week] {
        let values = Dictionary(weeks.map { ($0.period.id, $0.value) }, uniquingKeysWith: { first, _ in first })
        let end = page * span.weeks
        return (0 ..< span.weeks).reversed().map { back in
            let period = focus.adding(-(end + back), in: calendar)
            return Week(period: period, value: values[period.id] ?? nil)
        }
    }

    /// One number a week from `first` through `focus`, measured by `measure` from each week's days.
    /// Weeks that started before `recordingSince`'s week have no value.
    ///
    /// - Parameter days: every day from the first recorded week through `focus`; days missing
    ///   from it count as empty.
    public static func weekly(
        category: PlaceCategory?,
        measure: String,
        focus: TimePeriod,
        days: [DaySnapshot],
        recordingSince: Date?,
        calendar: Calendar,
        value: (_ days: [DaySnapshot]) -> TimeInterval
    ) -> InsightTrend {
        let byDay = Dictionary(days.map { ($0.day, $0) }, uniquingKeysWith: { first, _ in first })
        let firstDay = recordingSince.map { DwellDay(containing: $0, calendar: calendar) } ?? days.map(\.day).min() ?? focus.first
        let firstWeek = TimePeriod(.week, containing: firstDay, calendar: calendar)
        var weeks: [Week] = []
        var period = firstWeek
        while period.first <= focus.first {
            let snapshots = period.days(in: calendar).compactMap { byDay[$0] }
            weeks.append(Week(period: period, value: value(snapshots)))
            period = period.adding(1, in: calendar)
        }
        return InsightTrend(category: category, measure: measure, weeks: weeks, focus: focus)
    }
}

extension DaySnapshot {
    /// Time at the workplace, work from home left out: the office in "less time at the office".
    public func officeTime(now: Date) -> TimeInterval {
        entries.reduce(0) { total, entry in
            guard let visit = entry.visit, visit.category == .work, !visit.isWorkFromHome else { return total }
            return total + clippedDuration(of: entry, now: now)
        }
    }

    /// Whether any of the day's work was from home: a WFH day.
    public func isWorkFromHome(now: Date) -> Bool {
        entries.contains { entry in
            guard let visit = entry.visit, visit.isWorkFromHome else { return false }
            return clippedDuration(of: entry, now: now) > 0
        }
    }
}

extension VoicedSentence {
    /// The sentence with its runs written in, for a place that shows plain voiced text
    /// (Today's insight card).
    public var filledLine: VoicedLine {
        VoicedLine(
            peace: fill(line.peace),
            calm: line.calm.map(fill),
            plain: fill(line.plain),
            push: line.push.map(fill),
            grind: fill(line.grind))
    }
}
