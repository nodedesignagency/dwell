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
    /// `-DwellState empty` at launch shows one of Today's states (`DWELL_STATE=empty ./scripts/run.sh`).
    private let demo = UserDefaults.standard.string(forKey: "DwellState").flatMap(DemoRepository.Mode.init(rawValue:))

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.dial, Dial(position: dialPosition))
                // No tracking engine yet (CLAUDE.md): run on the sample week, clock ticking.
                .sampleWeek(launchedAt: launch, repository: demo.map { DemoRepository($0) as any DwellRepository } ?? SampleRepository())
                .environment(\.skyPhase, sky)
                .environment(\.permissions, demo?.permissions ?? .full)
        }
    }
}
