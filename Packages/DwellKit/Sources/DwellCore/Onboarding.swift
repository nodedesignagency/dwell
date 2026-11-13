import Foundation

/// The pages a new user swipes through before the account (onboarding flow, 13 Nov): the
/// promise, the places that matter, what Dwell shows, and the location ask. The flow goes on
/// to sign-in, age, consent and the dial as their designs arrive.
public enum OnboardingPage: Int, CaseIterable, Hashable, Sendable, Identifiable {
    /// "See where your time goes": Start my world, or I already have an account.
    case myWorld
    /// "Your places": home, work and others by address, all optional.
    case yourPlaces
    /// "See where it all goes": the week, hour by hour.
    case seeWhereItGoes
    /// "Start my day": the When-In-Use location ask (never Always here, brief A.1).
    case startMyDay

    public var id: Int { rawValue }

    public var next: OnboardingPage? { OnboardingPage(rawValue: rawValue + 1) }
    public var previous: OnboardingPage? { OnboardingPage(rawValue: rawValue - 1) }
}

/// What a place is saved as on onboarding's Your places ("Save as: Home · Work · Other").
/// The brief's roles also have gym, school and family (`Place.Role`); the design offers these
/// three, and Other leaves the place's category for its visits to settle.
public enum SetupRole: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
    case home
    case work
    case other

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .home: "Home"
        case .work: "Work"
        case .other: "Other"
        }
    }

    /// The role the saved place takes; Other has none.
    public var placeRole: Place.Role? {
        switch self {
        case .home: .home
        case .work: .work
        case .other: nil
        }
    }

    /// The category the saved place starts in, until its visits say otherwise.
    public var category: PlaceCategory {
        switch self {
        case .home: .home
        case .work: .work
        case .other: .other
        }
    }
}

/// A place typed in on onboarding's Your places and not saved yet. Saving a place does not
/// record a visit (brief A.1): it only tells Dwell what to call it when you stop there.
public struct PlaceDraft: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    /// The address as picked: "214 Kent Ave". Empty until one is.
    public var address: String
    /// The rest of the address, where there is one: "Brooklyn, NY".
    public var area: String?
    /// Where it is. `nil` until an address is picked from the list or a spot on the map:
    /// typed words alone don't place it.
    public var coordinate: Coordinate?
    public var role: SetupRole

    public init(id: UUID = UUID(), address: String = "", area: String? = nil, coordinate: Coordinate? = nil, role: SetupRole) {
        self.id = id
        self.address = address
        self.area = area
        self.coordinate = coordinate
        self.role = role
    }

    /// An address picked and placed: ready to save.
    public var isFilled: Bool {
        coordinate != nil && !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The name the place starts with: "Home" or "Work", or the address for Other. The user
    /// can rename it later in Your places.
    public var name: String {
        switch role {
        case .home, .work: role.name
        case .other: address
        }
    }
}

/// Onboarding's Your places as the user fills it in: the places added so far and the one
/// being entered. Everything here is optional: Skip saves nothing.
public struct PlaceSetup: Hashable, Sendable {
    /// Places moved into the list with "Add more", in the order added.
    public private(set) var added: [PlaceDraft]
    /// The place being entered. The first one starts as Home, as the design shows.
    public var current: PlaceDraft

    public init(added: [PlaceDraft] = []) {
        self.added = added
        current = PlaceDraft(role: Self.suggestedRole(after: added))
    }

    /// "Add more" needs an address picked first.
    public var canAddMore: Bool { current.isFilled }

    /// What Continue saves: every place added and the one being entered, once it has an address.
    public var places: [PlaceDraft] {
        current.isFilled ? added + [current] : added
    }

    /// Moves the place being entered into the list and starts another. Does nothing until
    /// the place has an address.
    public mutating func addMore() {
        guard canAddMore else { return }
        added.append(current)
        current = PlaceDraft(role: Self.suggestedRole(after: added))
    }

    /// Takes a place out of the list.
    public mutating func remove(_ id: PlaceDraft.ID) {
        added.removeAll { $0.id == id }
    }

    /// Words for a place picked on the map, once they come back: the place may be the one being
    /// entered or, by then, in the list.
    public mutating func name(_ id: PlaceDraft.ID, address: String, area: String?) {
        if current.id == id {
            current.address = address
            current.area = area
        } else if let index = added.firstIndex(where: { $0.id == id }) {
            added[index].address = address
            added[index].area = area
        }
    }

    /// The role a new place starts as: home first, then work, then Other. The user can pick
    /// any; a second home is theirs to choose.
    public static func suggestedRole(after places: [PlaceDraft]) -> SetupRole {
        let taken = Set(places.map(\.role))
        return [SetupRole.home, .work].first { !taken.contains($0) } ?? .other
    }
}

