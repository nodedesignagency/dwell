import Foundation

/// Last week, wrapped (brief §3.1 day 7, §10, S-06): Monday to Sunday, ready from Sunday at
/// 6 PM. Today invites the user in ("It's time for your weekly wrap-up") until they've
/// opened it.
public struct WeeklyWrap: Identifiable, Hashable, Sendable {
    public var firstDay: DwellDay
    public var lastDay: DwellDay
    public var isOpened: Bool

    public var id: DwellDay { firstDay }

    public init(firstDay: DwellDay, lastDay: DwellDay, isOpened: Bool) {
        self.firstDay = firstDay
        self.lastDay = lastDay
        self.isOpened = isOpened
    }
}

/// The wrap's first page (Weekly wrap design, "This week."): the week in two numbers.
/// "7 days, 9 places and every hour in between."
public struct WrapOpener: Hashable, Sendable {
    /// Days of the week Dwell was recording: 7 for a whole week, fewer when the first week
    /// started midweek.
    public var days: Int
    /// Different places with at least one visit that week. Private and personal places count:
    /// the wrap is the user's own screen and names none of them.
    public var places: Int
    /// The 3D art that pops out around the title.
    public var stickers: [WrapSticker]

    public init(days: Int, places: Int, stickers: [WrapSticker] = WrapSticker.opener) {
        self.days = days
        self.places = places
        self.stickers = stickers
    }

    /// Counts a week of days, Monday to Sunday. A visit that runs past 4 AM shows in both
    /// days and still counts its place once.
    public init(week: [DaySnapshot]) {
        let recorded = week.filter { snapshot in
            snapshot.recordingSince.map { $0 < snapshot.interval.end } ?? true
        }
        var places = Set<PlaceKey>()
        for snapshot in week {
            for entry in snapshot.entries {
                guard let visit = entry.visit else { continue }
                places.insert(visit.placeID.map(PlaceKey.known) ?? .unnamed(visit.placeName))
            }
        }
        self.init(days: recorded.count, places: places.count)
    }

    /// A visit Dwell couldn't name yet still went somewhere: it counts by the name it shows.
    private enum PlaceKey: Hashable {
        case known(PlaceID)
        case unnamed(String)
    }
}

/// 3D art that pops out around a wrap page's title (Weekly wrap design: an alarm clock, a
/// briefcase, a flame and a trophy around "This week.").
///
/// The art will follow the week's data. Which data picks which art comes from the designer
/// before hand-off (QUESTIONS.md, "Before hand-off"); until then the opener shows the
/// design's four every week. [MAPPING NEEDED]
public enum WrapSticker: String, CaseIterable, Hashable, Sendable {
    case alarmClock
    case briefcase
    case flame
    case trophy

    /// The design's four, in its order: top left, right, bottom left, bottom right.
    public static let opener: [WrapSticker] = [.alarmClock, .briefcase, .flame, .trophy]
}

/// The wrap's second page (Weekly wrap design, "Work vs yours"): the week's hours at work and
/// the hours that were yours, counted as Time counts them (`TimeReport.totals`,
/// `TimeReport.yours`), so the wrap and Time never disagree.
public struct WrapWorkAndYours: Hashable, Sendable {
    public var work: TimeInterval
    public var yours: TimeInterval

    public init(work: TimeInterval, yours: TimeInterval) {
        self.work = work
        self.yours = yours
    }

    /// Totals a week of days, Monday to Sunday.
    public init(week: [DaySnapshot], now: Date) {
        guard let first = week.first, let last = week.last else {
            self.init(work: 0, yours: 0)
            return
        }
        let whole = DateInterval(start: first.interval.start, end: max(first.interval.start, last.interval.end))
        let totals = TimeReport.totals(week, within: whole, now: now)
        self.init(work: totals[.work] ?? 0, yours: TimeReport.yours(totals))
    }

    /// Work's share of the two, 0 to 1: how much of the page work fills before the water of
    /// yours begins (the designer's idea, 13 Nov). Half when there's neither.
    public var workShare: Double {
        let both = work + yours
        return both > 0 ? work / both : 0.5
    }
}

