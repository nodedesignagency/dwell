import DwellCore
import DwellUI
import SwiftUI

/// The weekly wrap (S-06): last week as a story, a page at a time. Presented full screen from
/// Today's invite (T-16), growing out of the card on iOS 18 and later.
///
/// Loads the week's days from the repository for the opener's numbers. Pages move on with a
/// tap, or by themselves once their time is up (`WrapPage.duration`, the progress bar filling
/// as it runs, like an Instagram story), and cross-fade (`Motion.reduced`, the same with
/// Reduce Motion: nothing moves). The clock pauses while a finger is held on the page, while
/// the app is in the background, and on the opener until its numbers are in. With VoiceOver
/// or Switch Control on, pages never move by themselves: they wait for the user. Moving on
/// from the last page closes the wrap.
struct WeeklyWrapScreen: View {
    let wrap: WeeklyWrap
    var onClose: () -> Void

    @Environment(\.repository) private var repository
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @State private var state: Loadable<WrapOpener> = .loading
    @State private var page: WrapPage = .opener
    @State private var attempt = 0
    @State private var clock = StoryClock(duration: WrapPage.opener.duration ?? 0)
    @State private var isHolding = false

    var body: some View {
        WeeklyWrapContent(
            wrap: wrap,
            state: state,
            page: page,
            clock: movesOnByItself ? clock : nil,
            actions: WeeklyWrapActions(
                next: goForward,
                previous: {
                    guard let previous = page.previous else { return }
                    show(previous)
                },
                close: onClose,
                retry: {
                    state = .loading
                    attempt += 1
                },
                hold: { isHolding = $0 }))
            .task(id: attempt) { await load() }
            .onChange(of: shouldRun, initial: true) { _, run in
                clock = run ? clock.resumed(at: .now) : clock.paused(at: .now)
            }
            // Starts again whenever the clock pauses, resumes or starts a page.
            .task(id: clock) {
                guard clock.isRunning else { return }
                try? await Task.sleep(for: .seconds(clock.remaining(at: .now)))
                guard !Task.isCancelled else { return }
                goForward()
            }
    }

    /// The page moves on by itself: it has a duration, and nobody is moving with VoiceOver or
    /// Switch Control.
    private var movesOnByItself: Bool {
        page.duration != nil && !voiceOver && !switchControl
    }

    private var shouldRun: Bool {
        movesOnByItself && !isHolding && scenePhase == .active && (page != .opener || state.value != nil)
    }

    private func goForward() {
        guard let next = page.next else { return onClose() }
        show(next)
    }

    /// Shows a page from its start, its clock running if it can (going back starts the page
    /// over, as on Instagram).
    private func show(_ next: WrapPage) {
        withAnimation(Motion.reduced) { page = next }
        let fresh = StoryClock(duration: next.duration ?? 0)
        clock = shouldRun ? fresh.resumed(at: .now) : fresh
    }

    private func load() async {
        do {
            let week = try await repository.days(from: wrap.firstDay, through: wrap.lastDay)
            state = .loaded(WrapOpener(week: week))
        } catch is CancellationError {
            return
        } catch let error as LoadError {
            state = .failed(error.failure)
        } catch {
            state = .failed((error as? URLError)?.code == .notConnectedToInternet ? .offline : .unavailable)
        }
    }
}

// MARK: - Growing out of the invite

extension EnvironmentValues {
    /// Where Today's invite and the wrap meet for the zoom between them; `nil` turns it off
    /// (Reduce Motion, or no wrap to open).
    @Entry var wrapZoom: Namespace.ID? = nil
}

extension View {
    /// Marks the invite card as where the wrap grows from (iOS 18 and later), its corners
    /// rounded as the card's.
    @ViewBuilder
    func wrapZoomSource(id: some Hashable, in namespace: Namespace.ID?) -> some View {
        if #available(iOS 18.0, *), let namespace {
            matchedTransitionSource(id: id, in: namespace) { source in
                source.clipShape(RoundedRectangle(cornerRadius: Radius.xl))
            }
        } else {
            self
        }
    }

    /// The wrap grows out of the invite card and shrinks back into it on close; a swipe down
    /// closes it too. iOS 18 and later; before that the cover slides up, as any.
    @ViewBuilder
    func wrapZoomTransition(id: some Hashable, in namespace: Namespace.ID?) -> some View {
        if #available(iOS 18.0, *), let namespace {
            navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}
