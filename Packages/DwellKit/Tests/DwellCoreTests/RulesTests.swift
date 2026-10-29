import Foundation
import Testing
@testable import DwellCore

private func calendar(_ zone: String) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: zone)!
    return calendar
}

private func date(_ calendar: Calendar, _ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

@Suite("The day runs 4 AM to 4 AM")
struct DayBoundaryTests {
    let newYork = calendar("America/New_York")

    @Test func `3:59 AM still belongs to yesterday`() {
        let day = DwellDay(containing: date(newYork, 2026, 10, 27, 3, 59), calendar: newYork)
        #expect(day == DwellDay(year: 2026, month: 10, day: 26))
    }

    @Test func `4:00 AM starts a new day`() {
        let day = DwellDay(containing: date(newYork, 2026, 10, 27, 4, 0), calendar: newYork)
        #expect(day == DwellDay(year: 2026, month: 10, day: 27))
    }

    @Test func `a normal day is 24 hours`() {
        let interval = DwellDay(year: 2026, month: 10, day: 26).interval(in: newYork)
        #expect(interval.duration == 24 * 3600)
        #expect(interval.start == date(newYork, 2026, 10, 26, 4))
    }

    /// Clocks change at 2–3 AM, before the 4 AM boundary, so the long or short night
    /// belongs to the Dwell day that started the morning before.
    static let daylightSavingDays: [(zone: String, day: DwellDay, hours: Int)] = [
        ("America/New_York", DwellDay(year: 2026, month: 10, day: 31), 25),
        ("America/New_York", DwellDay(year: 2026, month: 11, day: 1), 24),
        ("America/New_York", DwellDay(year: 2026, month: 3, day: 7), 23),
        ("Europe/Rome", DwellDay(year: 2026, month: 10, day: 24), 25),
        ("Europe/Rome", DwellDay(year: 2026, month: 3, day: 28), 23),
    ]

    @Test(arguments: daylightSavingDays)
    func `the night the clocks change makes a 23 or 25 hour day`(zone: String, day: DwellDay, hours: Int) {
        #expect(day.interval(in: calendar(zone)).duration == TimeInterval(hours * 3600))
    }

    @Test func `adding days crosses months`() {
        let day = DwellDay(year: 2026, month: 10, day: 31).adding(days: 1, in: newYork)
        #expect(day == DwellDay(year: 2026, month: 11, day: 1))
    }
}

@Suite("Durations read like 9h 32m")
struct DurationTextTests {
    static let cases: [(seconds: TimeInterval, text: String)] = [
        (0, "0m"),
        (-5, "0m"),
        (30, "<1m"),
        (3599, "59m"),
        (3600, "1h"),
        (34_320, "9h 32m"),
        (36_779, "10h 12m"),
        (450_000, "125h"),
    ]

    @Test(arguments: cases)
    func formats(seconds: TimeInterval, expected: String) {
        #expect(DurationText.short(seconds) == expected)
    }
}

@Suite("The dial changes sentences, never numbers")
struct DialTests {
    let line = VoicedLine(peace: "P", plain: "N", grind: "G")

    @Test func `position is clamped`() {
        #expect(Dial(position: -20).position == 0)
        #expect(Dial(position: 140).position == 100)
    }

    static let stops: [(position: Double, stop: Dial.Stop)] = [
        (0, .peace), (12, .peace), (20, .calm), (49, .plain), (63, .push), (88, .grind), (100, .grind),
    ]

    @Test(arguments: stops)
    func `snaps to the nearest named stop`(position: Double, stop: Dial.Stop) {
        #expect(Dial(position: position).stop == stop)
    }

    @Test func `calm and push borrow the outer anchor when they have no line of their own`() {
        #expect(line.text(at: .peace) == "P")
        #expect(line.text(at: .calm) == "P")
        #expect(line.text(at: .plain) == "N")
        #expect(line.text(at: .push) == "G")
        #expect(line.text(at: .grind) == "G")
    }

    @Test func `calm and push use their own line when written`() {
        let written = VoicedLine(peace: "P", calm: "C", plain: "N", push: "U", grind: "G")
        #expect(written.text(at: .calm) == "C")
        #expect(written.text(at: .push) == "U")
    }

    @Test func `encodes as a plain number`() throws {
        let data = try JSONEncoder().encode(Dial(position: 62.5))
        #expect(String(decoding: data, as: UTF8.self) == "62.5")
        #expect(try JSONDecoder().decode(Dial.self, from: Data("400".utf8)).position == 100)
    }
}

@Suite("Charts show seven categories plus Everything else")
struct ChartFoldTests {
    @Test func `seven or fewer stay as they are, largest first`() {
        let slices = ChartSlice.fold([.home: 100, .work: 300, .fitness: 50, .other: 0])
        #expect(slices.map(\.bucket) == [.category(.work), .category(.home), .category(.fitness)])
    }

    @Test func `the rest folds into Everything else, never Other`() {
        var totals: [PlaceCategory: TimeInterval] = [:]
        for (index, category) in PlaceCategory.allCases.enumerated() {
            totals[category] = TimeInterval(100 - index)
        }
        let slices = ChartSlice.fold(totals)
        #expect(slices.count == 8)
        #expect(slices.last?.bucket == .everythingElse)
        #expect(slices.last?.bucket.name == "Everything else")
        #expect(slices.reduce(0) { $0 + $1.total } == totals.values.reduce(0, +))
        #expect(ChartBucket.category(.other).name == "Other")
    }
}

@Suite("One permission banner at a time")
struct PermissionTests {
    @Test func `location outranks everything`() {
        #expect(Permissions(location: .denied, isPreciseLocationOn: false, motion: .denied).banner == .locationDenied)
    }

    @Test func `then When-In-Use, then precise, then motion`() {
        #expect(Permissions(location: .whenInUse, isPreciseLocationOn: false, motion: .denied).banner == .whenInUseOnly)
        #expect(Permissions(location: .always, isPreciseLocationOn: false, motion: .denied).banner == .preciseOff)
        #expect(Permissions(location: .always, isPreciseLocationOn: true, motion: .denied).banner == .motionDenied)
        #expect(Permissions.full.banner == nil)
    }
}

@Suite("Privacy on shared surfaces")
struct SharePolicyTests {
    @Test func `home is only ever Home`() {
        let home = Place(id: "h", name: "14 Clinton St", category: .home, role: .home, shareLevel: .venue)
        #expect(SharePolicy.label(for: home) == "Home")
    }

    @Test func `private and personal places never appear`() {
        #expect(SharePolicy.label(for: Place(id: "p", name: "Clinic", category: .personal, shareLevel: .venue)) == nil)
        #expect(SharePolicy.label(for: Place(id: "q", name: "Bar", category: .social, shareLevel: .venue, isPrivate: true)) == nil)
    }

    @Test func `venue names only with venue-level sharing`() {
        let cafe = Place(id: "c", name: "Brambleline Café", category: .foodAndDrink, shareLevel: .category)
        #expect(SharePolicy.label(for: cafe) == "Food & drink")
        var venue = cafe
        venue.shareLevel = .venue
        #expect(SharePolicy.label(for: venue) == "Brambleline Café")
    }

    @Test func `scratch shares stop at city level`() {
        #expect(!ScratchLevel.neighborhood.isShareable)
        #expect(ScratchLevel.city.isShareable)
        #expect(ScratchLevel.country.isShareable)
    }
}

@Suite("Never celebrate more than 12 hours of work")
struct WorkCeilingTests {
    @Test func ceiling() {
        #expect(WorkCeiling.isCelebratable(12 * 3600))
        #expect(!WorkCeiling.isCelebratable(12 * 3600 + 60))
        #expect(WorkCeiling.rankValue(14 * 3600) == 12 * 3600)
        #expect(WorkCeiling.isCapped(13 * 3600))
    }
}
