import Foundation

/// Which places are growing or shrinking in your life (brief §7.3 "Places over time";
/// "Northline Gym: up 40% this month." "Brambleline Café: not since August.").
///
/// The last four weeks against the four before them, rolling, so it reads the same whatever
/// period Time shows. Home is left out (it's most of every week), and so are private and
/// personal places: they're never highlighted.
public struct PlaceTrend: Hashable, Sendable, Identifiable {
    public static let window: TimeInterval = 28 * 86_400
    /// A change smaller than this either way is steady.
    public static let steadyBand = 0.1
    public static let maxShown = 3

    public var placeID: PlaceID
    public var name: String
    public var category: PlaceCategory
    /// Time there in the last four weeks.
    public var recent: TimeInterval
    /// Time there in the four weeks before.
    public var before: TimeInterval
    /// The last visit, for a paused place ("Not since Sep 26").
    public var lastSeen: Date?

    public var id: PlaceID { placeID }

    /// Paused: there before, not since.
    public var isPaused: Bool { recent <= 0 && before > 0 }

    /// The change as a share of before: 0.4 is "up 40%". `nil` for a place new in the last
    /// four weeks, or paused.
    public var change: Double? {
        guard before > 0, recent > 0 else { return nil }
        return (recent - before) / before
    }

    /// The trends worth showing as of `now`: the place that grew most, the one that shrank
    /// most, the one paused most recently; then the next biggest changes, up to three.
    public static func compute(places: [Place], days: [DaySnapshot], now: Date) -> [PlaceTrend] {
        let recentWindow = DateInterval(start: now.addingTimeInterval(-window), end: now)
        let beforeWindow = DateInterval(start: now.addingTimeInterval(-2 * window), end: recentWindow.start)
        let shown = places.filter { $0.category != .home && $0.role != .home && !$0.isHiddenFromMaps }

        var trends: [PlaceID: PlaceTrend] = [:]
        for place in shown {
            trends[place.id] = PlaceTrend(placeID: place.id, name: place.name, category: place.category, recent: 0, before: 0)
        }
        var counted: Set<VisitID> = []
        for day in days {
            for entry in day.entries {
                guard let visit = entry.visit, let id = visit.placeID, trends[id] != nil else { continue }
                if let recent = day.span(of: entry, within: recentWindow, now: now) {
                    trends[id]?.recent += recent.duration
                }
                if let before = day.span(of: entry, within: beforeWindow, now: now) {
                    trends[id]?.before += before.duration
                }
                if counted.insert(visit.id).inserted, visit.arrival <= now {
                    let lastSeen = trends[id]?.lastSeen ?? .distantPast
                    trends[id]?.lastSeen = max(lastSeen, visit.arrival)
                }
            }
        }

        let all = trends.values.filter { $0.recent >= 60 || $0.before >= 60 }
        var picked: [PlaceTrend] = []
        func pick(_ trend: PlaceTrend?) {
            guard let trend, !picked.contains(where: { $0.id == trend.id }) else { return }
            picked.append(trend)
        }
        let changing = all.filter { $0.change != nil }
        pick(changing.filter { ($0.change ?? 0) > 0 }.max { $0.recent - $0.before < $1.recent - $1.before })
        pick(changing.filter { ($0.change ?? 0) < 0 }.max { $0.before - $0.recent < $1.before - $1.recent })
        pick(all.filter(\.isPaused).max { ($0.lastSeen ?? .distantPast) < ($1.lastSeen ?? .distantPast) })
        for trend in changing.sorted(by: { abs($0.recent - $0.before) > abs($1.recent - $1.before) }) where picked.count < maxShown {
            pick(trend)
        }

        // Growing, then shrinking, then paused, as the design reads.
        func rank(_ trend: PlaceTrend) -> Int {
            if trend.isPaused { return 2 }
            return (trend.change ?? 0) >= 0 ? 0 : 1
        }
        return Array(picked.prefix(maxShown)).sorted { rank($0) < rank($1) }
    }
}
