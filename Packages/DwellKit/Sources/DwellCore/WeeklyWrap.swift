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

/// The wrap's third page (Weekly wrap design, "Weekends were all yours."): the week hour by
/// hour with Saturday and Sunday picked out, what the weekend went to, and the biggest change
/// in time of your own since last weekend.
///
/// The weekend is Saturday's and Sunday's Dwell days: Saturday 4 AM to Monday 4 AM, so Friday
/// night out counts toward Friday. Times are counted as Time counts them (`TimeReport.totals`),
/// so the wrap and Time never disagree.
public struct WrapWeekends: Hashable, Sendable {
    /// What the weekend held, which picks the title.
    public enum Verdict: Hashable, Sendable {
        /// Recorded, and not a minute of work.
        case allYours
        /// Work on Saturday or Sunday: how much in all.
        case someWork(TimeInterval)
        /// Dwell recorded nothing on Saturday or Sunday, so the page claims nothing either way.
        case notRecorded
    }

    /// Where time of your own moved most against last weekend: "2h more social than last
    /// weekend."
    public struct Change: Hashable, Sendable {
        public var category: PlaceCategory
        /// This weekend's time less last weekend's: more when positive.
        public var difference: TimeInterval

        public init(category: PlaceCategory, difference: TimeInterval) {
            self.category = category
            self.difference = difference
        }
    }

    /// A change smaller than this isn't worth a sentence.
    public static let smallestChange: TimeInterval = 30 * 60

    public var verdict: Verdict
    /// The week, Monday to Sunday, a row a day (Time's "Every hour of the week").
    public var grid: HourGrid
    /// Saturday and Sunday, the rows the page picks out.
    public var weekend: [DwellDay]
    /// Work on each weekend day, Saturday first.
    public var workByDay: [TimeInterval]
    /// The weekend's time by category, largest first, work left out: "What you did instead".
    /// The grid names work and then the weekend's largest categories, seven in all, so the
    /// weekend's own colours show in both; anything past them is Everything else, last.
    /// Categories under a minute are left out.
    public var breakdown: [ChartSlice]
    /// `nil` when last weekend wasn't recorded whole, or nothing moved by half an hour.
    public var change: Change?

    public init(
        verdict: Verdict,
        grid: HourGrid,
        weekend: [DwellDay],
        workByDay: [TimeInterval],
        breakdown: [ChartSlice],
        change: Change?
    ) {
        self.verdict = verdict
        self.grid = grid
        self.weekend = weekend
        self.workByDay = workByDay
        self.breakdown = breakdown
        self.change = change
    }

    /// - Parameters:
    ///   - week: Monday to Sunday.
    ///   - lastWeekend: the Saturday and Sunday before it, for the change.
    public init(week: [DaySnapshot], lastWeekend: [DaySnapshot], now: Date, calendar: Calendar) {
        let first = week.first?.day ?? DwellDay(containing: now, calendar: calendar)
        let period = TimePeriod(.week, containing: first, calendar: calendar)
        let weekendDays = week.filter { Self.isWeekend($0.day, calendar: calendar) }
        let totals = Self.totals(weekendDays, now: now)
        let work = totals[.work] ?? 0

        // The grid names work, so the weekdays show what the weekend was free of, then the
        // weekend's own categories, then the rest of the week's, seven in all.
        let ranked = { (totals: [PlaceCategory: TimeInterval]) in
            ChartSlice.fold(totals, maxNamed: PlaceCategory.allCases.count).compactMap(\.bucket.category)
        }
        let weekTotals = Self.totals(week, now: now)
        var named: [PlaceCategory] = weekTotals[.work] ?? 0 > 0 ? [.work] : []
        for category in ranked(totals) + ranked(weekTotals) where !named.contains(category) {
            named.append(category)
        }
        let grid = HourGrid(PeriodSnapshot(period: period, days: week), now: now, calendar: calendar, named: named)

        let verdict: Verdict
        if totals.values.reduce(0, +) <= 0 {
            verdict = .notRecorded
        } else if work >= 60 {
            verdict = .someWork(work)
        } else {
            verdict = .allYours
        }

        // The grid's buckets: a category it folded into Everything else is folded here too.
        var buckets: [ChartBucket: TimeInterval] = [:]
        for (category, total) in totals where category != .work && total >= 60 {
            let named = grid.legend.contains(.bucket(.category(category)))
            buckets[named ? .category(category) : .everythingElse, default: 0] += total
        }
        let breakdown = buckets
            .map { ChartSlice(bucket: $0.key, total: $0.value) }
            .sorted { Self.rank($0) < Self.rank($1) }

        self.init(
            verdict: verdict,
            grid: grid,
            weekend: weekendDays.map(\.day),
            workByDay: weekendDays.map { Self.totals([$0], now: now)[.work] ?? 0 },
            breakdown: breakdown,
            change: Self.change(from: lastWeekend, to: totals, now: now))
    }

