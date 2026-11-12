import Foundation

/// Time's words. The design's and Appendix B's lines are used as they are, in sentence case;
/// the rest are placeholders marked [COPY NEEDED] until the client's copy deck arrives. Numbers
/// are passed in as runs or arguments, never written per voice, so they can't differ across
/// the dial.
public enum TimeCopy {
    public static let title = "Time"

    // MARK: Periods

    /// The date pill: "Sep 28 – Oct 4", "Mon, Oct 26", "October 2026", "2026".
    public static func label(_ period: TimePeriod, calendar: Calendar) -> String {
        switch period.range {
        case .day: ClockText.dayName(period.first, calendar: calendar)
        case .week: ClockText.dayRange(period.first, period.last, calendar: calendar)
        case .month: monthName(period.first, calendar: calendar, withYear: true)
        case .year: "\(period.first.year)"
        }
    }

    /// How a sentence opens on this period: "This week,", "Last week,", "Sep 28 – Oct 4,".
    public static func lead(_ period: TimePeriod, now: Date, calendar: Calendar) -> String {
        let current = TimePeriod(period.range, containing: DwellDay(containing: now, calendar: calendar), calendar: calendar)
        let previous = current.adding(-1, in: calendar)
        switch period.range {
        case .day:
            if period == current { return "Today," }
            if period == previous { return "Yesterday," }
            return "On \(ClockText.dayName(period.first, calendar: calendar)),"
        case .week:
            if period == current { return "This week," }
            if period == previous { return "Last week," }
            return "\(label(period, calendar: calendar)),"
        case .month:
            if period == current { return "This month," }
            if period == previous { return "Last month," }
            return "In \(monthName(period.first, calendar: calendar, withYear: period.first.year != current.first.year)),"
        case .year:
            if period == current { return "This year," }
            if period == previous { return "Last year," }
            return "In \(period.first.year),"
        }
    }

    /// "this week" for the period being lived, "that week" for one that's over.
    public static func this(_ period: TimePeriod, now: Date, calendar: Calendar) -> String {
        if period.range == .day {
            return period.isInProgress(now: now, calendar: calendar) ? "today" : "that day"
        }
        return (period.isInProgress(now: now, calendar: calendar) ? "this " : "that ") + period.range.noun
    }

    // MARK: Headline

    /// "This week, 42h 29m at work, up by 2h 44m, and 27h 09m at yours." (Time design.)
    ///
    /// Work leads, with its change from usual, then yours (brief A.4: the focus category's
    /// total and its signed delta with an arrow). With no work, yours leads. Peace calls the
    /// second number "yours", Grind calls it "off" (brief §7.3). `nil` when there's neither.
    /// [COPY NEEDED] Peace and Grind; Plain is the design's.
    public static func headline(_ report: TimeReport, lead: String) -> VoicedSentence? {
        let work = report.work
        let yours = report.yours
        if work >= 60 {
            let workRun = VoicedSentence.Run(category: .work, text: DurationText.short(work))
            let yoursRun = VoicedSentence.Run(mark: .yours, text: DurationText.short(yours))
            guard let usual = report.usualWork else {
                return VoicedSentence(
                    line: VoicedLine(
                        peace: "\(lead) {1} were yours, and {0} went to work.",
                        plain: "\(lead) {0} at work and {1} at yours.",
                        grind: "\(lead) {0} at work. {1} off."),
                    runs: [workRun, yoursRun])
            }
            let delta = work - usual
            guard abs(delta) >= 60 else {
                return VoicedSentence(
                    line: VoicedLine(
                        peace: "\(lead) {1} were yours, and {0} went to work, as usual.",
                        plain: "\(lead) {0} at work, as usual, and {1} at yours.",
                        grind: "\(lead) {0} at work, steady. {1} off."),
                    runs: [workRun, yoursRun])
            }
            let up = delta > 0
            let deltaRun = VoicedSentence.Run(mark: up ? .up : .down, text: DurationText.short(abs(delta)))
            return VoicedSentence(
                line: VoicedLine(
                    peace: "\(lead) {2} were yours, and {0} went to work, {1} \(up ? "more" : "less") than usual.",
                    plain: "\(lead) {0} at work, \(up ? "up" : "down") by {1}, and {2} at yours.",
                    grind: "\(lead) {0} at work, \(up ? "up" : "down") {1}. {2} off."),
                runs: [workRun, deltaRun, yoursRun])
        }

        guard yours >= 60 else { return nil }
        let yoursRun = VoicedSentence.Run(mark: .yours, text: DurationText.short(yours))
        guard let usual = report.usualYours, abs(yours - usual) >= 60 else {
            return VoicedSentence(
                line: VoicedLine(
                    peace: "\(lead) {0} were yours.",
                    plain: "\(lead) {0} at yours.",
                    grind: "\(lead) {0} off."),
                runs: [yoursRun])
        }
        let up = yours > usual
        let deltaRun = VoicedSentence.Run(mark: up ? .up : .down, text: DurationText.short(abs(yours - usual)))
        return VoicedSentence(
            line: VoicedLine(
                peace: "\(lead) {0} were yours, {1} \(up ? "more" : "less") than usual.",
                plain: "\(lead) {0} at yours, \(up ? "up" : "down") by {1}.",
                grind: "\(lead) {0} off, \(up ? "up" : "down") {1}."),
            runs: [yoursRun, deltaRun])
    }

