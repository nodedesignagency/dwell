import DwellCore
import DwellUI
import SwiftUI
import UIKit

/// Today (brief §7.1): where you are, today's day, what you learned.
///
/// Loads one day from the repository and ticks once a minute, on the minute the live visit
/// started, so the timer never lags. The day pill picks a past day; past days drop the live
/// status, the insights and the confirmation card.
struct TodayScreen: View {
    var openProfile: () -> Void = {}

    @Environment(\.repository) private var repository
    @Environment(\.fixedNow) private var fixedNow
    @Environment(\.clockOffset) private var clockOffset
    @Environment(\.calendar) private var calendar
    @Environment(\.openURL) private var openURL

    @State private var state: Loadable<TodayModel> = .loading
    @State private var pickedDay: DwellDay?
    @State private var isPickingDay = false
    @State private var reloads = 0
    @State private var confirmed: Set<VisitID> = []
    @State private var dismissed: Set<Insight.ID> = []
    @State private var openPlace: PlaceID?
    @State private var pending: PendingSheet?

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: tickAnchor.addingTimeInterval(-clockOffset), by: 60)) { context in
                let now = fixedNow ?? context.date.addingTimeInterval(clockOffset)
                let today = DwellDay(containing: now, calendar: calendar)
                let day = pickedDay ?? today
                TodayContent(
                    state: displayed(for: day),
                    day: day,
                    isToday: day == today,
                    now: now,
                    actions: actions(day: day, isToday: day == today))
                    .task(id: LoadKey(day: day, isToday: day == today, attempt: reloads)) {
                        await load(day, isToday: day == today)
                    }
                    .sheet(isPresented: $isPickingDay) {
                        DayPickerSheet(pickedDay: $pickedDay, today: today)
                    }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $openPlace) { _ in
                PendingView(title: "Place page", systemImage: "mappin.and.ellipse")
            }
            .sheet(item: $pending) { sheet in
                PendingView(title: sheet.title, systemImage: sheet.systemImage)
                    .presentationDetents([.medium])
            }
        }
        .haptic(.confirm, trigger: confirmed.count)
    }

    // MARK: Loading

    private struct LoadKey: Hashable {
        var day: DwellDay
        var isToday: Bool
        var attempt: Int
    }

    private func displayed(for day: DwellDay) -> Loadable<TodayModel> {
        switch state {
        case .loaded(let model, let staleSince):
            guard model.day == day else { return .loading }
            return .loaded(model.applying(confirmed: confirmed, dismissed: dismissed), staleSince: staleSince)
        default:
            return state
        }
    }

    private func load(_ day: DwellDay, isToday: Bool) async {
        do {
            let snapshot = try await repository.day(day)
            var liveStatus: LiveStatus?
            var insights: [Insight] = []
            if isToday {
                liveStatus = try await repository.liveStatus()
                insights = try await repository.insights(for: day)
            }
            state = .loaded(TodayModel(snapshot: snapshot, liveStatus: liveStatus, insights: insights))
        } catch is CancellationError {
            return
        } catch {
            state = .failed((error as? URLError)?.code == .notConnectedToInternet ? .offline : .unavailable)
        }
    }

    /// Ticks land on whole minutes of the live visit, so "1h 16m" turns over on time.
    private var tickAnchor: Date {
        switch state.value?.liveStatus {
        case .atPlace(let visit): visit.arrival
        case .inTransit(let since): since
        default: Date(timeIntervalSinceReferenceDate: 0)
        }
    }

    // MARK: Actions

    private func actions(day: DwellDay, isToday: Bool) -> TodayActions {
        TodayActions(
            openProfile: openProfile,
            pickDay: { isPickingDay = true },
            retry: { reloads += 1 },
            refresh: { await load(day, isToday: isToday) },
            openPlace: { openPlace = $0 },
            confirm: { visit in
                confirmed.insert(visit.id)
                Task { try? await repository.confirmVisit(visit.id) }
            },
            pickAnother: { pending = .placePicker($0.id) },
            openInsight: { pending = .insight($0.id) },
            share: { pending = .share($0.id) },
            notUseful: { insight in
                dismissed.insert(insight.id)
                Task { try? await repository.dismissInsight(insight.id) }
            },
            fixPermission: { _ in
                // "Fix" will open the Always upgrade (O-08) once it is designed.
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            })
    }
}

/// Sheets whose designs haven't arrived. Each says so instead of guessing.
private enum PendingSheet: Identifiable {
    case placePicker(VisitID)
    case insight(Insight.ID)
    case share(Insight.ID)

    var id: String {
        switch self {
        case .placePicker(let id): "picker-\(id)"
        case .insight(let id): "insight-\(id)"
        case .share(let id): "share-\(id)"
        }
    }

    var title: String {
        switch self {
        case .placePicker: "Place picker"
        case .insight: "Insight detail"
        case .share: "Share preview"
        }
    }

    var systemImage: String {
        switch self {
        case .placePicker: "mappin.and.ellipse"
        case .insight: "sparkles"
        case .share: "square.and.arrow.up"
        }
    }
}

#Preview("Screen · sample repository") {
    TodayScreen()
        .samplePreview()
}
