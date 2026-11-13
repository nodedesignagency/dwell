import SwiftUI

/// Text roles. Voice (headlines, insight sentences, empty states) and data (numbers, axes,
/// timeline rows) are kept typographically separate, so character never leaks into data
/// (brief §3.3, §6).
///
/// Set by the Today design: SF Pro Rounded throughout, medium for anything that leads,
/// tracking at -2% of the size. Sizes are the design's at the default text size and scale
/// with Dynamic Type relative to the nearest system style.
public enum TextRole: CaseIterable, Sendable {
    /// The voiced title of a wrap page: "This week." 60.
    case storyTitle
    /// The voiced title of a wrap page that runs to two lines: "Weekends were all yours." 48,
    /// set with its lines 48 apart (`LeadedText`).
    case storyHeadline
    /// The voiced line under a wrap page's title, and a wrap page's labels. 18 regular.
    case storyLine
    /// A wrap page's big number: "45h 40m" at work. 64 medium, proportional digits like the
    /// live timer (a monospaced "1" leaves a gap at this size; QUESTIONS.md, design vs brief 11).
    case storyNumber
    /// A wrap page's voiced heading over its art: "Earliest exit this week". 42 medium.
    case storyHeading
    /// A time of day as a wrap page's figure: "5:52 PM". 60 medium, proportional digits like
    /// the live timer.
    case storyTime
    /// A big voiced line on a feature card: the weekly wrap invite. 32.
    case voiceDisplay
    /// A sheet's big title: "Turn on your location". 40.
    case display
    /// The user's name on You: "Maya Cooper". 28.
    case profileName
    /// A card's big title: "Every hour of the week", the year in places. 28. Plain words.
    case cardTitle
    /// Today's headline sentence. 24.
    case voiceHero
    /// Insight sentences. 22.
    case voice
    /// The live timer. 40, monospaced digits (the timer itself opts out, see LiveCard).
    case dataHero
    /// A streak's run on You: "12 evenings". 32 medium, proportional digits like the live
    /// timer (a monospaced "1" leaves a gap at this size; QUESTIONS.md, design vs brief 11).
    case dataDisplay
    /// Hero stat numbers. 16 medium, proportional digits as in the design (monospaced ones
    /// opened a gap after each "1": "1h 3 1m"). The brief asks for monospaced everywhere:
    /// QUESTIONS.md, design vs brief 11.
    case dataStat
    /// Durations and times in rows and callouts. 14, monospaced digits.
    case data
    /// A page's title ("Your places", "You") and the dial's stop name ("Plain"). 24, like
    /// Today's headline, but plain words.
    case pageTitle
    /// Section titles: "This week", "Your day". 20.
    case title
    /// A list row that leads: Time's category names and their durations. 18 medium.
    case rowTitle
    /// Row titles and the live caption. 16 medium.
    case body
    /// Buttons and pills. 16 medium.
    case label
    /// The button on a feature card: "Let's go". 18 medium.
    case action
    /// Times, topic labels, stat labels, day labels. 14.
    case caption
    /// Legends and small buttons. 12.
    case footnote
    /// Tab bar labels. 12, line height 16, no tracking.
    case tab

    public var size: CGFloat {
        switch self {
        case .storyTitle: 60
        case .storyNumber: 64
        case .storyHeadline: 48
        case .storyHeading: 42
        case .storyTime: 60
        case .storyLine: 18
        case .display: 40
        case .voiceDisplay, .dataDisplay: 32
        case .profileName, .cardTitle: 28
        case .voiceHero, .pageTitle: 24
        case .voice: 22
        case .dataHero: 40
        case .dataStat: 16
        case .data: 14
        case .title: 20
        case .rowTitle: 18
        case .body: 16
        case .label: 16
        case .action: 18
        case .caption: 14
        case .footnote: 12
        case .tab: 12
        }
    }

    public var textStyle: Font.TextStyle {
        switch self {
        case .storyTitle, .storyNumber, .storyHeadline, .storyHeading, .storyTime, .display, .voiceDisplay, .dataDisplay: .largeTitle
        case .storyLine: .body
        case .profileName, .cardTitle: .title
        case .rowTitle: .body
        case .voiceHero, .pageTitle: .title2
        case .voice: .title3
        case .dataHero: .largeTitle
        case .dataStat, .body, .label: .callout
        case .action: .body
        case .data, .caption: .subheadline
        case .title: .title3
        case .footnote: .caption
        case .tab: .footnote
        }
    }

    public var weight: Font.Weight {
        switch self {
        case .storyTitle, .storyNumber, .storyHeadline, .storyHeading, .storyTime, .display, .voiceDisplay, .profileName, .cardTitle, .voiceHero, .voice, .dataHero, .dataDisplay, .dataStat, .pageTitle, .title,
             .rowTitle, .body, .label, .action, .tab: .medium
        case .storyLine, .data, .caption, .footnote: .regular
        }
    }

    public var usesMonospacedDigits: Bool {
        switch self {
        case .dataHero, .data: true
        default: false
        }
    }

    /// Tracking as a share of the point size: -2% unless a component says otherwise
    /// ("View more" -1%, the day pill 0).
    public static let tracking: CGFloat = -0.02

    /// The role at an already scaled size.
    public func font(size: CGFloat, weight: Font.Weight? = nil, monospacedDigits: Bool? = nil) -> Font {
        let font = Font.system(size: size, weight: weight ?? self.weight, design: .rounded)
        return monospacedDigits ?? usesMonospacedDigits ? font.monospacedDigit() : font
    }
}

extension View {
    /// Sets the font, Dynamic Type scaling and tracking for a text role.
    /// - Parameters:
    ///   - weight: overrides the role's weight, e.g. semibold for small buttons.
    ///   - tracking: overrides `TextRole.tracking`, as a share of the point size (-0.01 is -1%).
    ///   - monospacedDigits: overrides the role's digit style.
    public func textRole(
        _ role: TextRole,
        weight: Font.Weight? = nil,
        tracking: CGFloat? = nil,
        monospacedDigits: Bool? = nil
    ) -> some View {
        modifier(TextRoleModifier(role: role, weight: weight, tracking: tracking, monospacedDigits: monospacedDigits))
    }
}

private struct TextRoleModifier: ViewModifier {
    let role: TextRole
    let weight: Font.Weight?
    let tracking: CGFloat?
    let monospacedDigits: Bool?
    @ScaledMetric private var size: CGFloat

    init(role: TextRole, weight: Font.Weight?, tracking: CGFloat?, monospacedDigits: Bool?) {
        self.role = role
        self.weight = weight
        self.tracking = tracking
        self.monospacedDigits = monospacedDigits
        _size = ScaledMetric(wrappedValue: role.size, relativeTo: role.textStyle)
    }

    func body(content: Content) -> some View {
        content
            .font(role.font(size: size, weight: weight, monospacedDigits: monospacedDigits))
            .tracking(size * (tracking ?? TextRole.tracking))
    }
}
