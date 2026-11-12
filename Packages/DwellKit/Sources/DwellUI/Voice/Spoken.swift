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

extension DurationText {
    /// "186 hours": how VoiceOver reads a lifetime total that shows as "186h". Below ten hours,
    /// where the total keeps its minutes ("6h 50m"), the same as `spoken`.
    public static func spokenTotal(_ interval: TimeInterval) -> String {
        let hours = Int(interval / 3600)
        guard hours >= 10 else { return spoken(interval) }
        return Duration.seconds(hours * 3600).formatted(.units(allowed: [.hours], width: .wide))
    }
}
