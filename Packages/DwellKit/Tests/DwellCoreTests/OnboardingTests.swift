import Foundation
import Testing
@testable import DwellCore

private let calendar = SampleData.calendar

private func placed(_ role: SetupRole, _ address: String = "214 Kent Ave") -> PlaceDraft {
    PlaceDraft(address: address, area: "Brooklyn, NY", coordinate: Coordinate(latitude: 40.71, longitude: -73.96), role: role)
}

@Suite("Onboarding: the pages")
struct OnboardingPageTests {
    @Test func `four pages, in the design's order`() {
        #expect(OnboardingPage.allCases == [.myWorld, .yourPlaces, .seeWhereItGoes, .startMyDay])
        #expect(OnboardingPage.myWorld.previous == nil)
        #expect(OnboardingPage.myWorld.next == .yourPlaces)
        #expect(OnboardingPage.startMyDay.next == nil)
        #expect(OnboardingCopy.pageLabel(.seeWhereItGoes) == "Page 3 of 4")
    }
}

@Suite("Onboarding: Your places")
struct PlaceSetupTests {
    @Test func `the first place starts as home, the next as work, then Other`() {
        var setup = PlaceSetup()
        #expect(setup.current.role == .home)
        setup.current = placed(.home)
        setup.addMore()
        #expect(setup.current.role == .work)
        setup.current = placed(.work, "88 Water St")
        setup.addMore()
        #expect(setup.current.role == .other)
    }

    @Test func `a role picked out of order still leads to the one not taken`() {
        var setup = PlaceSetup()
        setup.current = placed(.work)
        setup.addMore()
        #expect(setup.current.role == .home)
    }

    @Test func `add more waits for an address placed on the map`() {
        var setup = PlaceSetup()
        #expect(!setup.canAddMore)
        // Typed words alone don't place it.
        setup.current.address = "214 Kent"
        #expect(!setup.canAddMore)
        setup.addMore()
        #expect(setup.added.isEmpty)
        setup.current = placed(.home)
        #expect(setup.canAddMore)
    }

    @Test func `continue saves the places added and the one being entered once it's placed`() {
        var setup = PlaceSetup()
        #expect(setup.places.isEmpty)
        setup.current = placed(.home)
        #expect(setup.places.map(\.role) == [.home])
        setup.addMore()
        // The new, empty entry isn't saved.
        #expect(setup.places.map(\.role) == [.home])
        setup.current = placed(.other, "Brambleline Café")
        #expect(setup.places.map(\.role) == [.home, .other])
    }

    @Test func `a place can come out of the list`() {
        var setup = PlaceSetup()
        setup.current = placed(.home)
        setup.addMore()
        let home = setup.added[0]
        setup.remove(home.id)
        #expect(setup.added.isEmpty)
        #expect(setup.places.isEmpty)
    }

    @Test func `a spot picked on the map gets its words, even once it's in the list`() {
        var setup = PlaceSetup()
        setup.current = placed(.home, "Finding the address…")
        let home = setup.current.id
        setup.addMore()
        setup.name(home, address: "214 Kent Ave", area: "Brooklyn, NY")
        #expect(setup.added[0].address == "214 Kent Ave")
        #expect(setup.added[0].area == "Brooklyn, NY")
        // An id that's gone changes nothing.
        setup.name(UUID(), address: "Elsewhere", area: nil)
        #expect(setup.places.map(\.address) == ["214 Kent Ave"])
    }

    @Test func `home and work are named by role, Other by its address`() {
        #expect(placed(.home).name == "Home")
        #expect(placed(.work).name == "Work")
        #expect(placed(.other, "Brambleline Café").name == "Brambleline Café")
        #expect(SetupRole.home.placeRole == .home)
        #expect(SetupRole.other.placeRole == nil)
        #expect(SetupRole.other.category == .other)
    }

    @Test func `the sample keeps its own places`() async throws {
        try await SampleRepository().savePlaces([placed(.home)])
        #expect(try await SampleRepository().places() == SampleData.places)
    }
}

