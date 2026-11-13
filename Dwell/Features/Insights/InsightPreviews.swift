import DwellCore
import DwellUI
import SwiftUI

// Every state of the Insights page on the sample week (Monday 26 October 2026, 2:47 PM).
// The sentence is voiced, so the loaded page is shown at Peace, Plain and Grind; the numbers,
// the bars and the tiles are the same at every stop.

/// The design's insight: office time last week against Maya's usual.
private let office = SampleData.insights.first { $0.id == SampleData.officeInsightID } ?? SampleData.insights[0]
private let officeDetail = SampleData.insightDetail(for: office)

/// The page in a navigation stack, as Today pushes it (an inside page: no tab bar).
private struct InsightPreview: View {
    var insight: Insight = office
    var state: Loadable<InsightDetail> = .loaded(officeDetail)
    var span: InsightSpan = .fourWeeks
    var page = 0

    var body: some View {
        NavigationStack {
            InsightContent(insight: insight, state: state, now: SampleData.now, span: span, page: page)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: Loaded, at three stops

#Preview("Loaded · Plain") {
    InsightPreview().samplePreview(.plain)
}

#Preview("Loaded · Peace") {
    InsightPreview().samplePreview(.peace)
}

#Preview("Loaded · Grind") {
    InsightPreview().samplePreview(.grind)
}

#Preview("Loaded · dark") {
    InsightPreview().samplePreview()
        .preferredColorScheme(.dark)
}

#Preview("Loaded · AX3") {
    InsightPreview().samplePreview()
        .dynamicTypeSize(.accessibility3)
}

#Preview("Loaded · AX3 · dark") {
    InsightPreview().samplePreview(.grind)
        .dynamicTypeSize(.accessibility3)
        .preferredColorScheme(.dark)
}

// MARK: The chart

#Preview("3M") {
    InsightPreview(span: .threeMonths).samplePreview()
}

#Preview("4W · earlier weeks") {
    InsightPreview(page: 1).samplePreview()
}

// MARK: Insights with no weeks of their own

#Preview("The hero: Today's chart of its week") {
    InsightPreview(insight: SampleData.insights[0], state: .loaded(SampleData.insightDetail(for: SampleData.insights[0])))
        .samplePreview(.peace)
}

#Preview("A lone number: Red Hook") {
    let cell = SampleData.insights.first { $0.id == "new-cell-red-hook" } ?? SampleData.insights[0]
    return InsightPreview(insight: cell, state: .loaded(SampleData.insightDetail(for: cell)))
        .samplePreview(.grind)
}

// MARK: States

#Preview("Loading") {
    InsightPreview(state: .loading).samplePreview()
}

#Preview("Stale") {
    InsightPreview(state: .loaded(officeDetail, staleSince: SampleData.now.addingTimeInterval(-2 * 3600)))
        .samplePreview()
}

#Preview("Failed") {
    InsightPreview(state: .failed(.unavailable)).samplePreview()
}

#Preview("Offline · dark") {
    InsightPreview(state: .failed(.offline)).samplePreview()
        .preferredColorScheme(.dark)
}
