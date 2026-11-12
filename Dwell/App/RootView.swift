import DwellUI
import SwiftUI

/// The four v1 surfaces in the brief's fixed order: Today first, You last.
///
/// The system `TabView` holds the screens; its own bar is hidden for `DwellTabBar`, the
/// design's glass bar, laid over the bottom. A safe-area inset on the `TabView` never reaches
/// the screens inside it (each tab is its own UIKit host), so the bar's measured height goes
/// down through the environment and each screen adds it with `.clearsTabBar()`: content
/// scrolls up behind the glass, and the confirmation card floats above it.
struct RootView: View {
    enum Tab: Hashable, CaseIterable {
        case today
        case map
        case time
        case you

        var title: String {
            switch self {
            case .today: "Today"
            case .map: "Map"
            case .time: "Time"
            case .you: "You"
            }
        }

        /// The design's tab icons: the same on every tab, selected or not.
        var icon: Image {
            switch self {
            case .today: Art.Tab.today
            case .map: Art.Tab.map
            case .time: Art.Tab.time
            case .you: Art.Tab.you
            }
        }
    }

    @State private var tab: Tab
    @State private var tabBarHeight: CGFloat = 0
    private let youPath: [YouPage]

    /// - Parameter open: a page to start on, for reviewing it (`DWELL_OPEN=places ./scripts/run.sh`).
    init(open: LaunchPage? = nil) {
        let tab: Tab = switch open {
        case nil: .today
        case .you, .places: .you
        case .time: .time
        }
        _tab = State(initialValue: tab)
        youPath = open == .places ? [.places] : []
    }

    var body: some View {
        TabView(selection: $tab) {
            TodayScreen(openProfile: { tab = .you })
                .tag(Tab.today)
                .toolbar(.hidden, for: .tabBar)
            MapScreen()
                .tag(Tab.map)
                .toolbar(.hidden, for: .tabBar)
            TimeScreen()
                .tag(Tab.time)
                .toolbar(.hidden, for: .tabBar)
            YouScreen(path: youPath)
                .tag(Tab.you)
                .toolbar(.hidden, for: .tabBar)
        }
        .environment(\.tabBarHeight, tabBarHeight)
        .overlay(alignment: .bottom) {
            DwellTabBar(selection: $tab)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    // A measurement, never an animation: the screens' insets snap to it.
                    var still = Transaction()
                    still.disablesAnimations = true
                    withTransaction(still) { tabBarHeight = height }
                }
                // Stays at the bottom under the keyboard, like the system bar.
                .ignoresSafeArea(.keyboard)
        }
    }
}

/// A page the app can open at launch, for reviewing it in the simulator.
enum LaunchPage: String {
    /// You, the fourth tab.
    case you
    /// Your places, pushed from You.
    case places
    /// The Time tab.
    case time
}

/// Holds a tab's place until its design arrives.
struct PendingScreen: View {
    let title: String
    let systemImage: String

    var body: some View {
        NavigationStack {
            PendingView(title: title, systemImage: systemImage)
                .navigationTitle(title)
                .clearsTabBar()
        }
    }
}

/// Holds a pushed page or a sheet until its design arrives.
struct PendingView: View {
    let title: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text("Waiting for the design."))
    }
}

#Preview {
    RootView()
        .samplePreview()
}
