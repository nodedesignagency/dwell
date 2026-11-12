import Foundation

/// You's words. The design's are used as they are, in sentence case (brief §8.6); the rest are
/// placeholders marked [COPY NEEDED] until the client's copy deck arrives. Numbers are passed
/// in, never written per voice.
public enum YouCopy {
    public static let title = "You"
    public static let settings = "Settings"

    // MARK: Profile

    /// "@maya"
    public static func handle(_ username: String) -> String {
        "@\(username)"
    }

    /// "3.2% mapped": the city's coverage at neighborhood level (brief §7.2).
    public static func mapped(_ coverage: ScratchCoverage?, locale: Locale = .current) -> String {
        "\(CoverageText.percent(coverage?.fraction ?? 0, locale: locale)) mapped"
    }

    /// How VoiceOver reads the coverage pill: "3.2% of Brooklyn mapped".
    public static func spokenMapped(_ coverage: ScratchCoverage?, city: String, locale: Locale = .current) -> String {
        "\(CoverageText.percent(coverage?.fraction ?? 0, locale: locale)) of \(city) mapped"
    }

    /// The design's line under the badges: a privacy fact stated where it applies (brief §8.2).
    public static let privacy = "Only you can see your map"

    // MARK: The dial

    public static let yourDial = "Your dial"

    /// What each stop does, under its name. The design writes Plain's; the rest are the brief's
    /// dial table (§6), trimmed to one line. Plain words describing a setting, so they don't
    /// change voice with the dial. [COPY NEEDED] Peace, Calm, Push, Grind.
    public static func dialDescription(_ stop: Dial.Stop) -> String {
        switch stop {
        case .peace: "Soft, unhurried, notices rest"
        case .calm: "Warm, notices routines kept"
        case .plain: "Neutral, facts only"
        case .push: "Direct, a little competitive"
        case .grind: "Blunt, proud, a bit cocky"
        }
    }

    // MARK: Notifications

    public static func title(of kind: NotificationKind) -> String {
        switch kind {
        case .morningRecap: "Morning recap"
        case .streakAtRisk: "Streak at risk"
        case .records: "New records"
        }
    }

    /// The design's lines: what the push is, or which stops send it.
    public static func detail(of kind: NotificationKind) -> String {
        switch kind {
        case .morningRecap: "A short summary of your day"
        case .streakAtRisk: "Push and grind only"
        case .records: "Grind only"
        }
    }

    // MARK: Streaks

    public static let streaks = "Streaks"
    public static let viewAll = "View all"
    public static let current = "Current"
    public static let best = "Best"
    public static let freezes = "Freezes"

    /// The big line: "12 evenings". Evenings for the streaks about evenings (Appendix B:
    /// "Fourteen evenings home by 6:30."), weeks for weekly ones, days for the rest.
    public static func run(_ streak: Streak) -> String {
        let count = streak.current
        switch streak.kind {
        case .outByTarget, .workFreeEvening: return count == 1 ? "1 evening" : "\(count) evenings"
        default: return length(count, period: streak.kind.period)
        }
    }

    /// "12 days", "4 weeks": the Current and Best columns.
    public static func length(_ count: Int, period: Streak.Period) -> String {
        switch period {
        case .day: count == 1 ? "1 day" : "\(count) days"
        case .week: count == 1 ? "1 week" : "\(count) weeks"
        }
    }

    /// "1 of 2": freezes in the bank of two (Appendix B: "1 of 2 left").
    public static func freezes(_ count: Int) -> String {
        "\(count) of \(Streak.maxFreezes)"
    }

    /// How VoiceOver reads the freezes column.
    public static func spokenFreezes(_ count: Int) -> String {
        "\(count) of \(Streak.maxFreezes) left"
    }

    /// What the streak asks for: the design's "Home by 6:30 PM" for the out-by streak.
    /// [COPY NEEDED] the other eight.
    public static func rule(_ streak: Streak, calendar: Calendar) -> String {
        switch streak.kind {
        case .outByTarget:
            guard let target = streak.target else { return "Out of work on time" }
            return "Home by \(ClockText.time(of: target, calendar: calendar))"
        case .workFreeEvening: return "Evenings without work"
        case .weekendGuard: return "Weekends without work"
        case .tenHourDays: return "Ten-hour days at work"
        case .firstIn: return "First one in"
        case .office: return "Days at the office"
        case .gymRegular: return "Days at the gym"
        case .explorerWeek: return "A new place every week"
        case .newCellWeek: return "A new cell every week"
        }
    }

