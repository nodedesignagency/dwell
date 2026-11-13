import SwiftUI

/// One way to share, as the postcard's panel shows it (Weekly wrap 7): the action's glyph in a
/// 46 circle outlined in ink 5%, 4 above its name (16 regular, ink). The glyphs are SF Symbols
/// in two tones, standing in for the design's duotone set [ICON NEEDED]. Use as the label of a
/// `Button` or `ShareLink`; it fills its column, and the name shrinks rather than wrap.
public struct ShareTargetLabel: View {
    @ScaledMetric(relativeTo: .callout) private var circle: CGFloat = 46
    @ScaledMetric(relativeTo: .callout) private var glyph: CGFloat = 18
    private let title: String
    private let systemImage: String

    public init(_ title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    public var body: some View {
        VStack(spacing: Space.xs) {
            Image(systemName: systemImage)
                .font(.system(size: glyph, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Palette.textPrimary)
                .frame(width: circle, height: circle)
                .overlay {
                    Circle().strokeBorder(Palette.outline, lineWidth: 1)
                }
            Text(verbatim: title)
                .textRole(.label, weight: .regular)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
    }
}
