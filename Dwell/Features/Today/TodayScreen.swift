import DwellCore
import DwellUI
import SwiftUI
import UIKit

/// Today (brief §7.1): where you are, today's day, what you learned.
///
/// Loads one day from the repository and ticks once a minute, on the minute the live visit
/// started, so the timer never lags. The day pill picks a past day; past days drop the live
/// status, the insights and the confirmation card.
///
/// With location off, "Turn on your location" slides up over Today once per launch, a moment
/// after Today has settled, and the banner's button opens it again. A modal, against brief §8.3; the client approved
/// it (QUESTIONS.md). "Yes, turn on" goes to Settings.
///
/// One card at a time slides up over Today (`TodayPrompt`), in this order: the location sheet;
/// Set your tone, right after onboarding (`ToneSheet`); Is this home?, after the first night
/// while no home is saved (`HomeQuestionSheet`). Each waits for Today to settle, and for the
/// card before it to be gone.
struct TodayScreen: View {
    var openProfile: () -> Void = {}
    /// Opens last week's wrap on this page once Today has loaded, for reviewing it
    /// (`DWELL_OPEN=wrap`, `DWELL_OPEN=wrap3`).
    var opensWrapAt: WrapPage?
    /// Opens this insight's page once Today has loaded, for reviewing it (`DWELL_OPEN=insight`).
    var opensInsight: Insight.ID?

