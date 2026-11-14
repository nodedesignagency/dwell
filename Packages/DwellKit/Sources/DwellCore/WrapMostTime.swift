import Foundation

/// The wrap's fourth page (Weekly wrap design, "Where you spent the most time"): the place the
/// week went to most, on a map, with its time that week, its visits and when it was last seen.
///
/// Home is left out, as Time's places over time leaves it out (`PlaceTrend`): it holds the
/// nights, so it would win every week, and the design's place is work (QUESTIONS.md). Private
/// and personal places are left out too: the page puts its place on a map, and they never go
/// on one (brief §7.2). Visits Dwell couldn't name yet have no place to show. Time is counted
/// as Time counts it, clipped to the week and to now, so the wrap and Time never disagree.
public struct WrapMostTime: Hashable, Sendable {
    /// Less than this in a week isn't "the most time" anywhere: the page says so instead.
    public static let minimum: TimeInterval = 60

    public var place: Place
    /// Time there in the wrap's week.
    public var total: TimeInterval
    /// Visits there that week. A visit that runs past 4 AM shows in both days and counts once.
    public var visits: Int

    public init(place: Place, total: TimeInterval, visits: Int) {
        self.place = place
        self.total = total
        self.visits = visits
    }

    /// The place with the most time in `week` among `places` that may be shown; `nil` when no
    /// such place had a minute (a week at home, or only at private places). Ties go to the
    /// place listed first.
    ///
    /// - Parameters:
    ///   - week: Monday to Sunday.
    ///   - places: every place, for names, the map and first and last seen.
    public init?(week: [DaySnapshot], places: [Place], now: Date) {
        guard let first = week.first, let last = week.last else { return nil }
        let whole = DateInterval(start: first.interval.start, end: max(first.interval.start, last.interval.end))
        let shown = places.filter(Self.isShown)
        let ids = Set(shown.map(\.id))

        var totals: [PlaceID: TimeInterval] = [:]
        var visits: [PlaceID: Set<VisitID>] = [:]
        for day in week {
            for entry in day.entries {
                guard
                    let visit = entry.visit, let id = visit.placeID, ids.contains(id),
                    let span = day.span(of: entry, within: whole, now: now)
                else { continue }
                totals[id, default: 0] += span.duration
                visits[id, default: []].insert(visit.id)
            }
        }

        var best: (place: Place, total: TimeInterval)?
        for place in shown {
            let total = totals[place.id] ?? 0
            if total > (best?.total ?? 0) { best = (place, total) }
        }
        guard let best, best.total >= Self.minimum else { return nil }
        self.init(place: best.place, total: best.total, visits: visits[best.place.id]?.count ?? 0)
    }

    /// Whether a place may be the page's: not home, and allowed on a map.
    public static func isShown(_ place: Place) -> Bool {
        place.category != .home && place.role != .home && !place.isHiddenFromMaps
    }
}
