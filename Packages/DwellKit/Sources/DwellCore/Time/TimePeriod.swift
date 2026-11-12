import Foundation

/// Time's range control (brief §7.3, A.4): Day / Week / Month / Year.
public enum TimeRange: String, CaseIterable, Codable, Sendable, Identifiable {
    case day
    case week
    case month
    case year

    public var id: Self { self }

    /// The control's label.
    public var title: String {
        switch self {
        case .day: "Day"
        case .week: "Week"
        case .month: "Month"
        case .year: "Year"
        }
    }

    /// The word in "Every hour of the week".
    public var noun: String {
        switch self {
        case .day: "day"
        case .week: "week"
        case .month: "month"
        case .year: "year"
        }
    }
}

/// One day, week, month or year of Dwell days, first to last inclusive. Weeks run Monday to
/// Sunday (the Time design: "Sep 28 – Oct 4"); every day inside runs 4 AM to 4 AM.
public struct TimePeriod: Hashable, Codable, Sendable, Identifiable {
    public let range: TimeRange
    public let first: DwellDay
    public let last: DwellDay

    public var id: String { "\(range.rawValue)-\(first.year)-\(first.month)-\(first.day)" }

    /// The period of this range that holds `day`.
    public init(_ range: TimeRange, containing day: DwellDay, calendar: Calendar) {
        self.range = range
        switch range {
        case .day:
            first = day
            last = day
        case .week:
            // 1 is Sunday in the Gregorian calendar; count back to Monday.
            let weekday = calendar.component(.weekday, from: day.start(in: calendar))
            first = day.adding(days: -((weekday + 5) % 7), in: calendar)
            last = first.adding(days: 6, in: calendar)
        case .month:
            first = DwellDay(year: day.year, month: day.month, day: 1)
            let length = calendar.range(of: .day, in: .month, for: first.start(in: calendar))?.count ?? 30
            last = DwellDay(year: day.year, month: day.month, day: length)
        case .year:
            first = DwellDay(year: day.year, month: 1, day: 1)
            last = DwellDay(year: day.year, month: 12, day: 31)
        }
    }

    /// Every Dwell day in the period, in order.
    public func days(in calendar: Calendar) -> [DwellDay] {
        var days: [DwellDay] = []
        var day = first
        while day <= last {
            days.append(day)
            day = day.adding(days: 1, in: calendar)
        }
        return days
    }

    /// 4 AM on the first day to 4 AM after the last.
    public func interval(in calendar: Calendar) -> DateInterval {
        DateInterval(start: first.start(in: calendar), end: last.interval(in: calendar).end)
    }

    public func contains(_ day: DwellDay) -> Bool {
        first <= day && day <= last
    }

    /// The period `count` steps later (negative for earlier), of the same range.
    public func adding(_ count: Int, in calendar: Calendar) -> TimePeriod {
        switch range {
        case .day:
            return TimePeriod(.day, containing: first.adding(days: count, in: calendar), calendar: calendar)
        case .week:
            return TimePeriod(.week, containing: first.adding(days: 7 * count, in: calendar), calendar: calendar)
        case .month:
            let months = first.year * 12 + (first.month - 1) + count
            let day = DwellDay(year: months / 12, month: months % 12 + 1, day: 1)
            return TimePeriod(.month, containing: day, calendar: calendar)
        case .year:
            return TimePeriod(.year, containing: DwellDay(year: first.year + count, month: 1, day: 1), calendar: calendar)
        }
    }

    /// Whether `now` falls inside the period: it's still being lived.
    public func isInProgress(now: Date, calendar: Calendar) -> Bool {
        let interval = interval(in: calendar)
        return interval.start <= now && now < interval.end
    }

    /// Whether the whole period is still to come.
    public func isFuture(now: Date, calendar: Calendar) -> Bool {
        first.start(in: calendar) > now
    }

    /// The window of this period that matches the part of `current` lived so far: the whole
    /// period, unless `current` is in progress, when it's the same length from the start.
    /// "Than usual" compares like with like: Monday so far against earlier Mondays so far.
    public func window(matching current: TimePeriod, now: Date, calendar: Calendar) -> DateInterval {
        let whole = interval(in: calendar)
        guard current.isInProgress(now: now, calendar: calendar) else { return whole }
        let lived = now.timeIntervalSince(current.interval(in: calendar).start)
        return DateInterval(start: whole.start, duration: min(max(0, lived), whole.duration))
    }
}