/// The example world onboarding shows before the user has anything of their own (brief A.1:
/// "an example world of made-up places"): the sample's made-up places, on one day of its last
/// week, so every page that names them agrees.
public enum OnboardingExample {
    /// A made-up place with its photo and its time on the example day.
    public struct Spot: Identifiable, Hashable, Sendable {
        /// The design's photos, one per example place.
        public enum Photo: String, Hashable, Sendable {
            case home
            case friend
            case cafe
        }

        public var id: PlaceID
        public var name: String
        public var category: PlaceCategory
        public var time: TimeInterval
        /// Where it sits on Your places' map.
        public var coordinate: Coordinate
        public var photo: Photo

        public init(id: PlaceID, name: String, category: PlaceCategory, time: TimeInterval, coordinate: Coordinate, photo: Photo) {
            self.id = id
            self.name = name
            self.category = category
            self.time = time
            self.coordinate = coordinate
            self.photo = photo
        }
    }

    /// Friday 23 October, the sample's one day with home, Mara's place and the café in it.
    public static let day = DwellDay(year: 2026, month: 10, day: 23)

    /// Your places' map as the design frames it: Greenpoint's label 110 pt in and 80 down,
    /// Brownsville's at 264 and 395, about 4,650 pt to a degree of latitude and 3,525 to a
    /// degree of longitude (Mercator at Brooklyn's latitude). Kept at every screen size, so the
    /// example places sit where they're drawn; a wider or taller screen shows more around them.
    /// Example places only: the user's own city isn't known yet (no location until Start my day).
    public enum Map {
        /// The map point at `anchorPoint`.
        public static let anchor = Coordinate(latitude: 40.7300, longitude: -73.9540)
        public static let anchorPoint = (x: 110.0, y: 80.0)
        public static let pointsPerDegree = (latitude: 4650.0, longitude: 3525.0)

        /// The middle and span of a map `width` × `height` points, drawn from the screen's top
        /// left corner.
        public static func region(width: Double, height: Double) -> (center: Coordinate, latitudeDelta: Double, longitudeDelta: Double) {
            let center = Coordinate(
                latitude: anchor.latitude - (height / 2 - anchorPoint.y) / pointsPerDegree.latitude,
                longitude: anchor.longitude + (width / 2 - anchorPoint.x) / pointsPerDegree.longitude)
            return (center, height / pointsPerDegree.latitude, width / pointsPerDegree.longitude)
        }

        /// Where a place lands on that map, in points from its top left corner.
        public static func point(of coordinate: Coordinate) -> (x: Double, y: Double) {
            (anchorPoint.x + (coordinate.longitude - anchor.longitude) * pointsPerDegree.longitude,
             anchorPoint.y - (coordinate.latitude - anchor.latitude) * pointsPerDegree.latitude)
        }
    }

    /// Your places' map (onboarding design: "GF's place 9h" and "Brambleline Café 2h", the
    /// design's own names and numbers): Mara's place and Brambleline Café.
    public static var mapSpots: [Spot] {
        [spot(.friend), spot(.cafe)]
    }

    /// Start my day's photos, back to front (onboarding design: "GF's place 3h", "Home 7h 29m",
    /// "Brambleline Café 2h"): Mara's place, home, Brambleline Café.
    public static var daySpots: [Spot] {
        [spot(.friend), spot(.home), spot(.cafe)]
    }

    /// See where it all goes: the sample's last full week, Monday 19 to Sunday 25 October.
    public static func week(calendar: Calendar) -> TimePeriod {
        TimePeriod(.week, containing: day, calendar: calendar)
    }

    private static func spot(_ photo: Spot.Photo) -> Spot {
        let (id, coordinate): (PlaceID, Coordinate) = switch photo {
        // Where the design pins each photo: by the waterfront in Williamsburg, and in Bushwick.
        case .friend: ("maras", Coordinate(latitude: 40.7114, longitude: -73.9659))
        case .home: ("home", Coordinate(latitude: 40.6782, longitude: -73.9442))
        case .cafe: ("brambleline", Coordinate(latitude: 40.6934, longitude: -73.9026))
        }
        let place = SampleData.place(id)
        return Spot(
            id: id, name: place.name, category: place.category,
            time: time(at: id, on: day), coordinate: coordinate, photo: photo)
    }

    /// Time at a sample place on a sample day, its visits clipped to the day.
    static func time(at id: PlaceID, on day: DwellDay) -> TimeInterval {
        let snapshot = SampleData.snapshot(for: day)
        var total: TimeInterval = 0
        for case .visit(let visit) in snapshot.entries where visit.placeID == id {
            total += visit.interval(now: SampleData.now).intersection(with: snapshot.interval)?.duration ?? 0
        }
        return total
    }
}
