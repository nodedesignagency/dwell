import Foundation

/// What Today's sample insights open into (Insights design, 13 Nov), counted from the timeline
/// so every number agrees with Today and Time.
extension SampleData {
    /// The insight the Insights design draws: office time last week against Maya's usual.
    /// On Monday afternoon "this week" is half a day, so the sample's is about last week, the
    /// last one she lived whole. `DWELL_OPEN=insight` opens it.
    public static let officeInsightID: Insight.ID = "office-week"

    /// Monday 19 to Sunday 25 October.
    static let lastFullWeek = TimePeriod(.week, containing: lastWeek[0], calendar: calendar)

    /// Every day from the install through last week.
    static let daysThroughLastWeek: [DaySnapshot] = {
        var days: [DaySnapshot] = []
        var day = DwellDay(containing: recordingSince, calendar: calendar)
        while day <= lastFullWeek.last {
            days.append(snapshot(for: day))
            day = day.adding(days: 1, in: calendar)
        }
        return days
    }()

    static let officeWeek = OfficeWeek(
        week: lastFullWeek, days: daysThroughLastWeek, recordingSince: recordingSince, now: now, calendar: calendar)

    static let officeInsight: Insight? = officeWeek?.insight(id: officeInsightID, now: now, calendar: calendar)

    /// The detail behind each of Today's sample insights. The rest, with no detail of their
    /// own, open onto their sentence, Today's chart and their number.
    public static func insightDetail(for insight: Insight) -> InsightDetail {
        guard insight.id == officeInsightID, let officeWeek else { return InsightDetail(insight: insight) }
        return officeWeek.detail(id: insight.id, now: now, calendar: calendar)
    }
}
