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

@Suite("Weekly wrap: weekends")
struct WrapWeekendsTests {
    let week = SampleData.lastWeek.map(SampleData.snapshot(for:))
    /// Saturday 17 and Sunday 18 October.
    let lastWeekend = [-2, -1].map { SampleData.lastWeek[0].adding(days: $0, in: calendar) }.map(SampleData.snapshot(for:))

    var weekends: WrapWeekends {
        WrapWeekends(week: week, lastWeekend: lastWeekend, now: SampleData.now, calendar: calendar)
    }

    /// The same week with a stretch of Saturday afternoon at work.
    func weekWithSaturdayWork(_ minutes: Int) -> [DaySnapshot] {
        week.map { snapshot in
            guard snapshot.day == SampleData.lastWeek[5] else { return snapshot }
            var snapshot = snapshot
            let start = snapshot.interval.start.addingTimeInterval(10 * 3600) // 2 PM
            let visit = Visit(
                id: "saturday-work", placeID: "kestriva", placeName: "Kestriva Labs", category: .work,
                arrival: start, departure: start.addingTimeInterval(Double(minutes) * 60))
            snapshot.entries.append(.visit(visit))
            return snapshot
        }
    }

    @Test func `the weekend is Saturday and Sunday`() {
        #expect(weekends.weekend == Array(SampleData.lastWeek.suffix(2)))
        #expect(WrapWeekends.isWeekend(SampleData.lastWeek[5], calendar: calendar))
        #expect(!WrapWeekends.isWeekend(SampleData.lastWeek[4], calendar: calendar))
    }

    @Test func `last weekend had no work`() {
        #expect(weekends.verdict == .allYours)
        #expect(weekends.workByDay == [0, 0])
        #expect(WrapCopy.weekendsTitle(weekends.verdict).plain == "Weekends were all yours.")
        #expect(WrapCopy.weekendsLine(weekends).plain == "Zero work hours Saturday and Sunday.")
        #expect(WrapCopy.weekendsBreakdown(weekends.verdict) == "What you did instead")
    }

    @Test func `work at the weekend is counted, never called all yours`() {
        let busy = WrapWeekends(week: weekWithSaturdayWork(130), lastWeekend: lastWeekend, now: SampleData.now, calendar: calendar)
        #expect(busy.verdict == .someWork(130.0 * 60))
        #expect(busy.workByDay == [130.0 * 60, 0])
        #expect(WrapCopy.weekendsTitle(busy.verdict).plain == "2h 10m of work this weekend.")
        #expect(WrapCopy.weekendsLine(busy).plain == "Saturday 2h 10m, Sunday 0m.")
        // Work is in the title, never among what you did instead.
        #expect(!busy.breakdown.contains { $0.bucket == .category(.work) })
    }

    @Test func `a weekend Dwell didn't see claims nothing`() {
        let asleep = week.map { snapshot in
            guard WrapWeekends.isWeekend(snapshot.day, calendar: calendar) else { return snapshot }
            var snapshot = snapshot
            snapshot.entries = [.gap(snapshot.interval)]
            return snapshot
        }
        let unseen = WrapWeekends(week: asleep, lastWeekend: lastWeekend, now: SampleData.now, calendar: calendar)
        #expect(unseen.verdict == .notRecorded)
        #expect(unseen.breakdown.isEmpty)
        #expect(!WrapCopy.weekendsTitle(unseen.verdict).allVariants.contains { $0.contains("yours") })
    }

    @Test func `what you did instead, largest first, as Time counts it`() {
        let slices = weekends.breakdown
        #expect(slices.map(\.bucket.name) == ["Home", "Food & drink", "Transit", "Outdoors", "Education", "Fitness", "Everything else"])
        #expect(slices.map { DurationText.short($0.total) } == ["34h 55m", "3h 27m", "3h 07m", "2h 17m", "1h 45m", "1h 05m", "39m"])
        // Time's totals for Saturday and Sunday, to the second.
        let saturday = SampleData.lastWeek[5].interval(in: calendar).start
        let sunday = SampleData.lastWeek[6].interval(in: calendar).end
        let time = TimeReport.totals(week, within: DateInterval(start: saturday, end: sunday), now: SampleData.now)
        #expect(slices.reduce(0) { $0 + $1.total } == time.values.reduce(0, +) - (time[.work] ?? 0))
    }

