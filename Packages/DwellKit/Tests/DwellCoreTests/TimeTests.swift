import Foundation
import Testing
@testable import DwellCore

/// The sample's periods, as Time loads them.
private enum Sample {
    static let calendar = SampleData.calendar
    static let now = SampleData.now

    static func snapshot(_ period: TimePeriod) -> PeriodSnapshot {
        PeriodSnapshot(period: period, days: period.days(in: calendar).map(SampleData.snapshot(for:)))
    }

    static func report(_ period: TimePeriod) -> TimeReport {
        let baselines = (1...TimeReport.baselinePeriods).map { snapshot(period.adding(-$0, in: calendar)) }
        return TimeReport(snapshot(period), baselines: baselines, now: now, calendar: calendar)
    }

    static let lastWeek = TimePeriod(.week, containing: SampleData.lastWeek[0], calendar: calendar)
    static let thisWeek = TimePeriod(.week, containing: SampleData.today, calendar: calendar)
}

@Suite("Time's periods")
struct TimePeriodTests {
    let calendar = SampleData.calendar

    @Test func `weeks run Monday to Sunday`() {
        let week = TimePeriod(.week, containing: DwellDay(year: 2026, month: 10, day: 1), calendar: calendar)
        #expect(week.first == DwellDay(year: 2026, month: 9, day: 28))
        #expect(week.last == DwellDay(year: 2026, month: 10, day: 4))
        #expect(TimeCopy.label(week, calendar: calendar) == "Sep 28 – Oct 4")
        let sunday = TimePeriod(.week, containing: DwellDay(year: 2026, month: 10, day: 4), calendar: calendar)
        #expect(sunday == week)
    }

    @Test func `months and years hold their days`() {
        let october = TimePeriod(.month, containing: SampleData.today, calendar: calendar)
        #expect(october.days(in: calendar).count == 31)
        #expect(october.adding(-1, in: calendar).days(in: calendar).count == 30)
        #expect(october.adding(-10, in: calendar).first == DwellDay(year: 2025, month: 12, day: 1))
        let year = TimePeriod(.year, containing: SampleData.today, calendar: calendar)
        #expect(year.days(in: calendar).count == 365)
        #expect(TimeCopy.label(october, calendar: calendar) == "October 2026")
    }

    @Test func `a week across the clocks changing still has seven days`() {
        let week = TimePeriod(.week, containing: SampleData.today, calendar: calendar)
        #expect(week.days(in: calendar).count == 7)
        #expect(week.last == DwellDay(year: 2026, month: 11, day: 1))
    }

    @Test func `this week is in progress, last week is over`() {
        #expect(Sample.thisWeek.isInProgress(now: Sample.now, calendar: calendar))
        #expect(!Sample.lastWeek.isInProgress(now: Sample.now, calendar: calendar))
        #expect(Sample.thisWeek.adding(1, in: calendar).isFuture(now: Sample.now, calendar: calendar))
    }

    @Test func `a sentence opens on the period`() {
        let now = Sample.now
        #expect(TimeCopy.lead(Sample.thisWeek, now: now, calendar: calendar) == "This week,")
        #expect(TimeCopy.lead(Sample.lastWeek, now: now, calendar: calendar) == "Last week,")
        #expect(TimeCopy.lead(Sample.lastWeek.adding(-1, in: calendar), now: now, calendar: calendar) == "Oct 12 – 18,")
        let day = TimePeriod(.day, containing: SampleData.today, calendar: calendar)
        #expect(TimeCopy.lead(day, now: now, calendar: calendar) == "Today,")
        #expect(TimeCopy.lead(day.adding(-1, in: calendar), now: now, calendar: calendar) == "Yesterday,")
        let september = TimePeriod(.month, containing: DwellDay(year: 2026, month: 9, day: 3), calendar: calendar)
        #expect(TimeCopy.lead(september, now: now, calendar: calendar) == "Last month,")
        #expect(TimeCopy.lead(september.adding(-1, in: calendar), now: now, calendar: calendar) == "In August,")
    }

