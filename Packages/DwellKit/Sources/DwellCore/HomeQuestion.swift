import Foundation

/// "Is this home?" (brief §3.1 day 1, A.2's confirmation card; the flow overview and the
/// sheet's design, 14 Nov: a sheet over Today after the first night). Dwell has seen the
/// user spend a night somewhere and asks whether it's home.
///
/// Only asked when no home is saved: a home set on onboarding's Your places is never asked
/// about.
public struct HomeQuestion: Identifiable, Hashable, Sendable {
    public let id: String
    /// Where the night was spent, as Dwell has it. Shown on the user's own map only: home is
    /// never shared with friends, and never leaves as anything but "Home" (brief §8.2).
    public var coordinate: Coordinate
    /// The place Dwell made of it, when it has one yet.
    public var placeID: PlaceID?

    public init(id: String, coordinate: Coordinate, placeID: PlaceID? = nil) {
        self.id = id
        self.coordinate = coordinate
        self.placeID = placeID
    }
}
