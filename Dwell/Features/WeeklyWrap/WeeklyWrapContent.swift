import DwellCore
import DwellUI
import SwiftUI

/// The weekly wrap's pages (S-06), in the order of the designer's flow (13 Nov), all seven
/// designed.
enum WrapPage: Int, CaseIterable, Identifiable {
    case opener
    case workAndYours
    case weekends
    case mostTime
    case earliestExit
    case explorer
    case postcard

    var id: Int { rawValue }

    var next: WrapPage? { WrapPage(rawValue: rawValue + 1) }
    var previous: WrapPage? { WrapPage(rawValue: rawValue - 1) }

    /// How long a page stays before moving on by itself, as an Instagram story does (the
    /// user, 13 Nov: 5–10 s; 7 s reads a title and a sentence without hurrying). Every page,
    /// the postcard too (the user, 14 Nov: the timer shows on all); when the postcard's runs
    /// out its bar stays full and the page stays, so its share buttons don't go anywhere.
    var duration: TimeInterval? {
        7
    }

    /// The header's colour: white on the colourful pages, the app's ink over the explorer
    /// page's light map (Weekly Wrap 6), its pages to come at 10% there, as drawn.
    var headerInk: Color {
        self == .explorer ? Palette.textPrimary : .white
    }

    var headerTrack: Double {
        self == .explorer ? 0.1 : StoryProgress.track
    }
}

struct WeeklyWrapActions {
    var next: () -> Void = {}
    var previous: () -> Void = {}
    var close: () -> Void = {}
    var retry: () -> Void = {}
    /// A finger is down (true) or lifted (false): the page's clock pauses while it's held.
    var hold: (Bool) -> Void = { _ in }
    /// The page's clock stops for as long as the page shows: someone started sharing it.
    var stopClock: () -> Void = {}
}

/// The weekly wrap as the designer draws it: a full-screen story, a page at a time. Each page
/// has its colour behind it and the same header on top ("Your weekly recap", the week, the
/// close button, the progress bar). As in an Instagram story, a tap on the right half moves
/// on and a tap on the left half goes back (mirrored for right-to-left languages). VoiceOver
/// moves with the progress bar (swipe up or down) or each page's own actions, and the escape
/// gesture closes.
///
/// Pages move on by themselves as their clock runs out (`WeeklyWrapScreen`). A finger held on
/// the page pauses it, and letting go carries on without moving; only a quick tap moves.
struct WeeklyWrapContent: View {
    let wrap: WeeklyWrap
    let state: Loadable<WrapWeek>
    let page: WrapPage
    /// How far the page has run; `nil` when it waits for a tap.
    var clock: StoryClock? = nil
    var actions = WeeklyWrapActions()

    /// A press longer than this is a hold: it pauses, and lifting the finger doesn't move on.
    private static let holdThreshold: TimeInterval = 0.25

    @Environment(\.calendar) private var calendar
    @Environment(\.layoutDirection) private var layoutDirection
    /// Where the header ends, down from the top of the screen. Pages keep their words below it.
    @State private var headerBottom: CGFloat = 136
    @State private var width: CGFloat = 393
    @State private var pressBegan: Date?
    @State private var lastPress: TimeInterval = 0

    var body: some View {
        ZStack(alignment: .top) {
            WrapBackdrop()

            pageView
                .id(page)
                .transition(.opacity)

            StoryHeader(
                title: WrapCopy.header,
                subtitle: ClockText.dayRange(wrap.firstDay, wrap.lastDay, calendar: calendar),
                pageCount: WrapPage.allCases.count,
                current: page.rawValue,
                clock: clock,
                ink: page.headerInk,
                track: page.headerTrack,
                closeLabel: WrapCopy.close,
                onClose: actions.close,
                onStep: { direction in
                    switch direction {
                    case .increment: actions.next()
                    case .decrement: actions.previous()
                    @unknown default: break
                    }
                })
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.frame(in: .global).maxY
                } action: { bottom in
                    headerBottom = bottom
                }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .contentShape(.rect)
        .onTapGesture { location in
            // A hold only paused the page; letting go carries on, as on Instagram.
            let held = pressBegan.map { Date.now.timeIntervalSince($0) } ?? lastPress
            guard held < Self.holdThreshold else { return }
            let fromLeading = layoutDirection == .rightToLeft ? width - location.x : location.x
            if fromLeading < width / 2 {
                actions.previous()
            } else {
                actions.next()
            }
        }
        .onLongPressGesture(minimumDuration: Self.holdThreshold, maximumDistance: 12) {
            // Holding pauses; there's nothing to do once it counts as a hold.
        } onPressingChanged: { isPressing in
            if isPressing {
                pressBegan = .now
            } else {
                lastPress = pressBegan.map { Date.now.timeIntervalSince($0) } ?? 0
                pressBegan = nil
            }
            actions.hold(isPressing)
        }
        .accessibilityAction(.escape, actions.close)
        // A wrap page is the same in dark mode: its colours are the design's.
        .environment(\.colorScheme, .light)
    }

    /// Keeps a page's words below the header, and as far from the bottom edge, so they stay
    /// centred on the screen and clear of it at every text size.
    private var reserve: CGFloat {
        headerBottom + Space.l
    }

    @ViewBuilder
    private var pageView: some View {
        switch page {
        case .opener:
            WrapOpenerPage(
                state: state.map(\.opener),
                reserve: reserve,
                onNext: actions.next,
                onRetry: actions.retry)
        case .workAndYours:
            WrapWorkPage(
                state: state.map(\.workAndYours),
                headerBottom: headerBottom,
                onNext: actions.next)
        case .weekends:
            WrapWeekendsPage(
                state: state.map(\.weekends),
                headerBottom: headerBottom,
                onNext: actions.next,
                onRetry: actions.retry)
        case .mostTime:
            WrapMostTimePage(
                state: state.mostTime,
                city: state.value?.city,
                headerBottom: headerBottom,
                onNext: actions.next,
                onRetry: actions.retry)
        case .earliestExit:
            WrapExitPage(
                state: state.map(\.earliestExit),
                headerBottom: headerBottom,
                onNext: actions.next)
        case .explorer:
            WrapExplorerPage(
                state: state.map(\.explorer),
                headerBottom: headerBottom,
                onNext: actions.next,
                onRetry: actions.retry)
        case .postcard:
            WrapPostcardPage(
                state: state.map(\.postcard),
                headerBottom: headerBottom,
                onNext: actions.next,
                onRetry: actions.retry,
                onShare: actions.stopClock)
        }
    }
}

extension Loadable where Value == WrapWeek {
    /// The most-time page's share of the week. Without the user's places no place can be named,
    /// so the page offers Retry.
    var mostTime: Loadable<WrapMostTime?> {
        if case .loaded(let week, _) = self, !week.hasPlaces { return .failed(.unavailable) }
        return map(\.mostTime)
    }
}

extension Loadable {
    /// The same state, holding part of the value: one page's share of the week.
    func map<Part>(_ part: (Value) -> Part) -> Loadable<Part> {
        switch self {
        case .loading: .loading
        case .empty: .empty
        case .stillMapping(let progress): .stillMapping(progress)
        case .failed(let failure): .failed(failure)
        case .loaded(let value, let staleSince): .loaded(part(value), staleSince: staleSince)
        }
    }
}