    @Test func `earlier periods compare over the same span lived so far`() {
        let window = Sample.lastWeek.window(matching: Sample.thisWeek, now: Sample.now, calendar: calendar)
        #expect(window.start == Sample.lastWeek.first.start(in: calendar))
        #expect(DurationText.short(window.duration) == "10h 47m") // Monday 4 AM to 2:47 PM
        let whole = Sample.lastWeek.adding(-1, in: calendar).window(matching: Sample.lastWeek, now: Sample.now, calendar: calendar)
        #expect(whole.duration == 7 * 86_400)
    }

    @Test func `axis hours drop the space`() {
        #expect(ClockText.hour(4, calendar: calendar) == "4AM")
        #expect(ClockText.hour(22, calendar: calendar) == "10PM")
        #expect(TimeCopy.gridCaption(.week, calendar: calendar) == "Your days, 4AM to 4AM")
    }
}

@Suite("Time's report")
struct TimeReportTests {
    let report = Sample.report(Sample.lastWeek)

    @Test func `usual is the four weeks before`() {
        #expect(report.baselineCount == 4)
        #expect(report.usualTotals != nil)
    }

    @Test func `totals agree with the days`() {
        let days = Sample.lastWeek.days(in: SampleData.calendar).map(SampleData.snapshot(for:))
        let work = days.reduce(0) { $0 + ($1.totals(now: Sample.now)[.work] ?? 0) }
        #expect(report.work == work)
        #expect(DurationText.short(report.work) == "45h 40m")
    }

    @Test func `lines run largest first with home last`() {
        #expect(report.lines.first?.category == .work)
        #expect(report.lines.last?.category == .home)
        let middle = report.lines.dropLast().map(\.total)
        #expect(middle == middle.sorted(by: >))
    }

    @Test func `food and drink breaks down into coffee, drinks and food`() throws {
        let food = try #require(report.lines.first { $0.category == .foodAndDrink })
        #expect(Set(food.parts.map(\.subcategory)) == [.coffee, .drinks, .food])
        #expect(food.parts.reduce(0) { $0 + $1.total } == food.total)
        #expect(report.lines.first { $0.category == .work }?.parts.isEmpty == true)
    }

    @Test func `the week's mapped time and gaps fill the week`() {
        let mapped = report.totals.values.reduce(0, +)
        #expect(mapped + report.unmapped == report.watched)
        #expect(report.watched == 7 * 86_400)
        #expect(DurationText.short(report.unmapped) == "1h 07m")
    }

    @Test func `a week in progress compares with earlier weeks' Monday so far`() {
        let current = Sample.report(Sample.thisWeek)
        #expect(DurationText.short(current.work) == "4h 40m")
        let usual = current.usualWork ?? 0
        // Earlier Mondays to 2:47 PM, never whole weeks: a few hours, not forty.
        #expect(usual < 8 * 3600)
        #expect(usual > 2 * 3600)
    }

    @Test func `no usual before Dwell was recording`() {
        let first = TimePeriod(.week, containing: DwellDay(year: 2026, month: 9, day: 1), calendar: SampleData.calendar)
        let report = Sample.report(first)
        #expect(report.baselineCount == 0)
        #expect(report.lines.allSatisfy { $0.usual == nil })
        #expect(TimeCopy.headline(report, lead: "This week,")?.runs.count == 2)
    }

    @Test func `a period before recording is empty`() {
        let august = TimePeriod(.week, containing: DwellDay(year: 2026, month: 8, day: 20), calendar: SampleData.calendar)
        #expect(Sample.report(august).isEmpty)
    }
}

@Suite("Time's headline")
struct TimeHeadlineTests {
    let report = Sample.report(Sample.lastWeek)
    var sentence: VoicedSentence? {
        TimeCopy.headline(report, lead: TimeCopy.lead(Sample.lastWeek, now: Sample.now, calendar: SampleData.calendar))
    }

    @Test func `plain reads like the design`() throws {
        let sentence = try #require(sentence)
        #expect(sentence.text(at: .plain) == "Last week, 45h 40m at work, down by 43m, and 23h 03m at yours.")
    }

