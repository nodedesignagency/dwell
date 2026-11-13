import Foundation
import Testing
@testable import DwellCore

@Suite("The Insights page")
struct InsightDetailTests {
    let calendar = SampleData.calendar
    let now = SampleData.now

    var office: OfficeWeek {
        get throws { try #require(SampleData.officeWeek) }
    }

    var detail: InsightDetail {
        get throws {
            let insight = try #require(SampleData.insights.first { $0.id == SampleData.officeInsightID })
            return SampleData.insightDetail(for: insight)
        }
    }

    @Test func `the design's insight sits second in Today's deck, after the hero`() {
        #expect(SampleData.insights.map(\.id).prefix(2) == ["weekend-zero-work", SampleData.officeInsightID])
        #expect(SampleData.insights.count == 4)
    }

    @Test func `office time leaves work from home out`() throws {
        // Last week: Monday 8:41–12:34 and 13:44–18:07; Friday was from home.
        let monday = SampleData.snapshot(for: SampleData.lastWeek[0])
        #expect(DurationText.short(monday.officeTime(now: now)) == "8h 16m")
        let friday = SampleData.snapshot(for: SampleData.lastWeek[4])
        #expect(friday.officeTime(now: now) == 0)
        #expect(friday.isWorkFromHome(now: now))
        #expect(try office.workFromHomeDays == 1)
    }

    @Test func `the week's office time is the sum of its days, and its bar says the same`() throws {
        let office = try office
        let days = SampleData.lastWeek.map(SampleData.snapshot(for:))
        #expect(office.office == days.reduce(0) { $0 + $1.officeTime(now: now) })
        #expect(office.trend.weeks.last?.period == office.week)
        #expect(office.trend.weeks.last?.value == office.office)
    }

    @Test func `usual is the four weeks before, and the percentage follows from them`() throws {
        let office = try office
        let earlier = office.trend.weeks.dropLast().suffix(4).compactMap(\.value)
        #expect(earlier.count == 4)
        #expect(abs(office.usual - earlier.reduce(0, +) / 4) < 1)
        let percent = Int((abs(office.office - office.usual) / office.usual * 100).rounded())
        let sentence = office.sentence(now: now, calendar: calendar)
        let direction = office.office > office.usual ? "more" : "less"
        #expect(sentence.runs.map(\.text) == ["\(percent)% \(direction) time"])
        #expect(sentence.runs.first?.category == .work)
    }

    @Test func `Plain says the design's sentence, about last week`() throws {
        let sentence = try office.sentence(now: now, calendar: calendar)
        #expect(sentence.line.plain == "You spent {0} at the office last week.")
    }

    @Test(arguments: Dial.Stop.allCases)
    func `the numbers are the same at every stop`(stop: Dial.Stop) throws {
        let sentence = try office.sentence(now: now, calendar: calendar)
        let text = sentence.text(at: stop)
        #expect(text.contains(try #require(sentence.runs.first?.text)))
        #expect(!text.contains("{"))
        #expect(!text.contains("!"))
        for word in ["location", "check-in", "track"] {
            #expect(!text.lowercased().contains(word))
        }
    }

    @Test func `the three tiles are the week, your usual and the WFH days`() throws {
        let office = try office
        let stats = try detail.stats
        #expect(stats.map(\.label) == ["last week", "your usual", "WFH"])
        #expect(stats.map(\.value) == [.duration(office.office), .duration(office.usual), .text("1 day")])
        #expect(InsightCopy.days(3) == "3 days")
    }

    @Test func `this week can't be compared before there's a usual`() {
        let firstWeek = TimePeriod(.week, containing: DwellDay(containing: SampleData.recordingSince, calendar: calendar), calendar: calendar)
        let days = (0 ..< 7).map { SampleData.snapshot(for: firstWeek.first.adding(days: $0, in: calendar)) }
        #expect(OfficeWeek(week: firstWeek, days: days, recordingSince: SampleData.recordingSince, now: now, calendar: calendar) == nil)
    }

    @Test func `within half a percent, the week's own time leads`() {
        let week = SampleData.lastFullWeek
        let sentence = InsightCopy.office(week: week, office: 36_000, usual: 36_100, celebrates: true, now: now, calendar: calendar)
        #expect(sentence.runs.map(\.text) == ["10h"])
        #expect(sentence.text(at: .plain) == "You spent 10h at the office last week, about your usual.")
    }

    @Test func `Grind never celebrates a week with a day over 12h`() {
        let week = SampleData.lastFullWeek
        let proud = InsightCopy.office(week: week, office: 50 * 3600, usual: 40 * 3600, celebrates: true, now: now, calendar: calendar)
        let capped = InsightCopy.office(week: week, office: 50 * 3600, usual: 40 * 3600, celebrates: false, now: now, calendar: calendar)
        #expect(proud.text(at: .grind) == "25% more time at the office last week. Putting in the hours.")
        #expect(capped.text(at: .grind) == "25% more time at the office last week.")
    }

    @Test func `a week being lived says this week and you've spent`() {
        let thisWeek = TimePeriod(.week, containing: SampleData.today, calendar: calendar)
        let sentence = InsightCopy.office(week: thisWeek, office: 9 * 3600, usual: 10 * 3600, celebrates: true, now: now, calendar: calendar)
        #expect(sentence.text(at: .plain) == "You've spent 10% less time at the office this week.")
        #expect(InsightCopy.weekWord(thisWeek.adding(-4, in: calendar), now: now, calendar: calendar) == "Sep 28 – Oct 4")
    }
}

@Suite("The insight's chart")
struct InsightTrendTests {
    let calendar = SampleData.calendar
    let now = SampleData.now

