import SwiftUI

/// Everything Dwell lets you feel (brief §6.1). Haptics mark something physical happening,
/// never decoration: nothing on scrolling, tab changes, ticking timers or chart scrubbing
/// beyond the system's own selection feedback. The dial changes what is said, not what is felt.
public enum Haptic: Sendable {
    /// Light tap: a confirmation accepted, a scratch cell uncovered.
    case confirm
    /// The dial passing a named stop.
    case dialStop
    /// One firm impact: a record lands, a badge unlocks, a streak extends.
    case milestone

    var feedback: SensoryFeedback {
        switch self {
        case .confirm: .impact(weight: .light)
        case .dialStop: .selection
        case .milestone: .impact(weight: .heavy)
        }
    }
}

extension View {
    /// Plays `haptic` each time `trigger` changes.
    public func haptic<T: Equatable>(_ haptic: Haptic, trigger: T) -> some View {
        sensoryFeedback(haptic.feedback, trigger: trigger)
    }
}
