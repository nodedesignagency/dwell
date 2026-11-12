import DwellCore
import DwellUI
import SwiftUI

// Every state of Time on the sample (Monday 26 October 2026, 2:47 PM). Last week (Oct 19 – 25)
// is the full week the design draws; this week has only Monday so far. Voiced text at Peace,
// Plain and Grind; the numbers must match across all three.

/// Time in a navigation stack, holding its range so the control works in the canvas.
private struct TimePreview: View {
    let state: Loadable<TimeOverview>
    @State private var range: TimeRange

    init(_ state: Loadable<TimeOverview>, range: TimeRange = .week) {
        self.state = state
        _range = State(initialValue: range)
    }

    var body: some View {
        NavigationStack {
            TimeContent(
                state: state,
                period: state.value?.period ?? TimePeriod(range, containing: SampleData.today, calendar: SampleData.calendar),
                range: $range,
                now: SampleData.now)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private let calendar = SampleData.calendar
private let lastWeek = TimePeriod(.week, containing: SampleData.lastWeek[0], calendar: calendar)
private let thisWeek = TimePeriod(.week, containing: SampleData.today, calendar: calendar)
private func sample(_ period: TimePeriod) -> Loadable<TimeOverview> { .loaded(.sample(period)) }

// MARK: Last week, across the dial

#Preview("Last week · Peace") {
    TimePreview(sample(lastWeek)).samplePreview(.peace)
}

#Preview("Last week · Plain") {
    TimePreview(sample(lastWeek)).samplePreview(.plain)
}

#Preview("Last week · Grind") {
    TimePreview(sample(lastWeek)).samplePreview(.grind)
}

#Preview("Last week · dark") {
    TimePreview(sample(lastWeek)).samplePreview()
        .preferredColorScheme(.dark)
}

#Preview("Last week · AX3") {
    TimePreview(sample(lastWeek)).samplePreview()
        .dynamicTypeSize(.accessibility3)
}

#Preview("Last week · Grind · AX3 · dark") {
    TimePreview(sample(lastWeek)).samplePreview(.grind)
        .dynamicTypeSize(.accessibility3)
        .preferredColorScheme(.dark)
}

// MARK: Other periods

#Preview("This week (Monday so far)") {
    TimePreview(sample(thisWeek)).samplePreview()
}

#Preview("Today") {
    TimePreview(sample(TimePeriod(.day, containing: SampleData.today, calendar: calendar)), range: .day).samplePreview()
}

#Preview("October") {
    TimePreview(sample(TimePeriod(.month, containing: SampleData.today, calendar: calendar)), range: .month).samplePreview()
}

#Preview("September") {
    TimePreview(sample(TimePeriod(.month, containing: DwellDay(year: 2026, month: 9, day: 1), calendar: calendar)), range: .month)
        .samplePreview()
}

#Preview("2026") {
    TimePreview(sample(TimePeriod(.year, containing: SampleData.today, calendar: calendar)), range: .year).samplePreview()
}

#Preview("Before Dwell started") {
    TimePreview(sample(TimePeriod(.week, containing: DwellDay(year: 2026, month: 8, day: 20), calendar: calendar)))
        .samplePreview()
}

// MARK: Calendar not connected, still learning

#Preview("Calendar not connected") {
    var overview = TimeOverview.sample(lastWeek)
    overview.calendarSection = .notConnected
    return TimePreview(.loaded(overview)).samplePreview()
}

#Preview("Still learning · Grind") {
    var overview = TimeOverview.sample(thisWeek)
    overview.learningDaysToGo = 4
    overview.rhythm = .locked(daysToGo: 11)
    overview.year = nil
    return TimePreview(.loaded(overview)).samplePreview(.grind)
}

// MARK: Loading, still mapping, stale, failed, permission

#Preview("Loading") {
    TimePreview(.loading).samplePreview()
}

#Preview("Nothing mapped yet · Peace") {
    TimePreview(.stillMapping(MappingProgress(daysCollected: 0, daysNeeded: 1))).samplePreview(.peace)
}

#Preview("Nothing mapped yet · Plain") {
    TimePreview(.stillMapping(MappingProgress(daysCollected: 0, daysNeeded: 1))).samplePreview(.plain)
}

#Preview("Nothing mapped yet · Grind · dark") {
    TimePreview(.stillMapping(MappingProgress(daysCollected: 0, daysNeeded: 1))).samplePreview(.grind)
        .preferredColorScheme(.dark)
}

#Preview("Stale") {
    TimePreview(.loaded(.sample(lastWeek), staleSince: SampleData.now.addingTimeInterval(-37 * 60))).samplePreview()
}

#Preview("Failed · retry") {
    TimePreview(.failed(.unavailable)).samplePreview()
}

#Preview("Offline · retry sync · dark") {
    TimePreview(.failed(.offline)).samplePreview()
        .preferredColorScheme(.dark)
}

#Preview("Permission banner") {
    TimePreview(sample(lastWeek)).samplePreview()
        .environment(\.permissions, Permissions(location: .whenInUse, isPreciseLocationOn: true, motion: .granted))
}
