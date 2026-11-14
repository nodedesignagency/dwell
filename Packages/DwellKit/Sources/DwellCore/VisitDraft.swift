import Foundation

/// The visit edit sheet's changes to one visit, held until Save (brief §7.1: "Long-press to
/// edit (relabel, split, merge, private, WFH, delete)", A.7; Visit Edit design, 14 Nov).
///
/// The sheet edits this copy; nothing reaches the engine until Save. Every rule lives here, so
/// the sheet, its live numbers and Today after Save agree:
/// - times move in 5-minute steps, and a visit is never shorter than a stop (5 minutes);
/// - a visit stretches over the transit and gaps beside it, never over another visit;
/// - only a visit at home can count as work from home ("Count as Work, shown as home");
/// - a split leaves two visits at the same place, each a stop long at least;
/// - a merge runs the visit on through the next visit's departure; the next visit, and the
///   transit or gap between them, go;
/// - a place picked for it (the place picker) replaces its place, and the visit no longer
///   waits for review.
///
/// Ends outside the day (a night at home that began yesterday) stay where they are: the sheet
/// edits the part of the visit inside the day it was opened from.
public struct VisitDraft: Hashable, Sendable {
    /// What else Save does to the visit's shape. One at a time.
    public enum Change: Hashable, Sendable {
        case none
        /// Two visits at the same place, the second from this time.
        case split(at: Date)
        /// One visit through the next visit's departure.
        case mergeWithNext
    }

    /// The shortest stop Dwell records (Getting started: "A wait of 5 minutes counts as a place").
    public static let minimumStop: TimeInterval = 5 * 60
    /// Times move in steps of this much.
    public static let step: TimeInterval = 5 * 60

    public let original: Visit
    /// The visit's place: its own, or the one picked for it.
    public private(set) var placeID: PlaceID?
    public private(set) var placeName: String
    /// What the visit counts as when it isn't work from home: its place's category.
    public private(set) var placeCategory: PlaceCategory
    public private(set) var placeSubcategory: PlaceSubcategory?
    /// Work from home needs home (brief A.2: "Working from home today?").
    public private(set) var isAtHome: Bool
    /// Private and personal places never go on a map, this sheet's included (brief §7.2).
    public private(set) var isHiddenFromMaps: Bool
    /// Where the place is, for the map; `nil` until the engine says.
    public private(set) var coordinate: Coordinate?

    public var arrival: Date
    /// `nil` while the visit is still going.
    public var departure: Date?
    public var isWorkFromHome: Bool
    public var isPrivate: Bool
    public var change: Change

    /// - Parameter place: the visit's place, when it has one; a visit waiting for "Review this
    ///   place" has none and keeps its own category.
    public init(visit: Visit, place: Place?) {
        original = visit
        placeID = visit.placeID
        placeName = visit.placeName
        if let place {
            placeCategory = place.category
            placeSubcategory = place.subcategory
            isAtHome = place.role == .home || place.category == .home
            isHiddenFromMaps = place.isHiddenFromMaps
            coordinate = place.coordinate
        } else {
            placeCategory = visit.isWorkFromHome ? .home : visit.category
            placeSubcategory = visit.subcategory
            isAtHome = visit.isWorkFromHome || visit.category == .home
            isHiddenFromMaps = visit.isPrivate || visit.category == .personal
            coordinate = nil
        }
        arrival = visit.arrival
        departure = visit.departure
        isWorkFromHome = visit.isWorkFromHome
        isPrivate = visit.isPrivate
        change = .none
    }

    /// Work from home counts as work and is shown as home; away from home it can't be.
    public var category: PlaceCategory {
        isWorkFromHome && isAtHome ? .work : placeCategory
    }

    /// Whether Save would change anything.
    public var hasChanges: Bool {
        arrival != original.arrival || departure != original.departure
            || isWorkFromHome != original.isWorkFromHome || isPrivate != original.isPrivate
            || change != .none || hasNewPlace
    }

