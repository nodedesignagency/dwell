import SwiftUI

/// A hero stat: one number, its label, and an icon with a glow behind it (Today design:
/// "4h 29m · At work", "57m · Yours"). The label is a plain label, never voiced.
public struct StatTile<Icon: View>: View {
    @ScaledMetric(relativeTo: .callout) private var iconSize: CGFloat = 33
    private let value: String
    private let label: String
    private let spokenValue: String
    private let tint: Color
    private let icon: Icon

    /// - Parameter spokenValue: what VoiceOver reads for `value`, e.g. "4 hours, 40 minutes".
    public init(value: String, label: String, spokenValue: String? = nil, tint: Color, @ViewBuilder icon: () -> Icon) {
        self.value = value
        self.label = label
        self.spokenValue = spokenValue ?? value
        self.tint = tint
        self.icon = icon()
    }

    public var body: some View {
        HStack(spacing: Space.s) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(verbatim: value)
                    .textRole(.dataStat)
                    .foregroundStyle(Palette.textPrimary)
                Text(verbatim: label)
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer(minLength: Space.xs)
            icon
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)
        }
        .padding(13)
        .frame(maxWidth: .infinity)
        .background {
            GeometryReader { proxy in
                ZStack {
                    Palette.surface
                    TileGlow(tint: tint)
                        .frame(width: TileGlow.size, height: TileGlow.size)
                        // Centred on the icon, as in the design.
                        .position(x: proxy.size.width - 13 - iconSize / 2, y: proxy.size.height / 2)
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
