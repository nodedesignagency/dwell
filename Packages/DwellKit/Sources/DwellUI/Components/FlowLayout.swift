import SwiftUI

/// Lays children out in a row and wraps them onto new lines, like words in a sentence.
/// Each line is centred vertically on its tallest child. A child wider than the line is
/// offered the full width so its own text can wrap.
public struct FlowLayout: Layout {
    public var alignment: HorizontalAlignment
    public var spacing: CGFloat
    public var lineSpacing: CGFloat

    public init(alignment: HorizontalAlignment = .leading, spacing: CGFloat = Space.s, lineSpacing: CGFloat = Space.xs) {
        self.alignment = alignment
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let lines = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = lines.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(0, lines.count - 1))
        let width = lines.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for line in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX + leadingOffset(for: line.width, in: bounds.width)
            for item in line.items {
                let origin = CGPoint(x: x, y: y + (line.height - item.size.height) / 2)
                subviews[item.index].place(at: origin, proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += line.height + lineSpacing
        }
    }

    private struct Item {
        var index: Int
        var size: CGSize
    }

    private struct Line {
        var items: [Item] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Line] {
        var lines: [Line] = []
        var line = Line()
        for index in subviews.indices {
            var size = subviews[index].sizeThatFits(.unspecified)
            if size.width > width {
                size = subviews[index].sizeThatFits(ProposedViewSize(width: width, height: nil))
            }
            if !line.items.isEmpty, line.width + spacing + size.width > width {
                lines.append(line)
                line = Line()
            }
            line.width += (line.items.isEmpty ? 0 : spacing) + size.width
            line.height = max(line.height, size.height)
            line.items.append(Item(index: index, size: size))
        }
        if !line.items.isEmpty {
            lines.append(line)
        }
        return lines
    }

    private func leadingOffset(for lineWidth: CGFloat, in width: CGFloat) -> CGFloat {
        if alignment == .center { return max(0, (width - lineWidth) / 2) }
        if alignment == .trailing { return max(0, width - lineWidth) }
        return 0
    }
}
