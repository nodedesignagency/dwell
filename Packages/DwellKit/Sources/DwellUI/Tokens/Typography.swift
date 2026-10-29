import SwiftUI

/// Text roles. Voice (headlines, insight sentences, empty states) and data (numbers, axes,
/// timeline rows) are kept typographically separate, so character never leaks into data
/// (brief §3.3, §6).
///
/// Set by the Today design: SF Pro Rounded throughout, medium for anything that leads,
/// tracking at -2% of the size. Sizes are the design's at the default text size and scale
/// with Dynamic Type relative to the nearest system style.
public enum TextRole: CaseIterable, Sendable {
    /// Today's headline sentence. 24.
    case voiceHero
    /// Insight sentences. 22.
    case voice
    /// The live timer. 40, monospaced digits.
    case dataHero
    /// Hero stat numbers. 16 medium, monospaced digits.
    case dataStat
    /// Durations and times in rows and callouts. 14, monospaced digits.
    case data
    /// Section titles: "This week", "Your day". 20.
    case title
    /// Row titles and the live caption. 16 medium.
    case body
    /// Buttons and pills. 16 medium.
    case label
    /// Times, topic labels, stat labels, day labels. 14.
    case caption
    /// Legends and small buttons. 12.
    case footnote

    public var size: CGFloat {
        switch self {
        case .voiceHero: 24
        case .voice: 22
        case .dataHero: 40
        case .dataStat: 16
        case .data: 14
        case .title: 20
        case .body: 16
        case .label: 16
        case .caption: 14
        case .footnote: 12
        }
    }

    public var textStyle: Font.TextStyle {
        switch self {
        case .voiceHero: .title2
        case .voice: .title3
        case .dataHero: .largeTitle
        case .dataStat, .body, .label: .callout
        case .data, .caption: .subheadline
        case .title: .title3
        case .footnote: .caption
        }
    }

    public var weight: Font.Weight {
        switch self {
        case .voiceHero, .voice, .dataHero, .dataStat, .title, .body, .label: .medium
        case .data, .caption, .footnote: .regular
        }
    }

    public var usesMonospacedDigits: Bool {
        switch self {
        case .dataHero, .dataStat, .data: true
        default: false
        }
    }

    /// Tracking as a share of the point size.
    static let tracking: CGFloat = -0.02

    /// The role at an already scaled size.
    public func font(size: CGFloat, weight: Font.Weight? = nil) -> Font {
        let font = Font.system(size: size, weight: weight ?? self.weight, design: .rounded)
        return usesMonospacedDigits ? font.monospacedDigit() : font
    }
}

extension View {
    /// Sets the font, Dynamic Type scaling and tracking for a text role.
    /// - Parameter weight: overrides the role's weight, e.g. semibold for small buttons.
    public func textRole(_ role: TextRole, weight: Font.Weight? = nil) -> some View {
        modifier(TextRoleModifier(role: role, weight: weight))
    }
}

private struct TextRoleModifier: ViewModifier {
    let role: TextRole
    let weight: Font.Weight?
    @ScaledMetric private var size: CGFloat

    init(role: TextRole, weight: Font.Weight?) {
        self.role = role
        self.weight = weight
        _size = ScaledMetric(wrappedValue: role.size, relativeTo: role.textStyle)
    }

    func body(content: Content) -> some View {
        content
            .font(role.font(size: size, weight: weight))
            .tracking(size * TextRole.tracking)
    }
}
