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
    @State private var tabBarHeight: CGFloat = 0

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
        .environment(\.tabBarHeight, tabBarHeight)
        .overlay(alignment: .bottom) {
            DwellTabBar(selection: $tab)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { tabBarHeight = $0 }
                // Stays at the bottom under the keyboard, like the system bar.
                .ignoresSafeArea(.keyboard)
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
