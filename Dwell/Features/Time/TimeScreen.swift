import DwellCore
import DwellUI
import SwiftUI
import UIKit

/// Time (brief §7.3): where the time goes, by day, week, month and year.
///
/// Opens on the week being lived. The range control switches between day, week, month and
/// year around the same day; the date pill picks another period. Everything for the period
/// loads in one go (`TimeOverview.load`), against the four periods before it.
struct TimeScreen: View {
    @Environment(\.repository) private var repository
    @Environment(\.fixedNow) private var fixedNow
    @Environment(\.clockOffset) private var clockOffset
    @Environment(\.calendar) private var calendar
    @Environment(\.openURL) private var openURL

    @State private var range: TimeRange = .week
    /// A day inside the period shown; `nil` follows today.
    @State private var pickedDay: DwellDay?
    @State private var state: Loadable<TimeOverview> = .loading
    @State private var reloads = 0
    @State private var isPicking = false
    @State private var pending: TimeSheet?
    @State private var path: [TimePage] = []

    var body: some View {
        let now = fixedNow ?? Date().addingTimeInterval(clockOffset)
        let today = DwellDay(containing: now, calendar: calendar)
        let period = TimePeriod(range, containing: min(pickedDay ?? today, today), calendar: calendar)
        NavigationStack(path: $path) {
            TimeContent(
                state: displayed(for: period),
                period: period,
                range: $range,
                now: now,
                actions: actions)
                .task(id: LoadKey(period: period, attempt: reloads)) {
                    await load(period, now: now)
                }
                .toolbar(.hidden, for: .navigationBar)
                .clearsTabBar()
                .navigationDestination(for: TimePage.self) { page in
                    switch page {
                    case .category:
                        // TI-05, not designed yet.
                        PendingView(title: "Category detail", systemImage: "chart.bar")
                            .clearsTabBar()
                    case .place:
                        // M-07, not designed yet: the stand-in Today and Your places open.
                        PendingView(title: "Place page", systemImage: "mappin.and.ellipse")
                            .clearsTabBar()
                    }
                }
                .sheet(isPresented: $isPicking) {
                    PeriodPickerSheet(
                        range: range,
                        shown: period,
                        today: today,
                        earliest: state.value?.recordingSince.map { DwellDay(containing: $0, calendar: calendar) },
                        onPick: { pickedDay = $0 })
                }
                .sheet(item: $pending) { sheet in
                    PendingView(title: sheet.title, systemImage: sheet.systemImage)
                        .presentationDetents([.medium])
                }
        }
    }

    // MARK: Loading

    private struct LoadKey: Hashable {
        var period: TimePeriod
        var attempt: Int
    }

    private func displayed(for period: TimePeriod) -> Loadable<TimeOverview> {
        if case .loaded(let overview, _) = state, overview.period != period {
            return .loading
        }
        return state
    }

    private func load(_ period: TimePeriod, now: Date) async {
        if case .failed = state { state = .loading }
        do {
            let overview = try await TimeOverview.load(period, from: repository, now: now, calendar: calendar)
            if try await !repository.places().hasRecordedVisit {
                // Day 0: nothing mapped, ever. Time says what it's waiting for.
                state = .stillMapping(MappingProgress(daysCollected: 0, daysNeeded: 1))
                return
            }
            state = .loaded(overview)
        } catch is CancellationError {
            return
        } catch let error as LoadError {
            state = .failed(error.failure)
        } catch {
            state = .failed((error as? URLError)?.code == .notConnectedToInternet ? .offline : .unavailable)
        }
    }

    // MARK: Actions

    private var actions: TimeActions {
        TimeActions(
            pickPeriod: { isPicking = true },
            share: { pending = .share },
            retry: { reloads += 1 },
            openCategory: { path.append(.category($0)) },
            openPlace: { path.append(.place($0)) },
            openRecord: { pending = .record($0.id) },
            openYear: { pending = .year },
            connectCalendar: { pending = .connectCalendar },
            fixPermission: { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            })
    }
}

/// The pages Time pushes.
enum TimePage: Hashable {
    case category(PlaceCategory)
    case place(PlaceID)
}

/// Sheets whose designs haven't arrived. Each says so instead of guessing.
private enum TimeSheet: Identifiable {
    case share
    case record(String)
    case year
    case connectCalendar

    var id: String {
        switch self {
        case .share: "share"
        case .record(let id): "record-\(id)"
        case .year: "year"
        case .connectCalendar: "calendar"
        }
    }

    var title: String {
        switch self {
        case .share: "Share preview"
        case .record: "Record card"
        case .year: "Year in places"
        case .connectCalendar: "Connect a calendar"
        }
    }

    var systemImage: String {
        switch self {
        case .share: "square.and.arrow.up"
        case .record: "trophy"
        case .year: "sparkles"
        case .connectCalendar: "calendar"
        }
    }
}

#Preview("Screen · sample repository") {
    TimeScreen()
        .samplePreview()
}
