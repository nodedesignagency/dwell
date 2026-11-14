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

    // MARK: Onboarding

    /// Keeps the places typed in on onboarding's Your places, home and work by role. Saving a
    /// place does not record a visit (brief A.1). Runs before the account exists, so the engine
    /// holds them on the phone until sign-in.
    func savePlaces(_ places: [PlaceDraft]) async throws

    // MARK: Account

    /// Save your world: signs in with what the user chose and says whether the account can go
    /// on (the beta's region). The places saved on the phone during onboarding join the account.
    func signIn(_ credential: SignInCredential) async throws -> AccountCheck
    /// One last thing's Continue: the age check passed (the date itself is never sent or kept)
    /// and the two consents, the models one on its own (brief §8.2: never bundled).
    func completeSetup(_ consent: Consent) async throws
    /// Setup stopped: nothing entered is kept (brief A.1 #2a, "Nothing you entered was saved"),
    /// neither the places from Your places nor the sign-in.
    func stopSetup(_ reason: SetupStop) async

    // MARK: Returning user

    /// Welcome back, then Checking: finds the account for this sign-in. Found, the places and
    /// hours come back to the phone.
    func resumeAccount(_ credential: SignInCredential) async throws -> ResumeCheck
    /// Re-consent (brief A.1, "when consent text changes"): the user's answers as they stand,
    /// when the terms changed since they last agreed; `nil` when nothing changed.
    func termsToReview() async throws -> Consent?
    /// Re-consent's Continue: the new terms agreed. Visits stays on (the brief's "core locked
    /// on"); the models answer goes as the user left it or changed it, on its own.
    func agreeToTerms(_ consent: Consent) async throws

    // MARK: First week

    /// "Is this home?": the place of the first night, while no home is saved; `nil` otherwise.
    func homeQuestion() async throws -> HomeQuestion?
    /// The answer: "Looks right" (it's home) or not.
    func answerHomeQuestion(_ id: HomeQuestion.ID, isHome: Bool) async throws

    // MARK: Visit edit

    /// The visit edit sheet's Save: the visit's times, work from home and private, split in
    /// two or merged with the next (`VisitDraft.visits(in:)` says what the day becomes).
    func saveVisit(_ draft: VisitDraft) async throws
    /// The visit edit sheet's Delete: the visit goes and its time counts toward nothing.
    func deleteVisit(_ id: VisitID) async throws
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

    /// The sample's places are already saved; onboarding's are let go.
    public func savePlaces(_ places: [PlaceDraft]) async throws {}

    /// Maya lives in Brooklyn: in the beta's region. No server: the sign-in is let go.
    public func signIn(_ credential: SignInCredential) async throws -> AccountCheck {
        .eligible
    }

    public func completeSetup(_ consent: Consent) async throws {}

    public func stopSetup(_ reason: SetupStop) async {}

    /// Maya's account is there to come back to.
    public func resumeAccount(_ credential: SignInCredential) async throws -> ResumeCheck {
        .found
    }

    /// Maya agreed to the terms as they stand.
    public func termsToReview() async throws -> Consent? {
        nil
    }

    public func agreeToTerms(_ consent: Consent) async throws {}

    /// Maya's home is saved, so Dwell doesn't ask.
    public func homeQuestion() async throws -> HomeQuestion? {
        nil
    }

    public func answerHomeQuestion(_ id: HomeQuestion.ID, isHome: Bool) async throws {}

    /// The sample week is fixed, so edits are not kept; Today shows them for the session.
    public func saveVisit(_ draft: VisitDraft) async throws {}

    public func deleteVisit(_ id: VisitID) async throws {}
}
