import Foundation

/// A day's numbers as Today reports them: one place for the rules about which time counts
/// as what, so the headline, the hero stats and the day bar never disagree.
public struct DayRecap: Hashable, Sendable {
    /// Where the most time went outside work and home: "57m at Brambleline Café".
    public struct Standout: Hashable, Sendable {
        public var name: String
        public var category: PlaceCategory
        public var duration: TimeInterval
    }

    public var work: TimeInterval
    public var home: TimeInterval
    /// Time that is yours: everything mapped except work, home and transit.
    ///
    /// The brief never defines "yours". This matches the Today design (57m, the café) and the
    /// brief's day-2 line ("9h 12m at work, 2h 40m yours"), which only add up if evenings at
    /// home are left out. Home and yours are different (the user's call, 12 Nov), so the
    /// first-place design's "28m Yours" at home reads 0m. Still open with Zac (QUESTIONS.md 11).
    public var yours: TimeInterval
    /// Separate stretches at work: "2 sessions".
    public var workSessions: Int
    /// Private and personal places never lead the headline.
    public var standout: Standout?
    /// Everything Dwell saw: visits and transit.
    public var mapped: TimeInterval
    /// The rest of the day so far: gaps, and any stretch with no entry at all.
    public var unmapped: TimeInterval
    /// How many different places the day's visits were at, private ones included:
    /// "and nowhere else yet" is only true at one.
    public var placesVisited: Int
}

extension DaySnapshot {
    /// The part of the day that has happened: 4:00 AM to now, or the whole day once it is over.
    /// On the install day it starts when Dwell began recording; days before it have none.
    public func elapsed(now: Date) -> DateInterval {
        let start = max(interval.start, recordingSince ?? interval.start)
        return DateInterval(start: start, end: max(start, min(interval.end, now)))
    }

    public func recap(now: Date) -> DayRecap {
        let totals = totals(now: now)
        let mapped = totals.values.reduce(0, +)
        let visits = entries.compactMap(\.visit).filter { clippedDuration(of: .visit($0), now: now) > 0 }

        var byPlace: [String: DayRecap.Standout] = [:]
        var order: [String] = []
        for visit in visits where Self.canStandOut(visit) {
            let key = visit.placeID?.rawValue ?? visit.placeName
            if byPlace[key] == nil {
                order.append(key)
                byPlace[key] = DayRecap.Standout(name: visit.placeName, category: visit.category, duration: 0)
            }
            byPlace[key]?.duration += clippedDuration(of: .visit(visit), now: now)
        }
        // Earliest place wins a tie.
        let standout = order.compactMap { byPlace[$0] }.reduce(nil) { best, next -> DayRecap.Standout? in
            guard let best else { return next }
            return next.duration > best.duration ? next : best
        }

        let work = totals[.work] ?? 0
        let home = totals[.home] ?? 0
        let transit = totals[.transit] ?? 0
        return DayRecap(
            work: work,
            home: home,
            yours: max(0, mapped - work - home - transit),
            workSessions: visits.filter { $0.category == .work }.count,
            standout: standout,
            mapped: mapped,
            unmapped: max(0, elapsed(now: now).duration - mapped),
            placesVisited: Set(visits.map { $0.placeID?.rawValue ?? $0.placeName }).count)
    }

    private static func canStandOut(_ visit: Visit) -> Bool {
        switch visit.category {
        case .work, .home, .transit, .personal: false
        default: !visit.isPrivate
        }
    }
}

/// The two big numbers on Today, chosen by the dial (brief §7.1): Peace sees work and yours,
/// Grind sees work and sessions.
///
/// Open question (docs/QUESTIONS.md): only Peace and Grind are specified. Calm and Plain
/// show yours, Push shows sessions, following each stop's nearer anchor.
public enum HeroStat: Hashable, Sendable {
    case work
    case yours
    case sessions

    public static func pair(for stop: Dial.Stop) -> (HeroStat, HeroStat) {
        switch stop {
        case .peace, .calm, .plain: (.work, .yours)
        case .push, .grind: (.work, .sessions)
        }
    }
}