    /// Saturday or Sunday, by the day the Dwell day starts on.
    public static func isWeekend(_ day: DwellDay, calendar: Calendar) -> Bool {
        let weekday = calendar.component(.weekday, from: day.start(in: calendar))
        return weekday == 1 || weekday == 7
    }

    /// Time of your own, as `TimeReport.yours` counts it: everything but work, home and transit.
    static let notYours: Set<PlaceCategory> = [.work, .home, .transit]

    static func totals(_ days: [DaySnapshot], now: Date) -> [PlaceCategory: TimeInterval] {
        guard let first = days.first, let last = days.last else { return [:] }
        let whole = DateInterval(start: first.interval.start, end: max(first.interval.start, last.interval.end))
        return TimeReport.totals(days, within: whole, now: now)
    }

    /// Largest first, Everything else last, ties in category order.
    private static func rank(_ slice: ChartSlice) -> (Int, TimeInterval, Int) {
        switch slice.bucket {
        case .category(let category):
            (0, -slice.total, PlaceCategory.allCases.firstIndex(of: category) ?? 0)
        case .everythingElse:
            (1, 0, 0)
        }
    }

    /// The category of your own whose time moved most, if last weekend was recorded from
    /// Saturday's 4 AM on and something moved by half an hour or more. Ties go to the category
    /// that comes first.
    static func change(from lastWeekend: [DaySnapshot], to totals: [PlaceCategory: TimeInterval], now: Date) -> Change? {
        guard !lastWeekend.isEmpty, lastWeekend.allSatisfy({ ($0.recordingSince ?? .distantPast) <= $0.interval.start }) else {
            return nil
        }
        let before = Self.totals(lastWeekend, now: now)
        guard before.values.reduce(0, +) > 0 else { return nil }
        var best: Change?
        for category in PlaceCategory.allCases where !notYours.contains(category) {
            let difference = (totals[category] ?? 0) - (before[category] ?? 0)
            if abs(difference) > abs(best?.difference ?? 0) {
                best = Change(category: category, difference: difference)
            }
        }
        guard let best, abs(best.difference) >= smallestChange else { return nil }
        return best
    }
}

/// The wrap's last page (Weekly wrap design, "Postcard from your week"): the week on a stamp
/// to share. A share card, so category level only (brief §8.6, §10): two totals, an exit time,
/// the weekend's work and a count of new places; never a place's name, never home, never a
/// pin. The map behind it shows the user's city and nothing closer (the user's call, 13 Nov).
public struct WrapPostcard: Hashable, Sendable {
    public var work: TimeInterval
    public var yours: TimeInterval
    /// `nil` when the user wasn't at the office on any weekday.
    public var earliestExit: WrapEarliestExit?
    /// Work on Saturday and Sunday; `nil` when Dwell recorded neither.
    public var weekendWork: TimeInterval?
    /// Places visited for the first time that week; `nil` when the places didn't load.
    public var newPlaces: Int?
    /// Where the stamp's map is centred: the middle of the user's city (`Profile.cityCenter`),
    /// never home. `nil`: no map, the stamp's paper shows instead.
    public var city: Coordinate?

    public init(
        work: TimeInterval,
        yours: TimeInterval,
        earliestExit: WrapEarliestExit?,
        weekendWork: TimeInterval?,
        newPlaces: Int?,
        city: Coordinate?
    ) {
        self.work = work
        self.yours = yours
        self.earliestExit = earliestExit
        self.weekendWork = weekendWork
        self.newPlaces = newPlaces
        self.city = city
    }

    /// Places whose first visit ever fell inside `week`.
    public static func newPlaces(_ places: [Place], in week: DateInterval) -> Int {
        places.filter { place in
            guard let first = place.firstSeen else { return false }
            return week.start <= first && first < week.end
        }.count
    }
}

