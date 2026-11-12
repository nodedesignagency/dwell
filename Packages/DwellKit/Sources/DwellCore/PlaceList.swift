import Foundation

/// How Your places orders its list: the design's first chip, "Most time" by default (the brief's
/// places manager lists "all places by lifetime time", A.6).
public enum PlaceSort: String, CaseIterable, Codable, Sendable, Identifiable {
    case mostTime
    case mostVisits
    case name

    public var id: Self { self }

    /// The chip's label and the menu's item. "Most time" is the design's; the other two are ours.
    public var title: String {
        switch self {
        case .mostTime: "Most time"
        case .mostVisits: "Most visits"
        case .name: "A to Z"
        }
    }
}

/// What Your places shows: the search text and the three chips (sort, category, favourites).
public struct PlaceQuery: Hashable, Codable, Sendable {
    public var search: String
    public var sort: PlaceSort
    /// `nil` is "All categories".
    public var category: PlaceCategory?
    /// The Favourites chip: only favourites, in one section.
    public var favoritesOnly: Bool

    public init(search: String = "", sort: PlaceSort = .mostTime, category: PlaceCategory? = nil, favoritesOnly: Bool = false) {
        self.search = search
        self.sort = sort
        self.category = category
        self.favoritesOnly = favoritesOnly
    }

    /// The search text without the spaces around it. Blank means no search.
    public var searchText: String {
        search.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether a chip leaves places out (sorting never does).
    public var hasFilters: Bool {
        category != nil || favoritesOnly
    }

    /// The query with every filter off and the search cleared; the sort stays.
    public var cleared: PlaceQuery {
        PlaceQuery(sort: sort)
    }

    /// Search matches the place's name or its category's, ignoring case and accents
    /// ("cafe" finds "Brambleline Café").
    public func matches(_ place: Place) -> Bool {
        if let category, place.category != category { return false }
        if favoritesOnly, !place.isFavorite { return false }
        let text = searchText
        guard !text.isEmpty else { return true }
        return Self.contains(place.name, text) || Self.contains(place.category.name, text)
    }

    /// The places in the chosen order. Ties go by name, so the order never jumps around.
    public func sorted(_ places: [Place]) -> [Place] {
        places.sorted { a, b in
            switch sort {
            case .mostTime where a.lifetimeTotal != b.lifetimeTotal:
                return a.lifetimeTotal > b.lifetimeTotal
            case .mostVisits where a.visitCount != b.visitCount:
                return a.visitCount > b.visitCount
            default:
                return a.name.compare(b.name, options: [.caseInsensitive, .diacriticInsensitive, .numeric]) == .orderedAscending
            }
        }
    }

    /// The list as Your places lays it out (design: "Favourites", then "All places", where a
    /// favourite shows in both). With the Favourites chip on, only favourites; while searching,
    /// one list of matches. Sections with nothing in them are left out, so no matches is `[]`.
    public func sections(_ places: [Place]) -> [PlaceSection] {
        let shown = sorted(places.filter(matches))
        guard !shown.isEmpty else { return [] }
        if favoritesOnly {
            return [PlaceSection(kind: .favorites, places: shown)]
        }
        if !searchText.isEmpty {
            return [PlaceSection(kind: .all, places: shown)]
        }
        let favorites = shown.filter(\.isFavorite)
        return (favorites.isEmpty ? [] : [PlaceSection(kind: .favorites, places: favorites)])
            + [PlaceSection(kind: .all, places: shown)]
    }

    /// The categories worth offering in the category menu: those with at least one place,
    /// in the fixed category order.
    public static func categories(in places: [Place]) -> [PlaceCategory] {
        let present = Set(places.map(\.category))
        return PlaceCategory.allCases.filter(present.contains)
    }

    private static func contains(_ text: String, _ search: String) -> Bool {
        text.range(of: search, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
}

/// One titled group of Your places.
public struct PlaceSection: Hashable, Sendable, Identifiable {
    public enum Kind: String, Hashable, Sendable {
        case favorites
        case all
    }

    public var kind: Kind
    public var places: [Place]

    public var id: Kind { kind }

    public init(kind: Kind, places: [Place]) {
        self.kind = kind
        self.places = places
    }
}

extension Collection where Element == Place {
    /// Every minute spent at these places: Your places' "640h mapped".
    public var totalTime: TimeInterval {
        reduce(0) { $0 + $1.lifetimeTotal }
    }
}
