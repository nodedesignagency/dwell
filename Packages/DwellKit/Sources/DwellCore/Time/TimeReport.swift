import Foundation

/// One period's days, as the repository returns them: Time's raw material.
public struct PeriodSnapshot: Hashable, Sendable {
    public var period: TimePeriod
    /// Every day of the period, in order. Days still to come are empty.
    public var days: [DaySnapshot]

    public init(period: TimePeriod, days: [DaySnapshot]) {
        self.period = period
        self.days = days
    }

    /// When Dwell began recording, as the days say.
    public var recordingSince: Date? {
        days.lazy.compactMap(\.recordingSince).first
    }
}

/// A period's time by category, against what's usual (brief §7.3, A.4: the headline, the
/// category rows and work vs yours all read from here, so they never disagree).
///
/// "Usual" is the average of up to four periods before this one, counted only once Dwell was
/// recording for all of them. While a period is still being lived, each earlier period counts
/// only as far in: Monday so far against earlier Mondays so far, never against whole weeks.
public struct TimeReport: Hashable, Sendable {
    /// A category's row in "All categories".
    public struct Line: Hashable, Sendable, Identifiable {
        public var category: PlaceCategory
        public var total: TimeInterval
        /// `nil` when there's nothing to compare with yet.
        public var usual: TimeInterval?
        /// Coffee, drinks, food: only for categories whose places say, largest first.
        public var parts: [Part]

        public var id: PlaceCategory { category }

        /// Signed: more than usual is positive.
        public var delta: TimeInterval? {
            usual.map { total - $0 }
        }
    }

    public struct Part: Hashable, Sendable, Identifiable {
        public var subcategory: PlaceSubcategory
        public var total: TimeInterval

        public var id: PlaceSubcategory { subcategory }
    }

    /// How many earlier periods "usual" averages, at most.
    public static let baselinePeriods = 4

    public var period: TimePeriod
    public var totals: [PlaceCategory: TimeInterval]
    /// `nil` before there's an earlier period to compare with.
    public var usualTotals: [PlaceCategory: TimeInterval]?
    /// Every category with time, largest first, home last (see `lines(_:)`).
    public var lines: [Line]
    /// Gaps, and stretches with no record, inside the part of the period Dwell watched:
    /// "Dwell was asleep for 8h 46m this week."
    public var unmapped: TimeInterval
    /// The part of the period that's been lived since Dwell started recording.
    public var watched: TimeInterval
    /// How many earlier periods went into "usual".
    public var baselineCount: Int

    public var work: TimeInterval { totals[.work] ?? 0 }

    /// Everything mapped except work, home and transit, as on Today (`DayRecap.yours`).
    public var yours: TimeInterval { Self.yours(totals) }

    public var usualWork: TimeInterval? { usualTotals.map { $0[.work] ?? 0 } }
    public var usualYours: TimeInterval? { usualTotals.map(Self.yours) }

    /// Nothing watched yet: before recording began, or a period still to come.
    public var isEmpty: Bool { watched <= 0 }

    public init(_ current: PeriodSnapshot, baselines: [PeriodSnapshot], now: Date, calendar: Calendar) {
        period = current.period
        let recordingSince = current.recordingSince ?? baselines.lazy.compactMap(\.recordingSince).first
        let recordingDay = recordingSince.map { DwellDay(containing: $0, calendar: calendar) }

        let whole = current.period.interval(in: calendar)
        totals = Self.totals(current.days, within: whole, now: now)
        watched = current.days.reduce(0) { $0 + $1.watched(within: whole, now: now) }
        unmapped = max(0, watched - totals.values.reduce(0, +))

        let counted = baselines
            .filter { baseline in
                guard baseline.period.range == current.period.range, baseline.period.last < current.period.first else { return false }
                if let recordingDay { return baseline.period.first >= recordingDay }
                return true
            }
            .sorted { $0.period.first > $1.period.first }
            .prefix(Self.baselinePeriods)
        baselineCount = counted.count

        if counted.isEmpty {
            usualTotals = nil
        } else {
            var sum: [PlaceCategory: TimeInterval] = [:]
            for baseline in counted {
                let window = baseline.period.window(matching: current.period, now: now, calendar: calendar)
                for (category, total) in Self.totals(baseline.days, within: window, now: now) {
                    sum[category, default: 0] += total
                }
            }
            usualTotals = sum.mapValues { $0 / Double(counted.count) }
        }

        let parts = Self.parts(current.days, within: whole, now: now)
        lines = Self.lines(totals: totals, usual: usualTotals, parts: parts)
    }

