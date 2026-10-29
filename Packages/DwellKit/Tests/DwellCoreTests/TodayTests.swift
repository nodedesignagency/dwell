import Foundation
import Testing
@testable import DwellCore

/// The digits of a string, in order: what must not change between Peace and Grind.
private func digits(_ text: String) -> String {
    String(text.filter(\.isNumber))
}

/// iOS and Linux put a narrow no-break space before AM and PM.
private func plainSpaces(_ text: String) -> String {
    text.replacingOccurrences(of: "\u{202F}", with: " ")
}

private let calendar = SampleData.calendar
private let now = SampleData.now

@Suite("Today's numbers")
struct DayRecapTests {
    let recap = SampleData.todaySnapshot.recap(now: now)

    @Test func `work, home and two work sessions`() {
        #expect(DurationText.short(recap.work) == "4h 40m")
        #expect(DurationText.short(recap.home) == "3h 47m")
        #expect(recap.workSessions == 2)
    }

    @Test func `yours is everything but work, home and transit`() {
        // Brambleline Café 57m and the clinic 34m.
        #expect(DurationText.short(recap.yours) == "1h 31m")
    }

    @Test func `private and personal places never lead the headline`() {
        #expect(recap.standout?.name == "Brambleline Café")
        #expect(DurationText.short(recap.standout?.duration ?? 0) == "57m")
    }

    @Test func `today is fully mapped from 4 AM`() {
        #expect(recap.unmapped == 0)
        #expect(recap.mapped == SampleData.todaySnapshot.elapsed(now: now).duration)
    }

    @Test func `a gap counts as unmapped`() {
        let monday = SampleData.snapshot(for: DwellDay(year: 2026, month: 10, day: 19)).recap(now: now)
        #expect(DurationText.short(monday.unmapped) == "22m")
    }

    static let pairs: [(stop: Dial.Stop, second: HeroStat)] = [
        (.peace, .yours), (.calm, .yours), (.plain, .yours), (.push, .sessions), (.grind, .sessions),
    ]

    @Test(arguments: pairs)
    func `the dial picks the second hero stat`(stop: Dial.Stop, second: HeroStat) {
        #expect(HeroStat.pair(for: stop) == (.work, second))
    }
}

@Suite("The day bar")
struct DayBarTests {
    let today = DayBar(snapshot: SampleData.todaySnapshot, now: now)
    let monday = DayBar(snapshot: SampleData.snapshot(for: DwellDay(year: 2026, month: 10, day: 19)), now: now)

    @Test func `categories run in display order, not by size`() {
        #expect(today.parts.map(\.segment) == [
            .bucket(.category(.work)), .bucket(.category(.home)), .bucket(.category(.foodAndDrink)),
            .bucket(.category(.transit)), .bucket(.category(.personal)),
        ])
    }

    @Test func `the bar adds up to the day so far`() {
        #expect(today.total == SampleData.todaySnapshot.elapsed(now: now).duration)
    }

    @Test func `unmapped time comes last`() {
        #expect(monday.parts.last?.segment == .unmapped)
        #expect(DurationText.short(monday.parts.last?.duration ?? 0) == "22m")
        #expect(monday.total == 24 * 3600)
    }

    @Test(arguments: [3, 12, 55, 80])
    func `ticks fill the bar exactly`(count: Int) {
        #expect(today.ticks(count).count == count)
        #expect(monday.ticks(count).count == count)
    }

    @Test func `a short stop keeps a tick`() {
        let ticks = monday.ticks(55)
        #expect(ticks.contains(.unmapped))
        for part in monday.parts {
            #expect(ticks.contains(part.segment))
        }
        #expect(ticks.last == .unmapped)
    }

    @Test func `an empty day so far is all unmapped`() {
        let empty = DayBar(snapshot: .empty(SampleData.today, calendar: calendar), now: now)
        #expect(empty.parts.map(\.segment) == [.unmapped])
        #expect(DurationText.short(empty.total) == "10h 47m")
    }

    @Test func `nothing to draw at 4 AM`() {
        let start = SampleData.today.start(in: calendar)
        #expect(DayBar(snapshot: .empty(SampleData.today, calendar: calendar), now: start).ticks(55).isEmpty)
    }
}

@Suite("Today's copy")
struct TodayCopyTests {
    let recap = SampleData.todaySnapshot.recap(now: now)

    @Test func `the headline reads like the design at Plain`() throws {
        let sentence = try #require(TodayCopy.headline(recap, isToday: true, dayName: "Today"))
        #expect(sentence.text(at: .plain) == "Today, you've spent 4h 40m at work, 57m at Brambleline Café and 3h 47m at home.")
        #expect(sentence.runs.map(\.category) == [.work, .foodAndDrink, .home])
    }

    @Test(arguments: [true, false])
    func `every voice uses every slot once`(isToday: Bool) {
        for drop in 0...2 {
            var partial = recap
            if drop >= 1 { partial.home = 0 }
            if drop >= 2 { partial.standout = nil }
            guard let sentence = TodayCopy.headline(partial, isToday: isToday, dayName: "Mon, Oct 19") else {
                Issue.record("Expected a headline")
                continue
            }
            for variant in sentence.line.allVariants {
                for index in sentence.runs.indices {
                    #expect(variant.components(separatedBy: "{\(index)}").count == 2, "\(variant)")
                }
                #expect(!variant.contains("{\(sentence.runs.count)}"))
            }
        }
    }

