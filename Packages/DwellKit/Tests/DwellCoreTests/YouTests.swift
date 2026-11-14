import Foundation
import Testing
@testable import DwellCore

@Suite("You: the dial decides which pushes can fire")
struct NotificationRuleTests {
    @Test func `the morning recap fires at every stop`() {
        #expect(Dial.Stop.allCases.allSatisfy { NotificationKind.morningRecap.isAvailable(at: $0) })
    }

    @Test func `streak at risk is push and grind only`() {
        let stops = Dial.Stop.allCases.filter { NotificationKind.streakAtRisk.isAvailable(at: $0) }
        #expect(stops == [.push, .grind])
    }

    @Test func `new records are grind only`() {
        let stops = Dial.Stop.allCases.filter { NotificationKind.records.isAvailable(at: $0) }
        #expect(stops == [.grind])
    }

    @Test func `peace never gets a streak-at-risk push, even if it was left on`() {
        #expect(!NotificationKind.streakAtRisk.fires(at: .peace, isOn: true))
        #expect(NotificationKind.streakAtRisk.fires(at: .push, isOn: true))
        #expect(!NotificationKind.streakAtRisk.fires(at: .grind, isOn: false))
    }

    @Test func `streak at risk is opt-in`() {
        #expect(!NotificationKind.streakAtRisk.isOnByDefault)
        #expect(NotificationKind.morningRecap.isOnByDefault)
    }
}

@Suite("You: which streak leads")
struct FeaturedStreakTests {
    let streaks = SampleData.streaks

    @Test func `plain leads with the longest daily streak going, as the design does`() {
        #expect(Streak.featured(in: streaks, at: .plain)?.kind == .outByTarget)
    }

    @Test func `peace leads with a streak about rest`() {
        #expect(Streak.featured(in: streaks, at: .peace)?.kind == .outByTarget)
        #expect(Streak.featured(in: streaks, at: .calm)?.kind == .outByTarget)
    }

    @Test func `grind never leads with a peace streak`() {
        let kind = Streak.featured(in: streaks, at: .grind)?.kind
        #expect(kind == .gymRegular)
        #expect(kind?.audience != .peace)
    }

    @Test func `a broken streak only leads when nothing is going`() {
        let broken = Streak(kind: .tenHourDays, current: 0, best: 9, freezes: 0, state: .broken)
        let going = Streak(kind: .firstIn, current: 2, best: 4, freezes: 0, state: .active)
        #expect(Streak.featured(in: [broken, going], at: .grind)?.kind == .firstIn)
        #expect(Streak.featured(in: [broken], at: .grind)?.kind == .tenHourDays)
    }

    @Test func `a streak going outside the dial's taste beats nothing going`() {
        let rest = Streak(kind: .workFreeEvening, current: 5, best: 5, freezes: 0, state: .active)
        let broken = Streak(kind: .tenHourDays, current: 0, best: 9, freezes: 0, state: .broken)
        #expect(Streak.featured(in: [broken, rest], at: .grind)?.kind == .workFreeEvening)
    }

    @Test func `no streaks, nothing to lead with`() {
        #expect(Streak.featured(in: [], at: .plain) == nil)
    }

    @Test func `the numbers are the same whichever stop picks the streak`() {
        let plain = Streak.featured(in: streaks, at: .plain)
        let peace = Streak.featured(in: streaks, at: .peace)
        #expect(plain == peace)
    }

    @Test func `the sample's last seven days end today, still open`() {
        let outBy = streaks.first { $0.kind == .outByTarget }
        #expect(outBy?.recent.count == 7)
        #expect(outBy?.recent.last?.start == SampleData.today)
        #expect(outBy?.recent.last?.state == .open)
        #expect(outBy?.recent.contains { $0.state == .frozen } == true)
    }

    @Test func `weekly marks start on sundays in the US`() {
        let explorer = streaks.first { $0.kind == .explorerWeek }
        #expect(explorer?.recent.last?.start == DwellDay(year: 2026, month: 10, day: 25))
        #expect(explorer?.recent.first?.start == DwellDay(year: 2026, month: 9, day: 13))
    }
}