    /// What VoiceOver says for one flame.
    public static func spokenMark(_ state: Streak.Mark.State) -> String {
        switch state {
        case .kept: "kept"
        case .frozen: "covered by a freeze"
        case .missed: "missed"
        case .open: "not yet"
        }
    }

    /// No streaks yet. An empty state, so it follows the dial. [COPY NEEDED] all three.
    public static let noStreaks = VoicedLine(
        peace: "No streaks yet. They'll find you.",
        plain: "No streaks yet.",
        grind: "No streaks yet. Start one.")

    /// [COPY NEEDED] all three.
    public static let noStreaksDetail = VoicedLine(
        peace: "Keep a habit for a few days and it shows here.",
        plain: "A streak starts after a few qualifying days in a row.",
        grind: "A few days in a row and it's on the board.")

    // MARK: Badges

    public static let badges = "Badges"

    /// "6 of 13": badges earned of all there are.
    public static func earned(_ count: Int) -> String {
        "\(count) of \(Badge.Kind.allCases.count)"
    }

    /// How VoiceOver reads it: "6 of 13 badges earned".
    public static func spokenEarned(_ count: Int) -> String {
        "\(count) of \(Badge.Kind.allCases.count) badges earned"
    }

    /// The brief's names (§9). Names, so they keep their capitals.
    public static func name(of kind: Badge.Kind) -> String {
        switch kind {
        case .explorer: "Explorer"
        case .regular: "Regular"
        case .cartographer: "Cartographer"
        case .globetrotter: "Globetrotter"
        case .earlyBird: "Early Bird"
        case .closer: "Closer"
        case .houdini: "Houdini"
        case .ironRoutine: "Iron Routine"
        case .homebody: "Homebody"
        case .marathoner: "Marathoner"
        case .balancedMonth: "Balanced Month"
        case .streakKeeper: "Streak Keeper"
        case .foundingUser: "Founding User"
        }
    }

    public static func tier(_ tier: Badge.Tier?) -> String {
        switch tier {
        case .bronze: "Bronze"
        case .silver: "Silver"
        case .gold: "Gold"
        case nil: "Locked"
        }
    }

    /// The facts under a badge's name, shown dot-separated: the design's "Gold • 41 places".
    public static func details(for badge: Badge) -> [String] {
        [tier(badge.tier)] + (measure(badge).map { [$0] } ?? [])
    }

    /// What the badge counts, in its own unit: "41 places". [COPY NEEDED] every unit but
    /// Explorer's, which is the design's.
    public static func measure(_ badge: Badge) -> String? {
        guard let count = badge.count else { return nil }
        func counted(_ one: String, _ many: String) -> String { count == 1 ? "1 \(one)" : "\(count) \(many)" }
        switch badge.kind {
        case .explorer: return counted("place", "places")
        case .regular: return counted("visit", "visits")
        case .cartographer: return counted("cell", "cells")
        case .globetrotter: return counted("country", "countries")
        case .earlyBird: return counted("early start", "early starts")
        case .closer: return counted("evening out on time", "evenings out on time")
        case .houdini: return counted("quiet exit", "quiet exits")
        case .ironRoutine: return counted("week", "weeks")
        case .homebody: return counted("evening in", "evenings in")
        case .marathoner: return counted("long day", "long days")
        case .balancedMonth: return counted("month", "months")
        case .streakKeeper: return counted("day", "days")
        case .foundingUser: return nil
        }
    }

    // MARK: Failed

    /// [COPY NEEDED]
    public static let couldNotLoad = "Your profile couldn't load"
    /// [COPY NEEDED]
    public static let offlineDetail = "Your streaks and badges load once you're back online."
    /// [COPY NEEDED]
    public static let unavailableDetail = "Try again in a moment. Your dial still works."
}
