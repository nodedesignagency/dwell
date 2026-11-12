import DwellCore
import DwellUI
import SwiftUI

/// You (brief §7.4). Still waiting for its design; until then it holds the way in to Your
/// places, which the brief puts here ("saved places and the places manager"). When You's
/// design arrives, its places entry pushes `YouPage.places` the same way.
struct YouScreen: View {
    @State private var path: [YouPage]

    /// - Parameter path: pages already open, for `DWELL_OPEN=places ./scripts/run.sh`.
    init(path: [YouPage] = []) {
        _path = State(initialValue: path)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ContentUnavailableView {
                Label("You", systemImage: "person")
            } description: {
                Text(verbatim: "Waiting for the design.")
            } actions: {
                NavigationLink(PlacesCopy.title, value: YouPage.places)
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.textPrimary)
            }
            .navigationTitle("You")
            .clearsTabBar()
            .navigationDestination(for: YouPage.self) { page in
                switch page {
                case .places:
                    YourPlacesScreen(openPlace: { path.append(.place($0)) })
                case .place:
                    // M-07, not designed yet: the same stand-in Today's rows open.
                    PendingView(title: "Place page", systemImage: "mappin.and.ellipse")
                        .clearsTabBar()
                }
            }
        }
    }
}

/// The pages You pushes.
enum YouPage: Hashable {
    case places
    case place(PlaceID)
}

#Preview {
    YouScreen()
        .samplePreview()
}
