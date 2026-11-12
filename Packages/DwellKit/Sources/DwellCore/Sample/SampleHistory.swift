import Foundation

extension SampleData {
    /// Maya's seven weeks before the hand-written one: Monday 31 August, when she installed
    /// Dwell at home at 7:40 AM, to Sunday 18 October, home at 9:10 PM, where the hand-written
    /// week takes over. Generated from her routines with a seeded dice, so it's the same every
    /// run.
    ///
    /// The routines: weekdays at Kestriva Labs (in by 8:15 at the earliest, never more than
    /// 9h 50m, so 22 October stays the record), coffee at Brambleline on the way some days,
    /// lunch out most days, the gym a couple of evenings a week (more in October), drinks at
    /// Juniper & Vine on Thursdays, the odd Friday from home. Weekends: the greenmarket or
    /// Prospect Park, Mara's place or Juniper & Vine in the evening. Labor Day (7 September) is
    /// a day off. The gym every day from 8 to 19 September (the records wall's 12-day streak);
    /// Halcyon Pool on two September Saturdays and not since (paused, for places over time); two
    /// private lunchtime visits to St. Agnes. Now and then Dwell sleeps through a walk home or
    /// an afternoon, as a real week has gaps. Never more than five places a day (the record is
    /// 20 October's five). The Monday standup ends early on 5 and 12 October, as on the 19th.
    static let history: (entries: [TimelineEntry], matches: [CalendarMatch]) = {
        var entries: [TimelineEntry] = []
        var matches: [CalendarMatch] = []
        var homeSince = recordingSince
        var day = DwellDay(year: 2026, month: 8, day: 31)
        let last = DwellDay(year: 2026, month: 10, day: 18)
        while day <= last {
            let (items, events) = HistoryDay.plan(day)
            func at(_ minutes: Int) -> Date { date(month: day.month, day: day.day, minutes: minutes) }
            let tag = "h-\(day.month)-\(day.day)"

            // The night at home, up to the first time out.
            if let first = items.first, at(first.start) > homeSince {
                entries.append(.visit(Visit(
                    id: VisitID("\(tag)-home"), placeID: "home", placeName: "Home", category: .home,
                    arrival: homeSince, departure: at(first.start))))
            }

            var homeArrival = items.last.map { at($0.end) } ?? homeSince
            var shown = items
            // A day that ends at home leaves the evening to the night's visit.
            if let final = shown.last, case .visit("home", let flags) = final.kind, !flags.contains(.workFromHome) {
                homeArrival = at(final.start)
                shown.removeLast()
            }
            for (index, item) in shown.enumerated() {
                let span = DateInterval(start: at(item.start), end: at(item.end))
                switch item.kind {
                case .visit(let id, let flags):
                    let venue = definition(id)
                    let fromHome = flags.contains(.workFromHome)
                    entries.append(.visit(Visit(
                        id: VisitID("\(tag)-\(index)"), placeID: id, placeName: venue.name,
                        category: fromHome ? .work : venue.category,
                        subcategory: fromHome ? nil : venue.subcategory,
                        arrival: span.start, departure: span.end,
                        precision: id == "prospect" ? .approximate : .exact,
                        isPrivate: venue.isPrivate, isWorkFromHome: fromHome)))
                case .transit:
                    entries.append(.transit(span))
                case .gap:
                    entries.append(.gap(span))
                }
            }
            for (index, event) in events.enumerated() {
                matches.append(CalendarMatch(
                    id: "event-\(tag)-\(index)", title: event.title,
                    interval: DateInterval(start: at(event.start), end: at(event.end)), state: event.state))
            }
            homeSince = homeArrival
            day = day.adding(days: 1, in: calendar)
        }
        return (entries, matches)
    }()
}

/// One generated day: what Maya did, minute by minute from that date's midnight.
private enum HistoryDay {
    enum Kind {
        case visit(PlaceID, SampleData.Flags)
        case transit
        case gap
    }

    typealias Item = (kind: Kind, start: Int, end: Int)
    typealias Event = (title: String, start: Int, end: Int, state: CalendarMatch.State)

    static func plan(_ day: DwellDay) -> ([Item], [Event]) {
        let weekday = SampleData.calendar.component(.weekday, from: day.start(in: SampleData.calendar))
        var dice = Dice(seed: day.year * 10_000 + day.month * 100 + day.day)
        let laborDay = day == DwellDay(year: 2026, month: 9, day: 7)
        switch weekday {
        case 2...6 where !laborDay: return workday(day, weekday: weekday, dice: &dice)
        case 7: return (saturday(day, dice: &dice), [])
        default: return (sunday(day, dice: &dice), [])
        }
    }

