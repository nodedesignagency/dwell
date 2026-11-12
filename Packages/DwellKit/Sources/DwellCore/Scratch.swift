import Foundation

/// A cell the user has uncovered on the scratch map (brief §7.2, §9): its outline and the day
/// it was first uncovered. Neighborhood cells are hexagons about 250 m across.
public struct ScratchCell: Identifiable, Hashable, Sendable {
    public let id: String
    public var level: ScratchLevel
    /// The cell's corners, in order. The outline closes back on the first.
    public var boundary: [Coordinate]
    public var firstUncovered: Date

    public init(id: String, level: ScratchLevel, boundary: [Coordinate], firstUncovered: Date) {
        self.id = id
        self.level = level
        self.boundary = boundary
        self.firstUncovered = firstUncovered
    }
}

extension Collection where Element == ScratchCoverage {
    /// The neighborhood level: the city's coverage ("3.2% of Brooklyn"), which You shows as
    /// "3.2% mapped".
    public var city: ScratchCoverage? {
        first { $0.level == .neighborhood }
    }
}

/// Coverage written as a share: "3.2%".
public enum CoverageText {
    /// One decimal, rounded down so Dwell never claims ground it hasn't covered; a whole
    /// number drops the decimal ("5%"). Something uncovered but under 0.1% reads "<0.1%",
    /// never "0%".
    public static func percent(_ fraction: Double, locale: Locale = .current) -> String {
        guard fraction > 0 else { return "0%" }
        // A hair over, so 0.29 × 1000 = 289.999… still reads 29%.
        let tenths = (min(fraction, 1) * 1000 + 1e-9).rounded(.down)
        guard tenths >= 1 else { return "<\(0.1.formatted(.number.locale(locale)))%" }
        let percent = tenths / 10
        return "\(percent.formatted(.number.precision(.fractionLength(0...1)).locale(locale)))%"
    }
}
