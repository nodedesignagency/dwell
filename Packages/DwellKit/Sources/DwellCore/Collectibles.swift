import Foundation

/// A templated, novel fact about the user's own data, voiced by the dial (brief §9).
public struct Insight: Identifiable, Hashable, Sendable {
    public enum Family: String, CaseIterable, Sendable {
        case record
        case first
        case trend
        case anomaly
        case rhythm
        case placesOverTime
        case calendarVsReality
        case scratchProgress
        case pastComparison
        case periodic
    }

    public let id: String
    public var family: Family
    /// A short label over the sentence, e.g. "Work hours". A label, not character: it never
    /// changes with the dial.
    public var topic: String?
    public var line: VoicedLine
    /// The one supporting number, e.g. "10h 12m". Data, never voiced.
    public var value: String?
    /// A supporting chart, one bar per day. Empty when the number says it all.
    public var week: [DayValue]
    public var isShareable: Bool

    public init(
        id: String,
        family: Family,
        topic: String? = nil,
        line: VoicedLine,
        value: String? = nil,
        week: [DayValue] = [],
        isShareable: Bool = true
    ) {
        self.id = id
        self.family = family
        self.topic = topic
        self.line = line
        self.value = value
        self.week = week
        self.isShareable = isShareable
    }

    /// A new user's first week (the Today design's "Please wait for the end of the week").
    /// The engine decides when insights start; this only decides what an empty deck says
    /// meanwhile: what it's waiting for, rather than nothing.
    public static let learningPeriod: TimeInterval = 7 * 24 * 3600
}

/// One number for one day, e.g. a bar in an insight's week chart.
public struct DayValue: Hashable, Sendable {
    public var day: DwellDay
    public var value: TimeInterval

    public init(day: DwellDay, value: TimeInterval) {
        self.day = day
        self.value = value
    }
}

/// Consecutive qualifying days, forgiven by earned freezes (brief §5, §9).
public struct Streak: Identifiable, Hashable, Sendable {
    public enum Kind: String, CaseIterable, Sendable {
        case outByTarget
        case workFreeEvening
        case weekendGuard
        case tenHourDays
        case firstIn
        case office
        case gymRegular
        case explorerWeek
        case newCellWeek

        /// Which end of the dial celebrates this streak.
        public var audience: Audience {
            switch self {
            case .outByTarget, .workFreeEvening, .weekendGuard: .peace
            case .tenHourDays, .firstIn, .office: .grind
            case .gymRegular, .explorerWeek, .newCellWeek: .everyone
            }
        }

        /// Whether the streak counts days or weeks. A weekend, a new place or a new cell can
        /// only be had once a week.
        public var period: Period {
            switch self {
            case .weekendGuard, .explorerWeek, .newCellWeek: .week
            default: .day
            }
        }
    }

    public enum Audience: Sendable {
        case peace
        case grind
        case everyone

        /// Peace and Calm celebrate rest, Push and Grind celebrate work, both celebrate
        /// the gym and new places; Plain celebrates nothing in particular, so all of them.
        public func isCelebrated(at stop: Dial.Stop) -> Bool {
            switch (self, stop.voice) {
            case (.everyone, _), (_, .plain), (.peace, .peace), (.grind, .grind): true
            default: false
            }
        }
    }

    public enum Period: Sendable {
        case day
        case week
    }

    /// One day (or week) of a streak's recent run: You's row of flames.
    public struct Mark: Hashable, Sendable {
        public enum State: Hashable, Sendable {
            /// It qualified.
            case kept
            /// It didn't, and a freeze covered it.
            case frozen
            /// It didn't, and nothing covered it.
            case missed
            /// Not decided yet: today until it qualifies, and anything after.
            case open
        }

        /// The day, or the first day of the week.
        public var start: DwellDay
        public var state: State

        public init(start: DwellDay, state: State) {
            self.start = start
            self.state = state
        }
    }

    public enum State: Hashable, Sendable {
        case empty
        case active
        case atRisk
        case frozen
        case broken
    }

    /// One freeze is earned per seven qualifying days, the bank holds two, and they are
    /// spent automatically. Never bought.
    public static let daysPerFreeze = 7
    public static let maxFreezes = 2

    public var kind: Kind
    public var current: Int
    public var best: Int
    public var freezes: Int
    public var state: State
    /// The last seven days (weeks for a weekly streak), oldest first, ending with this one.
    public var recent: [Mark]
    /// The out-by time, for `outByTarget`: "Home by 6:30 PM".
    public var target: TimeOfDay?

    public var id: Kind { kind }

    public init(
        kind: Kind,
        current: Int,
        best: Int,
        freezes: Int,
        state: State,
        recent: [Mark] = [],
        target: TimeOfDay? = nil
    ) {
        self.kind = kind
        self.current = current
        self.best = best
        self.freezes = min(max(freezes, 0), Self.maxFreezes)
        self.state = state
        self.recent = recent
        self.target = target
    }

    /// Still running: kept up, waiting on today, or held by a freeze.
    public var isGoing: Bool {
        switch state {
        case .active, .atRisk, .frozen: true
        case .empty, .broken: false
        }
    }

