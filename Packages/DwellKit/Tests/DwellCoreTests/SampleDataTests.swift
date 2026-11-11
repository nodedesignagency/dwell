import Foundation
import Testing
@testable import DwellCore

@Suite("Sample week")
struct SampleDataTests {
    let now = SampleData.now
    let today = SampleData.todaySnapshot

    func work(on day: Int) -> TimeInterval {
        SampleData.snapshot(for: DwellDay(year: 2026, month: 10, day: day)).totals(now: now)[.work] ?? 0
    }

    @Test func `today is Monday 26 October, at Kestriva Labs since 1:31 PM`() throws {
        #expect(SampleData.today == DwellDay(year: 2026, month: 10, day: 26))
        guard case .atPlace(let visit) = SampleData.liveStatus else {
            Issue.record("Expected a live visit")
            return
        }
        #expect(visit.placeName == "Kestriva Labs")
        #expect(DurationText.short(visit.interval(now: now).duration) == "1h 16m")
    }

    @Test func `today's work stops at now`() {
        #expect(DurationText.short(work(on: 26)) == "4h 40m")
    }

    @Test func `Thursday is the 10h 12m record`() {
        #expect(DurationText.short(work(on: 22)) == "10h 12m")
    }

    @Test func `the weekend has zero work`() {
        #expect(work(on: 24) == 0)
        #expect(work(on: 25) == 0)
    }

    @Test func `a gap is counted as a gap, not as time`() {
        let monday = SampleData.snapshot(for: DwellDay(year: 2026, month: 10, day: 19))
        #expect(DurationText.short(monday.gapTotal(now: now)) == "22m")
        #expect(monday.mappedTotal(now: now) + monday.gapTotal(now: now) == monday.interval.duration)
    }

    @Test(arguments: SampleData.lastWeek + [SampleData.today])
    func `entries are in order and never overlap`(day: DwellDay) {
        let entries = SampleData.snapshot(for: day).entries.map { $0.interval(now: now) }
        #expect(!entries.isEmpty)
        for (earlier, later) in zip(entries, entries.dropFirst()) {
            #expect(earlier.end <= later.start)
        }
    }

    @Test func `a night at home is one visit split across two days`() {
        let monday = SampleData.snapshot(for: DwellDay(year: 2026, month: 10, day: 19))
        let tuesday = SampleData.snapshot(for: DwellDay(year: 2026, month: 10, day: 20))
        #expect(monday.entries.last?.id == tuesday.entries.first?.id)
    }

    @Test func `private places stay private`() {
        let clinic = today.entries.compactMap(\.visit).first { $0.placeID == "stagnes" }
        #expect(clinic?.isPrivate == true)
        #expect(SharePolicy.label(for: SampleData.place("stagnes")) == nil)
    }
}

@Suite("Copy rules hold across the dial")
struct CopyRuleTests {
    @Test(arguments: SampleData.insights)
    func `only records may use an exclamation mark`(insight: Insight) {
        guard insight.family != .record else { return }
        #expect(insight.line.allVariants.allSatisfy { !$0.contains("!") })
    }

    @Test(arguments: SampleData.insights)
    func `vocabulary: place, visit, never location, check-in or track`(insight: Insight) {
        for text in insight.line.allVariants.map({ $0.lowercased() }) {
            #expect(!text.contains("location"))
            #expect(!text.contains("check-in"))
            #expect(!text.contains("track"))
        }
    }
}

@Suite("Design tokens")
struct TokenTests {
    /// design/tokens.json must name every category, so no category is ever left without a colour.
    @Test func `tokens cover every category`() throws {
        let url = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appending(path: "../../../../design/tokens.json")
            .standardized
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        let categories = try #require(json?["category"] as? [String: Any])
        #expect(Set(categories.keys) == Set(PlaceCategory.allCases.map(\.rawValue)))
    }

    /// Every sky phase needs its colours, or the generated `SkyPhase.colors` won't compile.
    @Test func `tokens cover every sky`() throws {
        let url = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appending(path: "../../../../design/tokens.json")
            .standardized
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        let sky = try #require(json?["sky"] as? [String: Any])
        #expect(Set(sky.keys.filter { !$0.hasPrefix("_") }) == Set(SkyPhase.allCases.map(\.rawValue)))
    }
}

@Suite("Demo states for the simulator")
struct DemoRepositoryTests {
    @Test func `empty has no visits, no insights and no place yet`() async throws {
        let repository = DemoRepository(.empty)
        #expect(try await repository.day(SampleData.today).entries.isEmpty)
        #expect(try await repository.insights(for: SampleData.today).isEmpty)
        #expect(try await repository.liveStatus() == .unknown)
    }

    @Test func `failed and offline say which`() async {
        await #expect(throws: LoadError(.unavailable)) { try await DemoRepository(.failed).day(SampleData.today) }
        await #expect(throws: LoadError(.offline)) { try await DemoRepository(.offline).liveStatus() }
    }

    @Test func `each banner mode raises its banner`() {
        #expect(DemoRepository.Mode.locationDenied.permissions.banner == .locationDenied)
        #expect(DemoRepository.Mode.whenInUse.permissions.banner == .whenInUseOnly)
        #expect(DemoRepository.Mode.preciseOff.permissions.banner == .preciseOff)
        #expect(DemoRepository.Mode.motionDenied.permissions.banner == .motionDenied)
        #expect(DemoRepository.Mode.transit.permissions.banner == nil)
    }

    @Test func `transit and last seen keep the sample day`() async throws {
        let transit = DemoRepository(.transit)
        #expect(!(try await transit.day(SampleData.today).entries.isEmpty))
        guard case .lastKnown = try await DemoRepository(.lastSeen).liveStatus() else {
            Issue.record("Expected last known")
            return
        }
    }
}
