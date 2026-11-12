import DwellCore
import SwiftUI

/// "Looks right? 57m at Brambleline Café." The one piece of work Dwell asks for (brief §7.1).
/// A navy card that floats above the tab bar while a visit needs a yes.
///
/// From the Today Figma frame (353 × 65, radius 20, #252537): the place's category art, a grey
/// question over the visit in white, then a white pill and an underlined link, all on one row.
/// The design's words are "Yes" / "Wrong place" and "47 min"; we use the brief's "Looks right"
/// / "Pick another" and `57m` (the user's call). Those buttons are wider than "Yes", so a long
/// place name wraps onto a second line rather than pushing the buttons off the row. At
/// accessibility sizes the buttons move under the text.
///
/// VoiceOver reads the whole ask in the dial's voice ("You spent 57m at Brambleline Café.
/// Looks right?"), then the two buttons.
public struct ConfirmationCard<Artwork: View>: View {
    @Environment(\.dial) private var dial
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var artSize: CGFloat = 32
    @ScaledMetric(relativeTo: .subheadline) private var detailSize: CGFloat = 14

    private let question: VoicedLine
    private let value: String
    private let detail: String
    private let sentence: VoicedLine
    private let art: Artwork
    private let onLooksRight: () -> Void
    private let onPickAnother: () -> Void

    /// - Parameters:
    ///   - question: the grey line, "Looks right?", in the dial's voice.
    ///   - value: the visit's duration, "57m". Never voiced.
    ///   - detail: the rest of the white line, "at Brambleline Café".
    ///   - sentence: the whole ask, for VoiceOver.
    ///   - art: the place's category art, drawn at 32 pt.
    public init(
        question: VoicedLine,
        value: String,
        detail: String,
        sentence: VoicedLine,
        onLooksRight: @escaping () -> Void,
        onPickAnother: @escaping () -> Void,
        @ViewBuilder art: () -> Artwork
    ) {
        self.question = question
        self.value = value
        self.detail = detail
        self.sentence = sentence
        self.art = art()
        self.onLooksRight = onLooksRight
        self.onPickAnother = onPickAnother
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Space.s) {
                    HStack(spacing: Space.m) {
                        artwork
                        text
                    }
                    buttons
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.vertical, Space.m)
            } else {
                HStack(spacing: Space.m) {
                    artwork
                    text
                    buttons
                        .fixedSize()
                }
                // Figma: 65 tall; the 44-pt buttons leave 10.5 above and below.
                .padding(.vertical, 10.5)
            }
        }
        .padding(.horizontal, Space.l)
        .frame(minHeight: 65)
        .background {
            let shape = RoundedRectangle(cornerRadius: Radius.xl)
            shape
                .fill(Palette.inverseSurface)
                .overlay { TopGlow().clipShape(shape) }
                .overlay { SweepingSheen().clipShape(shape) }
        }
        .accessibilityElement(children: .contain)
    }

    private var artwork: some View {
        art
            .frame(width: artSize, height: artSize)
            .foregroundStyle(Palette.inverseText)
            .accessibilityHidden(true)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: Space.xxs) {
            VoiceText(question)
                .textRole(.footnote)
                .foregroundStyle(Palette.inverseText.opacity(0.75))
            Text(detailLine)
                .tracking(detailSize * TextRole.tracking)
                .foregroundStyle(Palette.inverseText)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                .minimumScaleFactor(0.9)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sentence.text(for: dial))
    }

    /// "57m" semibold in monospaced digits, then "at Brambleline Café" regular.
    private var detailLine: AttributedString {
        var number = AttributedString(value)
        number.font = TextRole.caption.font(size: detailSize, weight: .semibold, monospacedDigits: true)
        var rest = AttributedString(" " + detail)
        rest.font = TextRole.caption.font(size: detailSize, weight: .regular)
        return number + rest
    }

    private var buttons: some View {
        HStack(spacing: Space.s) {
            Button(action: onLooksRight) {
                Text(verbatim: TodayCopy.looksRight)
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, Space.l)
                    .padding(.vertical, Space.s)
                    // Figma: white, a shade darker along the top.
                    .background(
                        Palette.inverseText.shadow(.inner(color: .black.opacity(0.08), radius: 4, y: 3)),
                        in: .capsule)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
            }
            Button(action: onPickAnother) {
                Text(verbatim: TodayCopy.pickAnother)
                    .underline()
                    .foregroundStyle(Palette.inverseText)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
            }
        }
        .buttonStyle(.plain)
        .textRole(.footnote, weight: .semibold)
        // The pill's ink is drawn for a white pill; keep it in dark mode too.
        .environment(\.colorScheme, .light)
    }
}

/// The light along the card's top edge: the design's five inner shadows, in the warm white
/// #FAEFD5, read from the screenshot as 15% at the edge fading to about 1% at the bottom.
/// Replace with the five Figma inner shadows once their values are in. [VALUES NEEDED]
private struct TopGlow: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Palette.inverseGlow.opacity(0.15), location: 0),
                .init(color: Palette.inverseGlow.opacity(0.11), location: 0.1),
                .init(color: Palette.inverseGlow.opacity(0.08), location: 0.2),
                .init(color: Palette.inverseGlow.opacity(0.055), location: 0.35),
                .init(color: Palette.inverseGlow.opacity(0.038), location: 0.5),
                .init(color: Palette.inverseGlow.opacity(0.018), location: 0.7),
                .init(color: Palette.inverseGlow.opacity(0.009), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// The card's two streaks of light, passing across it every few seconds so it reads as
/// waiting for an answer: they rest where the design draws them for 2.4 s, leave to the right,
/// and slide back in from the left. Under Reduce Motion they stay at rest.
private struct SweepingSheen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            Sheen()
        } else {
            Sheen()
                .phaseAnimator(SweepPhase.allCases) { content, phase in
                    let shift = phase.shift
                    content.visualEffect { content, proxy in
                        content.offset(x: shift * proxy.size.width)
                    }
                } animation: { phase in
                    switch phase {
                    case .gone: Motion.sweepOut
                    case .before: nil // off the card on both sides, so the jump is never seen
                    case .rest: Motion.sweepIn
                    }
                }
        }
    }
}

nonisolated private enum SweepPhase: CaseIterable {
    case rest, gone, before

    /// Where the streaks sit, as a share of the card's width from their resting place.
    var shift: CGFloat {
        switch self {
        case .rest: 0
        case .gone: 1
        case .before: -0.5
        }
    }
}
