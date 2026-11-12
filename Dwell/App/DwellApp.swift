import DwellCore
import DwellUI
import SwiftUI
import UIKit

@main
struct DwellApp: App {
    /// Set in onboarding ("Set your dial") and in You. Plain until the user chooses.
    @AppStorage("dial.position") private var dialPosition = Dial.Stop.plain.position
    @State private var launch = Date()
    /// `-DwellSky night` at launch forces Today's sky (`DWELL_SKY=night ./scripts/run.sh`).
    private let sky = UserDefaults.standard.string(forKey: "DwellSky").flatMap(SkyPhase.init(rawValue:))
    /// `-DwellState empty` at launch shows one of Today's states (`DWELL_STATE=empty ./scripts/run.sh`).
    private let demo = UserDefaults.standard.string(forKey: "DwellState").flatMap(DemoRepository.Mode.init(rawValue:))

    init() {
        // Tab labels as in the design: SF Pro Rounded medium, grey until selected. The
        // selected colour follows RootView's tint (ink).
        let size: CGFloat = 12
        let system = UIFont.systemFont(ofSize: size, weight: .medium)
        let rounded = system.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: size) } ?? system
        for state in [UIControl.State.normal, .selected] {
            UITabBarItem.appearance().setTitleTextAttributes([.font: rounded], for: state)
        }
        UITabBar.appearance().unselectedItemTintColor = UIColor(Palette.textSecondary)
    }

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
