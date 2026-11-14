import Foundation
import Testing
@testable import DwellCore

private let calendar = SampleData.calendar
private let now = SampleData.now
private let monday = SampleData.todaySnapshot

/// iOS and Linux put a narrow no-break space before AM and PM.
private func plain(_ text: String) -> String {
    text.replacingOccurrences(of: "\u{202F}", with: " ")
}

private func at(_ hour: Int, _ minute: Int) -> Date {
    SampleData.date(month: 10, day: 26, minutes: hour * 60 + minute)
}

/// Monday's café visit Dwell isn't sure about: Brambleline Café, 8:02 to 8:59 AM.
private func café() throws -> Visit {
    try #require(monday.entries.compactMap(\.visit).first { $0.id == "10-26-1" })
}

@Suite("Place picker")
struct PlacePickerTests {
    @Test func `nearby offers the guess first, 40 m off, and two venues beside it`() throws {
        let nearby = SampleData.nearbyPlaces(for: try café())
        #expect(nearby.count == 3)
        #expect(nearby.first?.placeID == "brambleline")
        #expect(DistanceText.short(nearby.first?.distance ?? 0, locale: Locale(identifier: "it_IT")) == "40 m")
        #expect(nearby.dropFirst().allSatisfy { $0.placeID == nil })
        #expect(nearby.map(\.distance) == nearby.map(\.distance).sorted { ($0 ?? 0) < ($1 ?? 0) })
    }

    @Test func `search finds Maya's places and the venues around, nearest first`() throws {
        let visit = try café()
        #expect(SampleData.searchPlaces("kestriva", for: visit).map(\.name) == ["Kestriva Labs"])
        #expect(SampleData.searchPlaces("WICKFIELD", for: visit).map(\.name) == ["Wickfield Coffee"])
        #expect(SampleData.searchPlaces("  ", for: visit).isEmpty)
        #expect(SampleData.searchPlaces("zzz", for: visit).isEmpty)
    }

    @Test func `distances follow the phone's units`() {
        let us = Locale(identifier: "en_US"), italy = Locale(identifier: "it_IT")
        #expect(DistanceText.short(40, locale: us) == "130 ft")
        #expect(DistanceText.short(40, locale: italy) == "40 m")
        #expect(DistanceText.short(3, locale: italy) == "10 m")
        #expect(DistanceText.short(1234, locale: italy) == "1,2 km")
        #expect(DistanceText.short(1234, locale: us) == "0.8 mi")
    }

    @Test func `the span reads like the design`() {
        #expect(plain(PlacePickerCopy.subtitle(arrival: at(12, 40), departure: at(13, 25), now: now, calendar: calendar))
            == "12:40 to 1:25 PM · 45m")
        #expect(plain(PlacePickerCopy.subtitle(arrival: at(11, 30), departure: at(12, 10), now: now, calendar: calendar))
            == "11:30 AM to 12:10 PM · 40m")
        #expect(plain(PlacePickerCopy.subtitle(arrival: at(13, 31), departure: nil, now: now, calendar: calendar))
            == "1:31 PM to now · 1h 16m")
    }

    @Test func `a row reads its category and distance`() throws {
        let guess = try #require(SampleData.nearbyPlaces(for: try café()).first)
        #expect(PlacePickerCopy.facts(guess, locale: Locale(identifier: "it_IT")) == "Food & drink · 40 m")
        #expect(PlacePickerCopy.select(guess.name) == "Select Brambleline Café")
    }

    @Test func `picking a place takes the visit and settles it`() throws {
        let visit = try café()
        var draft = VisitDraft(visit: visit, place: SampleData.place("brambleline"))
        let venue = try #require(SampleData.nearbyPlaces(for: visit).first { $0.placeID == nil })
        draft.choose(venue)
        #expect(draft.hasNewPlace)
        #expect(draft.hasChanges)
        let picked = try #require(monday.applying(draft).entries.compactMap(\.visit).first { $0.id == visit.id })
        #expect(picked.placeName == venue.name)
        #expect(picked.placeID == nil)
        #expect(picked.category == venue.category)
        #expect(!picked.needsReview)
    }

    @Test func `picking home lets the visit count as work from home`() throws {
        var draft = VisitDraft(visit: try café(), place: SampleData.place("brambleline"))
        #expect(!draft.isAtHome)
        draft.choose(PlaceCandidate(place: SampleData.place("home"), distance: nil))
        #expect(draft.isAtHome)
        draft.isWorkFromHome = true
        #expect(draft.category == .work)
        draft.choose(PlaceCandidate(place: SampleData.place("kestriva"), distance: nil))
        #expect(draft.category == .work)
        draft.choose(PlaceCandidate(place: SampleData.place("sorrel"), distance: nil))
        // Away from home it can't count as work from home.
        #expect(draft.category == .foodAndDrink)
    }

    @Test func `the place a visit is at is recognised among the candidates`() throws {
        let nearby = SampleData.nearbyPlaces(for: try café())
        #expect(nearby.first?.isSame(placeID: "brambleline", name: "Brambleline Café") == true)
        #expect(nearby.last?.isSame(placeID: "brambleline", name: "Brambleline Café") == false)
        let venue = try #require(nearby.last)
        #expect(venue.isSame(placeID: nil, name: venue.name))
    }

    @Test func `private places come with their privacy`() {
        let clinic = PlaceCandidate(place: SampleData.place("stagnes"), distance: 10)
        #expect(clinic.isHiddenFromMaps)
    }
}
