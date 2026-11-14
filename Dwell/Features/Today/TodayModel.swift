import DwellCore
import Foundation

/// Everything Today shows for one day.
struct TodayModel: Hashable {
    var snapshot: DaySnapshot
    /// `nil` on a past day: there is no "now" to be at.
    var liveStatus: LiveStatus?
    var insights: [Insight]
    /// Last week's wrap. Today invites the user in while it's unopened.
    var weeklyWrap: WeeklyWrap? = nil

    var day: DwellDay { snapshot.day }

    /// The wrap to invite the user into, if any. Only today invites.
    var wrapToOpen: WeeklyWrap? {
        guard liveStatus != nil, let weeklyWrap, !weeklyWrap.isOpened else { return nil }
        return weeklyWrap
    }

    /// The first visit Dwell isn't sure about. Only today asks.
    var visitToConfirm: Visit? {
        guard liveStatus != nil else { return nil }
        return snapshot.entries.lazy.compactMap(\.visit).first(where: \.needsReview)
    }

    static func empty(_ day: DwellDay, isToday: Bool, calendar: Calendar) -> TodayModel {
        TodayModel(snapshot: .empty(day, calendar: calendar), liveStatus: isToday ? .unknown : nil, insights: [])
    }

    /// The model after the user's answers this session, before the engine reflects them:
    /// visits confirmed, insights dismissed, wraps opened, and visits saved or deleted from
    /// the visit edit sheet, in the order they were.
    func applying(
        confirmed: Set<VisitID>,
        dismissed: Set<Insight.ID>,
        openedWraps: Set<WeeklyWrap.ID> = [],
        visitChanges: [VisitChange] = []
    ) -> TodayModel {
        var model = self
        if let id = weeklyWrap?.id, openedWraps.contains(id) {
            model.weeklyWrap?.isOpened = true
        }
        let edited = self.snapshot.applying(visitChanges)
        model.snapshot.entries = edited.entries.map { entry in
            guard case .visit(var visit) = entry, confirmed.contains(visit.id) else { return entry }
            visit.needsReview = false
            return .visit(visit)
        }
        model.insights = insights.filter { !dismissed.contains($0.id) }
        return model
    }
}

/// What Today's controls do. Screens wire these; previews leave them empty.
struct TodayActions {
    var openProfile: () -> Void = {}
    var pickDay: () -> Void = {}
    var retry: () -> Void = {}
    var openPlace: (PlaceID) -> Void = { _ in }
    var confirm: (Visit) -> Void = { _ in }
    var pickAnother: (Visit) -> Void = { _ in }
    /// A visit in "Your day" held: the visit edit sheet.
    var editVisit: (Visit) -> Void = { _ in }
    var openWeeklyWrap: (WeeklyWrap) -> Void = { _ in }
    var openInsight: (Insight) -> Void = { _ in }
    var share: (Insight) -> Void = { _ in }
    var notUseful: (Insight) -> Void = { _ in }
    var fixPermission: (PermissionBanner) -> Void = { _ in }
}

/// The sentence at the top of Today, over the sunrise.
enum TodayHeadline {
    /// "Today, you've spent 4h 40m at work, …" with its data runs.
    case sentence(VoicedSentence)
    /// An empty-state or still-mapping line.
    case line(VoicedLine)
    /// Skeleton bars while Today loads.
    case placeholder
    /// Nothing: Today failed to load and says so below.
    case none
}

extension PermissionBanner {
    var symbol: String {
        switch self {
        case .locationDenied: "location.slash"
        case .whenInUseOnly: "location"
        case .preciseOff: "scope"
        case .motionDenied: "figure.walk"
        }
    }
}

extension TodayModel {
    /// The sample week as Today would load it. Previews and the fictional demo.
    static func sample(_ day: DwellDay = SampleData.today) -> TodayModel {
        let isToday = day == SampleData.today
        return TodayModel(
            snapshot: SampleData.snapshot(for: day),
            liveStatus: isToday ? SampleData.liveStatus : nil,
            insights: isToday ? SampleData.insights : [],
            weeklyWrap: isToday ? SampleData.weeklyWrap : nil)
    }

    /// The sample Monday with last week's wrap ready and not opened yet (Today design,
    /// "Weekly Wrap").
    static var weeklyWrapInvite: TodayModel {
        var model = sample()
        model.weeklyWrap?.isOpened = false
        return model
    }

    /// The install day, minutes after the first place was mapped: at home for 28m,
    /// no insights yet (Today design, "after a few minutes of getting started").
    static var firstPlace: TodayModel {
        TodayModel(
            snapshot: SampleData.FirstPlace.snapshot(for: SampleData.today),
            liveStatus: SampleData.FirstPlace.liveStatus,
            insights: [])
    }
}