    /// The streak You leads with. The dial chooses which streaks it celebrates (brief §9:
    /// Peace counts evenings out of work, Grind long days and first-ins, both the gym and new
    /// places; Plain nothing in particular), so You leads with the longest one going among
    /// those. Daily streaks come before weekly ones, since the card is a week of days. With
    /// nothing going, the one with the best run, so the card still says what it was. The
    /// numbers never change with the dial; only which streak leads does (brief §6).
    public static func featured(in streaks: [Streak], at stop: Dial.Stop) -> Streak? {
        let celebrated = streaks.filter { $0.kind.audience.isCelebrated(at: stop) }
        let pool = celebrated.isEmpty ? streaks : celebrated
        func rank(_ streak: Streak) -> (Int, Int, Int) {
            (streak.isGoing ? 1 : 0, streak.kind.period == .day ? 1 : 0, streak.isGoing ? streak.current : streak.best)
        }
        let anyGoing = streaks.contains(where: \.isGoing)
        let candidates = anyGoing && !pool.contains(where: \.isGoing) ? streaks : pool
        // `max(by:)` keeps the first of equals, so ties go to the order the engine sent.
        return candidates.max { rank($0) < rank($1) }
    }
}

/// Flat, geometric, no mascots; legible at 44pt and glorious at 300pt (brief §9).
public struct Badge: Identifiable, Hashable, Sendable {
    public enum Kind: String, CaseIterable, Sendable {
        case explorer
        case regular
        case cartographer
        case globetrotter
        case earlyBird
        case closer
        case houdini
        case ironRoutine
        case homebody
        case marathoner
        case balancedMonth
        case streakKeeper
        case foundingUser
    }

    public enum Tier: Int, Comparable, CaseIterable, Sendable {
        case bronze
        case silver
        case gold

        public static func < (lhs: Tier, rhs: Tier) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    public var kind: Kind
    /// `nil` while locked.
    public var tier: Tier?
    /// 0...1 toward the next tier.
    public var progress: Double
    /// What the badge counts so far: places for Explorer, cells for Cartographer, countries
    /// for Globetrotter. `nil` where it counts nothing (Founding User).
    public var count: Int?

    public var id: Kind { kind }

    public init(kind: Kind, tier: Tier?, progress: Double, count: Int? = nil) {
        self.kind = kind
        self.tier = tier
        self.progress = min(max(progress, 0), 1)
        self.count = count
    }

    public var isEarned: Bool { tier != nil }

    /// You's grid (brief A.6, "tier grid with progress"): earned badges first, best tier
    /// first, then the locked ones closest to unlocking. Ties keep the brief's order.
    public static func showcase(_ badges: [Badge], limit: Int = 6) -> [Badge] {
        let order = Dictionary(uniqueKeysWithValues: Kind.allCases.enumerated().map { ($1, $0) })
        let sorted = badges.sorted { lhs, rhs in
            switch (lhs.tier, rhs.tier) {
            case let (left?, right?) where left != right: return left > right
            case (.some, nil): return true
            case (nil, .some): return false
            case (nil, nil) where lhs.progress != rhs.progress: return lhs.progress > rhs.progress
            default: return order[lhs.kind, default: 0] < order[rhs.kind, default: 0]
            }
        }
        return Array(sorted.prefix(limit))
    }
}

/// A lifetime best on the records wall. Locked records say what unlocks them.
public struct PersonalRecord: Identifiable, Hashable, Sendable {
    public let id: String
    public var title: String
    /// `nil` while locked.
    public var value: String?
    public var date: Date?
    public var unlockHint: String?

    public var isLocked: Bool { value == nil }

    public init(id: String, title: String, value: String?, date: Date? = nil, unlockHint: String? = nil) {
        self.id = id
        self.title = title
        self.value = value
        self.date = date
        self.unlockHint = unlockHint
    }
}

/// The three scratch-map zoom levels (brief §7.2). A cell is uncovered by a stop of
/// five minutes or more; passing through at speed never counts.
public enum ScratchLevel: String, CaseIterable, Sendable {
    case neighborhood
    case city
    case country

    public static let minimumStop: TimeInterval = 5 * 60

    /// Scratch-map shares show a silhouette at city level or above, never neighborhood (brief §8.2).
    public var isShareable: Bool { self != .neighborhood }
}

public struct ScratchCoverage: Hashable, Sendable {
    public var level: ScratchLevel
    /// What the percentage is of: "Brooklyn", "United States", "the world".
    public var area: String
    public var uncovered: Int
    public var total: Int
    public var uncoveredThisWeek: Int

    public init(level: ScratchLevel, area: String, uncovered: Int, total: Int, uncoveredThisWeek: Int = 0) {
        self.level = level
        self.area = area
        self.uncovered = uncovered
        self.total = total
        self.uncoveredThisWeek = uncoveredThisWeek
    }

    public var fraction: Double {
        total > 0 ? Double(uncovered) / Double(total) : 0
    }
}
