import Foundation

/// The weekly wrap's words (S-06). Appendix B lines are used verbatim; everything else is a
/// placeholder marked [COPY NEEDED] until the client's copy deck arrives. Numbers are passed
/// in, never written per voice, so they can't differ across the dial.
public enum WrapCopy {
    // MARK: Every page

    /// The design's "Your Weekly Recap", in sentence case (brief §8.6). A label, not voiced.
    public static let header = "Your weekly recap"
    public static let close = "Close"
    /// VoiceOver: the progress bar along the top.
    public static let progress = "Page"

    public static func progressValue(page: Int, of count: Int) -> String {
        "\(page) of \(count)"
    }

    /// VoiceOver actions on a page, for the taps a story takes.
    public static let nextPage = "Next page"
    public static let previousPage = "Previous page"

    /// [COPY NEEDED]
    public static let failed = "Your week couldn't load."
    public static let retry = "Retry"

    // MARK: The opener ("This week.")

    /// Appendix B, "Weekly wrap opener". Plain is the design's.
    public static let openerTitle = VoicedLine(
        peace: "Your week, gently.",
        plain: "This week.",
        grind: "The week. Receipts inside.")

    /// "7 days, 9 places and every hour in between. Here's how it went." Plain is the
    /// design's. [COPY NEEDED] Peace and Grind.
    public static func openerLine(_ opener: WrapOpener) -> VoicedLine {
        let days = count(opener.days, one: "day", many: "days")
        // A week with no visits at all still had its days.
        let span = opener.places > 0
            ? "\(days), \(count(opener.places, one: "place", many: "places"))"
            : days
        return VoicedLine(
            peace: "\(span) and every hour in between. No rush, here's how it went.",
            plain: "\(span) and every hour in between. Here's how it went.",
            grind: "\(span) and every hour in between. Here's the tally.")
    }

    /// The design's "TAP TO CONTINUE", written in sentence case and set in capitals as a
    /// label style, so VoiceOver reads words.
    public static let tapToContinue = "Tap to continue"

    // MARK: Work vs yours

    /// What VoiceOver reads for the page's title art (Weekly wrap design, "Work vs yours"). The
    /// art's words, fixed: an image can't follow the dial (QUESTIONS.md).
    public static let workVsYours = "Work vs yours"

    /// Labels over the two numbers, as Time's tiles: "At work"; "Yours", or "Off" at Grind.
    public static let atWork = TimeCopy.atWork
    public static let yours = TimeCopy.yours

    // MARK: Weekends

    /// The page's title. A weekend without work: Plain is the design's ("Weekends were all
    /// yours."); Peace and Grind are Appendix B's "Weekend, zero work", without "First since
    /// March 8", which needs weekends Dwell doesn't count yet. [COPY NEEDED] the rest.
    public static func weekendsTitle(_ verdict: WrapWeekends.Verdict) -> VoicedLine {
        switch verdict {
        case .allYours:
            VoicedLine(
                peace: "A whole weekend to yourself.",
                plain: "Weekends were all yours.",
                grind: "Zero work this weekend.")
        case .someWork(let work):
            VoicedLine(
                peace: "The weekend held \(DurationText.short(work)) of work.",
                plain: "\(DurationText.short(work)) of work this weekend.",
                grind: "\(DurationText.short(work)) in on the weekend.")
        case .notRecorded:
            VoicedLine(
                peace: "Your weekend went unrecorded.",
                plain: "No weekend on record.",
                grind: "No weekend on record.")
        }
    }

    /// The line under the title. A weekend without work: Peace and Plain are the design's
    /// "Zero work hours Saturday and Sunday."; Grind is the rest of Appendix B's line.
    /// [COPY NEEDED] the rest.
    public static func weekendsLine(_ weekends: WrapWeekends) -> VoicedLine {
        weekendsLine(weekends.verdict, workByDay: weekends.workByDay)
    }

    /// - Parameter workByDay: work on Saturday and on Sunday.
    public static func weekendsLine(_ verdict: WrapWeekends.Verdict, workByDay: [TimeInterval]) -> VoicedLine {
        switch verdict {
        case .allYours:
            return VoicedLine(
                peace: "Zero work hours Saturday and Sunday.",
                plain: "Zero work hours Saturday and Sunday.",
                grind: "Recharged or slacking? Monday decides.")
        case .someWork:
            let days = zip(["Saturday", "Sunday"], workByDay)
                .map { "\($0) \(DurationText.short($1))" }
                .joined(separator: ", ")
            return VoicedLine(peace: "\(days).", plain: "\(days).", grind: "\(days).")
        case .notRecorded:
            let line = "Dwell wasn't recording on Saturday or Sunday."
            return VoicedLine(peace: line, plain: line, grind: line)
        }
    }

    /// Over the weekend's categories: the design's "What you did instead"; with work in the
    /// weekend, what else it held. [COPY NEEDED]
    public static func weekendsBreakdown(_ verdict: WrapWeekends.Verdict) -> String {
        switch verdict {
        case .allYours, .notRecorded: "What you did instead"
        case .someWork: "The rest of your weekend"
        }
    }

    /// "2h more social than last weekend." The design's, at every stop. [COPY NEEDED] Peace
    /// and Grind, and a better name than "other" or "personal" in a sentence.
    public static func weekendsChange(_ change: WrapWeekends.Change) -> VoicedLine {
        let amount = DurationText.short(abs(change.difference))
        let direction = change.difference > 0 ? "more" : "less"
        let line = "\(amount) \(direction) \(change.category.name.lowercased()) than last weekend."
        return VoicedLine(peace: line, plain: line, grind: line)
    }

