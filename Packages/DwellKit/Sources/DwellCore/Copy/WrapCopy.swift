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

    private static func count(_ value: Int, one: String, many: String) -> String {
        "\(value) \(value == 1 ? one : many)"
    }
}