/// The wrap's sixth page (Weekly wrap design, "Weekly Wrap 6", "Explorer week"): the places
/// the user went to for the first time that week, tagged on a map, and the scratch cells the
/// week uncovered. "2 new places. 1 new corner."
///
/// A new place is one whose first visit ever fell inside the week, the postcard's count
/// (`WrapPostcard.newPlaces`), so the two pages always agree. Private and personal places count
/// (it's the user's own screen) but never go on the map (brief §7.2). A new cell is a
/// neighborhood cell first uncovered that week. An explorer week is one with a never-before
/// place (brief §9, the explorer week streak).
public struct WrapExplorer: Hashable, Sendable {
    /// A place first visited that week.
    public struct NewPlace: Identifiable, Hashable, Sendable {
        public var id: PlaceID
        public var name: String
        public var category: PlaceCategory
        public var firstVisit: Date
        /// `nil` when Dwell can't place it.
        public var coordinate: Coordinate?
        public var isHiddenFromMaps: Bool

        public init(
            id: PlaceID,
            name: String,
            category: PlaceCategory,
            firstVisit: Date,
            coordinate: Coordinate?,
            isHiddenFromMaps: Bool = false
        ) {
            self.id = id
            self.name = name
            self.category = category
            self.firstVisit = firstVisit
            self.coordinate = coordinate
            self.isHiddenFromMaps = isHiddenFromMaps
        }

        public init?(_ place: Place, in week: DateInterval) {
            guard let first = place.firstSeen, week.start <= first, first < week.end else { return nil }
            self.init(
                id: place.id,
                name: place.name,
                category: place.category,
                firstVisit: first,
                coordinate: place.coordinate,
                isHiddenFromMaps: place.isHiddenFromMaps)
        }

        /// Where the map tags it, or `nil` when it stays off the map.
        public var mapCoordinate: Coordinate? {
            isHiddenFromMaps ? nil : coordinate
        }
    }

    /// Tags the map holds at most: more would crowd it. The title still counts every place.
    public static let maxTags = 3

    /// Every place first visited that week, the earliest first; `nil` when the places didn't
    /// load.
    public var places: [NewPlace]?
    /// The neighborhood cells first uncovered that week, the earliest first; `nil` when they
    /// didn't load.
    public var cells: [ScratchCell]?
    /// Where the map sits with nothing new to show: the middle of the user's city.
    public var city: Coordinate?

    public init(places: [NewPlace]?, cells: [ScratchCell]?, city: Coordinate?) {
        self.places = places
        self.cells = cells
        self.city = city
    }

    /// - Parameters:
    ///   - places: every place; `nil` if they didn't load.
    ///   - cells: every uncovered cell; `nil` if they didn't load.
    public init(places: [Place]?, cells: [ScratchCell]?, week: DateInterval, city: Coordinate?) {
        self.init(
            places: places.map { places in
                places.compactMap { NewPlace($0, in: week) }.sorted { $0.firstVisit < $1.firstVisit }
            },
            cells: cells.map { cells in
                cells
                    .filter { $0.level == .neighborhood && week.start <= $0.firstUncovered && $0.firstUncovered < week.end }
                    .sorted { $0.firstUncovered < $1.firstUncovered }
            },
            city: city)
    }

    /// No places loaded and no cells loaded: the page has nothing it can claim.
    public static let unknown = WrapExplorer(places: nil, cells: nil, city: nil)

    /// A never-before place this week.
    public var isExplorerWeek: Bool {
        !(places?.isEmpty ?? true)
    }

    /// The new places the map tags: on a map, placed, the first `maxTags` of them.
    public var tagged: [NewPlace] {
        Array((places ?? []).filter { $0.mapCoordinate != nil }.prefix(Self.maxTags))
    }

    /// The neighborhoods the new cells lie in, each once, in the order they were first reached.
    public var neighborhoods: [String] {
        var names: [String] = []
        for name in (cells ?? []).compactMap(\.neighborhood) where !names.contains(name) {
            names.append(name)
        }
        return names
    }

    /// Everything the map should show: the tagged places and the new cells' corners. Empty
    /// when there's nothing new on it.
    public var pointsOnMap: [Coordinate] {
        tagged.compactMap(\.mapCoordinate) + (cells ?? []).flatMap(\.boundary)
    }
}

