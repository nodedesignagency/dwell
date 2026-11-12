import Foundation

/// Everything Time shows for one period, top to bottom (brief §7.3, Time design): the report
/// behind the headline and "All categories", every hour of the period, work and yours over the
/// last four periods, calendar vs reality, your rhythm, places over time, the records wall and
/// the year in places.
public struct TimeOverview: Hashable, Sendable {
    /// One pair of bars in Work and yours.
    public struct TrendPoint: Hashable, Sendable, Identifiable {
        public var period: TimePeriod
        public var work: TimeInterval
        public var yours: TimeInterval
        /// The period Time is showing; the others are the three before it.
        public var isShown: Bool

        public var id: String { period.id }
    }

    public enum CalendarSection: Hashable, Sendable {
        /// No calendar yet: the section sells the feature (brief A.4).
        case notConnected
        case report(CalendarReport)
    }

    public enum RhythmSection: Hashable, Sendable {
        /// Fewer than two weeks recorded (brief §3.1, day 14).
        case locked(daysToGo: Int)
        case ready(weekday: Rhythm?, weekend: Rhythm?)
    }

    /// The year so far, for the card at the end (brief §7.3 "Year in places").
    public struct Year: Hashable, Sendable {
        public var year: Int
        public var isCurrent: Bool
        public var places: Int
        public var coverage: ScratchCoverage?
        public var records: Int
    }

    /// The year in places opens after 30 days (brief A.4).
    public static let daysForYear = 30

    public var period: TimePeriod
    public var now: Date
    public var report: TimeReport
    public var grid: HourGrid
    public var trend: [TrendPoint]
    public var calendarSection: CalendarSection
    public var rhythm: RhythmSection
    public var placeTrends: [PlaceTrend]
    public var records: [PersonalRecord]
    /// `nil` until Dwell has a month.
    public var year: Year?
    /// Days to go while Dwell is still learning a week or a month (brief §3.1, day 3).
    public var learningDaysToGo: Int?
    public var recordingSince: Date?

    /// Whether Dwell has ever recorded anything: Time waits instead of showing empty charts.
    public var hasAnything: Bool {
        !report.isEmpty || recordingSince.map { $0 <= now } == true
    }

    public init(
        period current: PeriodSnapshot,
        baselines: [PeriodSnapshot],
        recent: [DaySnapshot],
        isCalendarConnected: Bool,
        records: [PersonalRecord],
        placeTrends: [PlaceTrend],
        coverage: [ScratchCoverage],
        places: [Place],
        now: Date,
        calendar: Calendar
    ) {
        period = current.period
        self.now = now
        report = TimeReport(current, baselines: baselines, now: now, calendar: calendar)
        grid = HourGrid(current, now: now, calendar: calendar)
        recordingSince = current.recordingSince ?? recent.lazy.compactMap(\.recordingSince).first

        // The shown period and up to three before it, oldest first.
        let earlier = baselines
            .filter { $0.period.range == current.period.range && $0.period.last < current.period.first }
            .sorted { $0.period.first > $1.period.first }
            .prefix(3)
            .reversed()
        trend = (Array(earlier) + [current]).map { snapshot in
            let totals = TimeReport.totals(snapshot.days, within: snapshot.period.interval(in: calendar), now: now)
            return TrendPoint(
                period: snapshot.period, work: totals[.work] ?? 0, yours: TimeReport.yours(totals),
                isShown: snapshot.period == current.period)
        }

        if isCalendarConnected {
            calendarSection = .report(CalendarReport(current, earlier: recent + baselines.flatMap(\.days), calendar: calendar))
        } else {
            calendarSection = .notConnected
        }

        let recorded = recordingSince.map { Self.days(from: $0, to: now, calendar: calendar) } ?? 0
        if recorded < Rhythm.daysNeeded {
            rhythm = .locked(daysToGo: Rhythm.daysNeeded - recorded)
        } else {
            rhythm = .ready(
                weekday: Rhythm.typical(.weekday, from: recent, now: now, calendar: calendar),
                weekend: Rhythm.typical(.weekend, from: recent, now: now, calendar: calendar))
        }

        self.placeTrends = placeTrends
        self.records = records

        let today = DwellDay(containing: now, calendar: calendar)
        if recorded >= Self.daysForYear {
            year = Year(
                year: today.year,
                isCurrent: true,
                places: places.filter { $0.visitCount > 0 }.count,
                coverage: coverage.first { $0.level == .neighborhood },
                records: records.filter { !$0.isLocked }.count)
        } else {
            year = nil
        }

        let length: Int? = switch current.period.range {
        case .week: 7
        case .month: 28
        case .day, .year: nil
        }
        if let length, recordingSince != nil, recorded < length, current.period.contains(today) {
            learningDaysToGo = length - recorded
        } else {
            learningDaysToGo = nil
        }
    }