    static func isStreak(_ day: DwellDay) -> Bool {
        day.month == 9 && (8...19).contains(day.day)
    }

    // MARK: Weekdays

    static func workday(_ day: DwellDay, weekday: Int, dice: inout Dice) -> ([Item], [Event]) {
        let october = day.month == 10
        var p = Planner(t: 7 * 60 + 35 + dice.int(0...30))
        if day == DwellDay(year: 2026, month: 8, day: 31) { p.t = max(p.t, 7 * 60 + 58) }
        var events: [Event] = []

        if weekday == 6, dice.chance(0.3) {
            // Friday from home: coffee first, lunch out.
            p.go(dice.int(14...18)); p.stay("brambleline", dice.int(25...40)); p.go(dice.int(14...18))
            p.stay("home", until: 12 * 60 + 30 + dice.int(0...15), .workFromHome)
            p.go(dice.int(8...12)); p.stay("sorrel", dice.int(35...50)); p.go(dice.int(8...12))
            p.stay("home", until: 17 * 60 + 40 + dice.int(0...30), .workFromHome)
            return (p.items, events)
        }

        if dice.chance(october ? 0.35 : 0.5) {
            p.go(dice.int(12...16)); p.stay("brambleline", dice.int(15...30)); p.go(dice.int(12...18))
        } else {
            p.go(dice.int(18...26))
        }
        p.arrive(atLeast: 8 * 60 + 15)
        let arrive = p.t

        let leftEarly: [DwellDay: TimeInterval] = [
            DwellDay(year: 2026, month: 10, day: 5): 6 * 60,
            DwellDay(year: 2026, month: 10, day: 12): 4 * 60,
        ]
        events.append(("Team standup", 9 * 60 + 30, 9 * 60 + 45,
                       leftEarly[day].map { .partial(arrivedLate: 0, leftEarly: $0) } ?? .attended))
        if weekday == 3 {
            events.append(("Design review", 14 * 60, 15 * 60, .attended))
        }

        var worked = 0
        let lunchAt = 12 * 60 + 10 + dice.int(0...45)
        let pick = dice.int(0...9)
        let privateLunch = day == DwellDay(year: 2026, month: 9, day: 22) || day == DwellDay(year: 2026, month: 10, day: 8)
        let lunch: PlaceID? = privateLunch ? "stagnes" : pick <= 3 ? "sorrel" : pick <= 5 ? "brambleline" : pick == 6 ? "halloway" : nil
        if let lunch {
            p.stay("kestriva", until: lunchAt)
            worked += lunchAt - arrive
            p.go(dice.int(5...8))
            p.stay(lunch, lunch == "halloway" ? dice.int(9...14) : lunch == "stagnes" ? dice.int(30...40) : dice.int(30...48))
            p.go(dice.int(5...8))
        }
        let back = p.t
        let leave = min(17 * 60 + 45 + dice.int(0...80), back + 9 * 60 + 50 - worked)
        if dice.chance(0.12) {
            let gapAt = 15 * 60 + dice.int(0...40)
            if gapAt > back + 30, gapAt + 40 < leave {
                p.stay("kestriva", until: gapAt)
                p.sleep(dice.int(15...35))
            }
        }
        p.stay("kestriva", until: leave)

        let gym = isStreak(day) || (october ? [2, 4, 6].contains(weekday) && dice.chance(0.7) : [2, 5].contains(weekday) && dice.chance(0.5))
        if day == DwellDay(year: 2026, month: 9, day: 24) {
            p.go(22); p.stay("larkspur", 140); p.go(22)
        } else if gym {
            p.go(dice.int(14...20)); p.stay("northline", dice.int(55...75)); p.go(dice.int(10...15))
        } else if weekday == 5, dice.chance(0.55) {
            p.go(dice.int(18...24)); p.stay("juniper", dice.int(90...150)); p.go(dice.int(18...24))
        } else if weekday == 3, dice.chance(0.35) {
            p.go(dice.int(18...24)); p.stay("greenmarket", dice.int(18...30)); p.go(dice.int(10...14))
        } else if dice.chance(0.2) {
            p.sleep(dice.int(18...28)) // Dwell slept through the walk home
        } else {
            p.go(dice.int(18...28))
        }
        return (p.items, events)
    }

    // MARK: Weekends

