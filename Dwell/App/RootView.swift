import DwellUI
import SwiftUI

/// The four v1 surfaces in the brief's fixed order: Today first, You last.
/// Tab icons are stand-ins until the design sets them.
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
            TodayScreen()
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(Tab.today)
            MapScreen()
                .tabItem { Label("Map", systemImage: "map") }
                .tag(Tab.map)
            TimeScreen()
                .tabItem { Label("Time", systemImage: "chart.bar") }
                .tag(Tab.time)
            YouScreen()
                .tabItem { Label("You", systemImage: "person.crop.circle") }
                .tag(Tab.you)
        }
    }
}

/// Holds a tab's place until its design arrives.
struct PendingScreen: View {
    let title: String
    let systemImage: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: systemImage, description: Text("Waiting for the design."))
                .navigationTitle(title)
        }
    }
}

#Preview {
    RootView()
        .samplePreview()
}