    // MARK: Totals

    /// Time per category across `days`, inside `window` and before `now`.
    public static func totals(_ days: [DaySnapshot], within window: DateInterval, now: Date) -> [PlaceCategory: TimeInterval] {
        var totals: [PlaceCategory: TimeInterval] = [:]
        for day in days {
            for entry in day.entries {
                guard let category = entry.category, let span = day.span(of: entry, within: window, now: now) else { continue }
                totals[category, default: 0] += span.duration
            }
        }
        return totals
    }

    static func parts(_ days: [DaySnapshot], within window: DateInterval, now: Date) -> [PlaceCategory: [PlaceSubcategory: TimeInterval]] {
        var parts: [PlaceCategory: [PlaceSubcategory: TimeInterval]] = [:]
        for day in days {
            for entry in day.entries {
                guard
                    let visit = entry.visit, let subcategory = visit.subcategory, subcategory.category == visit.category,
                    let span = day.span(of: entry, within: window, now: now)
                else { continue }
                parts[visit.category, default: [:]][subcategory, default: 0] += span.duration
            }
        }
        return parts
    }

    /// Yours from a set of totals: everything but work, home and transit.
    public static func yours(_ totals: [PlaceCategory: TimeInterval]) -> TimeInterval {
        let mapped = totals.values.reduce(0, +)
        return max(0, mapped - (totals[.work] ?? 0) - (totals[.home] ?? 0) - (totals[.transit] ?? 0))
    }

    /// Largest first, so the list leads with where the time went; home last, since most of it
    /// is sleep and it would sit on top of every week (the Time design leaves it out; the
    /// brief's honest breakdown keeps it, QUESTIONS.md). Categories under a minute are left out.
    static func lines(
        totals: [PlaceCategory: TimeInterval],
        usual: [PlaceCategory: TimeInterval]?,
        parts: [PlaceCategory: [PlaceSubcategory: TimeInterval]]
    ) -> [Line] {
        let order = Dictionary(uniqueKeysWithValues: PlaceCategory.allCases.enumerated().map { ($1, $0) })
        return totals
            .filter { $0.value >= 60 }
            .map { category, total in
                Line(
                    category: category,
                    total: total,
                    usual: usual.map { $0[category] ?? 0 },
                    parts: (parts[category] ?? [:])
                        .filter { $0.value >= 60 }
                        .map { Part(subcategory: $0.key, total: $0.value) }
                        .sorted { ($0.total, -$0.subcategory.sortIndex) > ($1.total, -$1.subcategory.sortIndex) })
            }
            .sorted { a, b in
                if (a.category == .home) != (b.category == .home) { return b.category == .home }
                if a.total != b.total { return a.total > b.total }
                return (order[a.category] ?? 0) < (order[b.category] ?? 0)
            }
    }
}

extension PlaceSubcategory {
    var sortIndex: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}

extension DaySnapshot {
    /// The part of an entry inside this day, before `now`, and inside `window` when given.
    public func span(of entry: TimelineEntry, within window: DateInterval? = nil, now: Date) -> DateInterval? {
        let whole = entry.interval(now: now)
        var start = max(whole.start, interval.start)
        var end = min(whole.end, interval.end, now)
        if let window {
            start = max(start, window.start)
            end = min(end, window.end)
        }
        return end > start ? DateInterval(start: start, end: end) : nil
    }

    /// How much of this day Dwell has watched inside `window`: from 4 AM (or when recording
    /// began) to now, or to the day's end once it's over.
    public func watched(within window: DateInterval, now: Date) -> TimeInterval {
        let elapsed = elapsed(now: now)
        let start = max(elapsed.start, window.start)
        let end = min(elapsed.end, window.end)
        return max(0, end.timeIntervalSince(start))
    }
}
