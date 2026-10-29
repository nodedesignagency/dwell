import Foundation

/// Everything recorded for one Dwell day: the timeline and the calendar against it.
public struct DaySnapshot: Hashable, Sendable {
    public var day: DwellDay
    /// 4:00 AM to 4:00 AM in the user's calendar.
    public var interval: DateInterval
    /// Chronological. Entries that cross 4:00 AM appear in both days and are clipped when totalled.
    public var entries: [TimelineEntry]
    public var calendarMatches: [CalendarMatch]

    public init(day: DwellDay, interval: DateInterval, entries: [TimelineEntry], calendarMatches: [CalendarMatch] = []) {
        self.day = day
        self.interval = interval
        self.entries = entries
        self.calendarMatches = calendarMatches
    }

    public static func empty(_ day: DwellDay, calendar: Calendar) -> DaySnapshot {
        DaySnapshot(day: day, interval: day.interval(in: calendar), entries: [])
    }

    /// Time per category inside this day, up to `now`. Feeds the day bar.
    public func totals(now: Date) -> [PlaceCategory: TimeInterval] {
        entries.reduce(into: [:]) { totals, entry in
            guard let category = entry.category else { return }
            totals[category, default: 0] += clippedDuration(of: entry, now: now)
        }
    }

    /// Everything Dwell saw today: visits and transit, gaps excluded.
    public func mappedTotal(now: Date) -> TimeInterval {
        totals(now: now).values.reduce(0, +)
    }

    public func gapTotal(now: Date) -> TimeInterval {
        entries.reduce(0) { total, entry in
            guard case .gap = entry else { return total }
            return total + clippedDuration(of: entry, now: now)
        }
    }

    /// The part of an entry that falls inside this day and before `now`.
    public func clippedDuration(of entry: TimelineEntry, now: Date) -> TimeInterval {
        let entryInterval = entry.interval(now: now)
        let start = max(entryInterval.start, interval.start)
        let end = min(entryInterval.end, interval.end, now)
        return max(0, end.timeIntervalSince(start))
    }
}

/// A calendar event paired with what actually happened (brief §9).
/// Titles and attendees stay on the phone; only the state and minutes sync.
public struct CalendarMatch: Identifiable, Hashable, Sendable {
    public enum State: Hashable, Sendable {
        /// There for most of it.
        case attended
        /// Arrived late or left early, by these amounts.
        case partial(arrivedLate: TimeInterval, leftEarly: TimeInterval)
        /// Somewhere else. `instead` names where, when Dwell knows.
        case missed(instead: String?)
        /// No location on the event and no clear match.
        case unknown
    }

    public let id: String
    public var title: String
    public var interval: DateInterval
    public var state: State

    public init(id: String, title: String, interval: DateInterval, state: State) {
        self.id = id
        self.title = title
        self.interval = interval
        self.state = state
    }
}

/// The heartbeat at the top of Today (brief §7.1).
public enum LiveStatus: Hashable, Sendable {
    /// At a place now. The timer is an estimate and says so.
    case atPlace(Visit)
    case inTransit(since: Date)
    /// The phone has been quiet. The timer stops and says "last seen", never pretends to run.
    case lastKnown(placeName: String, lastSeen: Date)
    /// Nothing recorded yet: "Mapping your first place".
    case unknown
    case noPermission
}
