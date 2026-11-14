import Foundation

/// The words around sharing, the same wherever something is shared (the insight's share sheet;
/// the weekly wrap's postcard says the same through `WrapCopy`). The design's five buttons all
/// read "IG Story"; the five are the user's (13 Nov). [COPY NEEDED] where marked.
public enum ShareCopy {
    /// Under the buttons: what a shared card holds (the design's line).
    public static let privacy = "Only categories are shared. Never places or home."

    /// The five ways to share. [COPY NEEDED]
    public static let instagram = "IG Story"
    public static let messages = "Messages"
    public static let save = "Save"
    public static let copy = "Copy"
    public static let more = "More"

    /// The confirmations after Save and Copy. [COPY NEEDED]
    public static let saved = "Saved to Photos"
    public static let copied = "Copied"
    public static let saveFailed = "Couldn't save. Allow Dwell to add photos in Settings."

    /// VoiceOver's name for the sheet's close button.
    public static let close = "Close"
}
