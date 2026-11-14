import Foundation
import Testing
@testable import DwellCore

private let calendar = SampleData.calendar
private let now = SampleData.now
private let monday = SampleData.todaySnapshot
private let friday = SampleData.snapshot(for: DwellDay(year: 2026, month: 10, day: 23))

/// A time on the sample's Monday 26 October, or another day of that week.
private func at(_ hour: Int, _ minute: Int, day: Int = 26) -> Date {
    SampleData.date(month: 10, day: day, minutes: hour * 60 + minute)
}

private func visit(_ id: VisitID, in snapshot: DaySnapshot = monday) throws -> Visit {
    try #require(snapshot.entries.compactMap(\.visit).first { $0.id == id })
}

private func draft(_ id: VisitID, in snapshot: DaySnapshot = monday) throws -> VisitDraft {
    let visit = try visit(id, in: snapshot)
    return VisitDraft(visit: visit, place: visit.placeID.map(SampleData.place))
}

private func work(_ snapshot: DaySnapshot) -> String {
    DurationText.short(snapshot.recap(now: now).work)
}

/// Monday's morning at Kestriva Labs, 9:14 AM to 12:38 PM: after a gap from 8:59, before
/// transit to the clinic at 12:46.
private let morning: VisitID = "10-26-3"

@Suite("Visit edit")
struct VisitEditTests {
    @Test func `a new draft changes nothing`() throws {
        let draft = try draft(morning)
        #expect(!draft.hasChanges)
        #expect(draft.category == .work)
        #expect(!draft.isAtHome)
        #expect(monday.applying(draft).entries == monday.entries)
    }

    @Test func `a visit stretches to the visits either side, over gaps and transit`() throws {
        let limits = try draft(morning).limits(in: monday, now: now)
        #expect(limits.start == at(8, 59))
        #expect(limits.end == at(12, 46))
    }

    @Test func `times move in 5-minute steps and count at once`() throws {
        var draft = try draft(morning)
        draft.moveArrival(to: at(9, 2), in: monday, now: now)
        #expect(draft.arrival == at(9, 0))
        #expect(draft.hasChanges)
        let edited = monday.applying(draft)
        // 14 minutes more at work; the gap before it shrinks to the minute left.
        #expect(work(monday) == "4h 40m")
        #expect(work(edited) == "4h 54m")
        #expect(edited.entries.contains(.gap(DateInterval(start: at(8, 59), end: at(9, 0)))))
    }

    @Test func `a visit never runs over the visits beside it`() throws {
        var draft = try draft(morning)
        draft.moveArrival(to: at(8, 30), in: monday, now: now)
        #expect(draft.arrival == at(8, 59))
        draft.moveDeparture(to: at(12, 55), in: monday, now: now)
        #expect(draft.departure == at(12, 46))
        // The transit to the clinic is covered, so it goes.
        let edited = monday.applying(draft)
        #expect(!edited.entries.contains { if case .transit(let span) = $0 { span.start == at(12, 38) } else { false } })
    }

    @Test func `a visit is never shorter than a stop`() throws {
        var draft = try draft(morning)
        draft.moveDeparture(to: at(9, 10), in: monday, now: now)
        #expect(draft.departure == at(9, 19))
        draft.moveArrival(to: at(10, 0), in: monday, now: now)
        #expect(draft.arrival == at(9, 14))
    }

    @Test func `giving time back leaves it unmapped`() throws {
        var draft = try draft(morning)
        draft.moveDeparture(to: at(12, 0), in: monday, now: now)
        let before = monday.recap(now: now).unmapped
        let after = monday.applying(draft).recap(now: now).unmapped
        #expect(after - before == 38 * 60)
    }

    @Test func `merge runs the visit on through the next and drops what came between`() throws {
        var draft = try draft(morning)
        #expect(draft.canMerge(in: monday))
        draft.toggleMerge(in: monday)
        #expect(draft.end(in: monday, now: now) == at(13, 20))
        #expect(!draft.canMoveDeparture(in: monday))
        let edited = monday.applying(draft)
        let visits = edited.entries.compactMap(\.visit)
        #expect(!visits.contains { $0.id == "10-26-5" })
        #expect(visits.first { $0.id == morning }?.departure == at(13, 20))
        // The clinic's 34m now count as work: 4h 06m and the afternoon's 1h 16m.
        #expect(work(edited) == "5h 22m")
        draft.toggleMerge(in: monday)
        #expect(!draft.hasChanges)
    }

