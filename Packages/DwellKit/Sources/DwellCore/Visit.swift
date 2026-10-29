import Foundation

public struct VisitID: Hashable, Codable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public var description: String { rawValue }
}

/// One stay at one place (brief §9).
public struct Visit: Identifiable, Hashable, Codable, Sendable {
    /// Exact is a geofence or GPS fix. Approximate is shown as approximate, always.
    public enum Precision: String, Codable, Sendable {
        case exact
        case approximate
    }

    public let id: VisitID
    /// `nil` while the place is unknown and the visit waits for "Review this place".
    public var placeID: PlaceID?
    public var placeName: String
    /// Usually the place's category; a work-from-home visit at home counts as work.
    public var category: PlaceCategory
    public var arrival: Date
    /// `nil` while the visit is still going ("→ now").
    public var departure: Date?
    public var precision: Precision
    public var isPrivate: Bool
    public var isWorkFromHome: Bool
    public var needsReview: Bool

    public init(
        id: VisitID,
        placeID: PlaceID?,
        placeName: String,
        category: PlaceCategory,
        arrival: Date,
        departure: Date?,
        precision: Precision = .exact,
        isPrivate: Bool = false,
        isWorkFromHome: Bool = false,
        needsReview: Bool = false
    ) {
        self.id = id
        self.placeID = placeID
        self.placeName = placeName
        self.category = category
        self.arrival = arrival
        self.departure = departure
        self.precision = precision
        self.isPrivate = isPrivate
        self.isWorkFromHome = isWorkFromHome
        self.needsReview = needsReview
    }

    public var isOngoing: Bool { departure == nil }

    /// Arrival to departure, or to `now` while the visit is ongoing.
    public func interval(now: Date) -> DateInterval {
        DateInterval(start: arrival, end: max(arrival, departure ?? now))
    }
}

/// A row of the day, in order. Gaps are shown as gaps, never hidden or filled in.
public enum TimelineEntry: Hashable, Sendable, Identifiable {
    case visit(Visit)
    /// Moving between places. Counts toward Transit; never uncovers a scratch cell.
    case transit(DateInterval)
    /// A stretch with no location: "Dwell was asleep · 42m". Counts toward nothing.
    case gap(DateInterval)

    public var id: String {
        switch self {
        case .visit(let visit): "visit-\(visit.id)"
        case .transit(let interval): "transit-\(interval.start.timeIntervalSince1970)"
        case .gap(let interval): "gap-\(interval.start.timeIntervalSince1970)"
        }
    }

    public func interval(now: Date) -> DateInterval {
        switch self {
        case .visit(let visit): visit.interval(now: now)
        case .transit(let interval), .gap(let interval): interval
        }
    }

    /// The category this time counts toward, or `nil` for a gap.
    public var category: PlaceCategory? {
        switch self {
        case .visit(let visit): visit.category
        case .transit: .transit
        case .gap: nil
        }
    }

    public var visit: Visit? {
        if case .visit(let visit) = self { visit } else { nil }
    }
}