    /// VoiceOver: the card's rows, Saturday and Sunday picked out.
    public static let weekendsGrid = "Every hour of the week, the weekend picked out" // [COPY NEEDED]

    // MARK: Earliest exit

    /// The page's title (Weekly wrap design, "Earliest exit this week"). Plain is the design's,
    /// as is Grind (Appendix B's early exit ends "Earliest exit this week."). [COPY NEEDED] Peace.
    public static let earliestExitTitle = VoicedLine(
        peace: "Out early this week",
        plain: "Earliest exit this week",
        grind: "Earliest exit this week")

    /// With no office weekday in the week. [COPY NEEDED]
    public static let noExitTitle = VoicedLine(
        peace: "No office this week",
        plain: "No office exits this week",
        grind: "No office days this week")

    /// "38 minutes earlier than your usual. The evening was yours." Plain is the design's (its
    /// last sentence carries Peace's warmth; QUESTIONS.md). Grind borrows Appendix B's "Soft."
    /// [COPY NEEDED] the rest.
    public static func earliestExitLine(_ exit: WrapEarliestExit?) -> VoicedLine {
        guard let exit else {
            return VoicedLine(
                peace: "Every evening was yours.",
                plain: "No weekday at the office, so no exit to time.",
                grind: "No exit to time. Monday's a fresh start.")
        }
        guard let earlier = exit.minutesEarlier else {
            return VoicedLine(
                peace: "Too soon for a usual. Dwell is still learning yours.",
                plain: "No usual to compare with yet.",
                grind: "No usual yet. This one sets the bar.")
        }
        let span = count(abs(earlier), one: "minute", many: "minutes")
        if earlier > 0 {
            return VoicedLine(
                peace: "\(span) before your usual. The whole evening was yours.",
                plain: "\(span) earlier than your usual. The evening was yours.",
                grind: "\(span) earlier than your usual. Soft.")
        }
        if earlier < 0 {
            return VoicedLine(
                peace: "Even your earliest was \(span) past your usual. Evenings will come back.",
                plain: "\(span) later than your usual, even at its earliest.",
                grind: "Even your earliest ran \(span) past your usual.")
        }
        return VoicedLine(
            peace: "Right on your usual. A steady week.",
            plain: "Right on your usual.",
            grind: "Right on your usual. Consistent.")
    }

    // MARK: Postcard

    /// The last page's title (Weekly wrap design, "Postcard from your week"), the design's
    /// at every stop. [COPY NEEDED] Peace and Grind.
    public static let postcardTitle = VoicedLine(
        peace: "Postcard from your week",
        plain: "Postcard from your week",
        grind: "Postcard from your week")

    /// The stamp's heading and rows: plain labels, never voiced (they are data).
    public static let postcardHeading = "My week"
    public static let earliestExitRow = "Earliest exit"
    public static let weekendWorkRow = "Weekend work"
    public static let newPlacesRow = "New places"

    /// "Fri 5:52 PM", or "None" with no office weekday. [COPY NEEDED] "None".
    public static func exitValue(_ exit: WrapEarliestExit?, calendar: Calendar) -> String {
        guard let exit else { return "None" }
        return "\(ClockText.weekday(exit.day, calendar: calendar)) \(ClockText.time(exit.time, calendar: calendar))"
    }

    /// "0m", or "Not recorded" when Dwell saw neither Saturday nor Sunday.
    public static func weekendWorkValue(_ work: TimeInterval?) -> String {
        work.map(DurationText.short) ?? TimeCopy.notRecorded
    }

    /// "2", or a dash when the places didn't load.
    public static func newPlacesValue(_ count: Int?) -> String {
        count.map(String.init) ?? "–"
    }

    /// Under the share buttons: what a shared postcard holds (the design's line, true of the
    /// stamp as built: no place names, no home, no pins).
    public static let sharePrivacy = "Only categories are shared. Never places or home."

    /// The share buttons (the design's five "IG Story" are placeholders; the user's five, 13
    /// Nov). [COPY NEEDED]
    public static let shareInstagram = "IG Story"
    public static let shareMessages = "Messages"
    public static let shareSave = "Save"
    public static let shareCopy = "Copy"
    public static let shareMore = "More"
    /// What VoiceOver adds to "IG Story": it opens the share sheet until Instagram's own
    /// sharing is connected.
    public static let shareInstagramHint = "Shares your postcard" // [COPY NEEDED]
    /// The confirmations after Save and Copy. [COPY NEEDED]
    public static let saved = "Saved to Photos"
    public static let copied = "Copied"
    public static let saveFailed = "Couldn't save. Allow Dwell to add photos in Settings."
    /// The shared image's title in the share sheet. [COPY NEEDED]
    public static let shareTitle = "My week on Dwell"

    /// VoiceOver's reading of the stamp, in one go.
    /// - Parameter totals: the two tiles as spoken: "At work, 42 hours 29 minutes. Yours, …"
    public static func postcardSpoken(_ postcard: WrapPostcard, totals: String, calendar: Calendar) -> String {
        [
            "Postcard. \(postcardHeading).",
            totals,
            "\(earliestExitRow), \(exitValue(postcard.earliestExit, calendar: calendar)).",
            "\(weekendWorkRow), \(weekendWorkValue(postcard.weekendWork)).",
            "\(newPlacesRow), \(newPlacesValue(postcard.newPlaces)).",
        ].joined(separator: " ")
    }

    private static func count(_ value: Int, one: String, many: String) -> String {
        "\(value) \(value == 1 ? one : many)"
    }
}
