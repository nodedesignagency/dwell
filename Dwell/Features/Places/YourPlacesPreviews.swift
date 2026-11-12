import DwellCore
import DwellUI
import SwiftUI

// Every state of Your places on the sample week (Monday 26 October 2026, 2:47 PM).
// The page's words are plain at every dial position; only the empty state is voiced, so it
// is shown at Peace, Plain and Grind. Numbers never change with the dial.

/// The page in a navigation stack, holding its query so the chips and search work in the canvas.
private struct PlacesPreview: View {
    let state: Loadable<[Place]>
    @State private var query: PlaceQuery

    init(state: Loadable<[Place]>, query: PlaceQuery = PlaceQuery()) {
        self.state = state
        _query = State(initialValue: query)
    }

    var body: some View {
        NavigationStack {
            YourPlacesContent(state: state, query: $query, now: SampleData.now)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private let sample = Loadable<[Place]>.loaded(SampleData.places)

// MARK: Loaded

#Preview("Loaded") {
    PlacesPreview(state: sample).samplePreview()
}

#Preview("Loaded · dark") {
    PlacesPreview(state: sample).samplePreview()
        .preferredColorScheme(.dark)
}

#Preview("Loaded · AX3") {
    PlacesPreview(state: sample).samplePreview()
        .dynamicTypeSize(.accessibility3)
}

#Preview("Loaded · AX3 · dark") {
    PlacesPreview(state: sample).samplePreview()
        .dynamicTypeSize(.accessibility3)
        .preferredColorScheme(.dark)
}

// MARK: Chips and search

#Preview("Favourites only") {
    PlacesPreview(state: sample, query: PlaceQuery(favoritesOnly: true)).samplePreview()
}

#Preview("Food & drink, by visits") {
    PlacesPreview(state: sample, query: PlaceQuery(sort: .mostVisits, category: .foodAndDrink)).samplePreview()
}

#Preview("Search · cafe") {
    PlacesPreview(state: sample, query: PlaceQuery(search: "cafe")).samplePreview()
}

#Preview("Search · no matches") {
    PlacesPreview(state: sample, query: PlaceQuery(search: "airport")).samplePreview()
}

#Preview("Filters · nothing left · dark") {
    PlacesPreview(state: sample, query: PlaceQuery(category: .education, favoritesOnly: true)).samplePreview()
        .preferredColorScheme(.dark)
}

// MARK: Still mapping (the install day: one place) and empty

#Preview("First place") {
    PlacesPreview(state: .loaded(SampleData.FirstPlace.places)).samplePreview()
}

#Preview("Empty · Peace") {
    PlacesPreview(state: .empty).samplePreview(.peace)
}

#Preview("Empty · Plain") {
    PlacesPreview(state: .empty).samplePreview(.plain)
}

#Preview("Empty · Grind") {
    PlacesPreview(state: .empty).samplePreview(.grind)
}

#Preview("Empty · Grind · AX3 · dark") {
    PlacesPreview(state: .empty).samplePreview(.grind)
        .dynamicTypeSize(.accessibility3)
        .preferredColorScheme(.dark)
}

// MARK: Loading, stale, failed

#Preview("Loading") {
    PlacesPreview(state: .loading).samplePreview()
}

#Preview("Stale") {
    PlacesPreview(state: .loaded(SampleData.places, staleSince: SampleData.now.addingTimeInterval(-37 * 60))).samplePreview()
}

#Preview("Failed · retry") {
    PlacesPreview(state: .failed(.unavailable)).samplePreview()
}

#Preview("Offline · retry sync · dark") {
    PlacesPreview(state: .failed(.offline)).samplePreview()
        .preferredColorScheme(.dark)
}
