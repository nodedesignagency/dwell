import DwellCore
import SwiftUI

/// A voiced sentence with its data runs set in place, as in Today's headline:
/// "Today, you've spent [icon] 4h 40m at work, [icon] 57m at Brambleline Café and…".
///
/// Character and data stay typographically apart: the voiced words are a lighter ink, each
/// run is full ink with its category's illustration and monospaced digits. Everything wraps
/// word by word, runs included, with the icon kept on the run's first word. The words
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
            ForEach(Array(pieces(of: template).enumerated()), id: \.offset) { _, piece in
                if piece.isData {
                    dataWord(piece)
                } else {
                    voiceWord(piece.text)
                }
            }
        }
        .textRole(role)
        .motion(value: template)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(sentence.text(for: dial))
        .accessibilityAddTraits(.isHeader)
    }

    /// One word of the sentence. A run's first word carries its icon and any voiced prefix.
    private struct Piece {
        var text: String
        var isData = false
        var category: PlaceCategory?
        var prefix = ""
    }

    private func pieces(of template: String) -> [Piece] {
        VoicedSentence.tokens(template).flatMap { token -> [Piece] in
            switch token {
            case .word(let word):
                return [Piece(text: word)]
            case .run(let prefix, let index, let suffix):
                guard sentence.runs.indices.contains(index) else { return [] }
                let run = sentence.runs[index]
                let words = (run.text + suffix).split(separator: " ").map(String.init)
                return words.enumerated().map { offset, word in
                    offset == 0
                        ? Piece(text: word, isData: true, category: run.category, prefix: prefix)
                        : Piece(text: word, isData: true)
                }
            }
        }
    }

    private func voiceWord(_ word: String) -> some View {
        Text(verbatim: word)
            .foregroundStyle(ink.opacity(0.7))
    }

    private func dataWord(_ piece: Piece) -> some View {
        HStack(spacing: Space.xs) {
            if !piece.prefix.isEmpty {
                voiceWord(piece.prefix)
            }
            if let category = piece.category {
                CategoryIcon(category, style: .illustration)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(ink)
            }
            Text(verbatim: piece.text)
                .monospacedDigit()
                .foregroundStyle(ink)
        }
    }
}
