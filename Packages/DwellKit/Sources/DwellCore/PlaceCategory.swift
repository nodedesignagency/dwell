import Foundation

/// The fixed category set (brief §9). Case order is the display order.
///
/// Health and religious places fold into `personal` on the device. Colour is never
/// the only carrier of a category: each one also has a name and an icon.
///
/// Named `PlaceCategory` rather than `Category` because the Objective-C runtime
/// already exports a `Category` type on Apple platforms.
public enum PlaceCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case work
    case home
    case foodAndDrink
    case shopping
    case fitness
    case errands
    case social
    case entertainment
    case outdoors
    case education
    case transit
    case travel
    case personal
    case other

    public var id: Self { self }

    /// Display name, sentence case.
    public var name: String {
        switch self {
        case .work: "Work"
        case .home: "Home"
        case .foodAndDrink: "Food & drink"
        case .shopping: "Shopping"
        case .fitness: "Fitness"
        case .errands: "Errands"
        case .social: "Social"
        case .entertainment: "Entertainment"
        case .outdoors: "Outdoors"
        case .education: "Education"
        case .transit: "Transit"
        case .travel: "Travel"
        case .personal: "Personal"
        case .other: "Other"
        }
    }
}

/// One slice of a chart: a named category, or the fold bucket.
///
/// Charts show at most seven named categories plus a bucket called "Everything else",
/// never "Other", which is a real category (brief §11).
public enum ChartBucket: Hashable, Sendable, Identifiable {
    case category(PlaceCategory)
    case everythingElse

    public static let maxNamedCategories = 7

    public var id: String {
        switch self {
        case .category(let category): category.rawValue
        case .everythingElse: "everythingElse"
        }
    }

    public var name: String {
        switch self {
        case .category(let category): category.name
        case .everythingElse: "Everything else"
        }
    }
}

public struct ChartSlice: Hashable, Sendable, Identifiable {
    public var bucket: ChartBucket
    public var total: TimeInterval

    public var id: String { bucket.id }

    public init(bucket: ChartBucket, total: TimeInterval) {
        self.bucket = bucket
        self.total = total
    }
}

extension ChartSlice {
    /// Largest categories first, at most `maxNamed` of them, the rest folded into
    /// "Everything else". Empty categories are dropped. Ties keep the category order.
    public static func fold(
        _ totals: [PlaceCategory: TimeInterval],
        maxNamed: Int = ChartBucket.maxNamedCategories
    ) -> [ChartSlice] {
        let ranked = PlaceCategory.allCases
            .compactMap { category -> ChartSlice? in
                guard let total = totals[category], total > 0 else { return nil }
                return ChartSlice(bucket: .category(category), total: total)
            }
            .enumerated()
            .sorted { ($0.element.total, -$0.offset) > ($1.element.total, -$1.offset) }
            .map(\.element)

        var slices = Array(ranked.prefix(maxNamed))
        let folded = ranked.dropFirst(maxNamed).reduce(0) { $0 + $1.total }
        if folded > 0 {
            slices.append(ChartSlice(bucket: .everythingElse, total: folded))
        }
        return slices
    }
}