    @Test func `the grid names work and the weekend's own categories`() {
        let named = weekends.grid.legend.compactMap { kind -> PlaceCategory? in
            if case .bucket(.category(let category)) = kind { category } else { nil }
        }
        #expect(named.count == ChartBucket.maxNamedCategories)
        #expect(named.contains(.work))
        for slice in weekends.breakdown {
            if let category = slice.bucket.category { #expect(named.contains(category)) }
        }
        // Monday to Sunday, a row a day.
        #expect(weekends.grid.rows.map(\.day) == SampleData.lastWeek)
    }

    @Test func `the biggest change in time of your own`() {
        // The library on Sunday morning; last weekend had none.
        #expect(weekends.change == WrapWeekends.Change(category: .education, difference: 105 * 60))
        #expect(WrapCopy.weekendsChange(weekends.change!).plain == "1h 45m more education than last weekend.")
        #expect(WrapCopy.weekendsChange(.init(category: .social, difference: -2 * 3600)).plain
            == "2h less social than last weekend.")
    }

    @Test func `the wrap finds the weekend before among the weeks it loads`() {
        let before = (1...WrapWeek.lookback).reversed().map {
            SampleData.snapshot(for: SampleData.lastWeek[0].adding(days: -$0, in: calendar))
        }
        let wrap = WrapWeek(week: week, before: before, now: SampleData.now, calendar: calendar)
        #expect(wrap.weekends == weekends)
        #expect(WrapWeek(week: week, now: SampleData.now, calendar: calendar).weekends.change == nil)
    }

    @Test func `no change without a whole last weekend to compare`() {
        let firstWeekend = lastWeekend.map { snapshot in
            var snapshot = snapshot
            snapshot.recordingSince = snapshot.interval.start.addingTimeInterval(3600)
            return snapshot
        }
        #expect(WrapWeekends(week: week, lastWeekend: firstWeekend, now: SampleData.now, calendar: calendar).change == nil)
        #expect(WrapWeekends(week: week, lastWeekend: [], now: SampleData.now, calendar: calendar).change == nil)
    }

    @Test func `a change under half an hour isn't news`() {
        #expect(WrapWeekends.change(from: lastWeekend, to: WrapWeekends.totals(lastWeekend, now: SampleData.now), now: SampleData.now) == nil)
    }

