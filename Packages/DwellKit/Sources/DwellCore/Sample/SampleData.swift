import Foundation

/// A stand-in week for previews, the simulator and the fictional demo: a product manager in
/// Brooklyn who works at Kestriva Labs (Maya from the brief, middle of the dial).
/// Sunday night 18 October to Monday 26 October 2026, 2:47 PM, which is "now".
///
/// Names come from the brief. Replace this with Appendix D ("a real week") once the client
/// sends it: it has the real string lengths, visits per day and how often gaps happen.
public enum SampleData {
    public static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }()

    /// Monday 26 October 2026, 2:47 PM in New York.
    public static let now = date(month: 10, day: 26, minutes: 14 * 60 + 47)
    public static let today = DwellDay(containing: now, calendar: calendar)
    /// Monday 19 to Sunday 25 October, the last full week.
    public static let lastWeek: [DwellDay] = (19...25).map { DwellDay(year: 2026, month: 10, day: $0) }

    // MARK: Places

    public static let places: [Place] = [
        Place(id: "home", name: "Home", category: .home, role: .home,
              lifetimeTotal: hours(412, 10), visitCount: 63),
        Place(id: "kestriva", name: "Kestriva Labs", category: .work, role: .work, shareLevel: .venue,
              isFavorite: true, lifetimeTotal: hours(148, 20), visitCount: 31),
        Place(id: "brambleline", name: "Brambleline Café", category: .foodAndDrink, shareLevel: .venue,
              isFavorite: true, lifetimeTotal: hours(21, 40), visitCount: 34),
        Place(id: "northline", name: "Northline Gym", category: .fitness, role: .gym,
              lifetimeTotal: hours(26, 10), visitCount: 22),
        Place(id: "sorrel", name: "Sorrel Kitchen", category: .foodAndDrink,
              lifetimeTotal: hours(6, 50), visitCount: 11),
        Place(id: "halloway", name: "Halloway Pharmacy", category: .errands,
              lifetimeTotal: hours(1, 20), visitCount: 7),
        Place(id: "greenmarket", name: "Carroll Street Greenmarket", category: .shopping,
              lifetimeTotal: hours(3, 5), visitCount: 8),
        Place(id: "juniper", name: "Juniper & Vine", category: .foodAndDrink,
              lifetimeTotal: hours(9, 30), visitCount: 5),
        Place(id: "larkspur", name: "Larkspur Cinema", category: .entertainment,
              lifetimeTotal: hours(4, 50), visitCount: 2),
        Place(id: "prospect", name: "Prospect Park", category: .outdoors,
              lifetimeTotal: hours(14, 15), visitCount: 9),
        Place(id: "maras", name: "Mara's place", category: .social,
              lifetimeTotal: hours(18, 40), visitCount: 6),
        Place(id: "ashgrove", name: "Ashgrove Library", category: .education,
              lifetimeTotal: hours(5, 30), visitCount: 4),
        Place(id: "tidewater", name: "Tidewater Books", category: .shopping,
              lifetimeTotal: hours(0, 39), visitCount: 1),
        Place(id: "stagnes", name: "St. Agnes Community Health & Wellness Center", category: .personal,
              isPrivate: true, lifetimeTotal: hours(2, 10), visitCount: 3),
    ]

    public static func place(_ id: PlaceID) -> Place {
        guard let place = places.first(where: { $0.id == id }) else {
            preconditionFailure("No sample place \(id)")
        }
        return place
    }

    // MARK: Days

    /// Every entry across the whole stretch, in order.
    public static var entries: [TimelineEntry] { timeline.entries }

    /// The day as Today and Time would receive it. Days without data come back empty.
    public static func snapshot(for day: DwellDay) -> DaySnapshot {
        let interval = day.interval(in: calendar)
        let entries = timeline.entries.filter { entry in
            let span = entry.interval(now: now)
            return span.start < min(interval.end, now) && span.end > interval.start
        }
        let matches = timeline.matches.filter { interval.contains($0.interval.start) }
        return DaySnapshot(day: day, interval: interval, entries: entries, calendarMatches: matches)
    }

    public static var todaySnapshot: DaySnapshot { snapshot(for: today) }

    public static var liveStatus: LiveStatus {
        guard let visit = todaySnapshot.entries.last?.visit, visit.isOngoing else { return .unknown }
        return .atPlace(visit)
    }

    // MARK: Voice, collectibles, coverage

    /// Today's deck, lines from the brief's copy deck (Appendix B). The first is the hero.
    /// Only lines that hold on Monday 26 October: the 10h 12m record ("…today") lives in `records`.
    public static let insights: [Insight] = [
        Insight(
            id: "weekend-zero-work", family: .first,
            topic: "Work hours", // [COPY NEEDED]
            line: VoicedLine(
                peace: "A whole weekend to yourself. First since March 8.",
                plain: "Zero work hours Sat–Sun. First since March 8.",
                grind: "Zero work this weekend. Recharged or slacking? Monday decides."),
            value: "0h",
            week: lastWeek.map { DayValue(day: $0, value: snapshot(for: $0).totals(now: now)[.work] ?? 0) }),
        Insight(
            id: "new-cell-red-hook", family: .scratchProgress,
            topic: "New places", // [COPY NEEDED]
            line: VoicedLine(
                peace: "Somewhere new: Red Hook.",
                plain: "New neighborhood: Red Hook. First time.",
                grind: "Red Hook, uncovered. 3.2% of Brooklyn."),
            value: "3.2%"),
        Insight(
            id: "early-exit", family: .record,
            topic: "Office hours", // [COPY NEEDED]
            line: VoicedLine(
                peace: "Out by 5:52. The evening is yours.",
                plain: "Office exit 5:52 PM. Earliest this week.",
                grind: "5:52? Soft. Earliest exit this week."),
            value: "5:52 PM"),
    ]

    public static let streaks: [Streak] = [
        Streak(kind: .gymRegular, current: 3, best: 12, freezes: 1, state: .active),
        Streak(kind: .explorerWeek, current: 4, best: 4, freezes: 0, state: .active),
        Streak(kind: .firstIn, current: 1, best: 4, freezes: 0, state: .active),
        Streak(kind: .outByTarget, current: 0, best: 14, freezes: 0, state: .broken),
    ]

    public static let badges: [Badge] = [
        Badge(kind: .foundingUser, tier: .gold, progress: 1),
        Badge(kind: .explorer, tier: .silver, progress: 0.45),
        Badge(kind: .earlyBird, tier: .bronze, progress: 0.6),
        Badge(kind: .cartographer, tier: .bronze, progress: 0.2),
        Badge(kind: .marathoner, tier: nil, progress: 0.3),
        Badge(kind: .globetrotter, tier: nil, progress: 0),
    ]

    public static let records: [PersonalRecord] = [
        PersonalRecord(id: "longest-day", title: "Longest day at work", value: "10h 12m",
                       date: date(month: 10, day: 22, minutes: 18 * 60 + 24)),
        PersonalRecord(id: "earliest-arrival", title: "Earliest arrival", value: "8:12 AM",
                       date: date(month: 10, day: 22, minutes: 8 * 60 + 12)),
        PersonalRecord(id: "most-places", title: "Most places in a day", value: "5",
                       date: date(month: 10, day: 20, minutes: 18 * 60 + 52)),
        PersonalRecord(id: "longest-gym-streak", title: "Longest gym streak", value: "12 days"),
        PersonalRecord(id: "longest-weekend-away", title: "Longest weekend away", value: nil,
                       unlockHint: "Spend a weekend away from home."),
    ]

    public static let coverage: [ScratchCoverage] = [
        ScratchCoverage(level: .neighborhood, area: "Brooklyn", uncovered: 41, total: 1281, uncoveredThisWeek: 1),
        ScratchCoverage(level: .city, area: "the United States", uncovered: 4, total: 310),
        ScratchCoverage(level: .country, area: "the world", uncovered: 4, total: 195),
    ]
}

