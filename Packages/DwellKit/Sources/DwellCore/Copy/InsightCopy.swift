import Foundation

/// The Insights page's words (insight detail, Insights design, 13 Nov). The design's lines are
/// used as they are, in sentence case; the rest are placeholders marked [COPY NEEDED] until
/// the client's copy deck arrives. Numbers come in as runs or arguments, never written per
/// voice, so they can't differ across the dial.
public enum InsightCopy {
    /// The page's title (the design's).
    public static let title = "Insights"
    /// The design's two buttons; "Not Useful" in sentence case (brief §8.6).
    public static let share = "Share"
    public static let notUseful = "Not useful"

    // MARK: The chart

    /// The window over the bars: "Sep 2026 – Oct 2026", or "Oct 2026" inside one month. The
    /// design writes "Oct 2026 - Nov 2026"; the en dash is the app's (as in "Oct 19 – 25").
    public static func window(_ weeks: [InsightTrend.Week], calendar: Calendar) -> String {
        guard let first = weeks.first?.period.first, let last = weeks.last?.period.last else { return "" }
        let start = monthYear(first, calendar: calendar)
        let end = monthYear(last, calendar: calendar)
        return start == end ? start : "\(start) – \(end)"
    }

    /// A bar's label at 4W: "This week" or "Last week" for the insight's own week, as in the
    /// design; otherwise the week's Monday, "Oct 5" (the design's "Sept 7").
    public static func barLabel(_ week: TimePeriod, focus: TimePeriod, now: Date, calendar: Calendar) -> String {
        guard week == focus else { return ClockText.monthDay(week.first, calendar: calendar) }
        let current = TimePeriod(.week, containing: DwellDay(containing: now, calendar: calendar), calendar: calendar)
        if week == current { return "This week" }
        if week == current.adding(-1, in: calendar) { return "Last week" }
        return ClockText.monthDay(week.first, calendar: calendar)
    }

    /// A month's label at 3M, under the first week that starts in it: "Sep".
    public static func monthLabel(_ week: TimePeriod, calendar: Calendar) -> String {
        week.first.start(in: calendar).formatted(style(calendar).month(.abbreviated))
    }

    /// What a picked bar says, and VoiceOver's name for every bar: "Oct 12 – 18".
    public static func weekName(_ week: TimePeriod, calendar: Calendar) -> String {
        ClockText.dayRange(week.first, week.last, calendar: calendar)
    }

    /// VoiceOver: the window arrows and the range control.
    public static let earlierWeeks = "Earlier weeks" // [COPY NEEDED]
    public static let laterWeeks = "Later weeks" // [COPY NEEDED]
    public static let span = "Range"

    // MARK: Office time

    /// What the bars measure, for VoiceOver.
    public static let officeMeasure = "Time at the office"
    /// Today's card label over the sentence. [COPY NEEDED]
    public static let officeTopic = "Office time"
    /// The second tile (the design's).
    public static let usual = "your usual"
    /// The third tile (the design's).
    public static let workFromHome = "WFH"

    /// "1 day", "3 days": the third tile's number.
    public static func days(_ count: Int) -> String {
        count == 1 ? "1 day" : "\(count) days"
    }

    /// The first tile's label: "this week", "last week", or the week's dates.
    public static func weekWord(_ week: TimePeriod, now: Date, calendar: Calendar) -> String {
        let current = TimePeriod(.week, containing: DwellDay(containing: now, calendar: calendar), calendar: calendar)
        if week == current { return "this week" }
        if week == current.adding(-1, in: calendar) { return "last week" }
        return weekName(week, calendar: calendar)
    }

    /// "You've spent 8% less time at the office this week." (the design's, Plain).
    ///
    /// The change against your usual is the data: "8% less time", with the building, the same
    /// at every stop. Within half a percent of usual, the week's own time leads instead: "38h
    /// 20m at the office last week, about your usual." Peace notices room left over; Grind
    /// notices the hours, and never celebrates a week with a day over 12h of work (brief §8.4).
    /// [COPY NEEDED] everything but the design's Plain line.
    public static func office(
        week: TimePeriod,
        office: TimeInterval,
        usual: TimeInterval,
        celebrates: Bool,
        now: Date,
        calendar: Calendar
    ) -> VoicedSentence {
        let lived = week.isInProgress(now: now, calendar: calendar)
        let you = lived ? "You've spent" : "You spent"
        let when = sentenceWeek(week, now: now, calendar: calendar)
        let percent = Int((abs(office - usual) / max(usual, 1) * 100).rounded())

        guard percent > 0 else {
            return VoicedSentence(
                line: VoicedLine(
                    peace: "{0} at the office \(when), about your usual. Steady.",
                    plain: "\(you) {0} at the office \(when), about your usual.",
                    grind: "{0} at the office \(when). Right on your usual."),
                runs: [VoicedSentence.Run(category: .work, text: DurationText.short(office))])
        }

        let more = office > usual
        let run = VoicedSentence.Run(category: .work, text: "\(percent)% \(more ? "more" : "less") time")
        let plain = "\(you) {0} at the office \(when)."
        let line: VoicedLine = if more {
            VoicedLine(
                peace: "{0} at the office \(when). Make room to rest.",
                plain: plain,
                grind: celebrates ? "{0} at the office \(when). Putting in the hours." : "{0} at the office \(when).")
        } else {
            VoicedLine(
                peace: "{0} at the office \(when). Room for other things.",
                plain: plain,
                grind: "{0} at the office \(when). Noted.")
        }
        return VoicedSentence(line: line, runs: [run])
    }

    /// "this week", "last week", "the week of Oct 12".
    static func sentenceWeek(_ week: TimePeriod, now: Date, calendar: Calendar) -> String {
        let word = weekWord(week, now: now, calendar: calendar)
        guard word == weekName(week, calendar: calendar) else { return word }
        return "the week of \(ClockText.monthDay(week.first, calendar: calendar))"
    }

    // MARK: States

    /// [COPY NEEDED]
    public static let couldNotLoad = "This insight couldn't load"
    /// [COPY NEEDED]
    public static let offlineDetail = "It loads once you're back online."
    /// [COPY NEEDED]
    public static let tryAgain = "Try again in a moment."
    public static let retry = "Retry"

    // MARK: Formatting

    /// "Oct 2026".
    static func monthYear(_ day: DwellDay, calendar: Calendar) -> String {
        day.start(in: calendar).formatted(style(calendar).month(.abbreviated).year())
    }

    private static func style(_ calendar: Calendar) -> Date.FormatStyle {
        Date.FormatStyle(locale: calendar.locale ?? .current, calendar: calendar, timeZone: calendar.timeZone)
    }
}