    var trend: InsightTrend {
        get throws { try #require(SampleData.officeWeek).trend }
    }

    @Test func `weeks run from the install to the insight's week`() throws {
        let trend = try trend
        #expect(trend.weeks.first?.period.first == DwellDay(year: 2026, month: 8, day: 31))
        #expect(trend.weeks.last?.period.first == DwellDay(year: 2026, month: 10, day: 19))
        #expect(trend.weeks.count == 8)
        #expect(trend.weeks.allSatisfy { $0.value != nil })
    }

    @Test func `4W ends with the insight's week and steps back four at a time`() throws {
        let trend = try trend
        let latest = trend.window(.fourWeeks, page: 0, calendar: calendar)
        #expect(latest.map(\.period.first) == [28, 5, 12, 19].enumerated().map { index, day in
            DwellDay(year: 2026, month: index == 0 ? 9 : 10, day: day)
        })
        #expect(trend.lastPage(.fourWeeks) == 1)
        let earlier = trend.window(.fourWeeks, page: 1, calendar: calendar)
        #expect(earlier.first?.period.first == DwellDay(year: 2026, month: 8, day: 31))
        #expect(earlier.allSatisfy { $0.value != nil })
    }

    @Test func `3M keeps thirteen slots; weeks before Dwell have no bar`() throws {
        let trend = try trend
        let window = trend.window(.threeMonths, page: 0, calendar: calendar)
        #expect(window.count == 13)
        #expect(window.prefix(5).allSatisfy { $0.value == nil })
        #expect(window.suffix(8).allSatisfy { $0.value != nil })
        #expect(trend.lastPage(.threeMonths) == 0)
    }

    @Test func `the window and the bars are labelled as the design labels them`() throws {
        let trend = try trend
        let window = trend.window(.fourWeeks, page: 0, calendar: calendar)
        #expect(InsightCopy.window(window, calendar: calendar) == "Sep 2026 – Oct 2026")
        #expect(InsightCopy.window(Array(window.suffix(2)), calendar: calendar) == "Oct 2026")
        let labels = window.map { InsightCopy.barLabel($0.period, focus: trend.focus, now: now, calendar: calendar) }
        #expect(labels == ["Sep 28", "Oct 5", "Oct 12", "Last week"])
        let thisWeek = TimePeriod(.week, containing: SampleData.today, calendar: calendar)
        #expect(InsightCopy.barLabel(thisWeek, focus: thisWeek, now: now, calendar: calendar) == "This week")
        #expect(InsightCopy.monthLabel(window[1].period, calendar: calendar) == "Oct")
        #expect(InsightCopy.weekName(window[3].period, calendar: calendar) == "Oct 19 – 25")
    }
}

@Suite("Insights with no detail of their own")
struct InsightFallbackTests {
    @Test func `they open onto their sentence and their number`() throws {
        let cell = try #require(SampleData.insights.first { $0.id == "new-cell-red-hook" })
        let detail = SampleData.insightDetail(for: cell)
        #expect(detail.headline == .line(cell.line))
        #expect(detail.trend == nil)
        #expect(detail.stats.map(\.value) == [.text("3.2%")])
    }

    @Test func `the hero keeps Today's chart of its week`() throws {
        let hero = try #require(SampleData.insights.first)
        let detail = SampleData.insightDetail(for: hero)
        #expect(detail.trend == nil)
        #expect(detail.days == hero.week)
        #expect(detail.days.count == 7)
        #expect(detail.stats.map(\.label) == ["Work hours"])
    }

    @Test func `the deck's card reads the detail's sentence, written out`() throws {
        let card = try #require(SampleData.insights.first { $0.id == SampleData.officeInsightID })
        let office = try #require(SampleData.officeWeek)
        let sentence = office.sentence(now: SampleData.now, calendar: SampleData.calendar)
        for stop in Dial.Stop.allCases {
            #expect(card.line.text(at: stop) == sentence.text(at: stop))
        }
        #expect(card.value == DurationText.short(office.office))
    }

    @Test func `a detail never shows more than three numbers`() {
        let stats = (0 ..< 5).map { InsightStat(id: "\($0)", value: .text("\($0)"), label: "", icon: .chart, tint: .accent) }
        let detail = InsightDetail(id: "x", headline: .line(VoicedLine(fixed: "x")), stats: stats)
        #expect(detail.stats.count == 3)
    }
}
