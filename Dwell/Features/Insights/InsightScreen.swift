import DwellCore
import DwellUI
import SwiftUI

/// Insights (brief A.2: "Tap → detail"; A.7: "Insight detail"; Insights design, 13 Nov): one
/// insight opened from Today's deck, with the weeks behind it, its numbers, Share and
/// Not useful.
///
/// An inside page: pushed over Today with no tab bar (the user's call, 13 Nov), Share and
/// Not useful where the bar would be. Not useful takes the insight off the deck and goes back.
/// Share slides up "Share this insight" (`InsightShareSheet`).
struct InsightScreen: View {
    let insight: Insight
    var onNotUseful: (Insight) -> Void = { _ in }

    @Environment(\.repository) private var repository
    @Environment(\.fixedNow) private var fixedNow
    @Environment(\.clockOffset) private var clockOffset
    @Environment(\.dismiss) private var dismiss

    @State private var state: Loadable<InsightDetail> = .loading
    @State private var reloads = 0

    var body: some View {
        InsightContent(
            insight: insight,
            state: state,
            now: fixedNow ?? Date().addingTimeInterval(clockOffset),
            actions: InsightActions(
                retry: { reloads += 1 },
                notUseful: {
                    onNotUseful(insight)
                    dismiss()
                }))
            .task(id: reloads) { await load() }
            .toolbar(.hidden, for: .navigationBar)
            .hidesTabBar()
    }

    private func load() async {
        if case .failed = state { state = .loading }
        do {
            state = .loaded(try await repository.insightDetail(for: insight))
        } catch is CancellationError {
            return
        } catch let error as LoadError {
            state = .failed(error.failure)
        } catch {
            state = .failed((error as? URLError)?.code == .notConnectedToInternet ? .offline : .unavailable)
        }
    }
}

/// What the Insights page's controls do. Screens wire these; previews leave them empty.
struct InsightActions {
    var retry: () -> Void = {}
    var notUseful: () -> Void = {}
}

#Preview("Screen · sample repository") {
    NavigationStack {
        InsightScreen(insight: SampleData.insights[1])
    }
    .samplePreview()
}
