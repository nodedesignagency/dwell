import DwellCore
import DwellUI
import SwiftUI

@main
struct DwellApp: App {
    /// Set in onboarding ("Set your dial") and in You. Plain until the user chooses.
    @AppStorage("dial.position") private var dialPosition = Dial.Stop.plain.position
    @State private var launch = Date()
    /// `-DwellSky night` at launch forces Today's sky (`DWELL_SKY=night ./scripts/run.sh`).
    private let sky = UserDefaults.standard.string(forKey: "DwellSky").flatMap(SkyPhase.init(rawValue:))

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.dial, Dial(position: dialPosition))
                // No tracking engine yet (CLAUDE.md): run on the sample week, clock ticking.
                .sampleWeek(launchedAt: launch)
                .environment(\.skyPhase, sky)
        }
    }
}
