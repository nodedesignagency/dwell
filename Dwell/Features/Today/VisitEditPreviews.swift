import DwellCore
import DwellUI
import SwiftUI

// Visit edit over Today, on the sample week. Monday 26 October: the morning at Kestriva Labs
// (9:14 AM to 12:38 PM, "10-26-3"), Brambleline Café (a long tag, "10-26-1"), the clinic (a
// private place, "10-26-5") and the afternoon still going ("10-26-7"); Friday 23 October's
// morning at home, worked from home ("10-23-3").

private let friday = DwellDay(year: 2026, month: 10, day: 23)

/// The sheet over Today for one of the sample's visits, after `change` (a split, a merge, a
/// moved end), as the screen would open it.
@ViewBuilder
private func visitEdit(
    _ id: VisitID,
    on day: DwellDay = SampleData.today,
    failed: Bool = false,
    saving: Bool = false,
    change: (inout VisitDraft, DaySnapshot) -> Void = { _, _ in }
) -> some View {
    let snapshot = SampleData.snapshot(for: day)
    if let visit = snapshot.entries.compactMap(\.visit).first(where: { $0.id == id }) {
        let draft = changed(VisitDraft(visit: visit, place: visit.placeID.map { SampleData.place($0) }), snapshot, change)
        TodayContent(state: .loaded(.sample(day)), day: day, isToday: day == SampleData.today, now: SampleData.now)
            .promptSheet(isPresented: .constant(true)) {
                VisitEditSheet(
                    request: VisitEditRequest(draft: draft, snapshot: snapshot, now: SampleData.now),
                    onSave: { _ in }, onDelete: { _ in }, failed: failed, saving: saving)
            }
    }
}

private func changed(
    _ draft: VisitDraft,
    _ snapshot: DaySnapshot,
    _ change: (inout VisitDraft, DaySnapshot) -> Void
) -> VisitDraft {
    var draft = draft
    change(&draft, snapshot)
    return draft
}

/// A time on the sample's Monday.
private func monday(_ hour: Int, _ minute: Int) -> Date {
    SampleData.today.start(in: SampleData.calendar).addingTimeInterval(TimeInterval((hour - 4) * 3600 + minute * 60))
}

// MARK: Across the dial (numbers the same; Grind calls yours "Off")

#Preview("Visit edit") {
    visitEdit("10-26-3")
        .samplePreview()
}

#Preview("Visit edit · Peace") {
    visitEdit("10-26-3")
        .samplePreview(.peace)
}

#Preview("Visit edit · Grind") {
    visitEdit("10-26-3")
        .samplePreview(.grind)
}

#Preview("Visit edit · dark") {
    visitEdit("10-26-3")
        .samplePreview()
        .preferredColorScheme(.dark)
}

#Preview("Visit edit · AX3") {
    visitEdit("10-26-3")
        .samplePreview()
        .dynamicTypeSize(.accessibility3)
}

// MARK: Visits

#Preview("Visit edit · still going") {
    visitEdit("10-26-7")
        .samplePreview()
}

#Preview("Visit edit · work from home") {
    visitEdit("10-23-3", on: friday)
        .samplePreview()
}

#Preview("Visit edit · private place") {
    visitEdit("10-26-5")
        .samplePreview()
}

#Preview("Visit edit · café") {
    visitEdit("10-26-1")
        .samplePreview()
}

// MARK: Changes waiting for Save

#Preview("Visit edit · moved") {
    visitEdit("10-26-3") { draft, snapshot in
        draft.moveArrival(to: monday(8, 45), in: snapshot, now: SampleData.now)
    }
    .samplePreview()
}

#Preview("Visit edit · split") {
    visitEdit("10-26-3") { draft, snapshot in
        draft.toggleSplit(in: snapshot, now: SampleData.now)
    }
    .samplePreview()
}

#Preview("Visit edit · merged") {
    visitEdit("10-26-3") { draft, snapshot in
        draft.toggleMerge(in: snapshot)
    }
    .samplePreview()
}

// MARK: Saving

#Preview("Visit edit · saving") {
    visitEdit("10-26-3", saving: true)
        .samplePreview()
}

#Preview("Visit edit · save failed") {
    visitEdit("10-26-3", failed: true)
        .samplePreview()
}

#Preview("Visit edit · save failed · dark AX3") {
    visitEdit("10-26-3", failed: true)
        .samplePreview()
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility3)
}
