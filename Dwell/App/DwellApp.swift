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
    /// `-DwellOpen places` at launch opens a page (`DWELL_OPEN=places ./scripts/run.sh`).
    private let open = UserDefaults.standard.string(forKey: "DwellOpen").flatMap(LaunchPage.init(rawValue:))
    /// First run's page, while onboarding shows. The sample account finished onboarding long
    /// ago, so until the client's app state says who's new, onboarding shows only when asked
    /// for (`DWELL_OPEN=onboarding ./scripts/run.sh`); finishing it opens Today.
    @State private var onboarding: OnboardingPage?

    init() {
        // `-DwellFresh YES` at launch forgets what's been seen, so first-sight animations play
        // again (`DWELL_FRESH=1 ./scripts/run.sh`).
        if UserDefaults.standard.bool(forKey: "DwellFresh") {
            FirstSight.reset()
        }
        let open = UserDefaults.standard.string(forKey: "DwellOpen").flatMap(LaunchPage.init(rawValue:))
        _onboarding = State(initialValue: open?.onboardingPage)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let onboarding {
                    OnboardingScreen(startsAt: onboarding, account: open?.accountStep) {
                        withAnimation(Motion.standard) { self.onboarding = nil }
                    }
                    .transition(.opacity)
                } else {
                    RootView(open: open)
                        .transition(.opacity)
                }
            }
            .environment(\.dial, Dial(position: dialPosition))
            // No tracking engine yet (CLAUDE.md): run on the sample week, clock ticking. Continue
            // with Apple signs the sample account in (`AppleSignIn.sample`, the environment's
            // default) until the client's server and Apple team are in.
            .sampleWeek(launchedAt: launch, repository: demo.map { DemoRepository($0) as any DwellRepository } ?? SampleRepository())
            .environment(\.skyPhase, sky)
            .environment(\.permissions, demo?.permissions ?? .full)
        }
    }
}