    @Test func `work, the change and yours are the runs, the same at every stop`() throws {
        let sentence = try #require(sentence)
        #expect(sentence.runs.map(\.text) == ["45h 40m", "43m", "23h 03m"])
        #expect(sentence.runs[1].mark == .down)
        for stop in Dial.Stop.allCases {
            let text = sentence.text(at: stop)
            for run in sentence.runs { #expect(text.contains(run.text)) }
        }
    }

    @Test(arguments: Voice.allCases)
    func `every voice uses every slot once`(voice: Voice) throws {
        let template = try #require(sentence).line.text(in: voice)
        for slot in 0..<3 {
            #expect(template.components(separatedBy: "{\(slot)}").count == 2)
        }
    }

    @Test func `grind calls yours off`() throws {
        #expect(try #require(sentence).text(at: .grind).contains("off"))
        #expect(TimeCopy.yours.text(at: .grind) == "Off")
        #expect(TimeCopy.yours.text(at: .peace) == "Yours")
    }

    @Test func `deltas read longer or less than usual`() {
        #expect(TimeCopy.delta(2 * 3600 + 44 * 60) == "2h 44m longer than usual")
        #expect(TimeCopy.delta(-40 * 60) == "40m less than usual")
        #expect(TimeCopy.delta(30) == "Same as usual")
    }

    @Test func `the asleep line keeps its number at every stop`() {
        let line = TimeCopy.asleep(8 * 3600 + 46 * 60, this: "this week")
        #expect(line.text(at: .plain) == "Dwell was asleep for 8h 46m this week. That time isn't counted.")
        #expect(line.allVariants.allSatisfy { $0.contains("8h 46m") })
    }
}

@Suite("Every hour of the week")
struct HourGridTests {
    let grid = HourGrid(Sample.snapshot(Sample.lastWeek), now: Sample.now, calendar: SampleData.calendar)

    @Test func `a row a day, each running 4 AM to 4 AM`() {
        #expect(grid.rows.count == 7)
        for row in grid.rows {
            #expect(row.segments.first?.start == 0)
            #expect(abs((row.segments.last?.end ?? 0) - 1) < 1e-9)
            for (earlier, later) in zip(row.segments, row.segments.dropFirst()) {
                #expect(earlier.end <= later.start + 1e-9)
                #expect(earlier.kind != later.kind || earlier.end < later.start)
            }
        }
    }

    @Test func `gaps show as gaps, and the legend says so`() {
        let monday = grid.rows[0]
        #expect(monday.segments.contains { $0.kind == .gap })
        #expect(grid.legend.contains(.gap))
        #expect(grid.legend.last == .bucket(.everythingElse))
    }

    @Test func `seven categories at most, then everything else`() {
        let named = grid.legend.filter { if case .bucket(.category) = $0 { true } else { false } }
        #expect(named.count <= ChartBucket.maxNamedCategories)
        #expect(named.first == .bucket(.category(.work)))
        #expect(named.last == .bucket(.category(.home)))
    }

    @Test func `this week stops at now and before recording there's nothing`() {
        let current = HourGrid(Sample.snapshot(Sample.thisWeek), now: Sample.now, calendar: SampleData.calendar)
        let monday = current.rows[0]
        let end = monday.segments.last?.end ?? 0
        let lived: Double = (10 * 3600 + 47 * 60) / 86_400
        #expect(abs(end - lived) < 1e-6)
        #expect(current.rows.dropFirst().allSatisfy { $0.isEmpty })
    }

    @Test func `a year shows a typical day a month`() {
        let year = TimePeriod(.year, containing: SampleData.today, calendar: SampleData.calendar)
        let grid = HourGrid(Sample.snapshot(year), now: Sample.now, calendar: SampleData.calendar)
        #expect(grid.rows.count == 12)
        #expect(grid.isTypical)
        #expect(grid.rows.prefix(7).allSatisfy { $0.isEmpty }) // before 31 August
        #expect(!grid.rows[8].isEmpty) // September
        #expect(grid.rows[8].segments.contains { $0.kind == .bucket(.category(.work)) })
        #expect(grid.rows[11].isEmpty) // December
    }