    @Environment(\.repository) private var repository
    @Environment(\.fixedNow) private var fixedNow
    @Environment(\.clockOffset) private var clockOffset
    @Environment(\.calendar) private var calendar
    @Environment(\.openURL) private var openURL
    @Environment(\.permissions) private var permissions
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var state: Loadable<TodayModel> = .loading
    @State private var pickedDay: DwellDay?
    @State private var isPickingDay = false
    @State private var reloads = 0
    @State private var confirmed: Set<VisitID> = []
    @State private var dismissed: Set<Insight.ID> = []
    @State private var openedWraps: Set<WeeklyWrap.ID> = []
    /// The wrap on screen, and the one the invite leaves for once it closes.
    @State private var openWrap: WeeklyWrap?
    @State private var viewedWrap: WeeklyWrap.ID?
    @State private var hasOpenedWrapAtLaunch = false
    /// The page the wrap opens on: the opener, unless launched on another for review.
    @State private var wrapStart: WrapPage = .opener
    @Namespace private var wrapZoom
    @State private var openPlace: PlaceID?
    /// The insight whose page is pushed (Insights design): an inside page, no tab bar.
    @State private var openInsight: Insight?
    @State private var hasOpenedInsightAtLaunch = false
    @State private var pending: PendingSheet?
    /// The card over Today, if any.
    @State private var prompt: TodayPrompt?
    /// The card on screen: kept while it slides away, after `prompt` has gone.
    @State private var shownPrompt: TodayPrompt = .location
    @State private var hasAskedForLocation = false
    @State private var hasAskedHome = false
    @State private var homeConfirmations = 0
    /// Set your tone's dial while it's dragged; saved to the app's dial by "Set my tone".
    @State private var toneDial = Dial.Stop.plain.position
    @AppStorage("dial.position") private var storedDial = Dial.Stop.plain.position
    @AppStorage(ToneSheet.asksKey) private var asksTone = false

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: tickAnchor.addingTimeInterval(-clockOffset), by: 60)) { context in
                let now = fixedNow ?? context.date.addingTimeInterval(clockOffset)
                let today = DwellDay(containing: now, calendar: calendar)
                let day = pickedDay ?? today
                TodayContent(
                    state: displayed(for: day),
                    day: day,
                    isToday: day == today,
                    now: now,
                    actions: actions(day: day, isToday: day == today))
                    .environment(\.wrapZoom, reduceMotion ? nil : wrapZoom)
                    .task(id: LoadKey(day: day, isToday: day == today, attempt: reloads)) {
                        await load(day, isToday: day == today)
                    }
                    .sheet(isPresented: $isPickingDay) {
                        DayPickerSheet(pickedDay: $pickedDay, today: today)
                    }
            }
            .toolbar(.hidden, for: .navigationBar)
            .clearsTabBar()
            .navigationDestination(item: $openPlace) { _ in
                PendingView(title: "Place page", systemImage: "mappin.and.ellipse")
                    .clearsTabBar()
            }
            .navigationDestination(item: $openInsight) { insight in
                InsightScreen(
                    insight: insight,
                    onShare: { pending = .share($0.id) },
                    onNotUseful: dismissInsight)
            }
            .sheet(item: $pending) { sheet in
                PendingView(title: sheet.title, systemImage: sheet.systemImage)
                    .presentationDetents([.medium])
            }
            .fullScreenCover(item: $openWrap, onDismiss: wrapClosed) { wrap in
                WeeklyWrapScreen(wrap: wrap, startsAt: wrapStart, onClose: closeWrap)
                    .wrapZoomTransition(id: wrap.id, in: reduceMotion ? nil : wrapZoom)
            }
            .promptSheet(isPresented: isPrompting) {
                promptCard
            } top: {
                if shownPrompt == .tone {
                    NotificationPreview(ToneSheetCopy.previewLine(for: state.value?.insights ?? []))
                        .environment(\.dial, Dial(position: toneDial))
                }
            }
        }
        .onChange(of: permissions.banner, initial: true) { _, banner in
            guard banner == .locationDenied, !hasAskedForLocation else { return }
            hasAskedForLocation = true
            presentSoon(.location)
        }
        .task {
            // Right after onboarding; the location sheet goes first when location is off.
            guard asksTone, permissions.banner != .locationDenied else { return }
            presentSoon(.tone)
        }
        .onChange(of: prompt) { previous, current in
            // However Set your tone goes (Set my tone, Later, a swipe), Today doesn't ask again.
            if previous == .tone, current == nil { asksTone = false }
        }
        .haptic(.confirm, trigger: confirmed.count + homeConfirmations)
    }

    // MARK: Cards over Today

    @ViewBuilder
    private var promptCard: some View {
        switch shownPrompt {
        case .location:
            PromptSheet(
                titleLines: LocationSheetCopy.titleLines,
                message: LocationSheetCopy.message,
                art: Art.Illustration.place,
                actionTitle: LocationSheetCopy.action,
                closeLabel: LocationSheetCopy.close,
                onAction: {
                    prompt = nil
                    openSettings()
                },
                onClose: { prompt = nil })
        case .tone:
            ToneSheet(
                dial: $toneDial,
                onSet: {
                    storedDial = toneDial
                    prompt = nil
                },
                onLater: { prompt = nil })
        case .home(let question):
            HomeQuestionSheet(
                question: question,
                onLooksRight: {
                    homeConfirmations += 1
                    prompt = nil
                    Task { try? await repository.answerHomeQuestion(question.id, isHome: true) }
                },
                onPickAnother: {
                    prompt = nil
                    Task {
                        // Once the card has slid away: one presentation at a time.
                        try? await Task.sleep(for: .milliseconds(450))
                        pending = .homePicker
                    }
                },
                onClose: { prompt = nil })
        }
    }

    private var isPrompting: Binding<Bool> {
        Binding(get: { prompt != nil }, set: { if !$0 { prompt = nil } })
    }

    /// Slides a card up, unless one is already up.
    private func present(_ next: TodayPrompt) {
        guard prompt == nil else { return }
        if next == .tone { toneDial = storedDial }
        shownPrompt = next
        prompt = next
    }

    /// A moment after Today has settled on screen, so the card arrives on its own.
    private func presentSoon(_ next: TodayPrompt) {
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            present(next)
        }
    }

    // MARK: Weekly wrap

    private func showWrap(_ wrap: WeeklyWrap) {
        viewedWrap = wrap.id
        Task { try? await repository.markWeeklyWrapOpened(wrap.id) }
        withoutAnimationUnderReduceMotion { openWrap = wrap }
    }

    private func closeWrap() {
        withoutAnimationUnderReduceMotion { openWrap = nil }
    }

    /// The invite stays behind the wrap, so the wrap can shrink back into it, and leaves
    /// Today once the wrap has closed.
    private func wrapClosed() {
        wrapStart = .opener
        guard let viewedWrap else { return }
        withAnimation(reduceMotion ? Motion.reduced : Motion.standard) {
            _ = openedWraps.insert(viewedWrap)
        }
    }

    /// Under Reduce Motion the wrap appears and goes at once instead of sliding.
    private func withoutAnimationUnderReduceMotion(_ change: () -> Void) {
        guard reduceMotion else { return change() }
        var still = Transaction()
        still.disablesAnimations = true
        withTransaction(still, change)
    }

    /// "Not useful", from the deck or the insight's page: it leaves the deck.
    private func dismissInsight(_ insight: Insight) {
        dismissed.insert(insight.id)
        Task { try? await repository.dismissInsight(insight.id) }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }

    // MARK: Loading

    private struct LoadKey: Hashable {
        var day: DwellDay
        var isToday: Bool
        var attempt: Int
    }

    private func displayed(for day: DwellDay) -> Loadable<TodayModel> {
        switch state {
        case .loaded(let model, let staleSince):
            guard model.day == day else { return .loading }
            return .loaded(
                model.applying(confirmed: confirmed, dismissed: dismissed, openedWraps: openedWraps),
                staleSince: staleSince)
        default:
            return state
        }
    }

    private func load(_ day: DwellDay, isToday: Bool) async {
        do {
            let snapshot = try await repository.day(day)
            if isToday, snapshot.entries.isEmpty, try await !repository.places().hasRecordedVisit {
                // Day 0: nothing mapped, ever. "Getting started" rather than an empty day.
                state = .stillMapping(MappingProgress(daysCollected: 0, daysNeeded: 1))
                return
            }
            var liveStatus: LiveStatus?
            var insights: [Insight] = []
            var weeklyWrap: WeeklyWrap?
            if isToday {
                liveStatus = try await repository.liveStatus()
                insights = try await repository.insights(for: day)
                // The invite is extra: Today still loads if the wrap doesn't.
                weeklyWrap = try? await repository.weeklyWrap()
            }
            state = .loaded(TodayModel(
                snapshot: snapshot, liveStatus: liveStatus, insights: insights, weeklyWrap: weeklyWrap))
            if let opensWrapAt, !hasOpenedWrapAtLaunch, let weeklyWrap {
                hasOpenedWrapAtLaunch = true
                wrapStart = opensWrapAt
                showWrap(weeklyWrap)
            }
            if let opensInsight, !hasOpenedInsightAtLaunch, let insight = insights.first(where: { $0.id == opensInsight }) {
                hasOpenedInsightAtLaunch = true
                openInsight = insight
            }
            // Is this home? once per launch, after the cards that go before it.
            if isToday, !hasAskedHome, !asksTone, permissions.banner != .locationDenied,
               let question = try? await repository.homeQuestion() {
                hasAskedHome = true
                presentSoon(.home(question))
            }
        } catch is CancellationError {
            return
        } catch let error as LoadError {
            state = .failed(error.failure)
        } catch {
            state = .failed((error as? URLError)?.code == .notConnectedToInternet ? .offline : .unavailable)
        }
    }

    /// Ticks land on whole minutes of the live visit, so "1h 16m" turns over on time.
    private var tickAnchor: Date {
        switch state.value?.liveStatus {
        case .atPlace(let visit): visit.arrival
        case .inTransit(let since): since
        default: Date(timeIntervalSinceReferenceDate: 0)
        }
    }

    // MARK: Actions

    private func actions(day: DwellDay, isToday: Bool) -> TodayActions {
        TodayActions(
            openProfile: openProfile,
            pickDay: { isPickingDay = true },
            retry: { reloads += 1 },
            openPlace: { openPlace = $0 },
            confirm: { visit in
                confirmed.insert(visit.id)
                Task { try? await repository.confirmVisit(visit.id) }
            },
            pickAnother: { pending = .placePicker($0.id) },
            openWeeklyWrap: showWrap,
            openInsight: { openInsight = $0 },
            share: { pending = .share($0.id) },
            notUseful: dismissInsight,
            fixPermission: { banner in
                if banner == .locationDenied {
                    present(.location)
                } else {
                    // "Fix" will open the Always upgrade (O-08) once it is designed.
                    openSettings()
                }
            })
    }
}

/// The cards that slide up over Today, one at a time.
private nonisolated enum TodayPrompt: Hashable {
    /// "Turn on your location".
    case location
    /// "Set your tone", right after onboarding.
    case tone
    /// "Is this home?", after the first night.
    case home(HomeQuestion)
}

/// Sheets whose designs haven't arrived. Each says so instead of guessing.
private enum PendingSheet: Identifiable {
    case placePicker(VisitID)
    /// Is this home?'s "Pick another": the place picker, to choose home.
    case homePicker
    case share(Insight.ID)

    var id: String {
        switch self {
        case .placePicker(let id): "picker-\(id)"
        case .homePicker: "home-picker"
        case .share(let id): "share-\(id)"
        }
    }

    var title: String {
        switch self {
        case .placePicker, .homePicker: "Place picker"
        case .share: "Share preview"
        }
    }

    var systemImage: String {
        switch self {
        case .placePicker, .homePicker: "mappin.and.ellipse"
        case .share: "square.and.arrow.up"
        }
    }
}

#Preview("Screen · sample repository") {
    TodayScreen()
        .samplePreview()
}
