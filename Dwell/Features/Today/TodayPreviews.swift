import DwellCore
import DwellUI
import SwiftUI

// Every state of Today on the sample week (Monday 26 October 2026, 2:47 PM, Kestriva Labs).
// Voiced text at Peace, Plain and Grind; numbers must match across all three.

private func today(
    _ state: Loadable<TodayModel>,
    day: DwellDay = SampleData.today,
    now: Date = SampleData.now
) -> some View {
    TodayContent(state: state, day: day, isToday: day == SampleData.today, now: now)
}

private let monday19 = DwellDay(year: 2026, month: 10, day: 19)

// MARK: Live, across the dial

#Preview("Live · Peace") {
    today(.loaded(.sample())).samplePreview(.peace)
}

#Preview("Live · Plain") {
    today(.loaded(.sample())).samplePreview(.plain)
}

#Preview("Live · Grind") {
    today(.loaded(.sample())).samplePreview(.grind)
}

#Preview("Live · Plain · dark") {
    today(.loaded(.sample())).samplePreview(.plain)
        .preferredColorScheme(.dark)
}

#Preview("Live · Peace · AX3") {
    today(.loaded(.sample())).samplePreview(.peace)
        .dynamicTypeSize(.accessibility3)
}

#Preview("Live · Grind · AX3 · dark") {
    today(.loaded(.sample())).samplePreview(.grind)
        .dynamicTypeSize(.accessibility3)
        .preferredColorScheme(.dark)
}

// MARK: Live status variants

#Preview("In transit") {
    var model = TodayModel.sample()
    model.liveStatus = .inTransit(since: SampleData.now.addingTimeInterval(-12 * 60))
    return today(.loaded(model)).samplePreview()
}

#Preview("Stale · last seen") {
    var model = TodayModel.sample()
    let lastSeen = SampleData.now.addingTimeInterval(-37 * 60)
    model.liveStatus = .lastKnown(placeName: "Kestriva Labs", lastSeen: lastSeen)
    return today(.loaded(model, staleSince: lastSeen)).samplePreview()
}

#Preview("Confirmed · no card") {
    today(.loaded(TodayModel.sample().applying(confirmed: ["10-26-1"], dismissed: [])))
        .samplePreview()
}

// MARK: A past day, with a gap

#Preview("Past day · Mon 19 · Plain") {
    today(.loaded(.sample(monday19)), day: monday19).samplePreview(.plain)
}

#Preview("Past day · Mon 19 · Grind · dark") {
    today(.loaded(.sample(monday19)), day: monday19).samplePreview(.grind)
        .preferredColorScheme(.dark)
}

// MARK: Loading, empty, still mapping, failed

#Preview("Loading") {
    today(.loading).samplePreview()
}

#Preview("Empty · Peace") {
    today(.empty).samplePreview(.peace)
}

#Preview("Empty · Plain") {
    today(.empty).samplePreview(.plain)
}

#Preview("Empty · Grind") {
    today(.empty).samplePreview(.grind)
}

#Preview("Still mapping") {
    today(.stillMapping(MappingProgress(daysCollected: 0, daysNeeded: 1))).samplePreview()
}

#Preview("Failed · retry") {
    today(.failed(.unavailable)).samplePreview()
}

#Preview("Offline · retry sync") {
    today(.failed(.offline)).samplePreview()
        .preferredColorScheme(.dark)
}

// MARK: Permission banners, one at a time

#Preview("Banner · location denied") {
    var model = TodayModel.sample()
    model.liveStatus = .noPermission
    return today(.loaded(model)).samplePreview()
        .environment(\.permissions, Permissions(location: .denied, isPreciseLocationOn: true, motion: .granted))
}

#Preview("Banner · When-In-Use") {
    today(.loaded(.sample())).samplePreview()
        .environment(\.permissions, Permissions(location: .whenInUse, isPreciseLocationOn: true, motion: .granted))
}

#Preview("Banner · precise off · AX3") {
    today(.loaded(.sample())).samplePreview()
        .environment(\.permissions, Permissions(location: .always, isPreciseLocationOn: false, motion: .granted))
        .dynamicTypeSize(.accessibility3)
}

#Preview("Banner · motion denied") {
    today(.loaded(.sample())).samplePreview()
        .environment(\.permissions, Permissions(location: .always, isPreciseLocationOn: true, motion: .denied))
}