    @Test func `short stops stay visible, true to their time`() {
        let segments = [
            HourGrid.Segment(kind: .bucket(.category(.home)), start: 0, end: 0.3),
            HourGrid.Segment(kind: .bucket(.category(.transit)), start: 0.3, end: 0.31),
            HourGrid.Segment(kind: .bucket(.category(.work)), start: 0.31, end: 1),
        ]
        let spans = HourGrid.layout(segments, width: 300, minWidth: 6, spacing: 2)
        #expect(spans.count == 3)
        #expect(spans[1].upperBound - spans[1].lowerBound >= 6 - 1e-9)
        #expect(spans[0].upperBound + 2 <= spans[1].lowerBound + 1e-9)
        #expect(spans[1].upperBound + 2 <= spans[2].lowerBound + 1e-9)
        #expect(spans[0].lowerBound == 0 && spans[2].upperBound == 300)
        // The transit stays about 3 AM after 4 AM's 30%: around 90 pt in.
        #expect(abs((spans[1].lowerBound + spans[1].upperBound) / 2 - 91.5) < 4)
    }

    @Test func `segments apart in time keep their place`() {
        let segments = [
            HourGrid.Segment(kind: .bucket(.category(.home)), start: 0.5, end: 0.6),
            HourGrid.Segment(kind: .gap, start: 0.6, end: 0.62),
        ]
        let spans = HourGrid.layout(segments, width: 100, minWidth: 6, spacing: 2)
        #expect(spans[0].lowerBound == 50)
        #expect(spans[1].upperBound <= 100)
        #expect(spans[0].upperBound + 2 <= spans[1].lowerBound + 1e-9)
    }
}

@Suite("Calendar vs reality")
struct CalendarReportTests {
    let report = CalendarReport(
        Sample.snapshot(Sample.lastWeek),
        earlier: (1...4).flatMap { Sample.snapshot(Sample.lastWeek.adding(-$0, in: SampleData.calendar)).days },
        calendar: SampleData.calendar)

    @Test func `counts each match state`() {
        #expect(report.scheduled == 7)
        #expect(report.attended == 4)
        #expect(report.leftEarly == 2)
        #expect(report.elsewhere == 1)
        #expect(report.attended + report.leftEarly + report.elsewhere + report.unknown == report.scheduled)
    }

    @Test func `notices the Monday standup three weeks running and the dentist`() {
        let lines = report.notes.map { TimeCopy.note($0.kind).text(at: .plain) }
        #expect(lines.contains("You left Team standup early 3 Mondays running."))
        #expect(lines.contains("Dentist was Wed at 1:00. You were at Kestriva Labs."))
    }

    @Test func `missed reads as a fact at every stop`() {
        let line = TimeCopy.note(.missed(title: "Dentist", day: "Wed", time: "1:00", instead: "Kestriva Labs"))
        #expect(line.allVariants.allSatisfy { !$0.contains("!") })
        #expect(line.text(at: .peace).hasSuffix("No judgment."))
    }
}

@Suite("Your rhythm")
struct RhythmTests {
    let days = (0..<Rhythm.lookback).map { SampleData.snapshot(for: SampleData.today.adding(days: -$0, in: SampleData.calendar)) }

    @Test func `weekdays: arrive, lunch, leave, home by, in order`() throws {
        let rhythm = try #require(Rhythm.typical(.weekday, from: days, now: Sample.now, calendar: SampleData.calendar))
        #expect(rhythm.moments.map(\.mark) == [.arrive, .lunch, .leave, .homeBy])
        let minutes = rhythm.moments.map(\.minutes)
        #expect(minutes == minutes.sorted())
        #expect(rhythm.stretches.map(\.phase) == [.morning, .lunch, .afternoon, .wayHome])
        // Arrives between 8 and 10.
        #expect(minutes[0] > 4 * 60 && minutes[0] < 6 * 60)
    }

    @Test func `weekends: out, lunch, home by`() throws {
        let rhythm = try #require(Rhythm.typical(.weekend, from: days, now: Sample.now, calendar: SampleData.calendar))
        #expect(rhythm.moments.first?.mark == .out)
        #expect(rhythm.moments.last?.mark == .homeBy)
    }

    @Test func `no workdays, no weekday rhythm`() {
        let weekend = days.filter { [1, 7].contains(SampleData.calendar.component(.weekday, from: $0.interval.start)) }
        #expect(Rhythm.typical(.weekday, from: weekend, now: Sample.now, calendar: SampleData.calendar) == nil)
    }
}

@Suite("Places over time")
struct PlaceTrendTests {
    let trends = SampleData.placeTrends

