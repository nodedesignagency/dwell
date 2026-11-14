import DwellCore
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

        /// The design's tab icons: the same on every tab, selected or not.
        var icon: Image {
            switch self {
            case .today: Art.Tab.today
            case .map: Art.Tab.map
            case .time: Art.Tab.time
            case .you: Art.Tab.you
            }
        }
    }

    @State private var tab: Tab
    @State private var tabBarHeight: CGFloat = 0
    @State private var tabBarVisibility = TabBarVisibility()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let youPath: [YouPage]
    /// The wrap page to open at launch, if any.
    private let opensWrapAt: WrapPage?
    private let opensInsight: Insight.ID?
    private let opensVisitEdit: VisitID?
    private let opensPlacePicker: VisitID?

    /// - Parameter open: a page to start on, for reviewing it (`DWELL_OPEN=places ./scripts/run.sh`).
    init(open: LaunchPage? = nil) {
        let tab: Tab = switch open {
        case .you?, .places?: .you
        case .time?: .time
        default: .today
        }
        _tab = State(initialValue: tab)
        youPath = open == .places ? [.places] : []
        if case .wrap(let page)? = open {
            opensWrapAt = WrapPage(rawValue: page - 1) ?? .opener
        } else {
            opensWrapAt = nil
        }
        opensInsight = open == .insight ? SampleData.officeInsightID : nil
        // Monday's morning at Kestriva Labs, 9:14 AM to 12:38 PM.
        opensVisitEdit = open == .visitEdit ? VisitID("10-26-3") : nil
        // Monday's café visit Dwell isn't sure about, as Pick another opens it.
        opensPlacePicker = open == .placePicker ? VisitID("10-26-1") : nil
    }

    var body: some View {
        TabView(selection: $tab) {
            TodayScreen(
                openProfile: { tab = .you }, opensWrapAt: opensWrapAt, opensInsight: opensInsight,
                opensVisitEdit: opensVisitEdit, opensPlacePicker: opensPlacePicker)
                .tag(Tab.today)
                .toolbar(.hidden, for: .tabBar)
            MapScreen()
                .tag(Tab.map)
                .toolbar(.hidden, for: .tabBar)
            TimeScreen()
                .tag(Tab.time)
                .toolbar(.hidden, for: .tabBar)
            YouScreen(path: youPath)
                .tag(Tab.you)
                .toolbar(.hidden, for: .tabBar)
        }
        .environment(\.tabBarHeight, tabBarHeight)
        .environment(tabBarVisibility)
        .overlay(alignment: .bottom) {
            let isHidden = tabBarVisibility.isHidden
            let slides = isHidden && !reduceMotion
            DwellTabBar(selection: $tab)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    // A measurement, never an animation: the screens' insets snap to it.
                    var still = Transaction()
                    still.disablesAnimations = true
                    withTransaction(still) { tabBarHeight = height }
                }
                // An inside page sends the bar away (`.hidesTabBar()`): it slides down past
                // the screen's edge, or fades under Reduce Motion. Its measured height stays,
                // so the screens behind keep their insets for its return.
                .visualEffect { content, proxy in
                    content.offset(y: slides ? proxy.size.height + 60 : 0)
                }
                .opacity(isHidden ? 0 : 1)
                .allowsHitTesting(!isHidden)
                .accessibilityHidden(isHidden)
                .motion(value: isHidden)
                // Stays at the bottom under the keyboard, like the system bar.
                .ignoresSafeArea(.keyboard)
        }
    }
}

/// A page the app can open at launch, for reviewing it in the simulator. Nonisolated: it only
/// reads the launch argument, and `DwellApp` parses it in a stored property's default value,
/// where a main-actor initializer can't be passed as a function.
nonisolated enum LaunchPage: Equatable {
    /// You, the fourth tab.
    case you
    /// Your places, pushed from You.
    case places
    /// The Time tab.
    case time
    /// Last week's wrap, over Today, on a page counted from 1: `wrap` opens it at the start,
    /// `wrap3` on its third page (`DWELL_OPEN=wrap3`).
    case wrap(page: Int)
    /// The Insights design's insight, pushed from Today's deck.
    case insight
    /// First run, on a page counted from 1: `onboarding` opens it at the start,
    /// `onboarding2` on Your places (`DWELL_OPEN=onboarding2`); 5 to 7 are account setup's
    /// steps over Start my day (5 Save your world, 6 the birthday, 7 One last thing).
    case onboarding(page: Int)
    /// Account setup stopped: `under16` (Account setup stopped) or `notInRegion`.
    case setupStopped(SetupStop)
    /// Today with Set your tone over it, as onboarding hands over.
    case tone
    /// Today with Visit edit over it, on Monday's morning at Kestriva Labs.
    case visitEdit
    /// Today with the place picker over it, for Monday's café visit.
    case placePicker
    /// The returning user: Welcome back over My world.
    case welcomeBack
    /// Welcome back with Checking up, signing in straight away.
    case checking
    /// Today with Re-consent over it, as when the terms changed.
    case reconsent

    init?(rawValue: String) {
        switch rawValue {
        case "you": self = .you
        case "places": self = .places
        case "time": self = .time
        case "insight": self = .insight
        case "wrap": self = .wrap(page: 1)
        case "onboarding": self = .onboarding(page: 1)
        case "under16": self = .setupStopped(.underSixteen)
        case "notInRegion": self = .setupStopped(.notInRegion)
        case "tone": self = .tone
        case "visitEdit": self = .visitEdit
        case "placePicker": self = .placePicker
        case "welcomeBack": self = .welcomeBack
        case "checking": self = .checking
        case "reconsent": self = .reconsent
        default:
            if rawValue.hasPrefix("onboarding"), let page = Int(rawValue.dropFirst(10)) {
                self = .onboarding(page: page)
                return
            }
            guard rawValue.hasPrefix("wrap"), let page = Int(rawValue.dropFirst(4)) else { return nil }
            self = .wrap(page: page)
        }
    }

    /// The onboarding page to start on, when this opens onboarding: Start my day under an
    /// account step.
    var onboardingPage: OnboardingPage? {
        switch self {
        case .onboarding(let page) where page > OnboardingPage.allCases.count: .startMyDay
        case .onboarding(let page): OnboardingPage(rawValue: page - 1) ?? .myWorld
        case .setupStopped: .startMyDay
        case .welcomeBack, .checking: .myWorld
        default: nil
        }
    }

    /// The account step to open over Start my day, if this opens one.
    var accountStep: AccountStep? {
        switch self {
        case .onboarding(page: 5): .saveYourWorld
        case .onboarding(page: 6): .birthday
        case .onboarding(page: 7): .oneLastThing
        case .setupStopped(let stop): .stopped(stop)
        default: nil
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