    /// A place was picked that isn't the one the visit had.
    public var hasNewPlace: Bool {
        placeID != original.placeID || placeName != original.placeName
    }

    /// The place picker's choice becomes the visit's place.
    public mutating func choose(_ candidate: PlaceCandidate) {
        placeID = candidate.placeID
        placeName = candidate.name
        placeCategory = candidate.category
        placeSubcategory = candidate.subcategory
        isAtHome = candidate.isHome
        isHiddenFromMaps = candidate.isHiddenFromMaps
        coordinate = candidate.coordinate
    }

    public var isOngoing: Bool { departure == nil }

    // MARK: The visit's span

    /// Where the visit ends as the sheet stands: the next visit's departure once merged; `now`
    /// while it's still going.
    public func end(in snapshot: DaySnapshot, now: Date) -> Date {
        if change == .mergeWithNext, let next = nextVisit(in: snapshot) {
            return max(arrival, next.departure ?? now)
        }
        return max(arrival, departure ?? now)
    }

    /// Whether the visit runs on to now, merged into a visit still going included.
    public func endsNow(in snapshot: DaySnapshot) -> Bool {
        if change == .mergeWithNext, let next = nextVisit(in: snapshot) {
            return next.isOngoing
        }
        return isOngoing
    }

    public func duration(in snapshot: DaySnapshot, now: Date) -> TimeInterval {
        end(in: snapshot, now: now).timeIntervalSince(arrival)
    }

    /// How far the visit can stretch: back to the end of the visit before it and on to the
    /// start of the visit after it, inside the day and never past now. An end already outside
    /// the day stays put, so the range keeps it.
    public func limits(in snapshot: DaySnapshot, now: Date) -> DateInterval {
        let visits = snapshot.entries.compactMap(\.visit)
        let index = visits.firstIndex { $0.id == original.id }
        let previousEnd = index.flatMap { $0 > 0 ? visits[$0 - 1].interval(now: now).end : nil }
        let nextStart = index.flatMap { $0 + 1 < visits.count ? visits[$0 + 1].arrival : nil }
        var lower = max(previousEnd ?? snapshot.interval.start, snapshot.interval.start)
        var upper = min(nextStart ?? snapshot.interval.end, snapshot.interval.end, now)
        lower = min(lower, original.arrival)
        upper = max(upper, original.departure ?? now)
        return DateInterval(start: lower, end: max(lower, upper))
    }

    /// Whether the arrival can be dragged: not when the visit began before the day did.
    public func canMoveArrival(in snapshot: DaySnapshot) -> Bool {
        original.arrival >= snapshot.interval.start
    }

    /// Whether the departure can be dragged: not while the visit is still going, once merged,
    /// or when it ends after the day does.
    public func canMoveDeparture(in snapshot: DaySnapshot) -> Bool {
        guard let departure = original.departure, change != .mergeWithNext else { return false }
        return departure <= snapshot.interval.end
    }

    /// Moves the arrival to the nearest 5-minute mark, keeping a stop's length before the end
    /// and staying inside `limits`.
    public mutating func moveArrival(to date: Date, in snapshot: DaySnapshot, now: Date) {
        guard canMoveArrival(in: snapshot) else { return }
        let limits = limits(in: snapshot, now: now)
        let latest = end(in: snapshot, now: now).addingTimeInterval(-Self.minimumStop - splitRoom)
        arrival = Self.clamp(Self.rounded(date), min(limits.start, latest), latest)
        keepSplitInside(snapshot: snapshot, now: now)
    }

    /// Moves the departure to the nearest 5-minute mark, keeping a stop's length after the
    /// arrival and staying inside `limits`.
    public mutating func moveDeparture(to date: Date, in snapshot: DaySnapshot, now: Date) {
        guard canMoveDeparture(in: snapshot) else { return }
        let limits = limits(in: snapshot, now: now)
        let earliest = arrival.addingTimeInterval(Self.minimumStop + splitRoom)
        departure = Self.clamp(Self.rounded(date), earliest, max(limits.end, earliest))
        keepSplitInside(snapshot: snapshot, now: now)
    }

