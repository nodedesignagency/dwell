import DwellCore
import DwellUI
import SwiftUI

@main
struct DwellApp: App {
    /// Set in onboarding ("Set your dial") and in You. Plain until the user chooses.
    @AppStorage("dial.position") private var dialPosition = Dial.Stop.plain.position
    @State private var launch = Date()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.dial, Dial(position: dialPosition))
                // No tracking engine yet (CLAUDE.md): run on the sample week, clock ticking.
                .sampleWeek(launchedAt: launch)
        }
    }
}
