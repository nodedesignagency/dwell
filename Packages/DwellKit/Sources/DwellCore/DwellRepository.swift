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

    public func coverage() async throws -> [ScratchCoverage] {
        SampleData.coverage
    }

    public func scratchCells() async throws -> [ScratchCell] {
        SampleData.scratchCells
    }
}
