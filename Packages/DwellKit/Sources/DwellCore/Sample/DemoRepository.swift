import Foundation

/// A repository failed to load, and how. Adapters throw this so screens can tell
/// "Retry sync" (offline) from "couldn't load".
public struct LoadError: Error, Hashable, Sendable {
    public var failure: LoadFailure

    public init(_ failure: LoadFailure) {
        self.failure = failure
    }
}

/// The sample week bent into one of Today's states, for reviewing them in the simulator:
/// `DWELL_STATE=empty ./scripts/run.sh`. Previews cover the rest (stale).
public struct DemoRepository: DwellRepository {
    public enum Mode: String, CaseIterable, Sendable {
        /// Never finishes loading: the skeleton.
        case loading
        /// No visits yet today.
        case empty
        /// The install day: nothing mapped ever, so Today shows "Getting started".
        case firstDay
        /// The install day, minutes after the first place: at home for 28m, nothing else yet.
        case firstPlace
        /// Last week's wrap is ready and not opened yet: Today invites the user in.
        case weeklyWrap
        /// Dwell asks whether the place of the night is home ("Is this home?").
        case isThisHome
        /// "Today couldn't load".
        case failed
        /// "You're offline" with Retry sync.
        case offline
        /// Between places: "In transit".
        case transit
        /// The phone went quiet: the timer freezes at "last seen".
        case lastSeen
        /// The four permission banners, one at a time.
        case locationDenied
        case whenInUse
        case preciseOff
        case motionDenied
        /// The terms changed since Maya agreed: Re-consent before Today, at launch and after
        /// Welcome back.
        case termsChanged
        /// Welcome back finds no account for the sign-in.
        case noAccount

        /// What the system would report in this mode. Banners only show for the last four.
        public var permissions: Permissions {
            switch self {
            case .locationDenied: Permissions(location: .denied, isPreciseLocationOn: true, motion: .granted)
            case .whenInUse: Permissions(location: .whenInUse, isPreciseLocationOn: true, motion: .granted)
            case .preciseOff: Permissions(location: .always, isPreciseLocationOn: false, motion: .granted)
            case .motionDenied: Permissions(location: .always, isPreciseLocationOn: true, motion: .denied)
            default: .full
            }
        }
    }

    public let mode: Mode
    private let sample = SampleRepository()

    public init(_ mode: Mode) {
        self.mode = mode
    }

    public func liveStatus() async throws -> LiveStatus {
        try await gate()
        switch mode {
        case .empty, .firstDay: return .unknown
        case .firstPlace: return SampleData.FirstPlace.liveStatus
        case .transit: return .inTransit(since: SampleData.now.addingTimeInterval(-12 * 60))
        case .lastSeen: return .lastKnown(placeName: "Kestriva Labs", lastSeen: SampleData.now.addingTimeInterval(-37 * 60))
        case .locationDenied: return .noPermission
        default: return try await sample.liveStatus()
        }
    }

    public func day(_ day: DwellDay) async throws -> DaySnapshot {
        try await gate()
        switch mode {
        case .empty, .firstDay: return .empty(day, calendar: SampleData.calendar)
        case .firstPlace: return SampleData.FirstPlace.snapshot(for: day)
        default: return try await sample.day(day)
        }
    }

    public func places() async throws -> [Place] {
        try await gate()
        switch mode {
        case .firstDay: return []
        case .firstPlace: return SampleData.FirstPlace.places
        default: return try await sample.places()
        }
    }

    public func insights(for day: DwellDay) async throws -> [Insight] {
        try await gate()
        switch mode {
        case .empty, .firstDay, .firstPlace: return []
        default: return try await sample.insights(for: day)
        }
    }

    public func confirmVisit(_ id: VisitID) async throws {}

    public func dismissInsight(_ id: Insight.ID) async throws {}

    public func insightDetail(for insight: Insight) async throws -> InsightDetail {
        try await gate()
        return try await sample.insightDetail(for: insight)
    }

    public func weeklyWrap() async throws -> WeeklyWrap? {
        try await gate()
        switch mode {
        case .firstDay, .firstPlace: return nil
        case .weeklyWrap:
            var wrap = SampleData.weeklyWrap
            wrap.isOpened = false
            return wrap
        default: return try await sample.weeklyWrap()
        }
    }

    public func markWeeklyWrapOpened(_ id: WeeklyWrap.ID) async throws {}

    public func profile() async throws -> Profile {
        try await gate()
        return try await sample.profile()
    }

