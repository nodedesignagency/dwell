import DwellCore
import DwellUI
import SwiftUI

/// Your places (brief §7.4, A.6): every place Dwell has mapped, favourites first, then all of
/// them by the time spent there. The brief's "Your places" (saved places with favourites) and
/// "Places manager" (all places by lifetime time) in one page, as the design draws it.
///
/// A pushed page: You opens it today (and the Map's "Places you return to" will). Tapping a
/// place opens its place page through `openPlace`, so whichever stack pushed this page decides
/// where that goes. The design's back button stands in for the system bar's.
struct YourPlacesScreen: View {
    var openPlace: (PlaceID) -> Void = { _ in }

    @Environment(\.repository) private var repository
    @Environment(\.fixedNow) private var fixedNow
    @Environment(\.clockOffset) private var clockOffset

    @State private var state: Loadable<[Place]> = .loading
    @State private var query = PlaceQuery()
    @State private var reloads = 0

    var body: some View {
        YourPlacesContent(
            state: state,
            query: $query,
            now: fixedNow ?? Date().addingTimeInterval(clockOffset),
            actions: YourPlacesActions(
                retry: { reloads += 1 },
                openPlace: openPlace))
            .task(id: reloads) { await load() }
            .toolbar(.hidden, for: .navigationBar)
            .clearsTabBar()
    }

    private func load() async {
        if case .failed = state { state = .loading }
        do {
            let places = try await repository.places()
            state = places.isEmpty ? .empty : .loaded(places)
        } catch is CancellationError {
            return
        } catch let error as LoadError {
            state = .failed(error.failure)
        } catch {
            state = .failed((error as? URLError)?.code == .notConnectedToInternet ? .offline : .unavailable)
        }
    }
}

/// What Your places' controls do. Screens wire these; previews leave them empty.
struct YourPlacesActions {
    var retry: () -> Void = {}
    var openPlace: (PlaceID) -> Void = { _ in }
}

#Preview("Screen · sample repository") {
    NavigationStack {
        YourPlacesScreen()
    }
    .samplePreview()
}
