import Foundation

/// Today's sentences. Appendix B lines are used verbatim; everything else is a placeholder
/// marked [COPY NEEDED] until the client's copy deck arrives. Numbers are passed in, never
/// written per voice, so they cannot differ across the dial.
public enum TodayCopy {
    // MARK: Headline

    /// "Today, you've spent 4h 40m at work, 57m at Brambleline Café and 3h 47m at home."
    ///
    /// Work, then the standout place, then home, as in the design. `nil` when nothing was
    /// recorded, so the screen shows the empty line instead.
    public static func headline(_ recap: DayRecap, isToday: Bool, dayName: String) -> VoicedSentence? {
        var runs: [VoicedSentence.Run] = []
        if recap.work >= 60 {
            runs.append(.init(category: .work, text: "\(DurationText.short(recap.work)) at work"))
        }
        if let standout = recap.standout, standout.duration >= 60 {
            runs.append(.init(category: standout.category, text: "\(DurationText.short(standout.duration)) at \(standout.name)"))
        }
        if recap.home >= 60 {
            runs.append(.init(category: .home, text: "\(DurationText.short(recap.home)) at home"))
        }
        guard !runs.isEmpty else { return nil }

        let list = slots(runs.count)
        // [COPY NEEDED] Peace and Grind, and every past-day line. Plain today is the design's.
        let line = isToday
            ? VoicedLine(
                peace: "So far today, \(list).",
                plain: "Today, you've spent \(list).",
                grind: "Today's count: \(list).")
            : VoicedLine(
                peace: "On \(dayName), \(list).",
                plain: "On \(dayName), you spent \(list).",
                grind: "\(dayName): \(list).")
        return VoicedSentence(line: line, runs: runs)
    }

    /// Appendix B, "Empty Today".
    public static let emptyToday = VoicedLine(
        peace: "Nothing yet today. Dwell is waiting for your first stop.",
        plain: "No stops yet today.",
        grind: "No stops yet. Go somewhere.")

    /// [COPY NEEDED]
    public static let emptyPastDay = VoicedLine(fixed: "No stops that day.")

    /// The install-day promise (brief §3.1). [COPY NEEDED] Peace and Grind variants.
    public static let stillMapping = VoicedLine(fixed: "Your day starts here. Tonight you'll see your first place.")

    /// What Today is waiting for before the first insight, and how long (brief §3.1).
    /// [COPY NEEDED]
    public static func waitingForInsights(_ progress: MappingProgress) -> String {
        let days = progress.daysToGo == 1 ? "1 day" : "\(progress.daysToGo) days"
        return "Your first insight comes after your first full day · \(days) to go"
    }

    /// [COPY NEEDED]
    public static let timelineEmpty = "Your stops show up here as you make them."

    // MARK: Live status

    /// The caption under the live timer. Appendix B for work; the place name and "estimate"
    /// only appear where the client's copy has them.
    public static func liveCaption(_ status: LiveStatus, calendar: Calendar) -> VoicedLine {
        switch status {
        case .atPlace(let visit):
            let time = ClockText.time(visit.arrival, calendar: calendar)
            let bare = ClockText.bareTime(visit.arrival, calendar: calendar)
            return VoicedLine(
                peace: "Here since \(bare).",
                plain: "At \(visit.placeName) since \(time) · estimate",
                // [COPY NEEDED] Grind away from work: Appendix B only covers "On the clock".
                grind: visit.category == .work ? "On the clock since \(bare)." : "At \(visit.placeName) since \(bare).")
        case .inTransit:
            return VoicedLine(fixed: "In transit")
        case .lastKnown(let name, let lastSeen):
            return VoicedLine(fixed: "Last known: \(name) · last seen \(ClockText.time(lastSeen, calendar: calendar))")
        case .unknown:
            return VoicedLine(fixed: "Mapping your first place")
        case .noPermission:
            return VoicedLine(fixed: PermissionBanner.locationDenied.message)
        }
    }

    // MARK: Confirmation

    /// Appendix B, "Confirm a visit". Buttons are always "Looks right" and "Pick another".
    public static func confirmVisit(placeName: String, duration: TimeInterval) -> VoicedLine {
        let time = DurationText.short(duration)
        return VoicedLine(
            peace: "Looks like \(time) at \(placeName). Right?",
            plain: "You spent \(time) at \(placeName). Looks right?",
            grind: "\(time) at \(placeName). Looks right?")
    }

    public static let looksRight = "Looks right"
    public static let pickAnother = "Pick another"

    // MARK: Timeline rows

    /// Timeline rows never carry character (brief §6), so gaps use the Plain line at every
    /// position. Appendix B's Peace and Grind gap lines belong to voiced surfaces.
    public static func gapRow(_ duration: TimeInterval) -> String {
        "Dwell was asleep · \(DurationText.short(duration))"
    }

    public static func transitRow(_ duration: TimeInterval) -> String {
        "In transit · \(DurationText.short(duration))"
    }

    // MARK: Failure

    /// Brief A.2.
    public static let couldNotLoad = "Today couldn't load"
    /// [COPY NEEDED]
    public static let offline = "You're offline"
    /// Brief A.2.
    public static let retrySync = "Retry sync"

    /// [COPY NEEDED]
    public static func stale(since date: Date, calendar: Calendar) -> String {
        "Updated at \(ClockText.time(date, calendar: calendar)). Dwell couldn't refresh."
    }

    /// "{0}", "{0} and {1}", "{0}, {1} and {2}".
    private static func slots(_ count: Int) -> String {
        let names = (0..<count).map { "{\($0)}" }
        guard let last = names.last, names.count > 1 else { return names.first ?? "" }
        return names.dropLast().joined(separator: ", ") + " and " + last
    }
}

extension PermissionBanner {
    /// One banner at a time, fixed at every dial position. Appendix B for location denied.
    public var message: String {
        switch self {
        case .locationDenied: "Dwell can't see any places. Enable location in Settings."
        // [COPY NEEDED] the three below.
        case .whenInUseOnly: "Dwell only sees places while it's open."
        case .preciseOff: "Precise location is off, so places may be approximate."
        case .motionDenied: "Motion is off, so Dwell may miss short stops."
        }
    }

    /// Brief A.2: "Fix / Open Settings".
    public var actionTitle: String {
        switch self {
        case .whenInUseOnly: "Fix"
        case .locationDenied, .preciseOff, .motionDenied: "Open Settings"
        }
    }
}
