import Foundation

/// How far a page of a story has run, for pages that move on by themselves (the weekly wrap,
/// like an Instagram story). A pause keeps what had run; resuming carries on from there.
public struct StoryClock: Hashable, Sendable {
    /// How long the page stays before moving on.
    public var duration: TimeInterval
    /// Time run before the current stretch.
    public var elapsed: TimeInterval
    /// When the current stretch began; `nil` while paused.
    public var runningSince: Date?

    public init(duration: TimeInterval, elapsed: TimeInterval = 0, runningSince: Date? = nil) {
        self.duration = duration
        self.elapsed = elapsed
        self.runningSince = runningSince
    }

    public var isRunning: Bool { runningSince != nil }

    /// Time run so far, never more than the page's duration.
    public func elapsed(at date: Date) -> TimeInterval {
        let running = runningSince.map { max(0, date.timeIntervalSince($0)) } ?? 0
        return min(duration, elapsed + running)
    }

    /// How much of the page has run, 0 to 1: how full its progress capsule is.
    public func fraction(at date: Date) -> Double {
        guard duration > 0 else { return 1 }
        return elapsed(at: date) / duration
    }

    public func remaining(at date: Date) -> TimeInterval {
        duration - elapsed(at: date)
    }

    public func paused(at date: Date) -> StoryClock {
        guard isRunning else { return self }
        return StoryClock(duration: duration, elapsed: elapsed(at: date))
    }

    public func resumed(at date: Date) -> StoryClock {
        guard !isRunning else { return self }
        return StoryClock(duration: duration, elapsed: elapsed, runningSince: date)
    }
}