    /// No stops at all in the period: Appendix B's "Empty Today", for any period.
    public static func nothingMapped(this: String) -> VoicedLine {
        VoicedLine(
            peace: "Nothing yet \(this). Dwell is waiting for your first stop.",
            plain: "No stops \(this).",
            grind: "No stops \(this). Go somewhere.")
    }

    /// When there's nothing but home and transit to report. [COPY NEEDED]
    public static func quietHeadline(lead: String) -> VoicedLine {
        VoicedLine(
            peace: "\(lead) mostly home. A quiet stretch.",
            plain: "\(lead) mostly at home.",
            grind: "\(lead) home base. Nothing else logged.")
    }

    // MARK: Every hour

    /// "Your days, 4AM to 4AM" (Time design). The year shows a typical day per month.
    public static func gridCaption(_ range: TimeRange, calendar: Calendar) -> String {
        let hour = ClockText.hour(DwellDay.startHour, calendar: calendar)
        switch range {
        case .day: return "Your day, \(hour) to \(hour)"
        case .week, .month: return "Your days, \(hour) to \(hour)"
        case .year: return "A typical day each month, \(hour) to \(hour)" // [COPY NEEDED]
        }
    }

    /// "Every hour of the week".
    public static func gridTitle(_ range: TimeRange) -> String {
        "Every hour of the \(range.noun)"
    }

    /// The legend's name for a gap, as the design has it. (Today's day bar says "Unmapped":
    /// QUESTIONS.md.)
    public static let gap = "Gap"

    /// A day's row before Dwell was recording, or still to come.
    public static let notRecorded = "Not recorded" // [COPY NEEDED]

    // MARK: All categories

    /// Sentence case; the design says "All Categories".
    public static let allCategories = "All categories"

    /// "2h 44m longer than usual", "40m less than usual" (Time design). A row's line: plain at
    /// every dial position, like a timeline row.
    public static func delta(_ delta: TimeInterval) -> String {
        guard abs(delta) >= 60 else { return "Same as usual" } // [COPY NEEDED]
        return "\(DurationText.short(abs(delta))) \(delta > 0 ? "longer" : "less") than usual"
    }

    /// The line under the list. Appendix B's gap line: Peace's words are the design's, and
    /// Plain keeps them here too, since they're plain facts; Grind is Appendix B's.
    public static func asleep(_ unmapped: TimeInterval, this: String) -> VoicedLine {
        let time = DurationText.short(unmapped)
        return VoicedLine(
            peace: "Dwell was asleep for \(time) \(this). That time isn't counted.",
            plain: "Dwell was asleep for \(time) \(this). That time isn't counted.",
            grind: "Dwell was asleep · \(time) \(this). Not counted.")
    }

    // MARK: Work and yours

    /// The section's title. Peace and Plain call the second number "yours", Grind "off" (brief
    /// §7.3), so the title follows. [COPY NEEDED] Grind.
    public static let workAndYours = VoicedLine(peace: "Work and yours", plain: "Work and yours", grind: "On and off")
    public static let atWork = "At work"
    /// The second tile's label (brief §7.3).
    public static let yours = VoicedLine(peace: "Yours", plain: "Yours", grind: "Off")

    /// A bar's label: "Oct 5" for an earlier week, "This week" for the one being lived.
    public static func trendLabel(_ period: TimePeriod, now: Date, calendar: Calendar) -> String {
        if period.isInProgress(now: now, calendar: calendar) {
            return period.range == .day ? "Today" : "This \(period.range.noun)"
        }
        switch period.range {
        case .day: return weekdayShort(period.first, calendar: calendar)
        case .week: return dayShort(period.first, calendar: calendar)
        case .month: return monthName(period.first, calendar: calendar, withYear: false, short: true)
        case .year: return "\(period.first.year)"
        }
    }

    // MARK: Calendar vs reality

