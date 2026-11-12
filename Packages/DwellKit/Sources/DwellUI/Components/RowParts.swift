import DwellCore
import SwiftUI

/// The round well a row's glyph sits in (Today's timeline, Your places): 32, the screen's
/// background with an ink-5% border inside (Figma); dashed for a gap. The glyph is 18.
public struct IconWell<Glyph: View>: View {
    @ScaledMetric(relativeTo: .callout) private var size: CGFloat = 32
    @ScaledMetric(relativeTo: .callout) private var glyphSize: CGFloat = 18
    private let isDashed: Bool
    private let glyph: Glyph

    public init(isDashed: Bool = false, @ViewBuilder glyph: () -> Glyph) {
        self.isDashed = isDashed
        self.glyph = glyph()
    }

    public var body: some View {
        glyph
            .frame(width: glyphSize, height: glyphSize)
            .frame(width: size, height: size)
            .background(Palette.background, in: .circle)
            .overlay {
                if isDashed {
                    Circle().strokeBorder(Palette.gap, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                } else {
                    Circle().strokeBorder(Palette.outline, lineWidth: 1)
                }
            }
            .accessibilityHidden(true)
    }
}

/// A row's time: the design's clock (14), the duration, and its chevron (8 × 14), all grey
/// (Today's timeline: "57m"; Your places: "186h"). VoiceOver reads the row, not this.
public struct DurationTrail: View {
    @ScaledMetric(relativeTo: .subheadline) private var clockSize: CGFloat = 14
    private let text: String
    private let showsChevron: Bool

    /// - Parameter text: the duration as written, "57m" or "186h".
    public init(_ text: String, showsChevron: Bool) {
        self.text = text
        self.showsChevron = showsChevron
    }

    public var body: some View {
        HStack(spacing: Space.xs) {
            Art.clock
                .resizable()
                .scaledToFit()
                .frame(width: clockSize, height: clockSize)
                .accessibilityHidden(true)
            Text(verbatim: text)
                .monospacedDigit()
            if showsChevron {
                Art.chevron
                    .resizable()
                    .scaledToFit()
                    .frame(width: clockSize * 8 / 14, height: clockSize)
                    .accessibilityHidden(true)
            }
        }
        .textRole(.data)
        .foregroundStyle(Palette.textSecondary)
    }
}

/// Short facts in a row, a small dot between each: "Work • 48 visits", "41 places • 640h
/// mapped" (Your places design). Wraps between facts, like words, at large text sizes. Takes
/// the font and colour it's given; the dot is 3 across and sits at the middle of the capitals.
public struct DotLine: View {
    @ScaledMetric(relativeTo: .subheadline) private var dotSize: CGFloat = 3
    private let items: [String]
    private let spacing: CGFloat

    /// - Parameter spacing: from each fact to the dot. The design has 8 under a place's name
    ///   (14 pt) and 12 under a page title (16 pt).
    public init(_ items: [String], spacing: CGFloat = Space.s) {
        self.items = items
        self.spacing = spacing
    }

    public var body: some View {
        // A line's height is its text's, and the line box's middle is within a fraction of a
        // point of the capitals' middle, so centring the dot on the line puts it there.
        FlowLayout(spacing: spacing, lineSpacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { offset, item in
                if offset > 0 {
                    Circle()
                        .frame(width: dotSize, height: dotSize)
                }
                Text(verbatim: item)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(items.joined(separator: ", "))
    }
}
