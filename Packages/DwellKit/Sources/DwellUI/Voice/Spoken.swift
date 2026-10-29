import DwellCore
import Foundation

extension DurationText {
    /// "1 hour, 16 minutes": how VoiceOver reads a duration that shows as "1h 16m".
    /// Rounds down to whole minutes, like the text on screen.
    public static func spoken(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int(interval / 60))
        let duration = Duration.seconds(minutes * 60)
        guard minutes > 0 else { return duration.formatted(.units(allowed: [.minutes], width: .wide)) }
        return duration.formatted(.units(allowed: [.hours, .minutes], width: .wide))
    }
}
