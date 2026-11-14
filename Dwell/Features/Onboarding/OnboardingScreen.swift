import DwellCore
import DwellUI
import SwiftUI
import UIKit

/// First run (onboarding flow, 13 Nov): four pages a swipe apart, My world, Your places, See
/// where it all goes and Start my day, each with its own colour and its own dots; then account
/// setup over them (`AccountSetupFlow`: Save your world, the birthday, One last thing, or a
/// stop; screens, 14 Nov); then the rest of the flow as its designs arrive. Full screen, no
/// tabs.
///
/// The pages are laid side by side and slid rather than held in a paging `TabView` or
/// `ScrollView`: each runs edge to edge under the status bar and the home indicator with the
/// screen's edges handed to it, and Reduce Motion can swap the slide for a cross-fade. A drag
/// follows the finger (only across, so a page that scrolls still scrolls) and settles on the
/// nearer page, or the next one when flicked; past the first or the last page it gives a
/// little and springs back. The buttons move on with `Motion.standard`. While a spot is picked
/// on the map the pages hold still. VoiceOver moves with the buttons, or a three-finger swipe.
///
/// The design's colours in every scheme: the pages are coloured pictures, so onboarding stays
/// light in dark mode, as the weekly wrap does.
struct OnboardingScreen: View {
    /// Steps the flow reaches whose designs haven't arrived yet.
    enum Next: String, Identifiable {
        /// I already have an account (the returning user's flow).
        case welcomeBack
        /// Save your world's Continue with phone number: the number and its code.
        case phoneNumber
        /// After One last thing (flow overview: "Set your dial").
        case setYourDial
        /// A stop's "View a no-data preview" (brief A.1 #2a: Today and Time on example data).
        case noDataPreview

        var id: String { rawValue }

        var title: String {
            switch self {
            case .welcomeBack: "Welcome back"
            case .phoneNumber: "Phone number"
            case .setYourDial: "Set your dial"
            case .noDataPreview: "No-data preview"
            }
        }
    }

    let onFinish: () -> Void

    @Environment(\.repository) private var repository
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page: OnboardingPage
    @State private var drag: CGFloat = 0
    @State private var setup = PlaceSetup()
    @State private var isPickingOnMap = false
    @State private var next: Next?
    /// Account setup, once Start my day is answered; `nil` while the pages show.
    @State private var account: AccountSetup?
    @State private var location = LocationAsk()
    @State private var isAskingForLocation = false
    @State private var isInSettings = false

    /// - Parameters:
    ///   - page: the page to start on, for reviewing it (`DWELL_OPEN=onboarding3`).
    ///   - step: an account step to open over Start my day (`DWELL_OPEN=onboarding6`).
    init(startsAt page: OnboardingPage = .myWorld, account step: AccountStep? = nil, onFinish: @escaping () -> Void) {
        _page = State(initialValue: step == nil ? page : .startMyDay)
        _account = State(initialValue: step.map(AccountSetup.reaching))
        self.onFinish = onFinish
    }

