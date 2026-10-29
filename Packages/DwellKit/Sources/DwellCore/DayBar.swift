import Foundation

/// Today's day bar (brief §7.1): the day so far by category, drawn as a strip of equal ticks.
///
/// Categories run in display order, at most seven plus "Everything else", and the unmapped
/// time comes last. The bar covers 4:00 AM to now, or the whole day once it is over.
public struct DayBar: Hashable, Sendable {
    public enum Segment: Hashable, Sendable, Identifiable {
        case bucket(ChartBucket)
        /// Time inside the day with no record: gaps ("Dwell was asleep"), and any stretch with
        /// no entry at all. Never folded into a category, never hidden.
        ///
        /// Open question (docs/QUESTIONS.md): the design labels this "Unmapped"; we read it as
        /// gaps only, not the part of the day still to come.
        case unmapped

        public var id: String {
            switch self {
            case .bucket(let bucket): bucket.id
            case .unmapped: "unmapped"
            }
        }

        public var name: String {
            switch self {
            case .bucket(let bucket): bucket.name
            case .unmapped: "Unmapped"
            }
        }
    }

    public struct Part: Hashable, Sendable, Identifiable {
        public var segment: Segment
        public var duration: TimeInterval

        public var id: String { segment.id }

        public init(segment: Segment, duration: TimeInterval) {
            self.segment = segment
            self.duration = duration
        }
    }

    public var parts: [Part]

    public init(parts: [Part]) {
        self.parts = parts
    }

    public init(snapshot: DaySnapshot, now: Date) {
        let order = Dictionary(uniqueKeysWithValues: PlaceCategory.allCases.enumerated().map { ($1, $0) })
        let slices = ChartSlice.fold(snapshot.totals(now: now)).sorted { lhs, rhs in
            Self.rank(lhs.bucket, order) < Self.rank(rhs.bucket, order)
        }
        var parts = slices.map { Part(segment: .bucket($0.bucket), duration: $0.total) }
        let unmapped = snapshot.recap(now: now).unmapped
        if unmapped >= 60 {
            parts.append(Part(segment: .unmapped, duration: unmapped))
        }
        self.init(parts: parts)
    }

    public var total: TimeInterval {
        parts.reduce(0) { $0 + $1.duration }
    }

    /// The bar split into `count` equal ticks, each naming the segment it belongs to.
    ///
    /// Shares are rounded by largest remainder, and every part gets at least one tick while
    /// there are enough to go round, so a short stop is never rounded away.
    public func ticks(_ count: Int) -> [Segment] {
        guard count > 0, total > 0 else { return [] }
        let exact = parts.map { $0.duration / total * Double(count) }
        let minimum = parts.count <= count ? 1 : 0
        var counts = exact.map { max(minimum, Int($0.rounded(.down))) }
        var sum = counts.reduce(0, +)
        while sum < count, let index = counts.indices.max(by: { exact[$0] - Double(counts[$0]) < exact[$1] - Double(counts[$1]) }) {
            counts[index] += 1
            sum += 1
        }
        while sum > count, let index = counts.indices.filter({ counts[$0] > minimum }).max(by: { Double(counts[$0]) - exact[$0] < Double(counts[$1]) - exact[$1] }) {
            counts[index] -= 1
            sum -= 1
        }
        return zip(parts, counts).flatMap { part, ticks in Array(repeating: part.segment, count: ticks) }
    }

    private static func rank(_ bucket: ChartBucket, _ order: [PlaceCategory: Int]) -> Int {
        switch bucket {
        case .category(let category): order[category] ?? .max
        case .everythingElse: .max
        }
    }
}
