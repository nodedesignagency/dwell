import SwiftUI

/// A hero stat: one number, its label, and an icon with a glow behind it (Today design:
/// "4h 29m · At work", "57m · Yours"). The label is a plain label, never voiced.
///
/// `compact` is the weekly wrap's three-up cut (Weekly wrap 4, "Kestriva Labs"): 11 in from
/// the sides and 8 from the top and bottom, the art 24, 54 tall, so three sit side by side in
/// a card; a value too long for it shrinks to fit.
public struct StatTile<Icon: View>: View {
    @ScaledMetric(relativeTo: .callout) private var regularIcon: CGFloat = 33
    @ScaledMetric(relativeTo: .callout) private var compactIcon: CGFloat = 24
    private let value: String
    private let label: String
    private let spokenValue: String
    private let tint: Color
    private let labelFirst: Bool
    private let compact: Bool
    private let icon: Icon

    /// - Parameters:
    ///   - spokenValue: what VoiceOver reads for `value`, e.g. "4 hours, 40 minutes".
    ///   - labelFirst: the label over the number (Time's "At work · 42h 29m"); Today's tiles
    ///     put the number first.
    ///   - compact: the weekly wrap's smaller tile, three to a row.
    public init(
        value: String,
        label: String,
        spokenValue: String? = nil,
        tint: Color,
        labelFirst: Bool = false,
        compact: Bool = false,
        @ViewBuilder icon: () -> Icon
    ) {
        self.value = value
        self.label = label
        self.spokenValue = spokenValue ?? value
        self.tint = tint
        self.labelFirst = labelFirst
        self.compact = compact
        self.icon = icon()
    }

    private var iconSize: CGFloat { compact ? compactIcon : regularIcon }
    private var inset: CGFloat { compact ? 11 : 13 }

    public var body: some View {
        HStack(spacing: Space.s) {
            VStack(alignment: .leading, spacing: compact ? Space.xxs : Space.xs) {
                if labelFirst {
                    labelText
                    valueText
                } else {
                    valueText
                    labelText
                }
            }
            Spacer(minLength: Space.xs)
            icon
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, inset)
        .padding(.vertical, compact ? 8 : 13)
        .frame(maxWidth: .infinity)
        .background {
            GeometryReader { proxy in
                ZStack {
                    Palette.surface
                    TileGlow(tint: tint)
                        .frame(width: TileGlow.size, height: TileGlow.size)
                        // Centred on the icon, as in the design.
                        .position(x: proxy.size.width - inset - iconSize / 2, y: proxy.size.height / 2)
                }
            }
            .clipShape(.rect(cornerRadius: Radius.l))
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.l)
                .strokeBorder(Palette.separator.opacity(0.7), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(spokenValue)
    }

    private var valueText: some View {
        Text(verbatim: value)
            .textRole(.dataStat)
            .foregroundStyle(Palette.textPrimary)
            .lineLimit(compact ? 1 : nil)
            .minimumScaleFactor(compact ? 0.7 : 1)
    }

    private var labelText: some View {
        Text(verbatim: label)
            .textRole(.caption)
            .foregroundStyle(Palette.textSecondary)
    }
}

/// The glow behind a hero stat's icon (Today design, Figma "Frame 2147239465", 271.55 pt
/// square): a blurred disc of the tile's colour, and over it sixteen faint rays of ink that
/// turn slowly around the icon, a full circle every 24 s. Under Reduce Motion they hold still.
private struct TileGlow: View {
    static let size: CGFloat = 271.55
    let tint: Color

    var body: some View {
        ZStack {
            // "Ellipse 39": 133.98 pt, 11.8 pt right of centre, the tint fading in from the
            // left, layer 50%, layer blur 66.82 (SwiftUI radius is half of Figma's blur).
            Circle()
                .fill(LinearGradient(colors: [tint.opacity(0), tint], startPoint: .leading, endPoint: .trailing))
                .frame(width: 133.98, height: 133.98)
                .offset(x: 11.8, y: -0.4)
                .blur(radius: 33.4)
                .opacity(0.5)
            // "Vector": rays of ink, radial from 50% at the centre to nothing at the edge,
            // fill 15%, layer 20%.
            TurningRays(color: Palette.textPrimary, size: Self.size, fadeRadius: Self.size / 2)
                .opacity(0.15 * 0.2)
        }
        .allowsHitTesting(false)
    }
}