    // MARK: Split and merge

    /// The visit after this one in the day, if any: what "Merge with next visit" joins.
    public func nextVisit(in snapshot: DaySnapshot) -> Visit? {
        let visits = snapshot.entries.compactMap(\.visit)
        guard let index = visits.firstIndex(where: { $0.id == original.id }), index + 1 < visits.count else { return nil }
        return visits[index + 1]
    }

    public func canMerge(in snapshot: DaySnapshot) -> Bool {
        nextVisit(in: snapshot) != nil
    }

    /// Two stops' worth: each part of a split is a stop long at least.
    public func canSplit(in snapshot: DaySnapshot, now: Date) -> Bool {
        duration(in: snapshot, now: now) >= 2 * Self.minimumStop
    }

    /// Where a new split starts: the middle of the visit, on a 5-minute mark.
    public func middle(in snapshot: DaySnapshot, now: Date) -> Date {
        let end = end(in: snapshot, now: now)
        return splitClamp(Self.rounded(arrival.addingTimeInterval(end.timeIntervalSince(arrival) / 2)), end: end)
    }

    /// Turns the split on at the middle, or off. A split replaces a merge.
    public mutating func toggleSplit(in snapshot: DaySnapshot, now: Date) {
        if case .split = change {
            change = .none
            return
        }
        // Measured on the visit without any merge.
        var unmerged = self
        unmerged.change = .none
        guard unmerged.canSplit(in: snapshot, now: now) else { return }
        change = .split(at: unmerged.middle(in: snapshot, now: now))
    }

    /// Turns the merge on, or off. A merge replaces a split, and the departure goes back to
    /// where it was: the visit now ends where the next one did.
    public mutating func toggleMerge(in snapshot: DaySnapshot) {
        if change == .mergeWithNext {
            change = .none
        } else if canMerge(in: snapshot) {
            departure = original.departure
            change = .mergeWithNext
        }
    }

    /// Moves the split to the nearest 5-minute mark, a stop's length from either end.
    public mutating func moveSplit(to date: Date, in snapshot: DaySnapshot, now: Date) {
        guard case .split = change else { return }
        change = .split(at: splitClamp(Self.rounded(date), end: end(in: snapshot, now: now)))
    }

    public var splitTime: Date? {
        if case .split(let at) = change { at } else { nil }
    }

    /// Room a split needs left inside the visit when an end moves.
    private var splitRoom: TimeInterval {
        splitTime == nil ? 0 : Self.minimumStop
    }

    private mutating func keepSplitInside(snapshot: DaySnapshot, now: Date) {
        guard let at = splitTime else { return }
        change = .split(at: splitClamp(at, end: end(in: snapshot, now: now)))
    }

    private func splitClamp(_ date: Date, end: Date) -> Date {
        let earliest = arrival.addingTimeInterval(Self.minimumStop)
        return Self.clamp(date, earliest, max(earliest, end.addingTimeInterval(-Self.minimumStop)))
    }

    // MARK: Saving

