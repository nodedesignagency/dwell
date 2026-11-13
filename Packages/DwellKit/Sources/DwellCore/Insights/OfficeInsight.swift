import Foundation

/// The Insights design's insight: time at the office in one week against your usual, with the
/// weeks behind it and three numbers (that week's time, your usual, days worked from home).
///
/// "The office" is work at the workplace: work from home counts as work everywhere else in
/// the app, but not here, where the third tile counts it in days. "Usual" is the average of
/// up to four earlier weeks, as on Time (`TimeReport`), counted only once Dwell was recording
/// for all of them, and like with like: a week still being lived is compared with earlier
/// weeks to the same point.
public struct OfficeWeek: Hashable, Sendable {
    public var week: TimePeriod
    public var office: TimeInterval
    public var usual: TimeInterval
    public var workFromHomeDays: Int
    /// No day of the week went over 12h of work, so Grind may celebrate it (brief §8.4).
    public var isCelebratable: Bool
    public var trend: InsightTrend

    /// Fewer hours than this as usual and a percentage means nothing: no insight.
    public static let minimumUsual: TimeInterval = 3600

    /// `nil` when there's nothing usual to compare with yet.
    ///
    /// - Parameter days: every day from when Dwell began recording through `week`'s last day.
    public init?(week: TimePeriod, days: [DaySnapshot], recordingSince: Date?, now: Date, calendar: Calendar) {
        let byDay = Dictionary(days.map { ($0.day, $0) }, uniquingKeysWith: { first, _ in first })
        func snapshots(_ period: TimePeriod) -> [DaySnapshot] {
            period.days(in: calendar).compactMap { byDay[$0] }
        }
        let recordingDay = recordingSince.map { DwellDay(containing: $0, calendar: calendar) }

        var baselines: [TimeInterval] = []
        for back in 1 ... TimeReport.baselinePeriods {
            let earlier = week.adding(-back, in: calendar)
            if let recordingDay, earlier.first < recordingDay { break }
            let window = earlier.window(matching: week, now: now, calendar: calendar)
            baselines.append(snapshots(earlier).reduce(0) { $0 + $1.officeTime(within: window, now: now) })
        }
        guard !baselines.isEmpty else { return nil }
        let usual = baselines.reduce(0, +) / Double(baselines.count)
        guard usual >= Self.minimumUsual else { return nil }

        let days = snapshots(week)
        self.week = week
        office = days.reduce(0) { $0 + $1.officeTime(now: now) }
        self.usual = usual
        workFromHomeDays = days.filter { $0.isWorkFromHome(now: now) }.count
        isCelebratable = days.allSatisfy { WorkCeiling.isCelebratable($0.totals(now: now)[.work] ?? 0) }
        trend = InsightTrend.weekly(
            category: .work,
            measure: InsightCopy.officeMeasure,
            focus: week,
            days: Array(byDay.values),
            recordingSince: recordingSince,
            calendar: calendar
        ) { days in
            days.reduce(0) { $0 + $1.officeTime(now: now) }
        }
    }

    public func sentence(now: Date, calendar: Calendar) -> VoicedSentence {
        InsightCopy.office(week: week, office: office, usual: usual, celebrates: isCelebratable, now: now, calendar: calendar)
    }

    /// The page: the sentence, the weeks, and the design's three tiles.
    public func detail(id: Insight.ID, now: Date, calendar: Calendar) -> InsightDetail {
        InsightDetail(
            id: id,
            headline: .sentence(sentence(now: now, calendar: calendar)),
            trend: trend,
            stats: [
                InsightStat(
                    id: "week", value: .duration(office),
                    label: InsightCopy.weekWord(week, now: now, calendar: calendar),
                    icon: .alarmClock, tint: .category(.work)),
                InsightStat(id: "usual", value: .duration(usual), label: InsightCopy.usual, icon: .briefcase, tint: .yours),
                InsightStat(
                    id: "wfh", value: .text(InsightCopy.days(workFromHomeDays)), label: InsightCopy.workFromHome,
                    icon: .sunrise, tint: .category(.home)),
            ])
    }

    /// The card on Today's deck: the same sentence, written out, and the week's office time.
    public func insight(id: Insight.ID, now: Date, calendar: Calendar) -> Insight {
        Insight(
            id: id,
            family: .pastComparison,
            topic: InsightCopy.officeTopic,
            line: sentence(now: now, calendar: calendar).filledLine,
            value: DurationText.short(office))
    }
}

extension DaySnapshot {
    /// Office time inside `window` (and this day, before `now`).
    func officeTime(within window: DateInterval, now: Date) -> TimeInterval {
        entries.reduce(0) { total, entry in
            guard let visit = entry.visit, visit.category == .work, !visit.isWorkFromHome,
                  let span = span(of: entry, within: window, now: now) else { return total }
            return total + span.duration
        }
    }
}