/// The wrap's fifth page (Weekly wrap design, "Earliest exit this week"): the weekday the
/// user left the office earliest, and how that sat against their usual.
///
/// An exit is the day's last departure from work on a weekday (Monday to Friday), as Time's
/// rhythm reads "Leave", but only from the office: a day worked from home has no exit. The
/// earliest is the one soonest after the day's 4 AM start, so a late night stays late. The
/// usual is the median exit over the four weeks before the wrap's week, once there are at
/// least five to go on.
public struct WrapEarliestExit: Hashable, Sendable {
    /// Exits the usual needs before it means anything.
    public static let exitsForUsual = 5

    public var day: DwellDay
    /// When the user left work that day.
    public var time: Date
    /// Minutes after the day's 4 AM start.
    public var minutes: Double
    /// The usual exit, in minutes after 4 AM; `nil` before there are enough exits to tell.
    public var usualMinutes: Double?

    public init(day: DwellDay, time: Date, minutes: Double, usualMinutes: Double?) {
        self.day = day
        self.time = time
        self.minutes = minutes
        self.usualMinutes = usualMinutes
    }

    /// The earliest exit of `week`, against the usual over `before`; `nil` with no office
    /// weekday in the week.
    public init?(week: [DaySnapshot], before: [DaySnapshot], calendar: Calendar) {
        let exits = week.compactMap { Self.exit(from: $0, calendar: calendar) }
        guard let earliest = exits.min(by: { $0.minutes < $1.minutes }) else { return nil }
        let usual = before.compactMap { Self.exit(from: $0, calendar: calendar)?.minutes }
        self.init(
            day: earliest.day,
            time: earliest.time,
            minutes: earliest.minutes,
            usualMinutes: usual.count >= Self.exitsForUsual ? Self.median(usual) : nil)
    }

    /// How much earlier than usual, in whole minutes (negative: later); `nil` with no usual.
    public var minutesEarlier: Int? {
        usualMinutes.map { Int(($0 - minutes).rounded()) }
    }

    /// The day's office exit: the last work visit's departure on a weekday, unless the day's
    /// work was from home.
    static func exit(from day: DaySnapshot, calendar: Calendar) -> (day: DwellDay, time: Date, minutes: Double)? {
        let weekday = calendar.component(.weekday, from: day.interval.start)
        guard (2...6).contains(weekday) else { return nil }
        let work = day.entries.compactMap(\.visit).filter { visit in
            visit.category == .work && !visit.isWorkFromHome && day.interval.contains(visit.arrival)
        }
        guard let last = work.max(by: { ($0.departure ?? .distantFuture) < ($1.departure ?? .distantFuture) }),
              let departure = last.departure
        else { return nil }
        return (day.day, departure, departure.timeIntervalSince(day.interval.start) / 60)
    }

    private static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }
}

/// Everything the wrap's pages show, from one load of the week (and the four weeks before it,
/// for what's usual).
public struct WrapWeek: Hashable, Sendable {
    public var opener: WrapOpener
    public var workAndYours: WrapWorkAndYours
    /// `nil` when the user wasn't at the office on any weekday.
    public var earliestExit: WrapEarliestExit?

    /// Days before the wrap's week that "usual" looks back over.
    public static let lookback = 28

    public init(opener: WrapOpener, workAndYours: WrapWorkAndYours, earliestExit: WrapEarliestExit?) {
        self.opener = opener
        self.workAndYours = workAndYours
        self.earliestExit = earliestExit
    }

    /// - Parameters:
    ///   - week: the wrap's seven days, Monday to Sunday.
    ///   - before: the days before it, for what's usual (`lookback` of them, or fewer).
    public init(week: [DaySnapshot], before: [DaySnapshot] = [], now: Date, calendar: Calendar) {
        self.init(
            opener: WrapOpener(week: week),
            workAndYours: WrapWorkAndYours(week: week, now: now),
            earliestExit: WrapEarliestExit(week: week, before: before, calendar: calendar))
    }
}
