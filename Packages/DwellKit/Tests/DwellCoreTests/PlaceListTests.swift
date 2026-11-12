import Foundation
import Testing
@testable import DwellCore

@Suite("Your places")
struct PlaceListTests {
    let places = SampleData.places

    private func names(_ places: [Place]) -> [String] {
        places.map(\.name)
    }

    @Test func `most time comes first by default`() {
        let all = PlaceQuery().sections(places).last
        #expect(all?.kind == .all)
        #expect(names(Array(all?.places.prefix(3) ?? [])) == ["Home", "Kestriva Labs", "Northline Gym"])
        #expect(all?.places.count == places.count)
    }

    @Test func `favourites come first and are also in all places`() {
        let sections = PlaceQuery().sections(places)
        #expect(sections.map(\.kind) == [.favorites, .all])
        #expect(names(sections[0].places) == ["Home", "Kestriva Labs", "Brambleline Café"])
        #expect(sections[1].places.contains { $0.id == "kestriva" })
    }

    @Test func `no favourites means no favourites section`() {
        let unstarred = places.map { place -> Place in
            var place = place
            place.isFavorite = false
            return place
        }
        #expect(PlaceQuery().sections(unstarred).map(\.kind) == [.all])
    }

    @Test func `the favourites chip keeps only favourites, once`() {
        let sections = PlaceQuery(favoritesOnly: true).sections(places)
        #expect(sections.map(\.kind) == [.favorites])
        #expect(sections[0].places.allSatisfy { $0.isFavorite })
    }

    @Test func `sorts by visits and by name, ties by name`() {
        let byVisits = PlaceQuery(sort: .mostVisits).sorted(places)
        #expect(names(Array(byVisits.prefix(3))) == ["Home", "Brambleline Café", "Kestriva Labs"])
        let byName = PlaceQuery(sort: .name).sorted(places)
        #expect(byName.first?.name == "Ashgrove Library")
        #expect(byName.last?.name == "Tidewater Books")

        let tied = [
            Place(id: "b", name: "Bay", category: .other, lifetimeTotal: 60),
            Place(id: "a", name: "Ash", category: .other, lifetimeTotal: 60),
        ]
        #expect(names(PlaceQuery().sorted(tied)) == ["Ash", "Bay"])
    }

    @Test func `the category chip filters both sections`() {
        let sections = PlaceQuery(category: .foodAndDrink).sections(places)
        #expect(sections.map(\.kind) == [.favorites, .all])
        #expect(names(sections[0].places) == ["Brambleline Café"])
        #expect(names(sections[1].places) == ["Brambleline Café", "Juniper & Vine", "Sorrel Kitchen"])
    }

    @Test func `the category menu offers only categories with places`() {
        let categories = PlaceQuery.categories(in: places)
        #expect(categories.first == .work)
        #expect(categories.contains(.personal))
        #expect(!categories.contains(.travel))
        #expect(!categories.contains(.transit))
    }

    @Test func `search ignores case and accents, and matches categories`() {
        #expect(names(PlaceQuery(search: "  cafe ").sections(places).flatMap(\.places)) == ["Brambleline Café"])
        #expect(PlaceQuery(search: "FOOD").sections(places).first?.places.count == 3)
        #expect(PlaceQuery(search: "zzz").sections(places).isEmpty)
    }

    @Test func `searching shows one list`() {
        #expect(PlaceQuery(search: "k").sections(places).map(\.kind) == [.all])
    }

    @Test func `clearing keeps the sort`() {
        let query = PlaceQuery(search: "x", sort: .name, category: .work, favoritesOnly: true)
        #expect(query.hasFilters)
        #expect(query.cleared == PlaceQuery(sort: .name))
        #expect(!query.cleared.hasFilters)
    }

    @Test func `the header counts every place and its time`() {
        #expect(PlacesCopy.count(places.count) == "14 places")
        #expect(PlacesCopy.count(1) == "1 place")
        #expect(PlacesCopy.mapped(places.totalTime) == "675h mapped")
    }
}

@Suite("Lifetime totals")
struct LifetimeTotalTests {
    @Test func `whole hours from ten hours up, rounded down`() {
        #expect(DurationText.total(186 * 3600 + 59 * 60) == "186h")
        #expect(DurationText.total(10 * 3600) == "10h")
    }

    @Test func `hours and minutes below ten hours`() {
        #expect(DurationText.total(9 * 3600 + 59 * 60) == "9h 59m")
        #expect(DurationText.total(39 * 60) == "39m")
        #expect(DurationText.total(0) == "0m")
    }
}

@Suite("A place's details")
struct PlaceDetailsTests {
    let calendar = SampleData.calendar
    let now = SampleData.now

    @Test func `category and visits`() {
        let details = PlacesCopy.details(for: SampleData.place("kestriva"), now: now, calendar: calendar)
        #expect(details == ["Work", "31 visits"])
    }

    @Test func `home says since when`() {
        let details = PlacesCopy.details(for: SampleData.place("home"), now: now, calendar: calendar)
        #expect(details == ["Since August"])
    }

    @Test func `another year is named`() {
        let lastYear = calendar.date(byAdding: .year, value: -1, to: now)!
        #expect(PlacesCopy.since(lastYear, now: now, calendar: calendar) == "Since October 2025")
    }

    @Test func `one visit, none yet, and private`() {
        #expect(PlacesCopy.details(for: SampleData.place("tidewater"), now: now, calendar: calendar) == ["Shopping", "1 visit"])
        let saved = Place(id: "gym", name: "Northline Gym", category: .fitness, role: .gym)
        #expect(PlacesCopy.details(for: saved, now: now, calendar: calendar) == ["Fitness", "No visits yet"])
        let clinic = PlacesCopy.details(for: SampleData.place("stagnes"), now: now, calendar: calendar)
        #expect(clinic == ["Personal", "3 visits", "Private"])
    }

    @Test func `home without a first visit falls back to visits`() {
        let home = Place(id: "home", name: "Home", category: .home, role: .home, visitCount: 2)
        #expect(PlacesCopy.details(for: home, now: now, calendar: calendar) == ["Home", "2 visits"])
    }
}