    /// Sentence case; the design says "Calendar vs Reality".
    public static let calendarTitle = "Calendar vs reality"
    public static let attended = "Attended"
    public static let leftEarly = "Left early"
    public static let elsewhere = "Elsewhere"
    /// An event Dwell couldn't match (brief §9: "unknown"). [COPY NEEDED]
    public static let noMatch = "No match"
    public static let worthNoticing = "Worth noticing"

    /// Under the ring's "6/8". The design's "meeting", plural.
    public static func meetings(_ count: Int) -> String {
        count == 1 ? "meeting" : "meetings"
    }

    /// "6 of 8 meetings attended this week." (brief §7.3), for VoiceOver.
    public static func attendedSummary(_ report: CalendarReport, this: String) -> String {
        "\(report.attended) of \(report.scheduled) \(meetings(report.scheduled)) attended \(this)"
    }

    /// A note under "Worth noticing". Appendix B's calendar lines where they fit.
    public static func note(_ kind: CalendarReport.Note.Kind) -> VoicedLine {
        switch kind {
        case .leftEarlyRun(let title, let weekday, let weeks):
            // Plain is the brief's §7.3 line, made to fit any meeting. [COPY NEEDED] Peace.
            return VoicedLine(
                peace: "You've left \(title) a little early \(weeks) \(weekday)s running.",
                plain: "You left \(title) early \(weeks) \(weekday)s running.",
                grind: "Bailed early on \(title) \(weeks) \(weekday)s running.")
        case .lateRun(let title, let weekday, let weeks):
            // [COPY NEEDED] all three.
            return VoicedLine(
                peace: "You've eased into \(title) late \(weeks) \(weekday)s running.",
                plain: "You got to \(title) late \(weeks) \(weekday)s running.",
                grind: "Late to \(title) \(weeks) \(weekday)s running.")
        case .missed(let title, let day, let time, let instead?):
            // Plain is the design's; Peace and Grind are Appendix B's "Calendar, missed".
            return VoicedLine(
                peace: "\(title) was \(day) at \(time). You were at \(instead). No judgment.",
                plain: "\(title) was \(day) at \(time). You were at \(instead).",
                grind: "\(title) · missed. You were at \(instead).")
        case .missed(let title, let day, let time, nil):
            // [COPY NEEDED]
            return VoicedLine(
                peace: "\(title) was \(day) at \(time). You were somewhere else, and that's fine.",
                plain: "\(title) was \(day) at \(time). You were elsewhere.",
                grind: "\(title) · missed.")
        }
    }

    /// Patterns wait for two weeks of meetings (brief A.4). [COPY NEEDED]
    public static let patternsWaiting = VoicedLine(
        peace: "Patterns show up after two weeks. No rush.",
        plain: "Patterns show up after two weeks.",
        grind: "Two weeks of meetings, then the patterns.")

    /// Nothing stood out. [COPY NEEDED]
    public static let nothingToNotice = VoicedLine(
        peace: "Nothing stood out. Your calendar and your day agreed.",
        plain: "Your calendar and your day agreed.",
        grind: "Calendar and reality matched. Clean.")

    /// [COPY NEEDED]
    public static func noMeetings(this: String) -> VoicedLine {
        VoicedLine(
            peace: "No meetings \(this). The calendar left you alone.",
            plain: "No meetings \(this).",
            grind: "Zero meetings \(this).")
    }

    /// Not connected: sells the feature (brief A.4). Titles stay on the phone (brief A.6).
    /// [COPY NEEDED]
    public static let connectTitle = VoicedLine(
        peace: "See how your plans and your days line up",
        plain: "See which meetings you really made",
        grind: "Find out which meetings you actually made")
    public static let connectDetail = "Connect a calendar and Dwell matches each event to where you were. Titles never leave your phone." // [COPY NEEDED]
    public static let connectAction = "Connect calendar"

    // MARK: Rhythm

    /// Sentence case; the design says "Your Rhythm".
    public static let rhythmTitle = "Your rhythm"

    /// "Rhythm needs two weeks · 11 days to go." (DwellCore's `MappingProgress`.)
    /// [COPY NEEDED] Peace and Grind.
    public static func rhythmLocked(daysToGo: Int) -> VoicedLine {
        let days = daysToGo == 1 ? "1 day" : "\(daysToGo) days"
        return VoicedLine(
            peace: "Your rhythm takes two weeks to show. \(days) to go.",
            plain: "Your rhythm needs two weeks · \(days) to go",
            grind: "Two weeks of data first. \(days) to go.")
    }

    /// No weekday (or weekend) in the last four weeks has the moments. [COPY NEEDED]
    public static func rhythmMissing(_ kind: Rhythm.Kind) -> String {
        kind == .weekday ? "No workdays to go on yet." : "No weekends to go on yet."
    }

    // MARK: Places over time

