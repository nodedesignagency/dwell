import Foundation

/// The states every screen designs for (brief §7, §12). Permissions are not a state here:
/// the app works at every permission level and shows one banner on top (`Permissions.banner`).
public enum Loadable<Value> {
    case loading
    case empty
    /// Not enough data yet. Screens say what they are waiting for and how long, never just spin.
    case stillMapping(MappingProgress)
    case failed(LoadFailure)
    /// `staleSince` is set when the value is usable but old: show it under a stale banner.
    case loaded(Value, staleSince: Date? = nil)

    public var value: Value? {
        if case .loaded(let value, _) = self { value } else { nil }
    }
}

extension Loadable: Sendable where Value: Sendable {}
extension Loadable: Equatable where Value: Equatable {}
extension Loadable: Hashable where Value: Hashable {}

/// "Rhythm needs two weeks · 11 days to go."
public struct MappingProgress: Hashable, Sendable {
    public var daysCollected: Int
    public var daysNeeded: Int

    public init(daysCollected: Int, daysNeeded: Int) {
        self.daysCollected = daysCollected
        self.daysNeeded = daysNeeded
    }

    public var daysToGo: Int { max(0, daysNeeded - daysCollected) }
    public var fraction: Double { daysNeeded > 0 ? min(1, Double(daysCollected) / Double(daysNeeded)) : 1 }
}

public enum LoadFailure: Hashable, Sendable {
    /// No connection: "Retry sync".
    case offline
    /// "Today couldn't load".
    case unavailable
}

/// What the user has granted. The app looks complete at every level (brief §8.3).
public struct Permissions: Hashable, Sendable {
    public enum Location: String, Sendable {
        case notDetermined
        case denied
        case whenInUse
        case always
    }

    public enum Motion: String, Sendable {
        case notDetermined
        case denied
        case granted
    }

    public var location: Location
    public var isPreciseLocationOn: Bool
    public var motion: Motion

    public init(location: Location, isPreciseLocationOn: Bool, motion: Motion) {
        self.location = location
        self.isPreciseLocationOn = isPreciseLocationOn
        self.motion = motion
    }

    public static let full = Permissions(location: .always, isPreciseLocationOn: true, motion: .granted)

    /// One persistent, non-modal banner at a time, in the brief's priority order.
    /// Never a blocking modal.
    ///
    /// Open question (docs/QUESTIONS.md): Always is asked on day 1–2 in its own moment,
    /// so the caller may want to hold back `.whenInUseOnly` until that moment has passed.
    public var banner: PermissionBanner? {
        switch location {
        case .denied, .notDetermined: return .locationDenied
        case .whenInUse: return .whenInUseOnly
        case .always: break
        }
        if !isPreciseLocationOn { return .preciseOff }
        if motion == .denied { return .motionDenied }
        return nil
    }
}

public enum PermissionBanner: CaseIterable, Sendable {
    case locationDenied
    case whenInUseOnly
    case preciseOff
    case motionDenied
}