    @Test func `the same numbers at every stop`() {
        let busy = WrapWeekends(week: weekWithSaturdayWork(130), lastWeekend: lastWeekend, now: SampleData.now, calendar: calendar)
        let lines = [
            WrapCopy.weekendsTitle(weekends.verdict), WrapCopy.weekendsLine(weekends),
            WrapCopy.weekendsTitle(busy.verdict), WrapCopy.weekendsLine(busy),
            WrapCopy.weekendsChange(weekends.change!),
        ]
        for line in lines {
            for variant in line.allVariants {
                #expect(digits(variant) == digits(line.plain))
                #expect(!variant.contains("!"))
            }
        }
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

@Suite("Weekly wrap: postcard")
struct WrapPostcardTests {
    let week = SampleData.lastWeek.map(SampleData.snapshot(for:))
    let before = (1...WrapWeek.lookback).reversed().map {
        SampleData.snapshot(for: SampleData.lastWeek[0].adding(days: -$0, in: calendar))
    }

    var wrap: WrapWeek {
        WrapWeek(week: week, before: before, places: SampleData.places, city: SampleData.profile.cityCenter,
                 now: SampleData.now, calendar: calendar)
    }

    @Test func `the stamp's numbers are the other pages' numbers`() {
        let postcard = wrap.postcard
        #expect(postcard.work == wrap.workAndYours.work)
        #expect(postcard.yours == wrap.workAndYours.yours)
        #expect(postcard.earliestExit == wrap.earliestExit)
        #expect(postcard.weekendWork == 0)
        #expect(WrapCopy.weekendWorkValue(postcard.weekendWork) == "0m")
    }

    @Test func `new places are the ones first visited that week`() {
        let interval = DateInterval(
            start: SampleData.lastWeek[0].interval(in: calendar).start,
            end: SampleData.lastWeek[6].interval(in: calendar).end)
        let firsts = SampleData.places.filter { place in
            place.firstSeen.map(interval.contains) ?? false
        }
        #expect(wrap.postcard.newPlaces == firsts.count)
        #expect(WrapWeek(week: week, now: SampleData.now, calendar: calendar).postcard.newPlaces == nil)
        #expect(WrapCopy.newPlacesValue(nil) == "–")
    }

    @Test func `the map is the city's, never home`() {
        #expect(wrap.postcard.city == SampleData.profile.cityCenter)
        #expect(WrapWeek(week: week, now: SampleData.now, calendar: calendar).postcard.city == nil)
    }

    @Test func `the exit reads as a weekday and a time`() throws {
        let exit = try #require(wrap.postcard.earliestExit)
        let value = WrapCopy.exitValue(exit, calendar: calendar)
        #expect(value == "\(ClockText.weekday(exit.day, calendar: calendar)) \(ClockText.time(exit.time, calendar: calendar))")
        #expect(WrapCopy.exitValue(nil, calendar: calendar) == "None")
    }

    @Test func `a weekend Dwell didn't see isn't zero`() {
        var unseen = wrap
        unseen.weekends.verdict = .notRecorded
        #expect(unseen.postcard.weekendWork == nil)
        #expect(WrapCopy.weekendWorkValue(nil) == TimeCopy.notRecorded)
    }

    @Test func `nothing on the stamp names a place or home`() {
        let spoken = WrapCopy.postcardSpoken(wrap.postcard, totals: "At work, 45 hours.", calendar: calendar)
        for place in SampleData.places {
            #expect(!spoken.contains(place.name))
        }
        #expect(!spoken.contains("Home"))
    }
}

@Suite("Weekly wrap: where you spent the most time")
struct WrapMostTimeTests {
    let week = SampleData.lastWeek.map(SampleData.snapshot(for:))
    let now = SampleData.now

    /// A place's time and visits in the week, counted by hand.
    private func counted(_ id: PlaceID) -> (total: TimeInterval, visits: Int) {
        let whole = DateInterval(start: week[0].interval.start, end: week[6].interval.end)
        var total: TimeInterval = 0
        var visits = Set<VisitID>()
        for day in week {
            for entry in day.entries {
                guard let visit = entry.visit, visit.placeID == id else { continue }
                let span = entry.interval(now: now)
                let start = max(span.start, day.interval.start, whole.start)
                let end = min(span.end, day.interval.end, whole.end, now)
                if end > start {
                    total += end.timeIntervalSince(start)
                    visits.insert(visit.id)
                }
            }
        }
        return (total, visits.count)
    }

    @Test func `last week went most to Kestriva Labs`() throws {
        let most = try #require(WrapMostTime(week: week, places: SampleData.places, now: now))
        #expect(most.place.id == "kestriva")
        let kestriva = counted("kestriva")
        #expect(most.total == kestriva.total)
        #expect(most.visits == kestriva.visits)
        // Every other place that could be shown had less.
        for place in SampleData.places where WrapMostTime.isShown(place) && place.id != "kestriva" {
            #expect(counted(place.id).total < most.total)
        }
    }

    @Test func `home holds more, and is left out`() throws {
        #expect(counted("home").total > counted("kestriva").total)
        let most = try #require(WrapMostTime(week: week, places: SampleData.places, now: now))
        #expect(most.place.id != "home")
        #expect(!WrapMostTime.isShown(SampleData.place("home")))
    }

    @Test func `private and personal places never go on the map`() throws {
        #expect(!WrapMostTime.isShown(SampleData.place("stagnes")))
        var places = SampleData.places
        let index = try #require(places.firstIndex { $0.id == "kestriva" })
        places[index].isPrivate = true
        let most = try #require(WrapMostTime(week: week, places: places, now: now))
        #expect(most.place.id != "kestriva")
        #expect(!most.place.isHiddenFromMaps)
    }

    @Test func `a week at home has no place to show`() {
        let atHome = week.map { day in
            var day = day
            day.entries = day.entries.filter { $0.visit?.placeID == "home" || $0.visit == nil }
            return day
        }
        #expect(WrapMostTime(week: atHome, places: SampleData.places, now: now) == nil)
    }

    @Test func `the wrap names no place when the places didn't load`() {
        let loaded = WrapWeek(week: week, places: SampleData.places, now: now, calendar: calendar)
        #expect(loaded.hasPlaces)
        #expect(loaded.mostTime?.place.id == "kestriva")
        let failed = WrapWeek(week: week, places: nil, now: now, calendar: calendar)
        #expect(!failed.hasPlaces)
        #expect(failed.mostTime == nil)
    }

    @Test func `the sample's work has a place on the map and was seen today`() throws {
        let kestriva = SampleData.place("kestriva")
        #expect(kestriva.coordinate != nil)
        // At Kestriva Labs since 9:02 this Monday morning, still there.
        #expect(kestriva.lastSeen == now)
        let first = try #require(kestriva.firstSeen)
        #expect(WrapCopy.visitingSince(first, calendar: calendar) == "Visiting since: August 31, 2026")
    }

    @Test func `last seen reads by Dwell days`() {
        let monday = SampleData.today.interval(in: calendar).start  // Monday 26 October, 4 AM
        func seen(_ offset: TimeInterval) -> String {
            WrapCopy.lastSeenValue(monday.addingTimeInterval(offset), now: now, calendar: calendar)
        }
        #expect(seen(5 * 3600) == "Today")
        // 3:30 AM on Monday is still Sunday's.
        #expect(seen(-30 * 60) == "Yesterday")
        #expect(seen(-20 * 3600) == "Yesterday")
        #expect(seen(-2 * 86_400) == "Saturday")
        #expect(seen(-6 * 86_400) == "Tuesday")
        #expect(seen(-7 * 86_400) == "Oct 19")
    }

    @Test func `all time is the place's lifetime, never less than the week`() throws {
        let most = try #require(WrapMostTime(week: week, places: SampleData.places, now: now))
        #expect(most.place.lifetimeTotal >= most.total)
        #expect(WrapCopy.allTime == "All time")
    }

    @Test func `one visit, or many`() {
        #expect(WrapCopy.visitsLabel(1) == "Visit")
        #expect(WrapCopy.visitsLabel(5) == "Visits")
    }

    @Test func `the titles carry no numbers and no exclamation marks`() {
        for variant in [WrapCopy.mostTimeTitle, WrapCopy.noMostTimeTitle].flatMap(\.allVariants) {
            #expect(digits(variant).isEmpty)
            #expect(!variant.contains("!"))
        }
        #expect(WrapCopy.mostTimeTitle.text(at: .plain) == "Where you spent the most time")
    }
}

@Suite("Weekly wrap: explorer week")
struct WrapExplorerTests {
    let week = SampleData.lastWeek.map(SampleData.snapshot(for:))
    let span = DateInterval(
        start: SampleData.lastWeek[0].interval(in: SampleData.calendar).start,
        end: SampleData.lastWeek[6].interval(in: SampleData.calendar).end)

    var wrap: WrapWeek {
        WrapWeek(week: week, places: SampleData.places, cells: SampleData.scratchCells,
                 city: SampleData.profile.cityCenter, now: SampleData.now, calendar: calendar)
    }

    /// One new place, first visited halfway through the week.
    func place(_ id: PlaceID, private isPrivate: Bool = false, category: PlaceCategory = .shopping) -> Place {
        Place(id: id, name: "\(id)", category: category, isPrivate: isPrivate,
              firstSeen: span.start.addingTimeInterval(3 * 86_400), coordinate: SampleData.tidewaterCoordinate)
    }

    @Test func `last week: two new places and one new cell, in Red Hook`() {
        let explorer = wrap.explorer
        #expect(explorer.places?.map(\.id) == ["ashgrove", "tidewater"])
        #expect(explorer.cells?.map(\.id) == [SampleData.redHookCell.id])
        #expect(explorer.neighborhoods == ["Red Hook"])
        #expect(explorer.isExplorerWeek)
        #expect(explorer.tagged.count == 2)
    }

    @Test func `the explorer page and the postcard count the same new places`() {
        #expect(wrap.explorer.places?.count == wrap.postcard.newPlaces)
    }

    @Test func `the design's words, the same numbers at every stop`() throws {
        let title = WrapCopy.explorerTitle(wrap.explorer)
        #expect(title.plain == "2 new places.\n1 new corner.")
        let line = try #require(WrapCopy.explorerLine(wrap.explorer))
        #expect(line.plain == "Your map grew by one cell in Red Hook.")
        for variant in title.allVariants {
            #expect(digits(variant) == "21")
        }
        for variant in line.allVariants {
            #expect(digits(variant).isEmpty)
            #expect(variant.contains("Red Hook"))
        }
    }

    @Test func `private and personal places count but stay off the map`() {
        let explorer = WrapExplorer(
            places: [place("open"), place("hidden", private: true), place("personal", category: .personal)],
            cells: [], week: span, city: nil)
        #expect(explorer.places?.count == 3)
        #expect(explorer.tagged.map(\.id) == ["open"])
        #expect(!WrapCopy.explorerMap(explorer).contains("hidden"))
    }

    @Test func `the map tags at most three places`() {
        let places = (1...5).map { place(PlaceID("p\($0)")) }
        let explorer = WrapExplorer(places: places, cells: [], week: span, city: nil)
        #expect(explorer.tagged.count == WrapExplorer.maxTags)
        #expect(WrapCopy.explorerTitle(explorer).plain == "5 new places.")
    }

    @Test func `places from before the week aren't new, cells from before aren't either`() {
        let old = Place(id: "old", name: "Old", category: .shopping, firstSeen: span.start.addingTimeInterval(-60))
        let cells = SampleData.scratchCells.filter { $0.id != SampleData.redHookCell.id }
        let explorer = WrapExplorer(places: [old], cells: cells, week: span, city: nil)
        #expect(explorer.places == [])
        #expect(explorer.cells == [])
        #expect(!explorer.isExplorerWeek)
        #expect(WrapCopy.explorerTitle(explorer).plain == "No new places this week.")
        #expect(WrapCopy.explorerLine(explorer)?.plain == "Your map stayed the same this week.")
    }

    @Test func `new places on mapped streets, and new cells without a new place`() {
        let placesOnly = WrapExplorer(places: [place("new")], cells: [], week: span, city: nil)
        #expect(WrapCopy.explorerTitle(placesOnly).plain == "1 new place.")
        #expect(WrapCopy.explorerLine(placesOnly)?.plain == "All on streets your map already had.")

        let cellsOnly = WrapExplorer(places: [], cells: SampleData.scratchCells, week: span, city: nil)
        #expect(!cellsOnly.isExplorerWeek)
        #expect(WrapCopy.explorerTitle(cellsOnly).plain == "1 new corner.")
    }

    @Test func `several cells name their neighborhoods once each`() {
        var cells = (0..<3).map { index in
            var cell = SampleData.redHookCell
            cell.neighborhood = index == 2 ? "Gowanus" : "Red Hook"
            return ScratchCell(id: "c\(index)", level: .neighborhood, boundary: cell.boundary,
                               firstUncovered: cell.firstUncovered.addingTimeInterval(Double(index)), neighborhood: cell.neighborhood)
        }
        let explorer = WrapExplorer(places: [], cells: cells, week: span, city: nil)
        #expect(explorer.neighborhoods == ["Red Hook", "Gowanus"])
        #expect(WrapCopy.explorerLine(explorer)?.plain == "Your map grew by 3 cells in Red Hook and Gowanus.")
        cells = cells.map { cell in
            var cell = cell
            cell.neighborhood = nil
            return cell
        }
        let unnamed = WrapExplorer(places: [], cells: cells, week: span, city: nil)
        #expect(WrapCopy.explorerLine(unnamed)?.plain == "Your map grew by 3 cells.")
    }

    @Test func `nothing loaded claims nothing`() {
        #expect(WrapCopy.explorerTitle(.unknown).plain == "Your new places couldn't load.")
        #expect(WrapCopy.explorerLine(.unknown) == nil)
        let noCells = WrapExplorer(places: [place("new")], cells: nil, week: span, city: nil)
        #expect(WrapCopy.explorerLine(noCells) == nil)
        #expect(WrapWeek(week: week, now: SampleData.now, calendar: calendar).explorer.places == nil)
    }
}