    static func saturday(_ day: DwellDay, dice: inout Dice) -> [Item] {
        let pool = day == DwellDay(year: 2026, month: 9, day: 5) || day == DwellDay(year: 2026, month: 9, day: 26)
        var p = Planner(t: pool ? 8 * 60 + 40 : 9 * 60 + 40 + dice.int(0...50))
        if pool {
            p.go(dice.int(12...16)); p.stay("halcyon", dice.int(55...65)); p.go(dice.int(12...16))
            p.stay("home", dice.int(40...70))
        } else if isStreak(day) {
            p.go(dice.int(12...16)); p.stay("northline", dice.int(55...70)); p.go(dice.int(12...16))
            p.stay("home", dice.int(30...60))
        }
        if dice.chance(0.55) {
            p.go(dice.int(16...22)); p.stay("greenmarket", dice.int(20...35)); p.go(dice.int(8...12))
            p.stay("brambleline", dice.int(30...45)); p.go(dice.int(12...16))
        } else {
            p.go(dice.int(15...22)); p.stay("prospect", dice.int(90...150)); p.go(dice.int(10...14))
            p.stay("sorrel", dice.int(40...55)); p.go(dice.int(12...16))
        }
        let evening = dice.int(0...9)
        if evening <= 4 {
            p.stay("home", until: 18 * 60 + 30 + dice.int(0...30)); p.go(dice.int(18...24))
            p.stay("maras", until: 23 * 60 + dice.int(0...45)); p.go(dice.int(16...22))
        } else if evening <= 7 {
            p.stay("home", until: 18 * 60 + 40 + dice.int(0...30)); p.go(dice.int(16...22))
            p.stay("juniper", dice.int(110...160)); p.go(dice.int(16...22))
        }
        return p.items
    }

    static func sunday(_ day: DwellDay, dice: inout Dice) -> [Item] {
        let lastOne = day == DwellDay(year: 2026, month: 10, day: 18)
        var p = Planner(t: 10 * 60 + 15 + dice.int(0...60))
        if isStreak(day) {
            p.go(dice.int(12...16)); p.stay("northline", dice.int(55...70)); p.go(dice.int(12...16))
            p.stay("home", dice.int(30...60))
        }
        let pick = dice.int(0...9)
        if pick <= 4 {
            p.go(dice.int(15...22)); p.stay("prospect", dice.int(80...140)); p.go(dice.int(12...18))
        } else if pick <= 6 {
            p.go(dice.int(20...28)); p.stay("ashgrove", dice.int(90...120)); p.go(dice.int(20...28))
        } else {
            p.go(dice.int(12...16)); p.stay("brambleline", dice.int(35...50)); p.go(dice.int(12...16))
        }
        if !lastOne, !isStreak(day), dice.chance(day.month == 10 ? 0.6 : 0.35) {
            p.stay("home", until: 16 * 60 + dice.int(0...40)); p.go(15)
            p.stay("northline", dice.int(60...70)); p.go(12)
        }
        if lastOne {
            // Into the hand-written week: home at 9:10 PM.
            p.stay("home", until: 18 * 60 + 20); p.go(20)
            p.stay("juniper", until: 20 * 60 + 50); p.go(until: 21 * 60 + 10)
        }
        return p.items
    }

    // MARK: Building a day

    struct Planner {
        var t: Int
        var items: [Item] = []

        init(t: Int) {
            self.t = t
        }

        mutating func go(_ minutes: Int) { add(.transit, minutes) }
        mutating func go(until end: Int) { add(.transit, max(1, end - t)) }
        mutating func sleep(_ minutes: Int) { add(.gap, minutes) }
        mutating func stay(_ id: PlaceID, _ minutes: Int, _ flags: SampleData.Flags = []) { add(.visit(id, flags), minutes) }
        mutating func stay(_ id: PlaceID, until end: Int, _ flags: SampleData.Flags = []) {
            add(.visit(id, flags), max(10, end - t))
        }

        /// Stretches the last leg so the next stop starts no earlier than `minute`.
        mutating func arrive(atLeast minute: Int) {
            guard t < minute, !items.isEmpty else { return }
            items[items.count - 1].end += minute - t
            t = minute
        }

        private mutating func add(_ kind: Kind, _ minutes: Int) {
            items.append((kind, t, t + minutes))
            t += minutes
        }
    }
}

/// A small seeded dice (SplitMix64): the same numbers every run, no Foundation randomness.
private struct Dice {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(truncatingIfNeeded: seed) &* 0x9E37_79B9_7F4A_7C15 &+ 0x2545_F491
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func int(_ range: ClosedRange<Int>) -> Int {
        range.lowerBound + Int(next() % UInt64(range.count))
    }

    mutating func chance(_ probability: Double) -> Bool {
        Double(next() % 10_000) / 10_000 < probability
    }
}
