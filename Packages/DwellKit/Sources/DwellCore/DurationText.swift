import Foundation

/// How Dwell writes a length of time: "9h 32m", "1h 07m", "57m", "10h".
public enum DurationText {
    /// Rounds down to whole minutes, so Dwell never claims time it didn't see.
    /// Shows in monospaced digits wherever it appears (that is the UI's job).
    ///
    /// After hours, minutes take two digits ("27h 09m", "1h 07m"), as the Time design writes
    /// them, so the minutes line up from row to row. Edge cases are open questions
    /// (docs/QUESTIONS.md): whole hours drop the minutes ("10h"), and anything under a minute
    /// reads "<1m".
    public static func short(_ interval: TimeInterval) -> String {
        guard interval >= 60 else { return interval > 0 ? "<1m" : "0m" }
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let rest = minutes % 60
        switch (hours, rest) {
        case (0, _): return "\(rest)m"
        case (_, 0): return "\(hours)h"
        default: return "\(hours)h \(rest < 10 ? "0" : "")\(rest)m"
        }
    }

    /// A lifetime total, as Your places writes it: whole hours from 10 hours up ("186h",
    /// "640h mapped"), where the minutes are noise, and `short` below that ("6h 50m", "39m").
    /// Rounds down, like `short`. The design shows only whole hours; the brief's format is
    /// "9h 32m" (QUESTIONS.md, design vs brief 20).
    public static func total(_ interval: TimeInterval) -> String {
        let hours = Int(interval / 3600)
        return hours >= 10 ? "\(hours)h" : short(interval)
    }
}

/// Nothing, at any dial position, celebrates more than 12 hours of work in a day
/// (brief §8.4). Leaderboards (later) count anything above 12h as 12h and show "12h+".
public enum WorkCeiling {
    public static let limit: TimeInterval = 12 * 3600

    public static func isCelebratable(_ work: TimeInterval) -> Bool {
        work <= limit
    }

    public static func isCapped(_ work: TimeInterval) -> Bool {
        work > limit
    }

    /// The value that counts toward rank.
    public static func rankValue(_ work: TimeInterval) -> TimeInterval {
        min(work, limit)
    }
}
