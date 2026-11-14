import Foundation

/// A place the place picker offers for a visit (Place picker design, 14 Nov; brief A.7:
/// "nearby, search, somewhere else"): one Dwell knows, or a venue near where the visit was
/// that it hasn't saved yet (the engine saves it on Select).
public struct PlaceCandidate: Identifiable, Hashable, Sendable {
    public var id: String
    /// The place, when Dwell already has it; `nil` for a venue it hasn't saved.
    public var placeID: PlaceID?
    public var name: String
    public var category: PlaceCategory
    public var subcategory: PlaceSubcategory?
    public var coordinate: Coordinate?
    /// How far it is from where the visit was, in metres; `nil` when Dwell can't say.
    public var distance: Double?
    /// Saved as home: a visit there can count as work from home.
    public var isHome: Bool
    /// Private and personal places never go on a map (brief §7.2).
    public var isHiddenFromMaps: Bool

    public init(
        id: String,
        placeID: PlaceID? = nil,
        name: String,
        category: PlaceCategory,
        subcategory: PlaceSubcategory? = nil,
        coordinate: Coordinate? = nil,
        distance: Double? = nil,
        isHome: Bool = false,
        isHiddenFromMaps: Bool = false
    ) {
        self.id = id
        self.placeID = placeID
        self.name = name
        self.category = category
        self.subcategory = subcategory
        self.coordinate = coordinate
        self.distance = distance
        self.isHome = isHome
        self.isHiddenFromMaps = isHiddenFromMaps
    }

    /// A place Dwell has, `distance` from where the visit was.
    public init(place: Place, distance: Double?) {
        self.init(
            id: "place-\(place.id.rawValue)", placeID: place.id, name: place.name,
            category: place.category, subcategory: place.subcategory, coordinate: place.coordinate,
            distance: distance, isHome: place.role == .home || place.category == .home,
            isHiddenFromMaps: place.isHiddenFromMaps)
    }

    /// Whether this is the place a visit is at now: the same place, or the same name for a
    /// venue not saved yet.
    public func isSame(placeID: PlaceID?, name: String) -> Bool {
        if let placeID, let own = self.placeID { return placeID == own }
        return self.placeID == nil && placeID == nil && self.name == name
    }
}

extension Coordinate {
    /// The distance to another point on the Earth's surface, in metres (haversine).
    public func distance(to other: Coordinate) -> Double {
        let radius = 6_371_000.0
        let lat1 = latitude * .pi / 180, lat2 = other.latitude * .pi / 180
        let dLat = lat2 - lat1
        let dLon = (other.longitude - longitude) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * radius * atan2(a.squareRoot(), (1 - a).squareRoot())
    }

    /// A point `metres` away on a compass bearing (0 is north, 90 east).
    public func moved(_ metres: Double, bearing degrees: Double) -> Coordinate {
        let angle = degrees * .pi / 180
        let north = metres * cos(angle), east = metres * sin(angle)
        return Coordinate(
            latitude: latitude + north / 111_320,
            longitude: longitude + east / (111_320 * cos(latitude * .pi / 180)))
    }
}

/// How Dwell writes a short distance: "40 m" and "1.2 km", or "130 ft" and "0.3 mi" where
/// the locale measures roads in miles (the US, the UK). Under a kilometre (1,000 ft) to the
/// nearest 10, never 0; beyond it to a tenth. The brief's units setting (A.6) will choose
/// once it exists; until then, the phone's region.
public enum DistanceText {
    public static func short(_ metres: Double, locale: Locale) -> String {
        let metres = max(0, metres)
        if usesMiles(locale) {
            let feet = metres * 3.280_84
            if feet < 1000 { return "\(roundedToTen(feet)) ft" }
            return "\(tenths(metres / 1609.344, locale: locale)) mi"
        }
        if metres < 1000 { return "\(roundedToTen(metres)) m" }
        return "\(tenths(metres / 1000, locale: locale)) km"
    }

    static func usesMiles(_ locale: Locale) -> Bool {
        locale.measurementSystem == .us || locale.measurementSystem == .uk
    }

    private static func roundedToTen(_ value: Double) -> Int {
        max(10, Int((value / 10).rounded()) * 10)
    }

    private static func tenths(_ value: Double, locale: Locale) -> String {
        value.formatted(.number.precision(.fractionLength(1)).locale(locale))
    }
}
