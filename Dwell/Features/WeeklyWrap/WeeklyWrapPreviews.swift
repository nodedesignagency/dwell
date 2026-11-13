import DwellCore
import DwellUI
import SwiftUI

// The weekly wrap on the sample: last week, Monday 19 to Sunday 25 October, 7 days and 13
// places (the design's 9 is its own), and the four weeks before it (the weekend before is 17
// and 18 October). Voiced text at Peace, Plain and Grind; the numbers must
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

private let sampleDays = SampleData.lastWeek.map(SampleData.snapshot(for:))
private let daysBefore = (1...WrapWeek.lookback).reversed().map {
    SampleData.snapshot(for: SampleData.lastWeek[0].adding(days: -$0, in: SampleData.calendar))
}
private let sampleWeek = WrapWeek(
    week: sampleDays,
    before: daysBefore,
    places: SampleData.places,
    city: SampleData.profile.cityCenter,
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

/// Last week with its weekend changed day by day, and the weekend before it as given.
private func weekends(
    _ change: (DaySnapshot) -> DaySnapshot,
    lastWeekend: [DaySnapshot] = Array(daysBefore.suffix(2))
) -> Loadable<WrapWeek> {
    var week = sampleWeek
    week.weekends = WrapWeekends(
        week: sampleDays.map { WrapWeekends.isWeekend($0.day, calendar: SampleData.calendar) ? change($0) : $0 },
        lastWeekend: lastWeekend,
        now: SampleData.now,
        calendar: SampleData.calendar)
    return .loaded(week)
}

/// Saturday with an afternoon at Kestriva Labs, 2 to 4:10 PM.
private let saturdayAtWork = weekends { day in
    guard day.day == SampleData.lastWeek[5] else { return day }
    var day = day
    let start = day.interval.start.addingTimeInterval(10 * 3600)
    day.entries.append(.visit(Visit(
        id: "saturday-work", placeID: "kestriva", placeName: "Kestriva Labs", category: .work,
        arrival: start, departure: start.addingTimeInterval(130 * 60))))
    return day
}

/// The phone was off all weekend: Dwell saw nothing.
private let weekendAsleep = weekends { day in
    var day = day
    day.entries = [.gap(day.interval)]
    return day
}

/// Dwell started on Saturday afternoon the weekend before, so there's nothing to compare.
private let noWeekendBefore = weekends({ $0 }, lastWeekend: daysBefore.suffix(2).map { day in
    var day = day
    day.recordingSince = day.interval.start.addingTimeInterval(10 * 3600)
    return day
})

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
    // The canvas runs the clock: the third capsule fills over 7 s, the tiles flowing.
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

// MARK: Weekends, across the dial (no work Saturday or Sunday; 1h 45m more education)

#Preview("Weekends · Peace") {
    WrapPreview(lastWeek, page: .weekends).samplePreview(.peace)
}

#Preview("Weekends · Plain") {
    WrapPreview(lastWeek, page: .weekends).samplePreview(.plain)
}

#Preview("Weekends · Grind") {
    WrapPreview(lastWeek, page: .weekends).samplePreview(.grind)
}

#Preview("Weekends · dark") {
    WrapPreview(lastWeek, page: .weekends).samplePreview()
        .preferredColorScheme(.dark)
}

#Preview("Weekends · AX3") {
    WrapPreview(lastWeek, page: .weekends).samplePreview()
        .dynamicTypeSize(.accessibility3)
}

#Preview("Weekends · Grind · AX5 · dark") {
    WrapPreview(lastWeek, page: .weekends).samplePreview(.grind)
        .dynamicTypeSize(.accessibility5)
        .preferredColorScheme(.dark)
}

// MARK: Weekends, other weekends

#Preview("Weekends · 2h 10m of work on Saturday") {
    WrapPreview(saturdayAtWork, page: .weekends).samplePreview()
}

#Preview("Weekends · work · Peace") {
    WrapPreview(saturdayAtWork, page: .weekends).samplePreview(.peace)
}

