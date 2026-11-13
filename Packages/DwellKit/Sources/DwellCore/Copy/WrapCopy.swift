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

    private static func count(_ value: Int, one: String, many: String) -> String {
        "\(value) \(value == 1 ? one : many)"
    }
}
