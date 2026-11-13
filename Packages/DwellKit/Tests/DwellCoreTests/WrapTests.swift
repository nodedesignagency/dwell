import Foundation
import Testing
@testable import DwellCore

/// The digits of a string, in order: what must not change between Peace and Grind.
private func digits(_ text: String) -> String {
    String(text.filter(\.isNumber))
}

private let calendar = SampleData.calendar

@Suite("Weekly wrap: the opener")
struct WrapOpenerTests {
    let week = SampleData.lastWeek.map(SampleData.snapshot(for:))

    @Test func `last week had seven days and its places, each once`() {
        let opener = WrapOpener(week: week)
        #expect(opener.days == 7)
        // Every place with a visit Monday 19 to Sunday 25 October, home and work included.
        let visited = Set(week.flatMap(\.entries).compactMap { $0.visit?.placeName })
        #expect(opener.places == visited.count)
        // The design says 9; the sample week is the build's (QUESTIONS.md, design vs brief 9).
        #expect(opener.places == 13)
    }

    @Test func `a first week counts only the days Dwell was recording`() {
        // Installed on Thursday morning: Thursday to Sunday.
        let thursday = SampleData.lastWeek[3].interval(in: calendar).start.addingTimeInterval(4 * 3600)
        let firstWeek = week.map { snapshot in
            var snapshot = snapshot
            snapshot.recordingSince = thursday
            return snapshot
        }
        #expect(WrapOpener(week: firstWeek).days == 4)
    }

    @Test func `the same numbers at every stop`() {
        let line = WrapCopy.openerLine(WrapOpener(days: 7, places: 9))
        #expect(line.plain == "7 days, 9 places and every hour in between. Here's how it went.")
        for variant in line.allVariants {
            #expect(digits(variant) == "79")
        }
    }

    @Test func `one day, one place, or none`() {
        #expect(WrapCopy.openerLine(WrapOpener(days: 1, places: 1)).plain.hasPrefix("1 day, 1 place and"))
        #expect(WrapCopy.openerLine(WrapOpener(days: 7, places: 0)).plain.hasPrefix("7 days and every hour"))
    }

    @Test func `the opener's title is Appendix B's`() {
        #expect(WrapCopy.openerTitle.text(at: .peace) == "Your week, gently.")
        #expect(WrapCopy.openerTitle.text(at: .plain) == "This week.")
        #expect(WrapCopy.openerTitle.text(at: .grind) == "The week. Receipts inside.")
    }

    @Test func `no exclamation marks`() {
        let lines = [WrapCopy.openerTitle, WrapCopy.openerLine(WrapOpener(days: 7, places: 9))]
        for variant in lines.flatMap(\.allVariants) {
            #expect(!variant.contains("!"))
        }
    }
}

@Suite("Weekly wrap: a page's clock")
struct StoryClockTests {
    let start = Date(timeIntervalSinceReferenceDate: 0)

    @Test func `runs from the start and fills its capsule`() {
        let clock = StoryClock(duration: 7).resumed(at: start)
        #expect(clock.fraction(at: start) == 0)
        #expect(clock.fraction(at: start + 3.5) == 0.5)
        #expect(clock.remaining(at: start + 3.5) == 3.5)
        #expect(clock.fraction(at: start + 20) == 1)
        #expect(clock.remaining(at: start + 20) == 0)
    }

    @Test func `a hold pauses it and letting go carries on`() {
        let held = StoryClock(duration: 7).resumed(at: start).paused(at: start + 2)
        #expect(!held.isRunning)
        // Holding for 10 seconds doesn't count.
        #expect(held.fraction(at: start + 12) == 2.0 / 7)
        let resumed = held.resumed(at: start + 12)
        #expect(resumed.remaining(at: start + 12) == 5)
        // 2 s before the hold and 3.5 s after it.
        #expect(resumed.elapsed(at: start + 15.5) == 5.5)
    }

    @Test func `pausing twice or resuming twice changes nothing`() {
        let running = StoryClock(duration: 7).resumed(at: start)
        #expect(running.resumed(at: start + 3) == running)
        let paused = running.paused(at: start + 1)
        #expect(paused.paused(at: start + 5) == paused)
    }
}