    /// Whole days from `start` to `end`, counting the day it started: 1 on the install day.
    static func days(from start: Date, to end: Date, calendar: Calendar) -> Int {
        let first = DwellDay(containing: start, calendar: calendar).start(in: calendar)
        let last = DwellDay(containing: end, calendar: calendar).start(in: calendar)
        let between = calendar.dateComponents([.day], from: first, to: last).day ?? 0
        return max(0, between) + (end >= start ? 1 : 0)
    }
}

extension TimeOverview {
    /// Loads everything Time shows for `period` as of `now`: the period, up to four before it
    /// (once Dwell was recording), the last four weeks for rhythm and calendar runs, and the
    /// rest. Throws what the repository throws.
    public static func load(
        _ period: TimePeriod,
        from repository: any DwellRepository,
        now: Date,
        calendar: Calendar
    ) async throws -> TimeOverview {
        let days = try await repository.days(from: period.first, through: period.last)
        let current = PeriodSnapshot(period: period, days: days)
        let recordingDay = current.recordingSince.map { DwellDay(containing: $0, calendar: calendar) }

        var baselines: [PeriodSnapshot] = []
        for step in 1...TimeReport.baselinePeriods {
            let earlier = period.adding(-step, in: calendar)
            // Nothing to compare before Dwell was recording.
            if let recordingDay, earlier.last < recordingDay { break }
            baselines.append(PeriodSnapshot(
                period: earlier, days: try await repository.days(from: earlier.first, through: earlier.last)))
        }

        let today = DwellDay(containing: now, calendar: calendar)
        let end = min(period.last, today)
        let recent = try await repository.days(from: end.adding(days: 1 - Rhythm.lookback, in: calendar), through: end)

        return TimeOverview(
            period: current,
            baselines: baselines,
            recent: recent,
            isCalendarConnected: try await repository.isCalendarConnected(),
            records: try await repository.records(),
            placeTrends: try await repository.placeTrends(),
            coverage: try await repository.coverage(),
            places: try await repository.places(),
            now: now,
            calendar: calendar)
    }

    /// The sample as Time shows it, synchronously, for previews.
    public static func sample(_ period: TimePeriod, now: Date = SampleData.now) -> TimeOverview {
        let calendar = SampleData.calendar
        func snapshot(_ period: TimePeriod) -> PeriodSnapshot {
            PeriodSnapshot(period: period, days: period.days(in: calendar).map(SampleData.snapshot(for:)))
        }
        let recordingDay = DwellDay(containing: SampleData.recordingSince, calendar: calendar)
        let baselines = (1...TimeReport.baselinePeriods)
            .map { period.adding(-$0, in: calendar) }
            .filter { $0.last >= recordingDay }
            .map(snapshot)
        let today = DwellDay(containing: now, calendar: calendar)
        let end = min(period.last, today)
        let recent = (0..<Rhythm.lookback).map { SampleData.snapshot(for: end.adding(days: -$0, in: calendar)) }.reversed()
        return TimeOverview(
            period: snapshot(period),
            baselines: baselines,
            recent: Array(recent),
            isCalendarConnected: true,
            records: SampleData.records,
            placeTrends: SampleData.placeTrends,
            coverage: SampleData.coverage,
            places: SampleData.places,
            now: now,
            calendar: calendar)
    }
}