    @Test func `no headline for an empty day`() {
        let empty = DaySnapshot.empty(SampleData.today, calendar: calendar).recap(now: now)
        #expect(TodayCopy.headline(empty, isToday: true, dayName: "Today") == nil)
    }

    @Test func `the live caption is Appendix B`() {
        let line = TodayCopy.liveCaption(SampleData.liveStatus, calendar: calendar)
        #expect(line.peace == "Here since 1:31.")
        #expect(plainSpaces(line.plain) == "At Kestriva Labs since 1:31 PM · estimate")
        #expect(line.grind == "On the clock since 1:31.")
    }

    @Test func `the confirmation is Appendix B`() {
        let line = TodayCopy.confirmVisit(placeName: "Brambleline Café", duration: 57 * 60)
        #expect(line.peace == "Looks like 57m at Brambleline Café. Right?")
        #expect(line.plain == "You spent 57m at Brambleline Café. Looks right?")
        #expect(line.grind == "57m at Brambleline Café. Looks right?")
    }

    static var voicedLines: [VoicedLine] {
        let recap = SampleData.todaySnapshot.recap(now: now)
        let visit = Visit(id: "v", placeID: nil, placeName: "Brambleline Café", category: .foodAndDrink,
                          arrival: now.addingTimeInterval(-3_000), departure: nil)
        return [
            TodayCopy.headline(recap, isToday: true, dayName: "Today")!.line,
            TodayCopy.headline(recap, isToday: false, dayName: "Mon, Oct 19")!.line,
            TodayCopy.liveCaption(SampleData.liveStatus, calendar: calendar),
            TodayCopy.liveCaption(.atPlace(visit), calendar: calendar),
            TodayCopy.confirmVisit(placeName: "Brambleline Café", duration: 57 * 60),
            TodayCopy.emptyToday,
            TodayCopy.emptyPastDay,
            TodayCopy.stillMapping,
        ]
    }

    @Test(arguments: voicedLines)
    func `numbers are identical across the dial`(line: VoicedLine) {
        let expected = digits(line.plain)
        for variant in line.allVariants {
            #expect(digits(variant) == expected, "\(variant)")
        }
    }

    @Test(arguments: voicedLines)
    func `no exclamation marks, no banned words`(line: VoicedLine) {
        for text in line.allVariants.map({ $0.lowercased() }) {
            #expect(!text.contains("!"))
            #expect(!text.contains("location"))
            #expect(!text.contains("check-in"))
            #expect(!text.contains("track"))
        }
    }

    @Test func `timeline rows never carry character`() {
        #expect(TodayCopy.gapRow(22 * 60) == "Dwell was asleep · 22m")
        #expect(TodayCopy.transitRow(15 * 60) == "In transit · 15m")
    }

    @Test func `buttons say Looks right and Pick another`() {
        #expect(TodayCopy.looksRight == "Looks right")
        #expect(TodayCopy.pickAnother == "Pick another")
    }

    @Test func `one permission line per banner, action as in the brief`() {
        #expect(PermissionBanner.locationDenied.message == "Dwell can't see any places. Enable location in Settings.")
        #expect(PermissionBanner.allCases.map(\.actionTitle) == ["Open Settings", "Fix", "Open Settings", "Open Settings"])
        for banner in PermissionBanner.allCases {
            #expect(!banner.message.contains("!"))
        }
    }
}

@Suite("Voiced sentences")
struct VoicedSentenceTests {
    @Test func `punctuation stays with its run`() {
        #expect(VoicedSentence.tokens("Today, you've spent {0}, {1} and {2}.") == [
            .word("Today,"), .word("you've"), .word("spent"),
            .run(prefix: "", index: 0, suffix: ","), .run(prefix: "", index: 1, suffix: ""),
            .word("and"), .run(prefix: "", index: 2, suffix: "."),
        ])
    }

    @Test func `fills every slot`() {
        let sentence = VoicedSentence(
            line: VoicedLine(peace: "{0} and {1}.", plain: "{0}, {1}.", grind: "{1}; {0}."),
            runs: [.init(text: "4h 40m at work"), .init(text: "57m at Brambleline Café")])
        #expect(sentence.text(at: .grind) == "57m at Brambleline Café; 4h 40m at work.")
    }
}

@Suite("Clock text")
struct ClockTextTests {
    let arrival = SampleData.todaySnapshot.entries.compactMap(\.visit).first { $0.placeID == "brambleline" }!

    @Test func spans() {
        #expect(plainSpaces(ClockText.span(from: arrival.arrival, to: arrival.departure, calendar: calendar)) == "8:02 AM – 8:59 AM")
        #expect(plainSpaces(ClockText.span(from: arrival.arrival, to: nil, calendar: calendar)) == "8:02 AM → now")
    }

    @Test func `bare times drop AM and PM`() {
        #expect(ClockText.bareTime(arrival.arrival, calendar: calendar) == "8:02")
    }

    @Test func `days read like Mon, Oct 19`() {
        #expect(ClockText.dayName(DwellDay(year: 2026, month: 10, day: 19), calendar: calendar) == "Mon, Oct 19")
    }
}

@Suite("Today's sample deck")
struct SampleDeckTests {
    @Test func `the hero insight charts last week's work, weekend at zero`() throws {
        let hero = try #require(SampleData.insights.first)
        #expect(hero.week.count == 7)
        #expect(hero.week.map(\.day) == SampleData.lastWeek)
        #expect(DurationText.short(hero.week[3].value) == "10h 12m")
        #expect(hero.week[5].value == 0 && hero.week[6].value == 0)
    }
}
