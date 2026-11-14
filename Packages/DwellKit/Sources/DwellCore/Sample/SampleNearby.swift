import Foundation

/// The place picker's neighbours on the sample week (Place picker design, 14 Nov): made-up
/// venues around where each visit was, as the engine would find them, and search over them and
/// Maya's places. Invented names, like every sample name; none is a real business (the design's
/// "Lucali" is).
extension SampleData {
    struct Venue: Sendable {
        var name: String
        var category: PlaceCategory
        var subcategory: PlaceSubcategory?
    }

    static let venues: [Venue] = [
        Venue(name: "Fernwood Bakery", category: .foodAndDrink, subcategory: .food),
        Venue(name: "Wickfield Coffee", category: .foodAndDrink, subcategory: .coffee),
        Venue(name: "Gable Street Books", category: .shopping),
        Venue(name: "Marrow & Rye", category: .foodAndDrink, subcategory: .food),
        Venue(name: "Linden Yoga", category: .fitness),
        Venue(name: "Pellmore Hardware", category: .shopping),
        Venue(name: "Corner Wash Laundromat", category: .errands),
        Venue(name: "The Tin Lantern", category: .foodAndDrink, subcategory: .drinks),
    ]

    /// Where the visit was, as the engine would have it: 40 m south-west of the place it
    /// guessed (the design's "40 m"). `nil` for a visit with no place on the map.
    static func spot(of visit: Visit) -> Coordinate? {
        guard let id = visit.placeID, let place = places.first(where: { $0.id == id }) else { return nil }
        return place.coordinate?.moved(40, bearing: 225)
    }

    /// Every venue around a spot, each on its own bearing and further out the later it comes;
    /// which comes first turns with `seed`, so each place has neighbours of its own.
    static func venues(around spot: Coordinate, seed: Int) -> [PlaceCandidate] {
        venues.indices.map { index in
            let venue = venues[(index + seed) % venues.count]
            let coordinate = spot.moved(70 + Double(index) * 55, bearing: Double(index) * 67 + 20)
            return PlaceCandidate(
                id: "venue-\(venue.name)", name: venue.name, category: venue.category,
                subcategory: venue.subcategory, coordinate: coordinate,
                distance: spot.distance(to: coordinate))
        }
    }

    /// The three nearest: the place Dwell guessed and the venues beside it.
    public static func nearbyPlaces(for visit: Visit) -> [PlaceCandidate] {
        guard let spot = spot(of: visit) else { return [] }
        let known = places.compactMap { place -> PlaceCandidate? in
            guard let coordinate = place.coordinate else { return nil }
            let distance = spot.distance(to: coordinate)
            return distance < 400 ? PlaceCandidate(place: place, distance: distance) : nil
        }
        let all = known + venues(around: spot, seed: seed(for: visit))
        return Array(all.sorted(by: nearestFirst).prefix(3))
    }

    /// Maya's places and the venues around the visit whose names hold the words.
    public static func searchPlaces(_ query: String, for visit: Visit) -> [PlaceCandidate] {
        let words = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !words.isEmpty else { return [] }
        let spot = spot(of: visit)
        let known = places.map { place in
            PlaceCandidate(place: place, distance: spot.flatMap { here in place.coordinate.map { here.distance(to: $0) } })
        }
        let around = spot.map { venues(around: $0, seed: seed(for: visit)) } ?? []
        return (known + around)
            .filter { $0.name.range(of: words, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
            .sorted(by: nearestFirst)
    }

    private static func seed(for visit: Visit) -> Int {
        (visit.placeID?.rawValue ?? visit.placeName).unicodeScalars.reduce(0) { $0 + Int($1.value) }
    }

    private static func nearestFirst(_ a: PlaceCandidate, _ b: PlaceCandidate) -> Bool {
        (a.distance ?? .infinity) < (b.distance ?? .infinity)
    }
}
