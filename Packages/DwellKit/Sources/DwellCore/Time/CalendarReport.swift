import Foundation

/// Calendar vs reality for a period (brief §7.3, A.4; Time design): how many meetings you made
/// of those scheduled, and what's worth noticing. "6 of 8 meetings attended this week." "You
/// left the Monday standup early 3 weeks running." Facts, never blame.
public struct CalendarReport: Hashable, Sendable {
    /// One note under "Worth noticing".
    public struct Note: Hashable, Sendable, Identifiable {
        public enum Kind: Hashable, Sendable {
            /// Left the same meeting early (or got there late) week after week.
            case leftEarlyRun(title: String, weekday: String, weeks: Int)
            case lateRun(title: String, weekday: String, weeks: Int)
            /// Somewhere else at the time; `instead` names where, when Dwell knows.
            case missed(title: String, day: String, time: String, instead: String?)
        }

        public var id: String
        public var kind: Kind
    }

    /// Patterns need a few weeks before they mean anything (brief A.4: "needs 2+ weeks").
    public static let weeksForPatterns = 2
    /// The most notes shown at once.
    public static let maxNotes = 3

    /// The period's matches in time order: one mark each on the ring.
    public var matches: [CalendarMatch]
    public var notes: [Note]

    public var attended: Int { count { $0 == .attended } }
    public var leftEarly: Int { count { if case .partial = $0 { true } else { false } } }
    public var elsewhere: Int { count { if case .missed = $0 { true } else { false } } }
    public var unknown: Int { count { $0 == .unknown } }
    public var scheduled: Int { matches.count }

    private func count(_ test: (CalendarMatch.State) -> Bool) -> Int {
        matches.filter { test($0.state) }.count
    }

    /// - Parameters:
    ///   - current: the period's days.
    ///   - earlier: days before it, any order, for runs that started before the period.
    public init(_ current: PeriodSnapshot, earlier: [DaySnapshot], calendar: Calendar) {
        matches = current.days.flatMap(\.calendarMatches).sorted { $0.interval.start < $1.interval.start }

        let all = (earlier.flatMap(\.calendarMatches) + matches)
            .reduce(into: [String: CalendarMatch]()) { $0[$1.id] = $1 }
            .values
            .sorted { $0.interval.start < $1.interval.start }
        var notes: [Note] = []

        // Runs: the same meeting on the same weekday, partial every week up to its latest
        // time in this period.
        var seen: Set<String> = []
        for match in matches.reversed() {
            guard case .partial(_, let early) = match.state else { continue }
            let weekday = calendar.component(.weekday, from: match.interval.start)
            let key = "\(match.title)|\(weekday)"
            guard seen.insert(key).inserted else { continue }
            let series = all.filter {
                $0.title == match.title && calendar.component(.weekday, from: $0.interval.start) == weekday
                    && $0.interval.start <= match.interval.start
            }
            var weeks = 0
            var expected = match.interval.start
            for occurrence in series.reversed() {
                // Consecutive weeks only: a skipped week ends the run.
                guard abs(occurrence.interval.start.timeIntervalSince(expected)) < 3 * 86_400 else { break }
                guard case .partial(let occurrenceLate, let occurrenceEarly) = occurrence.state else { break }
                if early > 0, occurrenceEarly <= 0 { break }
                if early <= 0, occurrenceLate <= 0 { break }
                weeks += 1
                expected = calendar.date(byAdding: .day, value: -7, to: occurrence.interval.start) ?? occurrence.interval.start
            }
            guard weeks >= Self.weeksForPatterns else { continue }
            let day = Self.weekdayName(match.interval.start, calendar: calendar)
            let kind: Note.Kind = early > 0
                ? .leftEarlyRun(title: match.title, weekday: day, weeks: weeks)
                : .lateRun(title: match.title, weekday: day, weeks: weeks)
            notes.append(Note(id: "run-\(key)", kind: kind))
        }

        for match in matches {
            guard case .missed(let instead) = match.state else { continue }
            notes.append(Note(
                id: "missed-\(match.id)",
                kind: .missed(
                    title: match.title,
                    day: Self.weekdayShort(match.interval.start, calendar: calendar),
                    time: ClockText.bareTime(match.interval.start, calendar: calendar),
                    instead: instead)))
        }
        self.notes = Array(notes.prefix(Self.maxNotes))
    }

    private static func weekdayName(_ date: Date, calendar: Calendar) -> String {
        date.formatted(Date.FormatStyle(locale: calendar.locale ?? .current, calendar: calendar, timeZone: calendar.timeZone).weekday(.wide))
    }

    private static func weekdayShort(_ date: Date, calendar: Calendar) -> String {
        date.formatted(Date.FormatStyle(locale: calendar.locale ?? .current, calendar: calendar, timeZone: calendar.timeZone).weekday(.abbreviated))
    }
}