    /// The visit or visits Save leaves in the day: one, or two once split.
    public func visits(in snapshot: DaySnapshot) -> [Visit] {
        var visit = original
        visit.placeID = placeID
        visit.placeName = placeName
        if hasNewPlace {
            // Picked by the user: nothing left to review.
            visit.needsReview = false
        }
        visit.arrival = arrival
        visit.departure = departure
        visit.isWorkFromHome = isWorkFromHome && isAtHome
        visit.isPrivate = isPrivate
        visit.category = isWorkFromHome && isAtHome ? .work : placeCategory
        visit.subcategory = visit.isWorkFromHome ? nil : placeSubcategory
        switch change {
        case .none:
            return [visit]
        case .mergeWithNext:
            if let next = nextVisit(in: snapshot) {
                visit.departure = next.departure
            }
            return [visit]
        case .split(let at):
            var first = visit
            first.departure = at
            let second = Visit(
                id: VisitID("\(original.id.rawValue)-split"),
                placeID: visit.placeID, placeName: visit.placeName, category: visit.category,
                subcategory: visit.subcategory, arrival: at, departure: visit.departure,
                precision: visit.precision, isPrivate: visit.isPrivate,
                isWorkFromHome: visit.isWorkFromHome, needsReview: visit.needsReview)
            return [first, second]
        }
    }

    // MARK: Helpers

    /// The nearest 5-minute mark on the clock.
    static func rounded(_ date: Date) -> Date {
        let seconds = date.timeIntervalSinceReferenceDate
        return Date(timeIntervalSinceReferenceDate: (seconds / step).rounded() * step)
    }

    static func clamp(_ date: Date, _ low: Date, _ high: Date) -> Date {
        min(max(date, low), max(low, high))
    }
}

/// What the user saved this session, for Today to show before the engine reflects it.
public enum VisitChange: Hashable, Sendable {
    case saved(VisitDraft)
    case deleted(VisitID)
}

extension DaySnapshot {
    /// The day as the draft would leave it: the visit (or its two parts) in place, the next
    /// visit gone once merged, and the transit and gaps it now covers cut back or gone. Time
    /// the visit gives up is left with no entry at all, so it counts as unmapped: Dwell didn't
    /// see anything else there.
    public func applying(_ draft: VisitDraft) -> DaySnapshot {
        guard entries.contains(where: { $0.visit?.id == draft.original.id }) else { return self }
        let edited = draft.visits(in: self)
        var removed: Set<VisitID> = [draft.original.id]
        if draft.change == .mergeWithNext, let next = draft.nextVisit(in: self) {
            removed.insert(next.id)
        }
        let start = draft.arrival
        let end = edited.last?.departure ?? .distantFuture

        var kept: [TimelineEntry] = []
        for entry in entries {
            switch entry {
            case .visit(let visit):
                if removed.contains(visit.id) { continue }
                kept.append(entry)
            case .transit(let interval):
                kept += Self.outside(interval, start: start, end: end).map { .transit($0) }
            case .gap(let interval):
                kept += Self.outside(interval, start: start, end: end).map { .gap($0) }
            }
        }
        kept += edited.map { .visit($0) }
        var snapshot = self
        snapshot.entries = kept.sorted { Self.start(of: $0) < Self.start(of: $1) }
        return snapshot
    }

    /// The day without this visit: its time counts toward nothing.
    public func removingVisit(_ id: VisitID) -> DaySnapshot {
        var snapshot = self
        snapshot.entries = entries.filter { $0.visit?.id != id }
        return snapshot
    }

    /// The day with this session's saves and deletes, in order.
    public func applying(_ changes: [VisitChange]) -> DaySnapshot {
        changes.reduce(self) { snapshot, change in
            switch change {
            case .saved(let draft): snapshot.applying(draft)
            case .deleted(let id): snapshot.removingVisit(id)
            }
        }
    }

    /// The parts of a stretch before and after a visit.
    private static func outside(_ interval: DateInterval, start: Date, end: Date) -> [DateInterval] {
        var parts: [DateInterval] = []
        if interval.start < start {
            parts.append(DateInterval(start: interval.start, end: min(interval.end, start)))
        }
        if interval.end > end {
            parts.append(DateInterval(start: max(interval.start, end), end: interval.end))
        }
        return parts.filter { $0.duration > 0 }
    }

    private static func start(of entry: TimelineEntry) -> Date {
        switch entry {
        case .visit(let visit): visit.arrival
        case .transit(let interval), .gap(let interval): interval.start
        }
    }
}
