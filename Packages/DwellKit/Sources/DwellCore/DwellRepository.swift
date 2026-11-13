import Foundation

/// Everything the screens read.
///
/// The client's tracking engine plugs in behind this protocol through an adapter once we
/// have it. Until then `SampleRepository` serves the sample week. Grow this one page at a
/// time: add only what the page being built needs.
public protocol DwellRepository: Sendable {
    func liveStatus() async throws -> LiveStatus
    func day(_ day: DwellDay) async throws -> DaySnapshot
    func places() async throws -> [Place]
    func insights(for day: DwellDay) async throws -> [Insight]
    /// The user tapped "Looks right" on a visit Dwell wasn't sure about.
    func confirmVisit(_ id: VisitID) async throws
    /// "Not useful": the insight leaves the deck and the engine learns from it.
    func dismissInsight(_ id: Insight.ID) async throws
    /// What an insight opens into (the Insights page): its sentence, the weeks behind it and
    /// its numbers. An insight with no detail of its own answers `InsightDetail(insight:)`.
    func insightDetail(for insight: Insight) async throws -> InsightDetail
    /// The latest weekly wrap, from Sunday 6 PM on; `nil` before the first full week.
    func weeklyWrap() async throws -> WeeklyWrap?
    /// The user opened the wrap from Today's invite, so the invite goes.
    func markWeeklyWrapOpened(_ id: WeeklyWrap.ID) async throws
    /// You: who the user is.
    func profile() async throws -> Profile
    /// You: every streak, going or not, each with its last seven days (or weeks).
    func streaks() async throws -> [Streak]
    /// You: all thirteen badges, locked ones included, with their progress.
    func badges() async throws -> [Badge]
    /// Coverage at each scratch level: the city's neighborhoods, the country's cities, the world.
    func coverage() async throws -> [ScratchCoverage]
    /// The neighborhood cells uncovered so far, for the map behind You's profile.
    func scratchCells() async throws -> [ScratchCell]

    // MARK: Time

    /// Every day from `first` through `last`, in order: a week, a month or a year for Time.
    /// Days still to come come back empty. Defaults to one `day(_:)` at a time; an engine
    /// adapter should answer in one go.
    func days(from first: DwellDay, through last: DwellDay) async throws -> [DaySnapshot]
    /// Lifetime bests, unlocked and locked (Time's records wall).
    func records() async throws -> [PersonalRecord]
    /// The places growing, shrinking or paused over the last weeks (Time's places over time).
    func placeTrends() async throws -> [PlaceTrend]
    /// Whether a calendar is connected. Until one is, Calendar vs reality sells the feature.
    func isCalendarConnected() async throws -> Bool
}

extension DwellRepository {
    public func days(from first: DwellDay, through last: DwellDay) async throws -> [DaySnapshot] {
        var snapshots: [DaySnapshot] = []
        var day = first
        while day <= last {
            snapshots.append(try await self.day(day))
            day = day.next
        }
        return snapshots
    }
}

extension DwellDay {
    /// The next date. Calendar dates step the same in every time zone, so no user calendar is
    /// needed.
    var next: DwellDay {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(identifier: "UTC") ?? gregorian.timeZone
        let noon = gregorian.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? .distantPast
        let parts = gregorian.dateComponents([.year, .month, .day], from: noon.addingTimeInterval(86_400))
        return DwellDay(year: parts.year ?? year, month: parts.month ?? month, day: parts.day ?? day)
    }
}

/// Serves `SampleData`. Used by previews, the simulator and the fictional demo.
public struct SampleRepository: DwellRepository {
    public init() {}

    public func liveStatus() async throws -> LiveStatus {
        SampleData.liveStatus
    }

    public func day(_ day: DwellDay) async throws -> DaySnapshot {
        SampleData.snapshot(for: day)
    }

    public func places() async throws -> [Place] {
        SampleData.places
    }

    public func insights(for day: DwellDay) async throws -> [Insight] {
        day == SampleData.today ? SampleData.insights : []
    }

    /// The sample week is fixed, so answers are not kept.
    public func confirmVisit(_ id: VisitID) async throws {}

    public func dismissInsight(_ id: Insight.ID) async throws {}

    public func insightDetail(for insight: Insight) async throws -> InsightDetail {
        SampleData.insightDetail(for: insight)
    }

    /// Maya opened last week's wrap on Sunday evening, so Today shows no invite.
    public func weeklyWrap() async throws -> WeeklyWrap? {
        SampleData.weeklyWrap
    }

    public func markWeeklyWrapOpened(_ id: WeeklyWrap.ID) async throws {}

    public func profile() async throws -> Profile {
        SampleData.profile
    }

    public func streaks() async throws -> [Streak] {
        SampleData.streaks
    }

    public func badges() async throws -> [Badge] {
        SampleData.badges
    }

    public func records() async throws -> [PersonalRecord] {
        SampleData.records
    }

    public func placeTrends() async throws -> [PlaceTrend] {
        SampleData.placeTrends
    }

    public func coverage() async throws -> [ScratchCoverage] {
        SampleData.coverage
    }

    public func scratchCells() async throws -> [ScratchCell] {
        SampleData.scratchCells
    }

    public func isCalendarConnected() async throws -> Bool {
        true
    }
}
