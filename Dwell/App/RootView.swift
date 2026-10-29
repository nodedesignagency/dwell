import DwellUI
import SwiftUI

/// The four v1 surfaces in the brief's fixed order: Today first, You last.
/// Tab icons follow the Today design's tab bar (house, map, clock, person). The system tab
/// bar stays: on iOS 26 it already floats like the design's.
struct RootView: View {
    enum Tab: Hashable {
        case today
        case map
        case time
        case you
    }

    @State private var tab: Tab = .today

    var body: some View {
        TabView(selection: $tab) {
            TodayScreen(openProfile: { tab = .you })
                .tabItem { Label("Today", systemImage: "house") }
                .tag(Tab.today)
            MapScreen()
                .tabItem { Label("Map", systemImage: "map") }
                .tag(Tab.map)
            TimeScreen()
                .tabItem { Label("Time", systemImage: "clock") }
                .tag(Tab.time)
            YouScreen()
                .tabItem { Label("You", systemImage: "person") }
                .tag(Tab.you)
        }
        .tint(Palette.textPrimary)
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
