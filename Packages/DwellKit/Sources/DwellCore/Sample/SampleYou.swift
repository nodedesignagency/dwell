import Foundation

// You's part of the sample: Maya's profile, the last seven days of her streaks, and the cells
// she has uncovered in Brooklyn.

extension SampleData {
    /// The middle of Brooklyn (Flatbush), where the design's map sits.
    public static let brooklyn = Coordinate(latitude: 40.6501, longitude: -73.9496)

    public static let profile = Profile(name: "Maya Cooper", username: "maya", city: "Brooklyn", cityCenter: brooklyn)

    /// The 41 neighborhood cells behind the 3.2% (`coverage`): a walk from the middle of
    /// Brooklyn, one 250 m hexagon at a time, as a few months of errands and evenings would make,
    /// up to the start of last week; then last week's one new cell, in Red Hook (`redHookCell`).
    public static let scratchCells: [ScratchCell] = ScratchGrid.walk(
        from: brooklyn,
        cells: (coverage.city?.uncovered ?? 41) - 1,
        since: recordingSince,
        until: lastWeek[0].start(in: calendar)) + [redHookCell]

    /// Last week's only new cell (the weekly wrap's "1 new corner", Today's "Somewhere new: Red
    /// Hook."): Tidewater Books' cell, uncovered by Sunday's first visit there at 12:10 PM.
    public static let redHookCell = ScratchCell(
        id: "cell-red-hook",
        level: .neighborhood,
        boundary: ScratchGrid.hexagon(q: 0, r: 0, around: tidewaterCoordinate),
        firstUncovered: date(month: 10, day: 25, minutes: 12 * 60 + 10),
        neighborhood: "Red Hook")

    /// The seven days ending today, oldest first, marked as given.
    static func lastSevenDays(_ states: [Streak.Mark.State]) -> [Streak.Mark] {
        states.enumerated().map { offset, state in
            Streak.Mark(start: today.adding(days: offset - (states.count - 1), in: calendar), state: state)
        }
    }

    /// The seven weeks ending with this one (Sunday to Saturday, as in the US), oldest first.
    static func lastSevenWeeks(_ states: [Streak.Mark.State]) -> [Streak.Mark] {
        let weekday = calendar.component(.weekday, from: today.start(in: calendar))
        let thisWeek = today.adding(days: -((weekday - calendar.firstWeekday + 7) % 7), in: calendar)
        return states.enumerated().map { offset, state in
            Streak.Mark(start: thisWeek.adding(days: 7 * (offset - (states.count - 1)), in: calendar), state: state)
        }
    }
}

extension SampleData.FirstPlace {
    /// Home's cell, and nothing else yet.
    public static let scratchCells = Array(SampleData.scratchCells.prefix(1))

    public static let coverage: [ScratchCoverage] = SampleData.coverage.map { coverage in
        var coverage = coverage
        coverage.uncovered = 1
        coverage.uncoveredThisWeek = 1
        return coverage
    }
}

/// Flat-topped hexagons on an axial grid, for sample cells only: the engine sends real ones.
enum ScratchGrid {
    /// Centre to corner, in metres: about 250 m from corner to corner.
    static let radius = 125.0
    private static let metresPerDegree = 111_320.0

    /// `cells` distinct cells along a seeded walk from `origin`, each uncovered a little after
    /// the last, between `since` and `until`.
    static func walk(from origin: Coordinate, cells count: Int, since: Date, until: Date) -> [ScratchCell] {
        let neighbours = [(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)]
        var seed: UInt64 = 0x5EED_D1A1
        func next() -> Int {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Int(seed >> 33)
        }
        var visited: [(q: Int, r: Int)] = [(0, 0)]
        var current = (q: 0, r: 0)
        var steps = 0
        while visited.count < count, steps < count * 20 {
            steps += 1
            // Now and then hop back to somewhere already known, so the walk branches.
            if next() % 4 == 0, let back = visited.pick(using: next) {
                current = back
            }
            let step = neighbours[next() % neighbours.count]
            current = (current.q + step.0, current.r + step.1)
            if !visited.contains(where: { $0 == current }) {
                visited.append(current)
            }
        }
        let span = until.timeIntervalSince(since)
        return visited.enumerated().map { index, cell in
            ScratchCell(
                id: "cell-\(cell.q)-\(cell.r)",
                level: .neighborhood,
                boundary: hexagon(q: cell.q, r: cell.r, around: origin),
                firstUncovered: since.addingTimeInterval(span * Double(index) / Double(max(visited.count, 1))))
        }
    }

    /// The six corners of the cell at (q, r).
    static func hexagon(q: Int, r: Int, around origin: Coordinate) -> [Coordinate] {
        let x = radius * 1.5 * Double(q)
        let y = radius * 3.0.squareRoot() * (Double(r) + Double(q) / 2)
        let metresPerLongitude = metresPerDegree * cos(origin.latitude * .pi / 180)
        return (0..<6).map { corner in
            let angle = Double(corner) * .pi / 3
            return Coordinate(
                latitude: origin.latitude + (y + radius * sin(angle)) / metresPerDegree,
                longitude: origin.longitude + (x + radius * cos(angle)) / metresPerLongitude)
        }
    }
}

private extension Array {
    /// A seeded pick, so the sample is the same on every run.
    func pick(using next: () -> Int) -> Element? {
        isEmpty ? nil : self[next() % count]
    }
}
