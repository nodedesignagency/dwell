import DwellUI
import SwiftUI

/// The four v1 surfaces in the brief's fixed order: Today first, You last.
/// Tab icons follow the Today design's tab bar: outlined house, map, clock, person, never
/// the filled variants the system would pick. The system tab bar stays: on iOS 26 it already
/// floats like the design's, with a pill behind the selected tab. Labels are styled in
/// DwellApp (SF Pro Rounded, grey until selected).
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
                .tabItem { Label("Today", systemImage: "house").environment(\.symbolVariants, .none) }
                .tag(Tab.today)
            MapScreen()
                .tabItem { Label("Map", systemImage: "map").environment(\.symbolVariants, .none) }
                .tag(Tab.map)
            TimeScreen()
                .tabItem { Label("Time", systemImage: "clock").environment(\.symbolVariants, .none) }
                .tag(Tab.time)
            YouScreen()
                .tabItem { Label("You", systemImage: "person").environment(\.symbolVariants, .none) }
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