    @Test func `growing, then shrinking, then paused`() {
        #expect(trends.count == 3)
        #expect((trends[0].change ?? 0) > 0)
        #expect((trends[1].change ?? 0) < 0)
        #expect(trends[2].isPaused)
        #expect(trends[2].name == "Halcyon Pool")
    }

    @Test func `home and private places are never highlighted`() {
        #expect(!trends.contains { $0.placeID == "home" || $0.placeID == "stagnes" })
    }

    @Test func `a paused place says since when`() throws {
        let pool = try #require(trends.first { $0.isPaused })
        let lastSeen = try #require(pool.lastSeen)
        #expect(TimeCopy.notSince(lastSeen, calendar: SampleData.calendar) == "Not since Sep 26")
    }
}

@Suite("Records and the year")
struct RecordsTests {
    @Test func `records agree with the timeline`() {
        let thursday = SampleData.snapshot(for: DwellDay(year: 2026, month: 10, day: 22))
        #expect(DurationText.short(thursday.totals(now: Sample.now)[.work] ?? 0) == SampleData.records[0].value)
        // No generated day beats Thursday's 10h 12m, 8:12 AM or Tuesday's five places.
        let longest: TimeInterval = 10 * 3600 + 12 * 60
        let earliest: TimeInterval = (8 * 60 + 12 - 4 * 60) * 60 // after the day's 4 AM start
        var day = DwellDay(year: 2026, month: 8, day: 31)
        while day <= SampleData.today {
            let snapshot = SampleData.snapshot(for: day)
            let work = snapshot.totals(now: Sample.now)[.work] ?? 0
            #expect(work <= longest)
            #expect(snapshot.recap(now: Sample.now).placesVisited <= 5)
            let office = snapshot.entries.compactMap(\.visit).first { $0.category == .work && !$0.isWorkFromHome }
            if let arrival = office?.arrival {
                let afterStart = arrival.timeIntervalSince(snapshot.interval.start)
                #expect(afterStart >= earliest)
            }
            day = day.adding(days: 1, in: SampleData.calendar)
        }
    }

    @Test func `a run of days reads as a range`() {
        let streak = SampleData.records[2]
        #expect(TimeCopy.recordDate(streak, calendar: SampleData.calendar) == "Sep 8 – 19")
        #expect(TimeCopy.recordDate(SampleData.records[0], calendar: SampleData.calendar) == "Oct 22")
    }

    @Test func `locked records keep a hint`() {
        #expect(SampleData.records.filter(\.isLocked).allSatisfy { $0.unlockHint != nil })
        #expect(SampleData.records.map(\.locked).allSatisfy { $0.isLocked && $0.unlockHint != nil })
    }

    @Test func `the year in a line`() {
        let coverage = SampleData.coverage.first { $0.level == .neighborhood }
        #expect(TimeCopy.yearTitle(places: 15, coverage: coverage, records: 4) == "15 places, 3.2% of Brooklyn, 4 records.")
        #expect(TimeCopy.yearTitle(places: 1, coverage: nil, records: 1) == "1 place, 1 record.")
        #expect(TimeCopy.percent(0.05) == "5%")
    }
}

@Suite("The sample's history")
struct SampleHistoryTests {
    @Test func `entries stay in order and never overlap, from install to now`() {
        let entries = SampleData.entries.map { $0.interval(now: Sample.now) }
        for (earlier, later) in zip(entries, entries.dropFirst()) {
            #expect(earlier.end <= later.start)
        }
        #expect(entries.first?.start == SampleData.recordingSince)
    }

    @Test func `the history hands over to the hand-written week at home`() {
        let sunday = SampleData.snapshot(for: DwellDay(year: 2026, month: 10, day: 18))
        let last = sunday.entries.last?.visit
        #expect(last?.placeName == "Home")
        #expect(sunday.entries.dropLast().last.map { if case .transit = $0 { true } else { false } } == true)
    }

