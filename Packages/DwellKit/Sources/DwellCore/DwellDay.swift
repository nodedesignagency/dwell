import Foundation

/// A Dwell day runs from 4:00 AM to 4:00 AM local time (brief §9), so a late night
/// belongs to the evening before and night shifts get sane days.
///
/// Identified by the calendar date it starts on. On daylight-saving days the
/// interval is 23 or 25 hours long.
public struct DwellDay: Hashable, Comparable, Codable, Sendable {
    public static let startHour = 4

    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The Dwell day a moment belongs to: 3:59 AM still counts toward yesterday.
    public init(containing date: Date, calendar: Calendar) {
        let midnight = calendar.startOfDay(for: date)
        var start = calendar.date(byAdding: .hour, value: Self.startHour, to: midnight) ?? midnight
        if date < start {
            start = calendar.date(byAdding: .day, value: -1, to: start) ?? start
        }
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        self.init(year: parts.year ?? 0, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    /// 4:00 AM on the starting date.
    public func start(in calendar: Calendar) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: Self.startHour)
        guard let start = calendar.date(from: components) else {
            preconditionFailure("Invalid Dwell day \(year)-\(month)-\(day)")
        }
        return start
    }

    /// 4:00 AM to 4:00 AM the next morning.
    public func interval(in calendar: Calendar) -> DateInterval {
        let start = start(in: calendar)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return DateInterval(start: start, end: end)
    }

    public func adding(days: Int, in calendar: Calendar) -> DwellDay {
        let start = start(in: calendar)
        let moved = calendar.date(byAdding: .day, value: days, to: start) ?? start
        return DwellDay(containing: moved, calendar: calendar)
    }

    public static func < (lhs: DwellDay, rhs: DwellDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}
