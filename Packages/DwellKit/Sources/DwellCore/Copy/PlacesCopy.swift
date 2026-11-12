import Foundation

/// Your places' words. The design's are used as they are; the rest are placeholders marked
/// [COPY NEEDED] until the client's copy deck arrives. Numbers are passed in, never written
/// per voice.
public enum PlacesCopy {
    public static let title = "Your places"
    public static let searchPrompt = "Search places"
    public static let allCategories = "All categories"
    public static let favorites = "Favourites"
    public static let allPlaces = "All places"

    /// "41 places"
    public static func count(_ count: Int) -> String {
        count == 1 ? "1 place" : "\(count) places"
    }

    /// "640h mapped"
    public static func mapped(_ total: TimeInterval) -> String {
        "\(DurationText.total(total)) mapped"
    }

    /// "48 visits"
    public static func visits(_ count: Int) -> String {
        switch count {
        case 0: "No visits yet" // [COPY NEEDED] a saved place Dwell hasn't seen you at
        case 1: "1 visit"
        default: "\(count) visits"
        }
    }

    /// "Since March", or "Since March 2025" when it wasn't this year.
    public static func since(_ date: Date, now: Date, calendar: Calendar) -> String {
        var style = Date.FormatStyle(locale: calendar.locale ?? .current, calendar: calendar, timeZone: calendar.timeZone)
            .month(.wide)
        if calendar.component(.year, from: date) != calendar.component(.year, from: now) {
            style = style.year()
        }
        return "Since \(date.formatted(style))"
    }

    /// The facts under a place's name, shown dot-separated (design: "Work • 48 visits",
    /// "Since March"). Home says how long it has been home, since visits there say little.
    /// A private place says so, as its timeline rows do.
    public static func details(for place: Place, now: Date, calendar: Calendar) -> [String] {
        var details: [String]
        if place.role == .home, let firstSeen = place.firstSeen {
            details = [since(firstSeen, now: now, calendar: calendar)]
        } else {
            details = [place.category.name, visits(place.visitCount)]
        }
        if place.isPrivate {
            details.append("Private")
        }
        return details
    }

    /// The section's label. Set in capitals on screen, as a label style.
    public static func title(of section: PlaceSection.Kind) -> String {
        switch section {
        case .favorites: favorites
        case .all: allPlaces
        }
    }

    // MARK: Empty and failed

    /// No places at all yet: before the first stop. An empty state, so it follows the dial.
    /// [COPY NEEDED] all three.
    public static let emptyTitle = VoicedLine(
        peace: "No places yet",
        plain: "No places yet",
        grind: "Zero places so far")

    /// [COPY NEEDED] all three. The 5 minutes is Today's first-stop wait (TodayCopy.firstStopMinutes).
    public static let emptyDetail = VoicedLine(
        peace: "Stay somewhere for \(TodayCopy.firstStopMinutes) minutes and it will gather here.",
        plain: "A stop of \(TodayCopy.firstStopMinutes) minutes or more puts a place here.",
        grind: "Hold still \(TodayCopy.firstStopMinutes) minutes somewhere. It lands here.")

    /// A search that finds nothing. [COPY NEEDED]
    public static func noMatches(for search: String) -> String {
        "No places match \u{201C}\(search)\u{201D}"
    }

    /// [COPY NEEDED]
    public static let noMatchesDetail = "Check the spelling, or try a category."

    /// Chips that leave nothing to show. [COPY NEEDED]
    public static let nothingFiltered = "No places here"
    /// [COPY NEEDED]
    public static let nothingFilteredDetail = "Try another category, or turn off Favourites."
    /// [COPY NEEDED]
    public static let clearFilters = "Clear filters"

    /// [COPY NEEDED]
    public static let couldNotLoad = "Your places couldn't load"
}
