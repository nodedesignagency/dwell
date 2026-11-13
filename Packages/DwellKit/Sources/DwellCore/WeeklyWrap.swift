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

/// The wrap's first page (Weekly wrap design, "This week."): the week in two numbers.
/// "7 days, 9 places and every hour in between."
public struct WrapOpener: Hashable, Sendable {
    /// Days of the week Dwell was recording: 7 for a whole week, fewer when the first week
    /// started midweek.
    public var days: Int
    /// Different places with at least one visit that week. Private and personal places count:
    /// the wrap is the user's own screen and names none of them.
    public var places: Int
    /// The 3D art that pops out around the title.
    public var stickers: [WrapSticker]

    public init(days: Int, places: Int, stickers: [WrapSticker] = WrapSticker.opener) {
        self.days = days
        self.places = places
        self.stickers = stickers
    }

    /// Counts a week of days, Monday to Sunday. A visit that runs past 4 AM shows in both
    /// days and still counts its place once.
    public init(week: [DaySnapshot]) {
        let recorded = week.filter { snapshot in
            snapshot.recordingSince.map { $0 < snapshot.interval.end } ?? true
        }
        var places = Set<PlaceKey>()
        for snapshot in week {
            for entry in snapshot.entries {
                guard let visit = entry.visit else { continue }
                places.insert(visit.placeID.map(PlaceKey.known) ?? .unnamed(visit.placeName))
            }
        }
        self.init(days: recorded.count, places: places.count)
    }

    /// A visit Dwell couldn't name yet still went somewhere: it counts by the name it shows.
    private enum PlaceKey: Hashable {
        case known(PlaceID)
        case unnamed(String)
    }
}

/// 3D art that pops out around a wrap page's title (Weekly wrap design: an alarm clock, a
/// briefcase, a flame and a trophy around "This week.").
///
/// The art will follow the week's data. Which data picks which art comes from the designer
/// before hand-off (QUESTIONS.md, "Before hand-off"); until then the opener shows the
/// design's four every week. [MAPPING NEEDED]
public enum WrapSticker: String, CaseIterable, Hashable, Sendable {
    case alarmClock
    case briefcase
    case flame
    case trophy

    /// The design's four, in its order: top left, right, bottom left, bottom right.
    public static let opener: [WrapSticker] = [.alarmClock, .briefcase, .flame, .trophy]
}
