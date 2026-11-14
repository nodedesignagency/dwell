import Foundation

/// "Set your tone" (screenshot, 14 Nov; brief A.1 "Set your dial", §6): the sheet over Today
/// right after onboarding, the dial with today's insight re-rendering as it's dragged.
public enum ToneSheetCopy {
    public static let title = "Set your tone"
    public static let message = "Pick how Dwell talks to you. Drag it & watch today's insights change."
    /// The design's "Yes, turn on" (the location sheet's words), on the user's call (14 Nov):
    /// the brief's "Set", as the title says it.
    public static let action = "Set my tone"
    /// The close button: the brief's "Later".
    public static let later = "Later"
    /// The preview's app name, as a notification shows it.
    public static let appName = "Dwell"
    /// What VoiceOver calls the preview. [COPY NEEDED]
    public static let previewLabel = "Preview"

    /// The sentence the preview shows while the dial is dragged: a record of today's if there
    /// is one (the design's "Office exit 5:52 PM. Earliest this week."), as records show the
    /// voices furthest apart, else today's lead insight; with none yet (a new account, minutes
    /// after onboarding), Appendix B's early exit as an example.
    public static func previewLine(for insights: [Insight]) -> VoicedLine {
        (insights.first { $0.family == .record } ?? insights.first)?.line ?? example
    }

    /// Appendix B, "Early exit".
    public static let example = VoicedLine(
        peace: "Out by 5:52. The evening is yours.",
        plain: "Office exit 5:52 PM. Earliest this week.",
        grind: "5:52? Soft. Earliest exit this week.")
}

/// "Is this home?" (screenshot, 14 Nov; brief A.2, Appendix B).
public enum HomeQuestionCopy {
    /// Appendix B, "Is this home?".
    public static let title = VoicedLine(
        peace: "Looks like home. Is it?",
        plain: "Is this home?",
        grind: "Home? Confirm it.")
    /// The design's "Home locations and visits are never shared with friends.", reworded on the
    /// user's call (14 Nov): the brief never says "location" for a place (§8.6).
    public static let message = "Where home is, and your visits there, are never shared with friends."
    /// The tag over the spot on the map.
    public static let tag = "Home?"
    /// The brief's buttons (§8.6).
    public static let looksRight = "Looks right"
    public static let pickAnother = "Pick another"
    public static let close = "Not now"
    /// What VoiceOver says for the map. [COPY NEEDED]
    public static let mapLabel = "A map with the place Dwell thinks is home"

    public static var allFixedLines: [String] {
        [message, tag, looksRight, pickAnother, close, mapLabel]
    }
}