// MARK: - Building the week

extension SampleData {
    private struct Flags: OptionSet, Sendable {
        let rawValue: Int
        static let approximate = Flags(rawValue: 1 << 0)
        static let workFromHome = Flags(rawValue: 1 << 1)
        static let needsReview = Flags(rawValue: 1 << 2)
        static let ongoing = Flags(rawValue: 1 << 3)
    }

    /// Times are "H:MM" from midnight of that row's date and may run past 24:00
    /// ("31:42" is 7:42 the next morning), so a night at home stays one visit.
    private enum Row: Sendable {
        case visit(PlaceID, String, String, Flags = [])
        case transit(String, String)
        case gap(String, String)
        case event(String, String, String, CalendarMatch.State)
    }

    private static let week: [(day: Int, rows: [Row])] = [
        (18, [
            .visit("home", "21:10", "31:42"),
        ]),
        (19, [
            .transit("7:42", "8:05"), .visit("brambleline", "8:05", "8:24"), .transit("8:24", "8:41"),
            .visit("kestriva", "8:41", "12:34"), .transit("12:34", "12:41"), .visit("sorrel", "12:41", "13:22"),
            .gap("13:22", "13:44"), .visit("kestriva", "13:44", "18:07"), .transit("18:07", "18:26"),
            .visit("northline", "18:26", "19:31"), .transit("19:31", "19:44"), .visit("home", "19:44", "31:58"),
            .event("Team standup", "9:30", "9:45", .attended),
        ]),
        (20, [
            .transit("7:58", "8:20"), .visit("kestriva", "8:20", "12:15"), .transit("12:15", "12:20"),
            .visit("halloway", "12:20", "12:31"), .transit("12:31", "12:36"),
            .visit("sorrel", "12:36", "13:10", [.approximate]), .transit("13:10", "13:14"),
            .visit("kestriva", "13:14", "17:52"), .transit("17:52", "18:15"), .visit("greenmarket", "18:15", "18:40"),
            .transit("18:40", "18:52"), .visit("home", "18:52", "31:40"),
            .event("Team standup", "9:30", "9:45", .attended),
            .event("Design review", "14:00", "15:00", .attended),
        ]),
        (21, [
            .transit("7:40", "8:02"), .visit("northline", "8:02", "8:58"), .transit("8:58", "9:20"),
            .visit("kestriva", "9:20", "19:12"), .transit("19:12", "19:35"), .visit("juniper", "19:35", "21:20"),
            .transit("21:20", "21:41"), .visit("home", "21:41", "31:51"),
            .event("Team standup", "9:30", "9:45", .attended),
            .event("Dentist", "13:00", "13:45", .missed(instead: "Kestriva Labs")),
        ]),
        (22, [
            .transit("7:51", "8:12"), .visit("kestriva", "8:12", "18:24"), .transit("18:24", "18:49"),
            .visit("larkspur", "18:49", "21:15"), .transit("21:15", "21:38"), .visit("home", "21:38", "32:09"),
            .event("Team standup", "9:30", "9:45", .attended),
        ]),
        (23, [
            .transit("8:09", "8:30"), .visit("brambleline", "8:30", "9:03"), .transit("9:03", "9:20"),
            .visit("home", "9:20", "12:30", [.workFromHome]), .transit("12:30", "12:40"),
            .visit("halloway", "12:40", "12:52"), .transit("12:52", "13:05"),
            .visit("home", "13:05", "18:42", [.workFromHome]), .transit("18:42", "19:05"),
            .visit("maras", "19:05", "23:48"), .transit("23:48", "24:06"), .visit("home", "24:06", "34:25"),
            .event("Coffee with Sam", "8:30", "9:15", .partial(arrivedLate: 0, leftEarly: 12 * 60)),
        ]),
        (24, [
            .transit("10:25", "10:41"), .visit("prospect", "10:41", "12:58", [.approximate]),
            .transit("12:58", "13:10"), .visit("brambleline", "13:10", "14:02"), .gap("14:02", "14:47"),
            .visit("home", "14:47", "18:30"), .transit("18:30", "18:55"), .visit("juniper", "18:55", "21:30"),
            .transit("21:30", "21:48"), .visit("home", "21:48", "33:30"),
        ]),
        (25, [
            .transit("9:30", "9:55"), .visit("ashgrove", "9:55", "11:40"), .transit("11:40", "12:10"),
            .visit("tidewater", "12:10", "12:49"), .transit("12:49", "13:15"), .visit("home", "13:15", "16:00"),
            .transit("16:00", "16:20"), .visit("northline", "16:20", "17:25"), .transit("17:25", "17:40"),
            .visit("home", "17:40", "31:47"),
        ]),
        (26, [
            .transit("7:47", "8:02"), .visit("brambleline", "8:02", "8:59", [.needsReview]),
            .transit("8:59", "9:14"), .visit("kestriva", "9:14", "12:38"), .transit("12:38", "12:46"),
            .visit("stagnes", "12:46", "13:20"), .transit("13:20", "13:31"),
            .visit("kestriva", "13:31", "", [.ongoing]),
            .event("Team standup", "9:30", "9:45", .attended),
            .event("Lunch with Priya", "12:30", "13:30", .missed(instead: nil)),
        ]),
    ]

