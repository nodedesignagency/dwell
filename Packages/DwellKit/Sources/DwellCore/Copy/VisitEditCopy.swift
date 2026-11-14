import Foundation

/// The visit edit sheet (Visit Edit design, 14 Nov; brief §7.1, A.7). An editing surface, so
/// plain words at every dial position (brief §6: character never lives in settings or rows).
public enum VisitEditCopy {
    /// The design's "Change Place", in sentence case (§8.6).
    public static let changePlace = "Change place"
    public static let split = "Split this visit"
    public static let merge = "Merge with next visit"

    public static let workFromHome = "Working from home"
    /// "Work" is the category's name, so it keeps its capital.
    public static let workFromHomeDetail = "Count as Work, shown as home"
    /// The line when the visit isn't at home, where it can't count as work from home.
    /// [COPY NEEDED]
    public static let workFromHomeElsewhere = "Only for a visit at home"
    public static let keepPrivate = "Keep this visit private"
    public static let keepPrivateDetail = "Hidden from friends and wraps"

    public static let save = "Save"
    public static let delete = "Delete"
    /// Delete asks first: it can't be undone. [COPY NEEDED]
    public static let deleteTitle = "Delete this visit?"
    /// The visit's time counts toward nothing afterwards: it isn't given to another place.
    /// [COPY NEEDED]
    public static let deleteMessage = "Its time won't count toward any place. This can't be undone."
    public static let deleteConfirm = "Delete visit"
    public static let cancel = "Cancel"
    /// Save or Delete didn't reach the engine; the sheet stays open. [COPY NEEDED]
    public static let saveFailed = "Couldn't save. Check your connection and try again."

    /// In place of the map for a private or personal place (brief §7.2). [COPY NEEDED]
    public static let hiddenFromMaps = "Private places stay off the map."

    /// The end of a visit still going, in the time track.
    public static let now = "Now"

    /// "Friday • 6h 33m": when, by Dwell days ("Today", "Yesterday", a weekday within the
    /// week, then the date), and how long.
    public static func subtitle(arrival: Date, duration: TimeInterval, now: Date, calendar: Calendar) -> String {
        let day = WrapCopy.lastSeenValue(arrival, now: now, calendar: calendar)
        return "\(day) • \(DurationText.short(duration))"
    }

    // MARK: VoiceOver [COPY NEEDED]

    /// A timeline row's action that opens the sheet (the long press, for VoiceOver).
    public static let editAction = "Edit visit"

    public static let close = "Close"
    public static let arrived = "Arrived"
    public static let left = "Left"
    public static let splitAt = "Split at"
    /// The time track as a whole.
    public static let span = "Time at this place"
    public static let changePlaceHint = "Opens the place picker"
    public static let splitHint = "Splits the visit in two at the time you choose"
    public static let mergeHint = "Joins this visit with the one after it"
    public static let noNextVisit = "No visit after this one"
    public static let tooShortToSplit = "Too short to split"

    /// "Map. Kestriva Labs."
    public static func mapLabel(_ place: String) -> String {
        "Map. \(place)."
    }
}
