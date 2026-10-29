import SwiftUI

/// Text roles. Voice (headlines, insight sentences, empty states) and data (numbers, axes,
/// timeline rows) are kept typographically separate, so character never leaks into data
/// (brief §3.3, §6). Every role scales with Dynamic Type.
///
/// Placeholder values (system text styles) until the first design sets the type scale.
public enum TextRole: CaseIterable, Sendable {
    /// The hero insight sentence.
    case voiceHero
    /// Insight sentences, empty states, lens readings.
    case voice
    /// Big numbers: hero stats, the live timer.
    case dataHero
    /// Durations, times, percentages in rows and callouts.
    case data
    case title
    case body
    case label
    case caption

    public var font: Font {
        switch self {
        case .voiceHero: .system(.title2, weight: .semibold)
        case .voice: .system(.body)
        case .dataHero: .system(.largeTitle, weight: .semibold).monospacedDigit()
        case .data: .system(.body).monospacedDigit()
        case .title: .system(.title3, weight: .semibold)
        case .body: .system(.body)
        case .label: .system(.subheadline, weight: .medium)
        case .caption: .system(.caption)
        }
    }
}

extension View {
    public func textRole(_ role: TextRole) -> some View {
        font(role.font)
    }
}
