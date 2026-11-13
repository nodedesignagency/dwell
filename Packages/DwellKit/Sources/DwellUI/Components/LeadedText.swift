import SwiftUI

/// Words set with their baselines a fixed distance apart, tighter than SwiftUI sets a `Text`'s
/// lines: the weekly wrap's two-line titles ("Weekends / were all yours.", 48 pt with lines 48
/// apart, Figma's 100%; a `Text` would set them about 57 apart).
///
/// SwiftUI can't tighten a `Text`'s lines on iOS 17, so each word is its own `Text`, flowed
/// like a paragraph, a fifth of the type size apart (about a space, as measured on the
/// design), and VoiceOver reads the words as one line. The distance between lines scales with
/// the text. Lines break only between words; a word wider than the space sits on a line of its
/// own. Hugs its widest line; give it a `maxWidth` frame to set where lines break.
public struct LeadedText: View {
    private let text: String
    private let role: TextRole
    private let alignment: HorizontalAlignment
    @ScaledMetric private var lineHeight: CGFloat
    @ScaledMetric private var wordSpacing: CGFloat

    /// - Parameters:
    ///   - lineHeight: baseline to baseline, at the default text size.
    public init(_ text: String, role: TextRole, lineHeight: CGFloat, alignment: HorizontalAlignment = .center) {
        self.text = text
        self.role = role
        self.alignment = alignment
        _lineHeight = ScaledMetric(wrappedValue: lineHeight, relativeTo: role.textStyle)
        _wordSpacing = ScaledMetric(wrappedValue: role.size * 0.2, relativeTo: role.textStyle)
    }

    public var body: some View {
        BaselineFlow(alignment: alignment, spacing: wordSpacing, lineHeight: lineHeight) {
            ForEach(Array(text.split(separator: " ").enumerated()), id: \.offset) { _, word in
                Text(verbatim: String(word))
                    .textRole(role)
                    .fixedSize()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: text))
    }
}

/// Lays words out in lines, each line's baseline `lineHeight` below the one before.
private struct BaselineFlow: Layout {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    let lineHeight: CGFloat

    private struct Line {
        var indices: [Int] = []
        var width: CGFloat = 0
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let lines = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        return CGSize(width: lines.map(\.width).max() ?? 0, height: height(of: lines))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // Broken as when measured, so a rounded-off bounds width never moves a word.
        let lines = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        guard let first = lines.first else { return }
        for (number, line) in lines.enumerated() {
            let baseline = bounds.minY + first.ascent + CGFloat(number) * lineHeight
            var x = bounds.minX + offset(for: line.width, in: bounds.width)
            for index in line.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                let ascent = subviews[index].dimensions(in: .unspecified)[VerticalAlignment.firstTextBaseline]
                subviews[index].place(at: CGPoint(x: x, y: baseline - ascent), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
        }
    }

    private func height(of lines: [Line]) -> CGFloat {
        guard let first = lines.first, let last = lines.last else { return 0 }
        return first.ascent + CGFloat(lines.count - 1) * lineHeight + last.descent
    }

    private func offset(for width: CGFloat, in available: CGFloat) -> CGFloat {
        switch alignment {
        case .leading: 0
        case .trailing: available - width
        default: (available - width) / 2
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Line] {
        var lines: [Line] = []
        var line = Line()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let ascent = subviews[index].dimensions(in: .unspecified)[VerticalAlignment.firstTextBaseline]
            let needed = line.indices.isEmpty ? size.width : line.width + spacing + size.width
            if !line.indices.isEmpty, needed > width {
                lines.append(line)
                line = Line()
            }
            line.width = line.indices.isEmpty ? size.width : line.width + spacing + size.width
            line.indices.append(index)
            line.ascent = max(line.ascent, ascent)
            line.descent = max(line.descent, size.height - ascent)
        }
        if !line.indices.isEmpty { lines.append(line) }
        return lines
    }
}
