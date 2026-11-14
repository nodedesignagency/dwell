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
    var isSharing = false

    var body: some View {
        NavigationStack {
            InsightContent(insight: insight, state: state, now: SampleData.now, span: span, page: page, isSharing: isSharing)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

/// "Share this insight" on its own, where the sheet floats: 10 in, 21 up, over the dimmed page.
private struct ShareSheetPreview: View {
    var detail: InsightDetail = officeDetail
    var span: InsightSpan = .fourWeeks

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.scrim.ignoresSafeArea()
            ViewThatFits(in: .vertical) {
                sheet
                ScrollView { sheet }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 21)
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    private var sheet: some View {
        InsightShareSheet(detail: detail, span: span, now: SampleData.now, onClose: {})
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

// MARK: Share this insight

#Preview("Share · Plain") {
    ShareSheetPreview().samplePreview(.plain)
}

#Preview("Share · Peace") {
    ShareSheetPreview().samplePreview(.peace)
}

#Preview("Share · Grind") {
    ShareSheetPreview().samplePreview(.grind)
}

#Preview("Share · dark") {
    ShareSheetPreview().samplePreview()
        .preferredColorScheme(.dark)
}

#Preview("Share · AX3") {
    ShareSheetPreview().samplePreview()
        .dynamicTypeSize(.accessibility3)
}

#Preview("Share · 3M") {
    ShareSheetPreview(span: .threeMonths).samplePreview()
}

#Preview("Share · the hero, from Today's deck") {
    ShareSheetPreview(detail: SampleData.insightDetail(for: SampleData.insights[0])).samplePreview(.peace)
}

#Preview("Share · over the page") {
    InsightPreview(isSharing: true).samplePreview()
}

/// What's shared: the 1080 × 1920 image, at 393 pt wide.
#Preview("Share · the image") {
    InsightShareImage(detail: officeDetail, span: .fourWeeks, page: 0, now: SampleData.now)
        .samplePreview()
}
