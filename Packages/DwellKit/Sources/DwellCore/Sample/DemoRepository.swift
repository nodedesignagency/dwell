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
/// `DWELL_STATE=empty ./scripts/run.sh`. Previews cover the rest (still mapping, stale).
public struct DemoRepository: DwellRepository {
    public enum Mode: String, CaseIterable, Sendable {
        /// Never finishes loading: the skeleton.
        case loading
        /// No visits yet today.
        case empty
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
        case .empty: return .unknown
        case .transit: return .inTransit(since: SampleData.now.addingTimeInterval(-12 * 60))
        case .lastSeen: return .lastKnown(placeName: "Kestriva Labs", lastSeen: SampleData.now.addingTimeInterval(-37 * 60))
        case .locationDenied: return .noPermission
        default: return try await sample.liveStatus()
        }
    }

    public func day(_ day: DwellDay) async throws -> DaySnapshot {
        try await gate()
        return mode == .empty ? .empty(day, calendar: SampleData.calendar) : try await sample.day(day)
    }

    public func places() async throws -> [Place] {
        try await gate()
        return try await sample.places()
    }

    public func insights(for day: DwellDay) async throws -> [Insight] {
        try await gate()
        return mode == .empty ? [] : try await sample.insights(for: day)
    }

    public func confirmVisit(_ id: VisitID) async throws {}

    public func dismissInsight(_ id: Insight.ID) async throws {}

    /// Holds or fails every load, as the mode says.
    private func gate() async throws {
        switch mode {
        case .loading: try await Task.sleep(for: .seconds(24 * 3600))
        case .failed: throw LoadError(.unavailable)
        case .offline: throw LoadError(.offline)
        default: return
        }
    }
}
