import Foundation

/// The sky over Today's header, by time of day: sunrise, day, sunset, night.
///
/// Follows the clock in the user's time zone. Open question (docs/QUESTIONS.md): fixed hours,
/// or the real sunrise and sunset for where the user is.
public enum SkyPhase: String, CaseIterable, Codable, Sendable, Identifiable {
    case sunrise
    case day
    case sunset
    case night

    public var id: Self { self }

    /// The hour each phase begins: 5 AM, 10 AM, 5 PM, 8 PM.
    public var startHour: Int {
        switch self {
        case .sunrise: 5
        case .day: 10
        case .sunset: 17
        case .night: 20
        }
    }

    public init(date: Date, calendar: Calendar) {
        let hour = calendar.component(.hour, from: date)
        self = Self.allCases.last { hour >= $0.startHour } ?? .night
    }

    /// Sunset and night are dark enough to need light text over them.
    public var isDark: Bool {
        self == .sunset || self == .night
    }
}
