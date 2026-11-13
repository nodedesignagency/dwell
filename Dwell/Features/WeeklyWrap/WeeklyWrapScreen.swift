import DwellCore
import DwellUI
import SwiftUI

/// The weekly wrap (S-06): last week as a story, a page at a time. Presented full screen from
/// Today's invite (T-16), growing out of the card on iOS 18 and later.
///
/// Loads the week's days from the repository for the opener's numbers. Pages move on with a
/// tap and cross-fade (`Motion.reduced`, the same with Reduce Motion: nothing moves). Moving on
/// from the last page closes the wrap.
struct WeeklyWrapScreen: View {
    let wrap: WeeklyWrap
    var onClose: () -> Void

    @Environment(\.repository) private var repository
    @State private var state: Loadable<WrapOpener> = .loading
    @State private var page: WrapPage = .opener
    @State private var attempt = 0

    var body: some View {
        WeeklyWrapContent(
            wrap: wrap,
            state: state,
            page: page,
            actions: WeeklyWrapActions(
                next: {
                    guard let next = page.next else { return onClose() }
                    withAnimation(Motion.reduced) { page = next }
                },
                previous: {
                    guard let previous = page.previous else { return }
                    withAnimation(Motion.reduced) { page = previous }
                },
                close: onClose,
                retry: {
                    state = .loading
                    attempt += 1
                }))
            .task(id: attempt) { await load() }
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
