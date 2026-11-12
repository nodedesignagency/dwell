/// The pushes You turns on and off (brief §6, §10). The dial decides which can fire at all;
/// the user decides, within that, which do. The lock screen only ever says "Dwell update.
/// Open Dwell to see what changed."; the voiced sentence shows in the app after the tap.
public enum NotificationKind: String, CaseIterable, Sendable {
    /// The one insight push a day, at the user's morning. Every stop.
    case morningRecap
    /// In the evening, when a streak hasn't qualified yet. Push and Grind, opt-in.
    case streakAtRisk
    /// When a record lands. Grind.
    case records

    /// The brief's dial table: Peace, Calm and Plain get the morning recap only; Push adds
    /// streak-at-risk; Grind adds records (and rank moves, which wait for Compare).
    public func isAvailable(at stop: Dial.Stop) -> Bool {
        switch self {
        case .morningRecap: true
        case .streakAtRisk: stop == .push || stop == .grind
        case .records: stop == .grind
        }
    }

    /// Before the user has touched it. Streak-at-risk is opt-in (brief §10), so it starts off;
    /// the other two start on, and only fire where the dial lets them.
    public var isOnByDefault: Bool {
        switch self {
        case .morningRecap, .records: true
        case .streakAtRisk: false
        }
    }

    /// Whether this push fires: the dial allows it and the user left it on.
    public func fires(at stop: Dial.Stop, isOn: Bool) -> Bool {
        isOn && isAvailable(at: stop)
    }
}