@Suite("Onboarding: the example world")
struct OnboardingExampleTests {
    @Test func `the example places are the sample's, with their time on one day`() {
        #expect(OnboardingExample.mapSpots.map(\.name) == ["Mara's place", "Brambleline Café"])
        #expect(OnboardingExample.daySpots.map(\.name) == ["Mara's place", "Home", "Brambleline Café"])
        let times = Dictionary(uniqueKeysWithValues: OnboardingExample.daySpots.map { ($0.photo, $0.time) })
        // Friday 23 October in the sample: home 16h 50m, Mara's place 4h 43m, the café 33m.
        #expect(DurationText.short(times[.home] ?? 0) == "16h 50m")
        #expect(DurationText.short(times[.friend] ?? 0) == "4h 43m")
        #expect(DurationText.short(times[.cafe] ?? 0) == "33m")
    }

    @Test func `every page that names a place gives it the same time`() {
        for spot in OnboardingExample.mapSpots {
            #expect(OnboardingExample.daySpots.first { $0.id == spot.id }?.time == spot.time)
        }
    }

    @Test func `no example place is private, personal or kept off maps`() {
        for spot in OnboardingExample.mapSpots + OnboardingExample.daySpots {
            #expect(!SampleData.place(spot.id).isHiddenFromMaps)
            #expect(spot.time > 0)
        }
    }

    @Test func `the example photos land on the map where the design pins them`() {
        // The photo's middle in the design, at 393 × 852: Mara's place (GF's place) by the
        // East River, the café by Bushwick.
        let designed: [OnboardingExample.Spot.Photo: (x: Double, y: Double)] = [.friend: (68, 166.5), .cafe: (291.5, 250)]
        for spot in OnboardingExample.mapSpots {
            let point = OnboardingExample.Map.point(of: spot.coordinate)
            let target = designed[spot.photo]
            #expect(abs(point.x - (target?.x ?? 0)) < 1.5, "\(spot.name) x \(point.x)")
            #expect(abs(point.y - (target?.y ?? 0)) < 1.5, "\(spot.name) y \(point.y)")
        }
        // The region's middle is the screen's middle.
        let region = OnboardingExample.Map.region(width: 393, height: 852)
        let middle = OnboardingExample.Map.point(of: region.center)
        #expect(abs(middle.x - 196.5) < 0.01 && abs(middle.y - 426) < 0.01)
    }

    @Test func `the example week is the sample's last full week`() {
        let week = OnboardingExample.week(calendar: calendar)
        #expect(week.first == SampleData.lastWeek.first)
        #expect(week.last == SampleData.lastWeek.last)
    }
}

@Suite("Onboarding: words")
struct OnboardingCopyTests {
    @Test func `vocabulary: place, visit, never location as a noun for a place, check-in or track`() {
        let lines = OnboardingCopy.allFixedLines + OnboardingCopy.myWorldTitle.allVariants
        for line in lines {
            let lower = line.lowercased()
            #expect(!lower.contains("track"), "\(line)")
            #expect(!lower.contains("check-in"), "\(line)")
            #expect(!line.contains("!"), "\(line)")
        }
        // "Location" names the permission only, on its button.
        #expect(lines.filter { $0.lowercased().contains("location") } == [OnboardingCopy.allowLocation])
    }

    @Test func `sentence case: nothing past the first word is capitalised but names`() {
        let names = ["Dwell", "Brooklyn", "Mara's", "Brambleline", "Café", "Home", "Work", "Other"]
        for line in OnboardingCopy.allFixedLines {
            let words = line.split(separator: " ").dropFirst()
            for word in words where word.first?.isUppercase == true {
                let previous = line.components(separatedBy: " " + word).first ?? ""
                // A new sentence may start with a capital.
                let startsSentence = previous.hasSuffix(".") || previous.hasSuffix(":") || previous.hasSuffix(";")
                #expect(startsSentence || names.contains { word.hasPrefix($0) }, "\(word) in \(line)")
            }
        }
    }

    @Test func `the brief's own lines are kept`() {
        #expect(OnboardingCopy.placesLine.hasSuffix("Saving a place does not record a visit."))
        #expect(OnboardingCopy.startLine == "Dwell records places and times. Never the route between them.")
        #expect(OnboardingCopy.myWorldTitle.plain == "See where your time goes")
        #expect(OnboardingCopy.addMore == "Add more")
    }

    @Test func `the example captions say the places are made up`() {
        #expect(OnboardingCopy.exampleMap().contains("made-up"))
        #expect(OnboardingCopy.examplePhotos().contains("Mara's place, 4h 43m"))
    }
}
