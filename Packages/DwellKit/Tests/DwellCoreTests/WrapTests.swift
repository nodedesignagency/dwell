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
