import DwellUI
import SwiftUI

/// The four v1 surfaces in the brief's fixed order: Today first, You last.
///
/// The system `TabView` holds the screens; its own bar is hidden for `DwellTabBar`, the
/// design's glass bar, which sits in the bottom safe area so content scrolls up behind it.
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

        /// Outlined, as in the design's tab bar.
        var symbol: String {
            switch self {
            case .today: "house"
            case .map: "map"
            case .time: "clock"
            case .you: "person"
            }
        }
    }

    @State private var tab: Tab = .today

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
            YouScreen()
                .tag(Tab.you)
                .toolbar(.hidden, for: .tabBar)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            DwellTabBar(selection: $tab)
        }
    }
}

/// Holds a tab's place until its design arrives.
struct PendingScreen: View {
    let title: String
    let systemImage: String

    var body: some View {
        NavigationStack {
            PendingView(title: title, systemImage: systemImage)
                .navigationTitle(title)
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