    public static let placesTitle = "Places over time"
    public static let paused = "Paused"

    /// The design's "12h 10m in September", as a rolling four weeks. [COPY NEEDED]
    public static func recent(_ total: TimeInterval) -> String {
        "\(DurationText.short(total)) in the last 4 weeks"
    }

    /// "Not since Sep 26" (the design's "Not since August 21"; brief: "not since August").
    public static func notSince(_ date: Date, calendar: Calendar) -> String {
        "Not since \(date.formatted(style(calendar).month(.abbreviated).day()))"
    }

    /// "40%".
    public static func change(_ change: Double) -> String {
        "\(Int((abs(change) * 100).rounded()))%"
    }

    /// Too soon for trends. [COPY NEEDED]
    public static let placesWaiting = "Places over time shows up after a few weeks."

    // MARK: Records

    public static let recordsTitle = "Records"

    /// "Oct 22", or "Sep 8 – 19" for a run.
    public static func recordDate(_ record: PersonalRecord, calendar: Calendar) -> String? {
        guard let date = record.date else { return nil }
        let end = DwellDay(containing: date, calendar: calendar)
        guard let startDate = record.startDate else {
            return date.formatted(style(calendar).month(.abbreviated).day())
        }
        return ClockText.dayRange(DwellDay(containing: startDate, calendar: calendar), end, calendar: calendar)
    }

    // MARK: Year in places

    /// "2026 in places, so far" (Time design).
    public static func yearCaption(_ year: Int, isCurrent: Bool) -> String {
        isCurrent ? "\(year) in places, so far" : "\(year) in places"
    }

    /// "86 places, 3.2% of Brooklyn, 14 records." (Time design.) Plain facts at every dial
    /// position until the copy deck voices the year. [COPY NEEDED] Peace and Grind.
    public static func yearTitle(places: Int, coverage: ScratchCoverage?, records: Int) -> String {
        var parts = [places == 1 ? "1 place" : "\(places) places"]
        if let coverage, coverage.uncovered > 0 {
            parts.append("\(percent(coverage.fraction)) of \(coverage.area)")
        }
        parts.append(records == 1 ? "1 record" : "\(records) records")
        return parts.joined(separator: ", ") + "."
    }

    public static let openYear = "Open your year"

    /// "3.2%".
    public static func percent(_ fraction: Double) -> String {
        let value = (fraction * 1000).rounded() / 10
        return value == value.rounded() ? "\(Int(value))%" : "\(value)%"
    }

    // MARK: States

    /// The range is younger than Dwell's record of you (brief §3.1, day 3: "still learning your
    /// week"). [COPY NEEDED] Peace and Grind.
    public static func stillLearning(_ range: TimeRange, daysToGo: Int) -> VoicedLine {
        let days = daysToGo == 1 ? "1 day" : "\(daysToGo) days"
        return VoicedLine(
            peace: "Still getting to know your \(range.noun). \(days) to go.",
            plain: "Still learning your \(range.noun) · \(days) to go",
            grind: "Still learning your \(range.noun). \(days) of data to go.")
    }

    /// Nothing recorded yet, ever (the install day). [COPY NEEDED]
    public static let waitingTitle = VoicedLine(
        peace: "Your time will gather here",
        plain: "Time fills in as you go",
        grind: "Nothing to count yet")

    public static let waitingDetail = VoicedLine(
        peace: "Your first place shows up tonight. No rush.",
        plain: "Your first place shows up here tonight.",
        grind: "First place tonight. Then the numbers.")

    /// A period from before Dwell was recording. [COPY NEEDED]
    public static func beforeRecording(this: String) -> VoicedLine {
        VoicedLine(fixed: "Dwell wasn't recording yet \(this).")
    }

    /// [COPY NEEDED]
    public static let couldNotLoad = "Time couldn't load"

    // MARK: Formatting

    private static func style(_ calendar: Calendar) -> Date.FormatStyle {
        Date.FormatStyle(locale: calendar.locale ?? .current, calendar: calendar, timeZone: calendar.timeZone)
    }

    private static func monthName(_ day: DwellDay, calendar: Calendar, withYear: Bool, short: Bool = false) -> String {
        var format = style(calendar).month(short ? .abbreviated : .wide)
        if withYear { format = format.year() }
        return day.start(in: calendar).formatted(format)
    }

    private static func dayShort(_ day: DwellDay, calendar: Calendar) -> String {
        day.start(in: calendar).formatted(style(calendar).month(.abbreviated).day())
    }

    private static func weekdayShort(_ day: DwellDay, calendar: Calendar) -> String {
        day.start(in: calendar).formatted(style(calendar).weekday(.abbreviated))
    }
}
