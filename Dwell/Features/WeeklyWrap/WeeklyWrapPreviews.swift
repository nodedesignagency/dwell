import DwellCore
import DwellUI
import SwiftUI

// The weekly wrap on the sample: last week, Monday 19 to Sunday 25 October, 7 days and 13
// places (the design's 9 is its own). Voiced text at Peace, Plain and Grind; the numbers must
// match across all three. Stale and the permission banner don't apply: the wrap is a finished
// week, shown full screen without banners.

/// The wrap holding its page, so taps move through it in the canvas.
private struct WrapPreview: View {
    let state: Loadable<WrapOpener>
    @State private var page: WrapPage

    init(_ state: Loadable<WrapOpener>, page: WrapPage = .opener) {
        self.state = state
        _page = State(initialValue: page)
    }

    var body: some View {
        WeeklyWrapContent(
            wrap: SampleData.weeklyWrap,
            state: state,
            page: page,
            actions: WeeklyWrapActions(
                next: { withAnimation(Motion.reduced) { page = page.next ?? .opener } },
                previous: { withAnimation(Motion.reduced) { page = page.previous ?? page } }))
    }
}

private let lastWeek = Loadable<WrapOpener>.loaded(
    WrapOpener(week: SampleData.lastWeek.map(SampleData.snapshot(for:))))

// MARK: The opener, across the dial

#Preview("Opener · Peace") {
    WrapPreview(lastWeek).samplePreview(.peace)
}

#Preview("Opener · Plain") {
    WrapPreview(lastWeek).samplePreview(.plain)
}

#Preview("Opener · Grind") {
    WrapPreview(lastWeek).samplePreview(.grind)
}

#Preview("Opener · dark") {
    WrapPreview(lastWeek).samplePreview()
        .preferredColorScheme(.dark)
}

#Preview("Opener · AX3") {
    WrapPreview(lastWeek).samplePreview()
        .dynamicTypeSize(.accessibility3)
}

#Preview("Opener · Grind · AX5 · dark") {
    WrapPreview(lastWeek).samplePreview(.grind)
        .dynamicTypeSize(.accessibility5)
        .preferredColorScheme(.dark)
}

// MARK: States

#Preview("Loading") {
    WrapPreview(.loading).samplePreview()
}

#Preview("Failed · retry") {
    WrapPreview(.failed(.unavailable)).samplePreview()
}

#Preview("A first week, from Thursday") {
    WrapPreview(.loaded(WrapOpener(days: 4, places: 5))).samplePreview()
}

#Preview("A week with no visits") {
    WrapPreview(.loaded(WrapOpener(days: 7, places: 0))).samplePreview()
}

// MARK: The page's clock

#Preview("Held at 40% of its 7 s") {
    WeeklyWrapContent(
        wrap: SampleData.weeklyWrap,
        state: lastWeek,
        page: .opener,
        clock: StoryClock(duration: 7, elapsed: 2.8))
        .samplePreview()
}

#Preview("Page 3, running") {
    // The canvas runs the clock: the third capsule fills over 7 s.
    WeeklyWrapContent(
        wrap: SampleData.weeklyWrap,
        state: lastWeek,
        page: .weekends,
        clock: StoryClock(duration: 7).resumed(at: .now))
        .samplePreview()
}

// MARK: Pages still to come

#Preview("Page 2, waiting for its design") {
    WrapPreview(lastWeek, page: .workAndYours).samplePreview()
}

// MARK: The real screen, loading the sample week

#Preview("Screen · sample repository") {
    WeeklyWrapScreen(wrap: SampleData.weeklyWrap, onClose: {})
        .samplePreview()
}