    var body: some View {
        GeometryReader { proxy in
            let insets = PageInsets(top: proxy.safeAreaInsets.top, bottom: proxy.safeAreaInsets.bottom)
            let width = proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing
            ZStack {
                ForEach(OnboardingPage.allCases) { item in
                    pageView(item, insets: insets)
                        .frame(width: width)
                        .frame(maxHeight: .infinity)
                        .offset(x: offset(of: item, width: width))
                        .opacity(reduceMotion && item != page ? 0 : 1)
                        .allowsHitTesting(item == page)
                        .accessibilityHidden(item != page)
                }
            }
            .frame(width: width)
            .ignoresSafeArea()
            .simultaneousGesture(paging(width: width), including: isPickingOnMap ? .subviews : .all)
            .accessibilityScrollAction { edge in
                switch edge {
                case .trailing: if let next = page.next { go(to: next) }
                case .leading: if let previous = page.previous { go(to: previous) }
                default: break
                }
            }
        }
        // Covered by account setup or a step waiting for its design: VoiceOver reads what's on top.
        .accessibilityHidden(account != nil || next != nil)
        .ignoresSafeArea(.keyboard)
        .overlay {
            if account != nil {
                GeometryReader { proxy in
                    AccountSetupFlow(
                        setup: Binding(get: { account ?? AccountSetup() }, set: { account = $0 }),
                        insets: PageInsets(top: proxy.safeAreaInsets.top, bottom: proxy.safeAreaInsets.bottom),
                        onLeave: { setAccount(nil) },
                        onPending: { show($0) })
                        .ignoresSafeArea()
                }
                .accessibilityHidden(next != nil)
                .transition(reduceMotion ? .opacity : .move(edge: .trailing))
            }
        }
        .overlay {
            if let next {
                NextStepPending(step: next, onBack: { show(nil) }, onFinish: onFinish)
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing))
            }
        }
        // Flow step 4b: location declined at iOS's question.
        .promptSheet(isPresented: $isAskingForLocation) {
            PromptSheet(
                titleLines: LocationSheetCopy.titleLines,
                message: LocationSheetCopy.message,
                art: Art.Illustration.place,
                actionTitle: LocationSheetCopy.action,
                closeLabel: LocationSheetCopy.close,
                onAction: {
                    isAskingForLocation = false
                    openSettings()
                },
                onClose: {
                    isAskingForLocation = false
                    setAccount(AccountSetup())
                })
        }
        // Back from Settings, whatever was chosen there: on to the next step.
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, isInSettings else { return }
            isInSettings = false
            setAccount(AccountSetup())
        }
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private func pageView(_ item: OnboardingPage, insets: PageInsets) -> some View {
        switch item {
        case .myWorld:
            MyWorldPage(
                insets: insets,
                onStart: { go(to: .yourPlaces) },
                onHaveAccount: { show(.welcomeBack) })
        case .yourPlaces:
            PlacesSetupPage(
                setup: $setup,
                isPickingOnMap: $isPickingOnMap,
                isCurrent: page == .yourPlaces,
                insets: insets,
                onContinue: { savePlaces() },
                onSkip: { go(to: .seeWhereItGoes) })
        case .seeWhereItGoes:
            SeeWhereItGoesPage(
                isCurrent: page == .seeWhereItGoes,
                insets: insets,
                onContinue: { go(to: .startMyDay) })
        case .startMyDay:
            StartMyDayPage(
                isCurrent: page == .startMyDay,
                insets: insets,
                onAllow: { allowLocation() },
                onNotNow: { setAccount(AccountSetup()) })
        }
    }

    // MARK: Paging

    /// Pages sit a screen apart, the one showing at 0, moved by the finger while it drags.
    /// Under Reduce Motion they stack and cross-fade instead.
    private func offset(of item: OnboardingPage, width: CGFloat) -> CGFloat {
        guard !reduceMotion else { return 0 }
        let across = layoutDirection == .rightToLeft ? -1.0 : 1.0
        return (CGFloat(item.rawValue - page.rawValue) * width + drag) * across
    }

    private func paging(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 16)
            .onChanged { value in
                guard !reduceMotion else { return }
                let across = layoutDirection == .rightToLeft ? -1.0 : 1.0
                let dx = value.translation.width * across
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                // Past the first or the last page, the page gives a little and springs back.
                let isPastEnd = (dx < 0 && page.next == nil) || (dx > 0 && page.previous == nil)
                drag = isPastEnd ? dx / 3 : dx
            }
            .onEnded { value in
                let across = layoutDirection == .rightToLeft ? -1.0 : 1.0
                let flung = value.predictedEndTranslation.width * across
                var target = page
                if abs(value.translation.width) > abs(value.translation.height) {
                    if flung < -width / 3, let next = page.next { target = next }
                    if flung > width / 3, let previous = page.previous { target = previous }
                }
                go(to: target)
            }
    }

    private func go(to target: OnboardingPage) {
        withAnimation(reduceMotion ? Motion.reduced : Motion.standard) {
            page = target
            drag = 0
        }
    }

    private func show(_ step: Next?) {
        withAnimation(reduceMotion ? Motion.reduced : Motion.standard) {
            next = step
        }
    }

    /// Opens account setup over the pages (Start my day answered), or closes it (Back on Save
    /// your world).
    private func setAccount(_ setup: AccountSetup?) {
        withAnimation(reduceMotion ? Motion.reduced : Motion.standard) {
            account = setup
        }
    }

    // MARK: Actions

    /// Keeps the places typed in, then moves on. They're the phone's until sign-in; if they
    /// can't be kept, onboarding goes on all the same and they can be added from Your places.
    private func savePlaces() {
        let places = setup.places
        Task { try? await repository.savePlaces(places) }
        go(to: .seeWhereItGoes)
    }

    /// iOS's own question (flow step 4a). Allowed: on to Save your world. Declined: the "Turn on
    /// your location" sheet (flow step 4b), which goes to Settings and then on, or just on.
    private func allowLocation() {
        Task {
            switch await location.ask() {
            case .allowed: setAccount(AccountSetup())
            case .declined: isAskingForLocation = true
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            setAccount(AccountSetup())
            return
        }
        isInSettings = true
        openURL(url)
    }
}

/// Holds a step of the flow until its design arrives: Welcome back for a returning user, the
/// phone number, Set your dial after One last thing, a stop's no-data preview. Back returns to
/// where it was opened from; Go to Today ends onboarding here, so the rest of the app can be
/// reviewed.
struct NextStepPending: View {
    let step: OnboardingScreen.Next
    let onBack: () -> Void
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            OnboardingBackdrop(.sky)
            VStack(spacing: Space.s) {
                ContentUnavailableView(
                    step.title, systemImage: "hourglass",
                    description: Text(verbatim: "Waiting for the design."))
                    .environment(\.colorScheme, .dark)
                Button("Go to Today", action: onFinish) // [COPY NEEDED] a stand-in's button
                    .buttonStyle(.secondary)
                Button("Back", action: onBack)
                    .buttonStyle(.text(.white))
            }
            .padding(.horizontal, Space.screen)
            .padding(.bottom, Space.xxl)
        }
    }
}