    private static let timeline: (entries: [TimelineEntry], matches: [CalendarMatch]) = {
        var entries: [TimelineEntry] = []
        var matches: [CalendarMatch] = []
        for (day, rows) in week {
            for (index, row) in rows.enumerated() {
                func at(_ time: String) -> Date { date(month: 10, day: day, time: time) }
                switch row {
                case .visit(let id, let start, let end, let flags):
                    let venue = place(id)
                    entries.append(.visit(Visit(
                        id: VisitID("10-\(day)-\(index)"),
                        placeID: id,
                        placeName: venue.name,
                        category: flags.contains(.workFromHome) ? .work : venue.category,
                        arrival: at(start),
                        departure: flags.contains(.ongoing) ? nil : at(end),
                        precision: flags.contains(.approximate) ? .approximate : .exact,
                        isPrivate: venue.isPrivate,
                        isWorkFromHome: flags.contains(.workFromHome),
                        needsReview: flags.contains(.needsReview))))
                case .transit(let start, let end):
                    entries.append(.transit(DateInterval(start: at(start), end: at(end))))
                case .gap(let start, let end):
                    entries.append(.gap(DateInterval(start: at(start), end: at(end))))
                case .event(let title, let start, let end, let state):
                    matches.append(CalendarMatch(
                        id: "event-10-\(day)-\(index)", title: title,
                        interval: DateInterval(start: at(start), end: at(end)), state: state))
                }
            }
        }
        return (entries, matches)
    }()

    private static func date(month: Int, day: Int, time: String) -> Date {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        precondition(parts.count == 2, "Bad sample time \(time)")
        return date(month: month, day: day, minutes: parts[0] * 60 + parts[1])
    }

    private static func date(month: Int, day: Int, minutes: Int) -> Date {
        let midnight = calendar.date(from: DateComponents(year: 2026, month: month, day: day)) ?? .distantPast
        return calendar.date(byAdding: .minute, value: minutes, to: midnight) ?? midnight
    }

    private static func hours(_ hours: Int, _ minutes: Int) -> TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60)
    }
}
