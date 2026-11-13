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
    }

    var body: some View {
        TabView(selection: $tab) {
            TodayScreen(openProfile: { tab = .you }, opensWrapAt: opensWrapAt, opensInsight: opensInsight)
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
    /// `onboarding2` on Your places (`DWELL_OPEN=onboarding2`).
    case onboarding(page: Int)

    init?(rawValue: String) {
        switch rawValue {
        case "you": self = .you
        case "places": self = .places
        case "time": self = .time
        case "insight": self = .insight
        case "wrap": self = .wrap(page: 1)
        case "onboarding": self = .onboarding(page: 1)
        default:
            if rawValue.hasPrefix("onboarding"), let page = Int(rawValue.dropFirst(10)) {
                self = .onboarding(page: page)
                return
            }
            guard rawValue.hasPrefix("wrap"), let page = Int(rawValue.dropFirst(4)) else { return nil }
            self = .wrap(page: page)
        }
    }

    /// The onboarding page to start on, when this opens onboarding.
    var onboardingPage: OnboardingPage? {
        guard case .onboarding(let page) = self else { return nil }
        return OnboardingPage(rawValue: page - 1) ?? .myWorld
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