    @Test func `lifetime totals are the timeline's`() {
        let kestriva = SampleData.place("kestriva")
        let visits = SampleData.entries.compactMap(\.visit).filter { $0.placeID == "kestriva" }
        #expect(kestriva.visitCount == visits.count)
        #expect(kestriva.lifetimeTotal == visits.reduce(0) { $0 + $1.interval(now: Sample.now).duration })
        #expect(SampleData.place("home").firstSeen == SampleData.recordingSince)
    }
}

@Suite("Time, top to bottom")
struct TimeOverviewTests {
    @Test func `last week has every section`() throws {
        let overview = TimeOverview.sample(Sample.lastWeek)
        #expect(overview.trend.count == 4)
        #expect(overview.trend.last?.isShown == true)
        #expect(overview.trend.map(\.period.first) == (0..<4).reversed().map { Sample.lastWeek.adding(-$0, in: SampleData.calendar).first })
        guard case .report(let calendar) = overview.calendarSection else {
            Issue.record("Expected a calendar report")
            return
        }
        #expect(calendar.scheduled == 7)
        guard case .ready(let weekday, let weekend) = overview.rhythm else {
            Issue.record("Expected a rhythm")
            return
        }
        #expect(weekday != nil && weekend != nil)
        let year = try #require(overview.year)
        #expect(year.places == 15)
        #expect(year.records == 4)
        #expect(overview.learningDaysToGo == nil)
    }

    @Test func `the loader reads the same as the sample`() async throws {
        let loaded = try await TimeOverview.load(Sample.lastWeek, from: SampleRepository(), now: Sample.now, calendar: SampleData.calendar)
        let sample = TimeOverview.sample(Sample.lastWeek)
        #expect(loaded.report == sample.report)
        #expect(loaded.grid == sample.grid)
        #expect(loaded.trend == sample.trend)
        #expect(loaded.rhythm == sample.rhythm)
    }

    @Test func `the install day has no rhythm, year or calendar yet`() async throws {
        let week = TimePeriod(.week, containing: SampleData.today, calendar: SampleData.calendar)
        let overview = try await TimeOverview.load(week, from: DemoRepository(.firstPlace), now: Sample.now, calendar: SampleData.calendar)
        #expect(overview.rhythm == .locked(daysToGo: 13))
        #expect(overview.year == nil)
        #expect(overview.calendarSection == .notConnected)
        #expect(overview.learningDaysToGo == 6)
        #expect(overview.trend.count == 1)
    }

    @Test func `the first day has nothing at all`() async throws {
        let week = TimePeriod(.week, containing: SampleData.today, calendar: SampleData.calendar)
        let overview = try await TimeOverview.load(week, from: DemoRepository(.firstDay), now: Sample.now, calendar: SampleData.calendar)
        #expect(overview.report.lines.isEmpty)
    }
}

@Suite("Time's copy follows the rules")
struct TimeCopyRuleTests {
    static let lines: [VoicedLine] = [
        TimeCopy.asleep(3600, this: "this week"),
        TimeCopy.workAndYours, TimeCopy.yours,
        TimeCopy.note(.leftEarlyRun(title: "Team standup", weekday: "Monday", weeks: 3)),
        TimeCopy.note(.lateRun(title: "Team standup", weekday: "Monday", weeks: 3)),
        TimeCopy.note(.missed(title: "Dentist", day: "Wed", time: "1:00", instead: "Kestriva Labs")),
        TimeCopy.note(.missed(title: "Dentist", day: "Wed", time: "1:00", instead: nil)),
        TimeCopy.patternsWaiting, TimeCopy.nothingToNotice, TimeCopy.noMeetings(this: "this week"),
        TimeCopy.connectTitle, TimeCopy.rhythmLocked(daysToGo: 3), TimeCopy.stillLearning(.week, daysToGo: 4),
        TimeCopy.waitingTitle, TimeCopy.waitingDetail, TimeCopy.nothingMapped(this: "this week"),
        TimeCopy.quietHeadline(lead: "This week,"), TimeCopy.beforeRecording(this: "that week"),
    ]

    @Test(arguments: lines)
    func `no exclamation marks, and Dwell's words`(line: VoicedLine) {
        for text in line.allVariants {
            #expect(!text.contains("!"))
            let lower = text.lowercased()
            #expect(!lower.contains("track") && !lower.contains("location") && !lower.contains("check-in"))
        }
    }

    @Test func `the details on the page say place, never location`() {
        for text in [TimeCopy.connectDetail, TimeCopy.placesWaiting, TimeCopy.gridCaption(.year, calendar: SampleData.calendar)] {
            #expect(!text.lowercased().contains("location"))
            #expect(!text.contains("!"))
        }
    }
}
