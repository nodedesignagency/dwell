import Foundation

/// The place picker (Place picker design, 14 Nov; brief A.7: "nearby, search, somewhere
/// else"). Plain words at every dial position: it's a form, not a voice.
public enum PlacePickerCopy {
    public static let title = "Where were you?"
    /// For a visit still going. [COPY NEEDED]
    public static let titleNow = "Where are you?"
    public static let searchPrompt = "Search places"
    /// Set in capitals as a label style (as Your places' "FAVOURITES").
    public static let nearby = "Nearby places"
    /// Over search results. [COPY NEEDED]
    public static let results = "Places"
    public static let somewhereElse = "Somewhere else"
    /// The design's "Name it and pick category", with its article.
    public static let somewhereElseDetail = "Name it and pick a category"
    /// The button with nothing picked. [COPY NEEDED]
    public static let pickAPlace = "Pick a place"
    public static let close = "Close"

    // MARK: States [COPY NEEDED]

    public static let noNearby = "No places nearby. Search, or name it yourself."
    public static let failed = "Couldn't find places nearby. Check your connection and try again."
    public static let tryAgain = "Try again"
    public static let saveFailed = "Couldn't save. Check your connection and try again."

    /// "No places called “Lucali”."
    public static func noMatches(_ query: String) -> String {
        "No places called “\(query.trimmingCharacters(in: .whitespacesAndNewlines))”."
    }

    /// "Select Brambleline Café".
    public static func select(_ name: String) -> String {
        "Select \(name)"
    }

    /// "12:40 to 1:25 PM · 45m": when the visit was and how long. The first time drops its AM
    /// or PM when the second has the same; a visit still going runs "to now".
    public static func subtitle(arrival: Date, departure: Date?, now: Date, calendar: Calendar) -> String {
        let duration = DurationText.short(max(0, (departure ?? now).timeIntervalSince(arrival)))
        guard let departure else {
            return "\(ClockText.time(arrival, calendar: calendar)) to now · \(duration)"
        }
        let sameHalf = (calendar.component(.hour, from: arrival) < 12) == (calendar.component(.hour, from: departure) < 12)
        let first = sameHalf ? ClockText.bareTime(arrival, calendar: calendar) : ClockText.time(arrival, calendar: calendar)
        return "\(first) to \(ClockText.time(departure, calendar: calendar)) · \(duration)"
    }

    /// "Food & drink · 40 m": the category and how far, in the phone's units.
    public static func facts(_ candidate: PlaceCandidate, locale: Locale) -> String {
        guard let distance = candidate.distance else { return candidate.category.name }
        return "\(candidate.category.name) · \(DistanceText.short(distance, locale: locale))"
    }

    /// VoiceOver: the map, with the place picked on it.
    public static func mapLabel(_ name: String) -> String {
        "Map. \(name)." // [COPY NEEDED]
    }
}