@Suite("You: the badge grid")
struct BadgeShowcaseTests {
    @Test func `earned badges come first, best tier first, then the closest to unlocking`() {
        let kinds = Badge.showcase(SampleData.badges).map(\.kind)
        #expect(kinds == [.explorer, .foundingUser, .cartographer, .earlyBird, .globetrotter, .marathoner])
    }

    @Test func `the grid holds six`() {
        let all = Badge.Kind.allCases.map { Badge(kind: $0, tier: .bronze, progress: 0) }
        #expect(Badge.showcase(all).count == 6)
    }

    @Test func `six of thirteen`() {
        #expect(YouCopy.earned(6) == "6 of 13")
    }

    @Test func `a badge reads its tier and what it counts`() {
        let explorer = Badge(kind: .explorer, tier: .gold, progress: 1, count: 41)
        #expect(YouCopy.details(for: explorer) == ["Gold", "41 places"])
        #expect(YouCopy.details(for: Badge(kind: .foundingUser, tier: .gold, progress: 1)) == ["Gold"])
        #expect(YouCopy.details(for: Badge(kind: .globetrotter, tier: nil, progress: 0.8, count: 1)) == ["Locked", "1 country"])
    }
}

@Suite("You: coverage reads like 3.2%")
struct CoverageTextTests {
    let english = Locale(identifier: "en_US")

    static let cases: [(fraction: Double, text: String)] = [
        (0, "0%"),
        (41.0 / 1281, "3.2%"),
        (0.05, "5%"),
        (0.29, "29%"),
        (0.0399, "3.9%"),
        (1, "100%"),
        (1.0 / 1281, "<0.1%"),
    ]

    @Test(arguments: cases)
    func `coverage rounds down to one decimal`(fraction: Double, text: String) {
        #expect(CoverageText.percent(fraction, locale: english) == text)
    }

    @Test func `the profile pill`() {
        #expect(YouCopy.mapped(SampleData.coverage.city, locale: english) == "3.2% mapped")
        #expect(YouCopy.mapped(nil, locale: english) == "0% mapped")
    }
}

@Suite("You: streak words")
struct StreakCopyTests {
    let calendar = SampleData.calendar

    @Test func `the out-by streak reads like the design`() throws {
        let outBy = try #require(SampleData.streaks.first { $0.kind == .outByTarget })
        #expect(YouCopy.run(outBy) == "12 evenings")
        #expect(YouCopy.rule(outBy, calendar: calendar) == "Home by 6:30\u{202F}PM")
        #expect(YouCopy.length(outBy.current, period: .day) == "12 days")
        #expect(YouCopy.freezes(outBy.freezes) == "1 of 2")
    }

    @Test func `weekly streaks count weeks`() {
        let explorer = Streak(kind: .explorerWeek, current: 1, best: 4, freezes: 0, state: .active)
        #expect(YouCopy.run(explorer) == "1 week")
    }

    @Test func `weekday labels`() {
        #expect(ClockText.weekday(SampleData.today, calendar: calendar) == "Mon")
        #expect(ClockText.monthDay(SampleData.today, calendar: calendar) == "Oct 26")
    }
}

@Suite("You: the sample's scratch cells")
struct ScratchCellTests {
    @Test func `one cell for every uncovered neighborhood cell, each a hexagon`() {
        let cells = SampleData.scratchCells
        #expect(cells.count == SampleData.coverage.city?.uncovered)
        #expect(Set(cells.map(\.id)).count == cells.count)
        #expect(cells.allSatisfy { $0.boundary.count == 6 && $0.level == .neighborhood })
    }

    @Test func `cells stay near the middle of brooklyn, but last week's in Red Hook`() {
        let centre = SampleData.brooklyn
        let walk = SampleData.scratchCells.filter { $0.id != SampleData.redHookCell.id }
        #expect(walk.count == SampleData.scratchCells.count - 1)
        #expect(SampleData.redHookCell.neighborhood == "Red Hook")
        for corner in walk.flatMap(\.boundary) {
            #expect(abs(corner.latitude - centre.latitude) < 0.03)
            #expect(abs(corner.longitude - centre.longitude) < 0.04)
        }
    }

    @Test func `cells were uncovered while Dwell was recording`() {
        for cell in SampleData.scratchCells {
            #expect(cell.firstUncovered >= SampleData.recordingSince)
            #expect(cell.firstUncovered <= SampleData.now)
        }
    }
}