    /// The install day has nothing to count yet; every other mode is the usual Monday.
    public func streaks() async throws -> [Streak] {
        try await gate()
        switch mode {
        case .firstDay, .firstPlace: return []
        default: return try await sample.streaks()
        }
    }

    public func badges() async throws -> [Badge] {
        try await gate()
        switch mode {
        case .firstDay, .firstPlace: return Badge.Kind.allCases.map { Badge(kind: $0, tier: nil, progress: 0) }
        default: return try await sample.badges()
        }
    }

    /// A new account has every record still to win.
    public func records() async throws -> [PersonalRecord] {
        try await gate()
        switch mode {
        case .firstDay, .firstPlace: return SampleData.records.map(\.locked)
        default: return try await sample.records()
        }
    }

    public func placeTrends() async throws -> [PlaceTrend] {
        try await gate()
        switch mode {
        case .firstDay, .firstPlace: return []
        default: return try await sample.placeTrends()
        }
    }

    public func coverage() async throws -> [ScratchCoverage] {
        try await gate()
        switch mode {
        case .firstDay: return SampleData.FirstPlace.coverage.map { coverage in
            var coverage = coverage
            coverage.uncovered = 0
            coverage.uncoveredThisWeek = 0
            return coverage
        }
        case .firstPlace: return SampleData.FirstPlace.coverage
        default: return try await sample.coverage()
        }
    }

    public func scratchCells() async throws -> [ScratchCell] {
        try await gate()
        switch mode {
        case .firstDay: return []
        case .firstPlace: return SampleData.FirstPlace.scratchCells
        default: return try await sample.scratchCells()
        }
    }

    /// New accounts haven't connected a calendar yet.
    public func isCalendarConnected() async throws -> Bool {
        try await gate()
        switch mode {
        case .firstDay, .firstPlace: return false
        default: return try await sample.isCalendarConnected()
        }
    }

    public func savePlaces(_ places: [PlaceDraft]) async throws {
        try await gate()
    }

    /// Fails as the mode says (`DWELL_STATE=offline` shows Save your world's failed sign-in).
    public func signIn(_ credential: SignInCredential) async throws -> AccountCheck {
        try await gate()
        return try await sample.signIn(credential)
    }

    public func completeSetup(_ consent: Consent) async throws {
        try await gate()
    }

    public func stopSetup(_ reason: SetupStop) async {}

    /// Holds (`loading`: Checking stays) or fails (`offline`: Checking's Try again) as the mode
    /// says; `noAccount` finds nothing.
    public func resumeAccount(_ credential: SignInCredential) async throws -> ResumeCheck {
        try await gate()
        return mode == .noAccount ? .notFound : try await sample.resumeAccount(credential)
    }

    /// Maya's answers as she left them, models off, when the terms changed.
    public func termsToReview() async throws -> Consent? {
        try await gate()
        return mode == .termsChanged ? Consent() : try await sample.termsToReview()
    }

    public func agreeToTerms(_ consent: Consent) async throws {
        try await gate()
    }

    /// Asks about Maya's flat in Crown Heights, as the design's map shows it.
    public func homeQuestion() async throws -> HomeQuestion? {
        try await gate()
        guard mode == .isThisHome else { return try await sample.homeQuestion() }
        return HomeQuestion(id: "first-night", coordinate: SampleData.homeCoordinate, placeID: "home")
    }

    public func answerHomeQuestion(_ id: HomeQuestion.ID, isHome: Bool) async throws {
        try await gate()
    }

    /// Holds or fails every load, as the mode says.
    /// Saving fails as loading does: offline, or the engine unavailable.
    public func saveVisit(_ draft: VisitDraft) async throws {
        try failIfDown()
    }

    public func deleteVisit(_ id: VisitID) async throws {
        try failIfDown()
    }

    public func nearbyPlaces(for visit: Visit) async throws -> [PlaceCandidate] {
        try await gate()
        return try await sample.nearbyPlaces(for: visit)
    }

    public func searchPlaces(_ query: String, for visit: Visit) async throws -> [PlaceCandidate] {
        try await gate()
        return try await sample.searchPlaces(query, for: visit)
    }

    private func failIfDown() throws {
        switch mode {
        case .failed: throw LoadError(.unavailable)
        case .offline: throw LoadError(.offline)
        default: return
        }
    }

    private func gate() async throws {
        switch mode {
        case .loading: try await Task.sleep(for: .seconds(24 * 3600))
        case .failed: throw LoadError(.unavailable)
        case .offline: throw LoadError(.offline)
        default: return
        }
    }
}
