import SwiftUI

extension View {
    /// A capsule of glass behind the view (You design, Figma values from the user, 13 Nov:
    /// "41 places", "3.2% mapped", "Your dial"): fill white 65%; Figma's Glass (light −45° at
    /// 80%, refraction 80, depth 21.7, dispersion 50, frost 4.34) drawn as the close button's
    /// rim and inner shade, since SwiftUI has no refraction; and its drop shadow, x 0, y 5.42,
    /// blur 10.85, #1B1C1D at 5%, shown behind the glass as Figma's "show behind transparent
    /// areas" asks (SwiftUI blur is half Figma's).
    public func glassPill() -> some View {
        background {
            ZStack {
                Capsule()
                    .fill(Palette.glassShadow)
                    .blur(radius: 10.85 / 2)
                    .offset(y: 5.42)
                DrawnGlass(shape: Capsule(), fill: Palette.glassPill)
            }
        }
    }
}

/// A fact on glass with its art (You design, Figma: the 3D push pin and "41 places", the globe
/// and "3.2% mapped"): 40 tall, 10 across, the art (24 for the pin, whose canvas it keeps; 20
/// for the globe) 4.34 from the words (14 medium). Plain words, never voiced.
public struct StatPill: View {
    @ScaledMetric(relativeTo: .subheadline) private var height: CGFloat = 40
    @ScaledMetric(relativeTo: .subheadline) private var scale: CGFloat = 1
    private let text: String
    private let art: Image
    private let artSize: CGFloat

    /// - Parameter artSize: the art's square at the default text size.
    public init(_ text: String, art: Image, artSize: CGFloat = 20) {
        self.text = text
        self.art = art
        self.artSize = artSize
    }

    public var body: some View {
        HStack(spacing: 4.34) {
            art
                .resizable()
                .scaledToFit()
                .frame(width: artSize * scale, height: artSize * scale)
                .accessibilityHidden(true)
            Text(verbatim: text)
                .textRole(.caption, weight: .medium)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .frame(minHeight: height)
        .glassPill()
        .contentShape(.capsule)
    }
}

/// A card's label on glass (You design: "Your dial" at the top of the dial card): 14 medium,
/// 16 across and 8 down, so 32 tall, on the pills' glass.
public struct LabelPill: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(verbatim: text)
            .textRole(.caption, weight: .medium)
            .foregroundStyle(Palette.textPrimary)
            .padding(.horizontal, Space.l)
            .padding(.vertical, Space.s)
            .glassPill()
            .accessibilityAddTraits(.isHeader)
    }
}
