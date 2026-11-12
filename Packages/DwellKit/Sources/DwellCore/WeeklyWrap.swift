import Foundation

/// Last week, wrapped (brief §3.1 day 7, §10, S-06): Monday to Sunday, ready from Sunday at
/// 6 PM. Today invites the user in ("It's time for your weekly wrap-up") until they've
/// opened it.
public struct WeeklyWrap: Identifiable, Hashable, Sendable {
    public var firstDay: DwellDay
    public var lastDay: DwellDay
    public var isOpened: Bool

    public var id: DwellDay { firstDay }

    public init(firstDay: DwellDay, lastDay: DwellDay, isOpened: Bool) {
        self.firstDay = firstDay
        self.lastDay = lastDay
        self.isOpened = isOpened
    }
}
