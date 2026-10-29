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
    public var line: VoicedLine
    /// The one supporting number, e.g. "10h 12m". Data, never voiced.
    public var value: String?
    public var isShareable: Bool

    public init(id: String, family: Family, line: VoicedLine, value: String? = nil, isShareable: Bool = true) {
        self.id = id
        self.family = family
        self.line = line
        self.value = value
        self.isShareable = isShareable
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
    }

    public enum Audience: Sendable {
        case peace
        case grind
        case everyone
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

    public var id: Kind { kind }

    public init(kind: Kind, current: Int, best: Int, freezes: Int, state: State) {
        self.kind = kind
        self.current = current
        self.best = best
        self.freezes = min(max(freezes, 0), Self.maxFreezes)
        self.state = state
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

    public var id: Kind { kind }

    public init(kind: Kind, tier: Tier?, progress: Double) {
        self.kind = kind
        self.tier = tier
        self.progress = min(max(progress, 0), 1)
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
