import DwellCore
import SwiftUI

/// A voiced sentence with its data runs set in place, as in Today's headline:
/// "Today, you've spent [icon] 4h 40m at work, [icon] 57m at Brambleline Café and…".
///
/// Character and data stay typographically apart: the voiced words are a lighter ink, each
/// run is full ink with its category's illustration and monospaced digits. The words
/// re-render when the dial moves; the runs never change.
public struct VoicedSentenceView: View {
    @Environment(\.dial) private var dial
    @ScaledMetric(relativeTo: .title2) private var iconSize: CGFloat = 20
    /// The design's gaps: 6 between words, lines 32 apart at 24pt.
    @ScaledMetric(relativeTo: .title2) private var wordSpacing: CGFloat = 6
    @ScaledMetric(relativeTo: .title2) private var lineSpacing: CGFloat = 4

    private let sentence: VoicedSentence
    private let role: TextRole
    private let ink: Color

    public init(_ sentence: VoicedSentence, role: TextRole = .voiceHero, ink: Color = Palette.textPrimary) {
        self.sentence = sentence
        self.role = role
        self.ink = ink
    }

    public var body: some View {
        let template = sentence.line.text(for: dial)
        FlowLayout(spacing: wordSpacing, lineSpacing: lineSpacing) {
            ForEach(Array(VoicedSentence.tokens(template).enumerated()), id: \.offset) { _, token in
                switch token {
                case .word(let word):
                    Text(verbatim: word)
                        .foregroundStyle(ink.opacity(0.7))
                case .run(let prefix, let index, let suffix):
                    if sentence.runs.indices.contains(index) {
                        run(sentence.runs[index], prefix: prefix, suffix: suffix)
                    }
                }
            }
        }
        .textRole(role)
        .motion(value: template)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sentence.text(for: dial))
        .accessibilityAddTraits(.isHeader)
    }

    private func run(_ run: VoicedSentence.Run, prefix: String, suffix: String) -> some View {
        HStack(spacing: Space.xs) {
            if !prefix.isEmpty {
                Text(verbatim: prefix)
                    .foregroundStyle(ink.opacity(0.7))
            }
            if let category = run.category {
                CategoryIcon(category, style: .illustration)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(ink)
            }
            Text(verbatim: run.text + suffix)
                .monospacedDigit()
                .foregroundStyle(ink)
        }
    }
}
