import Foundation

public struct PlaceID: Hashable, Codable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public var description: String { rawValue }
}

/// A named venue with a category and a share level (brief §9).
public struct Place: Identifiable, Hashable, Codable, Sendable {
    /// The roles a place can be saved under in onboarding.
    public enum Role: String, CaseIterable, Codable, Sendable {
        case home
        case work
        case gym
        case school
        case family
    }

    /// How much of this place may leave the phone on shared surfaces.
    public enum ShareLevel: String, CaseIterable, Codable, Sendable {
        case none
        case category
        case venue
    }

    public let id: PlaceID
    public var name: String
    public var category: PlaceCategory
    /// Coffee, drinks or food within Food & drink, where known (Time's breakdown).
    public var subcategory: PlaceSubcategory?
    public var role: Role?
    public var shareLevel: ShareLevel
    public var isFavorite: Bool
    public var isPrivate: Bool
    public var lifetimeTotal: TimeInterval
    public var visitCount: Int
    /// The first visit, or when the place was saved if it has none yet. Your places reads it
    /// for home ("Since March"), where a count of visits says little.
    public var firstSeen: Date?
    /// When Dwell last saw the user there: the last visit's departure, or now while it goes
    /// on (the brief's place page, "first/last seen"). The weekly wrap's "Last seen".
    public var lastSeen: Date?
    /// Where the place is, for maps (the weekly wrap's most-time and explorer pages). `nil`
    /// until the engine says. Private and personal places never go on a map however they're
    /// placed (`isHiddenFromMaps`).
    public var coordinate: Coordinate?

    public init(
        id: PlaceID,
        name: String,
        category: PlaceCategory,
        subcategory: PlaceSubcategory? = nil,
        role: Role? = nil,
        shareLevel: ShareLevel = .category,
        isFavorite: Bool = false,
        isPrivate: Bool = false,
        lifetimeTotal: TimeInterval = 0,
        visitCount: Int = 0,
        firstSeen: Date? = nil,
        lastSeen: Date? = nil,
        coordinate: Coordinate? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.subcategory = subcategory
        self.role = role
        self.shareLevel = shareLevel
        self.isFavorite = isFavorite
        self.isPrivate = isPrivate
        self.lifetimeTotal = lifetimeTotal
        self.visitCount = visitCount
        self.firstSeen = firstSeen
        self.lastSeen = lastSeen
        self.coordinate = coordinate
    }

    /// Personal and private places are never on any map, the user's own included (brief §7.2).
    public var isHiddenFromMaps: Bool {
        isPrivate || category == .personal
    }
}

/// What may leave the phone (brief §8.2). Share cards are category-level unless the user
/// set a place to venue-level sharing; home is only ever "Home"; personal and private
/// places never appear at all.
public enum SharePolicy {
    /// The label a share card may use for a place, or `nil` when it must be left out.
    public static func label(for place: Place) -> String? {
        if place.isPrivate || place.category == .personal { return nil }
        if place.role == .home || place.category == .home { return PlaceCategory.home.name }
        switch place.shareLevel {
        case .venue: return place.name
        case .category, .none: return place.category.name
        }
    }
}

extension Collection where Element == Place {
    /// Whether any place has a recorded visit yet. Places saved in onboarding don't count:
    /// saving a place doesn't record a visit (brief A.1). False only before the first stop,
    /// when Today shows "Getting started".
    public var hasRecordedVisit: Bool {
        contains { $0.visitCount > 0 }
    }
}