@Suite("Weekly wrap: work vs yours")
struct WrapWorkAndYoursTests {
    let week = SampleData.lastWeek.map(SampleData.snapshot(for:))

    @Test func `the same numbers as Time's last week`() {
        let split = WrapWorkAndYours(week: week, now: SampleData.now)
        #expect(DurationText.short(split.work) == "45h 40m")
        #expect(DurationText.short(split.yours) == "23h 03m")
        let period = TimePeriod(.week, containing: SampleData.lastWeek[0], calendar: calendar)
        let report = TimeOverview.sample(period).report
        #expect(split.work == report.work)
        #expect(split.yours == report.yours)
    }

    @Test func `work fills its share of the page`() {
        #expect(WrapWorkAndYours(work: 30, yours: 10).workShare == 0.75)
        #expect(WrapWorkAndYours(work: 0, yours: 10).workShare == 0)
        #expect(WrapWorkAndYours(work: 0, yours: 0).workShare == 0.5)
        #expect(WrapWorkAndYours(week: [], now: SampleData.now) == WrapWorkAndYours(work: 0, yours: 0))
    }

    @Test func `grind calls yours off`() {
        #expect(WrapCopy.yours.text(at: .grind) == "Off")
        #expect(WrapCopy.yours.text(at: .plain) == "Yours")
    }
}

@Suite("Weekly wrap: earliest exit")
struct WrapEarliestExitTests {
    let week = SampleData.lastWeek.map(SampleData.snapshot(for:))
    let before = (1...WrapWeek.lookback).reversed().map {
        SampleData.snapshot(for: SampleData.lastWeek[0].adding(days: -$0, in: calendar))
    }

    @Test func `last week's earliest office exit, against the usual`() throws {
        let exit = try #require(WrapEarliestExit(week: week, before: before, calendar: calendar))
        #expect(ClockText.weekdayName(exit.day, calendar: calendar) == "Tuesday")
        #expect(ClockText.time(exit.time, calendar: calendar).replacingOccurrences(of: "\u{202F}", with: " ") == "5:52 PM")
        // Her usual over the four weeks before is 6:05 PM.
        #expect(exit.minutesEarlier == 13)
        // Its day is a weekday, and no other weekday left the office earlier.
        let weekday = calendar.component(.weekday, from: exit.day.start(in: calendar))
        #expect((2...6).contains(weekday))
        for day in week {
            if let other = WrapEarliestExit.exit(from: day, calendar: calendar) {
                #expect(other.minutes >= exit.minutes)
            }
        }
    }

    @Test func `no usual without five exits before`() throws {
        let exit = try #require(WrapEarliestExit(week: week, before: Array(before.suffix(3)), calendar: calendar))
        #expect(exit.usualMinutes == nil)
        #expect(exit.minutesEarlier == nil)
    }

    @Test func `no exit without an office weekday`() {
        let weekend = week.filter { day in
            let weekday = calendar.component(.weekday, from: day.interval.start)
            return weekday == 1 || weekday == 7
        }
        #expect(WrapEarliestExit(week: weekend, before: before, calendar: calendar) == nil)
    }

    @Test func `the same minutes at every stop`() {
        let day = SampleData.lastWeek[4]
        for usual in [1090.0, 1052.0, 1014.0] {
            let exit = WrapEarliestExit(day: day, time: SampleData.now, minutes: 1052, usualMinutes: usual)
            let line = WrapCopy.earliestExitLine(exit)
            let numbers = Set(line.allVariants.map { String($0.filter(\.isNumber)) })
            #expect(numbers.count == 1)
            for variant in line.allVariants { #expect(!variant.contains("!")) }
        }
        let early = WrapEarliestExit(day: day, time: SampleData.now, minutes: 1052, usualMinutes: 1090)
        #expect(WrapCopy.earliestExitLine(early).plain == "38 minutes earlier than your usual. The evening was yours.")
        let one = WrapEarliestExit(day: day, time: SampleData.now, minutes: 1052, usualMinutes: 1053)
        #expect(WrapCopy.earliestExitLine(one).plain.hasPrefix("1 minute earlier"))
    }

    @Test func `weekday names in full`() {
        #expect(ClockText.weekdayName(SampleData.lastWeek[4], calendar: calendar) == "Friday")
    }
}