#Preview("Weekends · work · Grind") {
    WrapPreview(saturdayAtWork, page: .weekends).samplePreview(.grind)
}

#Preview("Weekends · Dwell saw nothing") {
    WrapPreview(weekendAsleep, page: .weekends).samplePreview()
}

#Preview("Weekends · no weekend before to compare") {
    WrapPreview(noWeekendBefore, page: .weekends).samplePreview()
}

#Preview("Weekends · loading") {
    WrapPreview(.loading, page: .weekends).samplePreview()
}

#Preview("Weekends · failed · retry") {
    WrapPreview(.failed(.unavailable), page: .weekends).samplePreview()
}

// MARK: Weekends, the pattern on its own (moving; still under Reduce Motion)

#Preview("Slanted tiles, full strength") {
    SlantTiles()
        .ignoresSafeArea()
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

// MARK: Postcard, across the dial (45h 40m, 23h 03m, Tue 5:52 PM, 0m, 2 new places; Brooklyn)

#Preview("Postcard · Peace") {
    WrapPreview(lastWeek, page: .postcard).samplePreview(.peace)
}

#Preview("Postcard · Plain") {
    WrapPreview(lastWeek, page: .postcard).samplePreview(.plain)
}

#Preview("Postcard · Grind (\"Off\" on the tile)") {
    WrapPreview(lastWeek, page: .postcard).samplePreview(.grind)
}

#Preview("Postcard · dark") {
    WrapPreview(lastWeek, page: .postcard).samplePreview()
        .preferredColorScheme(.dark)
}

#Preview("Postcard · AX3") {
    WrapPreview(lastWeek, page: .postcard).samplePreview()
        .dynamicTypeSize(.accessibility3)
}

#Preview("Postcard · Grind · AX5 · dark") {
    WrapPreview(lastWeek, page: .postcard).samplePreview(.grind)
        .dynamicTypeSize(.accessibility5)
        .preferredColorScheme(.dark)
}

// MARK: Postcard, other weeks

/// Last week with the postcard's extras changed.
private func postcardWeek(_ change: (inout WrapWeek) -> Void) -> Loadable<WrapWeek> {
    var week = sampleWeek
    change(&week)
    return .loaded(week)
}

#Preview("Postcard · no office this week") {
    WrapPreview(postcardWeek { $0.earliestExit = nil }, page: .postcard).samplePreview()
}

#Preview("Postcard · a weekend Dwell didn't see") {
    WrapPreview(postcardWeek { $0.weekends.verdict = .notRecorded }, page: .postcard).samplePreview()
}

#Preview("Postcard · places didn't load, no city (no map)") {
    WrapPreview(postcardWeek { $0.newPlaces = nil; $0.city = nil }, page: .postcard).samplePreview()
}

#Preview("Postcard · loading") {
    WrapPreview(.loading, page: .postcard).samplePreview()
}

#Preview("Postcard · failed · retry") {
    WrapPreview(.failed(.unavailable), page: .postcard).samplePreview()
}

// MARK: Postcard, its parts

#Preview("The stamp alone, no map") {
    PostcardStamp(postcard: sampleWeek.postcard)
        .padding(40)
        .background(Palette.wrapPostcardEdge)
        .samplePreview()
}

#Preview("The shared image (1080 × 1920), no map") {
    PostcardShareCard(postcard: sampleWeek.postcard, map: nil)
        .samplePreview()
}

#Preview("Swirl stripes, full strength") {
    SwirlStripes()
        .ignoresSafeArea()
}

// MARK: Pages still to come

#Preview("Page 4, waiting for its design") {
    WrapPreview(lastWeek, page: .mostTime).samplePreview()
}

// MARK: The real screen, loading the sample week

#Preview("Screen · sample repository") {
    WeeklyWrapScreen(wrap: SampleData.weeklyWrap, onClose: {})
        .samplePreview()
}