    @Test func `split leaves two visits at the same place and the same total`() throws {
        var draft = try draft(morning)
        draft.toggleSplit(in: monday, now: now)
        // The middle of 9:14 to 12:38, on a 5-minute mark.
        #expect(draft.splitTime == at(10, 55))
        let edited = monday.applying(draft)
        let parts = edited.entries.compactMap(\.visit).filter { $0.placeID == "kestriva" }
        #expect(parts.count == 3)
        #expect(parts.first?.departure == at(10, 55))
        #expect(parts.dropFirst().first?.id == "10-26-3-split")
        #expect(work(edited) == work(monday))
        #expect(edited.recap(now: now).workSessions == 3)
    }

    @Test func `each part of a split is a stop long at least`() throws {
        var draft = try draft(morning)
        draft.toggleSplit(in: monday, now: now)
        draft.moveSplit(to: at(9, 15), in: monday, now: now)
        #expect(draft.splitTime == at(9, 19))
        draft.moveSplit(to: at(12, 40), in: monday, now: now)
        #expect(draft.splitTime == at(12, 33))
        // Moving an end carries the split with it.
        draft.moveDeparture(to: at(10, 0), in: monday, now: now)
        #expect(draft.splitTime == at(9, 55))
    }

    @Test func `split and merge replace each other`() throws {
        var draft = try draft(morning)
        draft.toggleMerge(in: monday)
        draft.toggleSplit(in: monday, now: now)
        #expect(draft.splitTime == at(10, 55))
        draft.toggleMerge(in: monday)
        #expect(draft.change == .mergeWithNext)
    }

    @Test func `a visit still going ends now and has nothing after it`() throws {
        let draft = try draft("10-26-7")
        #expect(draft.isOngoing)
        #expect(!draft.canMoveDeparture(in: monday))
        #expect(!draft.canMerge(in: monday))
        #expect(draft.limits(in: monday, now: now).end == now)
        #expect(VisitEditCopy.subtitle(arrival: draft.arrival, duration: draft.duration(in: monday, now: now), now: now, calendar: calendar)
            == "Today • 1h 16m")
    }

    @Test func `a night that began yesterday keeps its start`() throws {
        let night = try #require(monday.entries.compactMap(\.visit).first)
        let draft = VisitDraft(visit: night, place: SampleData.place("home"))
        #expect(!draft.canMoveArrival(in: monday))
        #expect(draft.canMoveDeparture(in: monday))
    }

    @Test func `work from home counts as work and is shown as home`() throws {
        let draft = try draft("10-23-3", in: friday)
        #expect(draft.isAtHome)
        #expect(draft.isWorkFromHome)
        #expect(draft.category == .work)
        #expect(draft.placeCategory == .home)
        #expect(VisitEditCopy.subtitle(arrival: draft.arrival, duration: draft.duration(in: friday, now: now), now: now, calendar: calendar)
            == "Friday • 3h 10m")

        var notWork = draft
        notWork.isWorkFromHome = false
        let edited = friday.applying(notWork)
        #expect(edited.entries.compactMap(\.visit).first { $0.id == "10-23-3" }?.category == .home)
        let lost = friday.recap(now: now).work - edited.recap(now: now).work
        #expect(DurationText.short(lost) == "3h 10m")
    }

    @Test func `only a visit at home can be work from home`() throws {
        var draft = try draft("10-26-1")
        #expect(!draft.isAtHome)
        draft.isWorkFromHome = true
        let visit = try #require(draft.visits(in: monday).first)
        #expect(!visit.isWorkFromHome)
        #expect(visit.category == .foodAndDrink)
    }

    @Test func `private places stay off the map`() throws {
        #expect(try draft("10-26-5").isHiddenFromMaps)
        #expect(try !draft(morning).isHiddenFromMaps)
    }

    @Test func `deleting a visit leaves its time to nothing`() throws {
        let edited = monday.removingVisit(morning)
        #expect(work(edited) == "1h 16m")
        #expect(!edited.entries.contains { $0.visit?.id == morning })
    }

    @Test func `the track's hours read like the design's`() {
        let marks = [4, 8, 12, 16, 20, 24].map { at($0, 0) }
            .map { ClockText.hourMark($0, calendar: calendar).replacingOccurrences(of: "\u{202F}", with: " ") }
        #expect(marks == ["4 AM", "8 AM", "12 PM", "4 PM", "8 PM", "12 AM"])
    }

    @Test func `saves and deletes apply in order`() throws {
        var draft = try draft(morning)
        draft.moveArrival(to: at(9, 0), in: monday, now: now)
        let edited = monday.applying([.saved(draft), .deleted("10-26-7")])
        #expect(work(edited) == "3h 38m")
    }
}