/// Everything the wrap's pages show, from one load of the week and the four weeks before it
/// (what's usual for the earliest exit, and the weekend before for the weekend page), with the
/// user's places and city for the postcard.
public struct WrapWeek: Hashable, Sendable {
    public var opener: WrapOpener
    public var workAndYours: WrapWorkAndYours
    public var weekends: WrapWeekends
    /// `nil` when the user wasn't at the office on any weekday.
    public var earliestExit: WrapEarliestExit?
    /// The place the week went to most; `nil` when no place outside home had a minute, or the
    /// places didn't load (`hasPlaces`).
    public var mostTime: WrapMostTime?
    /// Whether the user's places loaded: without them no place can be named, and the most-time
    /// page offers Retry.
    public var hasPlaces: Bool
    /// Places visited for the first time that week; `nil` when the places didn't load.
    public var newPlaces: Int?
    /// The middle of the user's city, for the postcard's map; `nil` without a profile.
    public var city: Coordinate?
    /// The week's new places and cells (the explorer page).
    public var explorer: WrapExplorer

    /// Days before the wrap's week that "usual" looks back over.
    public static let lookback = 28

    public init(
        opener: WrapOpener,
        workAndYours: WrapWorkAndYours,
        weekends: WrapWeekends,
        earliestExit: WrapEarliestExit?,
        mostTime: WrapMostTime? = nil,
        hasPlaces: Bool = true,
        newPlaces: Int? = nil,
        city: Coordinate? = nil,
        explorer: WrapExplorer = .unknown
    ) {
        self.opener = opener
        self.workAndYours = workAndYours
        self.weekends = weekends
        self.earliestExit = earliestExit
        self.mostTime = mostTime
        self.hasPlaces = hasPlaces
        self.newPlaces = newPlaces
        self.city = city
        self.explorer = explorer
    }

    /// - Parameters:
    ///   - week: the wrap's seven days, Monday to Sunday.
    ///   - before: the days before it, for what's usual and the weekend before (`lookback` of
    ///     them, or fewer).
    ///   - places: every place, for the one the week went to most and the ones first visited
    ///     that week; `nil` if they didn't load.
    ///   - cells: every uncovered scratch cell, for the ones the week uncovered; `nil` if they
    ///     didn't load.
    ///   - city: the middle of the user's city (`Profile.cityCenter`).
    public init(
        week: [DaySnapshot],
        before: [DaySnapshot] = [],
        places: [Place]? = nil,
        cells: [ScratchCell]? = nil,
        city: Coordinate? = nil,
        now: Date,
        calendar: Calendar
    ) {
        var lastWeekend: [DaySnapshot] = []
        if let monday = week.first?.day {
            let saturday = monday.adding(days: -2, in: calendar)
            lastWeekend = before.filter { $0.day >= saturday && $0.day < monday }
        }
        var newPlaces: Int?
        var explorer = WrapExplorer.unknown
        if let first = week.first, let last = week.last {
            let span = DateInterval(start: first.interval.start, end: max(first.interval.start, last.interval.end))
            if let places {
                newPlaces = WrapPostcard.newPlaces(places, in: span)
            }
            explorer = WrapExplorer(places: places, cells: cells, week: span, city: city)
        }
        self.init(
            opener: WrapOpener(week: week),
            workAndYours: WrapWorkAndYours(week: week, now: now),
            weekends: WrapWeekends(week: week, lastWeekend: lastWeekend, now: now, calendar: calendar),
            earliestExit: WrapEarliestExit(week: week, before: before, calendar: calendar),
            mostTime: places.flatMap { WrapMostTime(week: week, places: $0, now: now) },
            hasPlaces: places != nil,
            newPlaces: newPlaces,
            city: city,
            explorer: explorer)
    }

    /// The last page's stamp, from the other pages' numbers, so they never disagree.
    public var postcard: WrapPostcard {
        let weekendWork: TimeInterval? = switch weekends.verdict {
        case .notRecorded: nil
        case .allYours, .someWork: weekends.workByDay.reduce(0, +)
        }
        return WrapPostcard(
            work: workAndYours.work,
            yours: workAndYours.yours,
            earliestExit: earliestExit,
            weekendWork: weekendWork,
            newPlaces: newPlaces,
            city: city)
    }
}
