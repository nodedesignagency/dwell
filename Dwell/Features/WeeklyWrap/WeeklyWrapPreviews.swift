import DwellCore
import DwellUI
import SwiftUI

// The weekly wrap on the sample: last week, Monday 19 to Sunday 25 October, 7 days and 13
// places (the design's 9 is its own). Voiced text at Peace, Plain and Grind; the numbers must
// match across all three. Stale and the permission banner don't apply: the wrap is a finished
// week, shown full screen without banners.

/// The wrap holding its page, so taps move through it in the canvas.
private struct WrapPreview: View {
    let state: Loadable<WrapWeek>
    @State private var page: WrapPage

    init(_ state: Loadable<WrapWeek>, page: WrapPage = .opener) {
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

private let sampleWeek = WrapWeek(
    week: SampleData.lastWeek.map(SampleData.snapshot(for:)),
    before: (1...WrapWeek.lookback).reversed().map {
        SampleData.snapshot(for: SampleData.lastWeek[0].adding(days: -$0, in: SampleData.calendar))
    },
    now: SampleData.now,
    calendar: SampleData.calendar)
private let lastWeek = Loadable<WrapWeek>.loaded(sampleWeek)

/// Last week with other numbers on one page.
private func week(
    opener: WrapOpener? = nil,
    work: TimeInterval? = nil,
    yours: TimeInterval? = nil,
    exit: WrapEarliestExit?? = .none
) -> Loadable<WrapWeek> {
    var week = sampleWeek
    if let exit { week.earliestExit = exit }
    if let opener { week.opener = opener }
    if let work { week.workAndYours.work = work }
    if let yours { week.workAndYours.yours = yours }
    return .loaded(week)
}

private let hour: TimeInterval = 3600

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
    WrapPreview(week(opener: WrapOpener(days: 4, places: 5))).samplePreview()
}

#Preview("A week with no visits") {
    WrapPreview(week(opener: WrapOpener(days: 7, places: 0))).samplePreview()
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

// MARK: Work vs yours, across the dial (45h 40m at work, 23h 03m yours: two-thirds purple)

#Preview("Work vs yours · Peace") {
    WrapPreview(lastWeek, page: .workAndYours).samplePreview(.peace)
}

#Preview("Work vs yours · Plain") {
    WrapPreview(lastWeek, page: .workAndYours).samplePreview(.plain)
}

#Preview("Work vs yours · Grind") {
    WrapPreview(lastWeek, page: .workAndYours).samplePreview(.grind)
}

#Preview("Work vs yours · dark") {
    WrapPreview(lastWeek, page: .workAndYours).samplePreview()
        .preferredColorScheme(.dark)
}

#Preview("Work vs yours · AX3") {
    WrapPreview(lastWeek, page: .workAndYours).samplePreview()
        .dynamicTypeSize(.accessibility3)
}

#Preview("Work vs yours · Grind · AX5 · dark") {
    WrapPreview(lastWeek, page: .workAndYours).samplePreview(.grind)
        .dynamicTypeSize(.accessibility5)
        .preferredColorScheme(.dark)
}

// MARK: Work vs yours, the water's level

#Preview("Work vs yours · the design's week (38h 20m, 41h 10m)") {
    WrapPreview(week(work: 38 * hour + 20 * 60, yours: 41 * hour + 10 * 60), page: .workAndYours).samplePreview()
}

#Preview("Work vs yours · nearly all work (52h, 4h)") {
    WrapPreview(week(work: 52 * hour, yours: 4 * hour), page: .workAndYours).samplePreview()
}

#Preview("Work vs yours · a week off (0m, 31h)") {
    WrapPreview(week(work: 0, yours: 31 * hour), page: .workAndYours).samplePreview()
}

#Preview("Work vs yours · loading") {
    WrapPreview(.loading, page: .workAndYours).samplePreview()
}

// MARK: Earliest exit, across the dial (Tuesday 5:52 PM, 13 minutes before her usual 6:05)

#Preview("Earliest exit · Peace") {
    WrapPreview(lastWeek, page: .earliestExit).samplePreview(.peace)
}

#Preview("Earliest exit · Plain") {
    WrapPreview(lastWeek, page: .earliestExit).samplePreview(.plain)
}

#Preview("Earliest exit · Grind") {
    WrapPreview(lastWeek, page: .earliestExit).samplePreview(.grind)
}

#Preview("Earliest exit · dark") {
    WrapPreview(lastWeek, page: .earliestExit).samplePreview()
        .preferredColorScheme(.dark)
}

#Preview("Earliest exit · AX3") {
    WrapPreview(lastWeek, page: .earliestExit).samplePreview()
        .dynamicTypeSize(.accessibility3)
}

#Preview("Earliest exit · Grind · AX5 · dark") {
    WrapPreview(lastWeek, page: .earliestExit).samplePreview(.grind)
        .dynamicTypeSize(.accessibility5)
        .preferredColorScheme(.dark)
}

// MARK: Earliest exit, other weeks

/// Last week's exit (5:52 PM, 832 minutes after 4 AM) against another usual.
private func exitAgainst(usual: Double?) -> WrapEarliestExit? {
    sampleWeek.earliestExit.map { exit in
        var exit = exit
        exit.usualMinutes = usual
        return exit
    }
}

#Preview("Earliest exit · the design's 38 minutes") {
    WrapPreview(week(exit: exitAgainst(usual: 832 + 38)), page: .earliestExit).samplePreview()
}

#Preview("Earliest exit · later than usual") {
    WrapPreview(week(exit: exitAgainst(usual: 800)), page: .earliestExit).samplePreview()
}

#Preview("Earliest exit · no usual yet (first weeks)") {
    WrapPreview(week(exit: exitAgainst(usual: nil)), page: .earliestExit).samplePreview()
}

#Preview("Earliest exit · no office this week") {
    WrapPreview(week(exit: .some(nil)), page: .earliestExit).samplePreview()
}

#Preview("Earliest exit · loading") {
    WrapPreview(.loading, page: .earliestExit).samplePreview()
}

// MARK: Pages still to come

#Preview("Page 3, waiting for its design") {
    WrapPreview(lastWeek, page: .weekends).samplePreview()
}

// MARK: The real screen, loading the sample week

#Preview("Screen · sample repository") {
    WeeklyWrapScreen(wrap: SampleData.weeklyWrap, onClose: {})
        .samplePreview()
}
