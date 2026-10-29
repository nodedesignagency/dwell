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
    public var role: Role?
    public var shareLevel: ShareLevel
    public var isFavorite: Bool
    public var isPrivate: Bool
    public var lifetimeTotal: TimeInterval
    public var visitCount: Int

    public init(
        id: PlaceID,
        name: String,
        category: PlaceCategory,
        role: Role? = nil,
        shareLevel: ShareLevel = .category,
        isFavorite: Bool = false,
        isPrivate: Bool = false,
        lifetimeTotal: TimeInterval = 0,
        visitCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.role = role
        self.shareLevel = shareLevel
        self.isFavorite = isFavorite
        self.isPrivate = isPrivate
        self.lifetimeTotal = lifetimeTotal
        self.visitCount = visitCount
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
