import DwellCore

/// Everything You shows from the repository. The dial and the notification switches aren't
/// in it: they're the phone's own settings, so they show and work even when this fails to load.
struct YouModel: Equatable {
    var profile: Profile
    var placeCount: Int
    /// The city's coverage at neighborhood level: "3.2% mapped".
    var coverage: ScratchCoverage?
    var cells: [ScratchCell]
    var streaks: [Streak]
    var badges: [Badge]

    var earnedBadges: Int {
        badges.filter(\.isEarned).count
    }

    /// The badges in the grid: earned first, then the closest to unlocking.
    var showcase: [Badge] {
        Badge.showcase(badges)
    }

    /// The streak the card leads with at this stop.
    func featuredStreak(at stop: Dial.Stop) -> Streak? {
        Streak.featured(in: streaks, at: stop)
    }
}

extension YouModel {
    /// The sample week's You (Monday 26 October, 2:47 PM).
    static let sample = YouModel(
        profile: SampleData.profile,
        placeCount: SampleData.places.count,
        coverage: SampleData.coverage.city,
        cells: SampleData.scratchCells,
        streaks: SampleData.streaks,
        badges: SampleData.badges)

    /// The install day before the first stop: nothing counted yet, every badge locked.
    static let firstDay = YouModel(
        profile: SampleData.profile,
        placeCount: 0,
        coverage: SampleData.coverage.city.map { coverage in
            var coverage = coverage
            coverage.uncovered = 0
            return coverage
        },
        cells: [],
        streaks: [],
        badges: Badge.Kind.allCases.map { Badge(kind: $0, tier: nil, progress: 0) })

    /// The install day, minutes after the first place: one place, one cell.
    static let firstPlace = YouModel(
        profile: SampleData.profile,
        placeCount: SampleData.FirstPlace.places.count,
        coverage: SampleData.FirstPlace.coverage.city,
        cells: SampleData.FirstPlace.scratchCells,
        streaks: [],
        badges: Badge.Kind.allCases.map { Badge(kind: $0, tier: nil, progress: 0) })
}
