import SwiftUI

extension View {
    /// A capsule of glass behind the view (You design, Figma, 13 Nov: "41 places", "3.2%
    /// mapped", "Your dial"). `PillGlass`.
    public func glassPill() -> some View {
        background { PillGlass() }
    }
}

/// Figma's pill glass, matched to the Figma screenshot (13 Nov). Fill white 65%; inside it a
/// touch darker at the top and lighter at the bottom (about 3 below the page's grey under the
/// top edge, 3 above it near the bottom), as Figma's Glass draws it; a 1-pt white rim all the
/// way round; and Figma's drop shadow, y 5.42, blur 10.85 (SwiftUI radius 5.43), #1B1C1D,
/// cast by the glass itself so it shows through it ("show behind transparent areas"). SwiftUI
/// casts a shadow from the glass's own 65%, so the colour is set at 7.7% to land at Figma's 5%.
/// Figma's refraction and dispersion aren't drawn.
struct PillGlass: View {
    var body: some View {
        Capsule()
            .fill(Palette.glassPill)
            .overlay {
                Capsule().fill(LinearGradient(
                    colors: [.black.opacity(0.02), .white.opacity(0.2)],
                    startPoint: .top, endPoint: .bottom))
            }
            .overlay {
                Capsule().strokeBorder(Palette.glowRays, lineWidth: 1)
            }
            .shadow(color: Palette.glassShadow, radius: 10.85 / 2, x: 0, y: 5.42)
    }
}

/// A fact on glass with its art (You design, Figma: the 3D push pin and "41 places", the globe
/// and "3.2% mapped"): 40 tall, 10 across, the art 20, 4.34 to the words: SF Pro 14 regular,
/// as Figma sets them (cap height 9.9, x-height 7.2 on the Figma screenshot), not the app's
/// rounded face. Plain words, never voiced.
public struct StatPill: View {
    @ScaledMetric(relativeTo: .subheadline) private var height: CGFloat = 40
    @ScaledMetric(relativeTo: .subheadline) private var artSize: CGFloat = 20
    @ScaledMetric(relativeTo: .subheadline) private var textSize: CGFloat = 14
    private let text: String
    private let art: Image

    public init(_ text: String, art: Image) {
        self.text = text
        self.art = art
    }

    public var body: some View {
        HStack(spacing: 4.34) {
            art
                .resizable()
                .scaledToFit()
                .frame(width: artSize, height: artSize)
                .accessibilityHidden(true)
            Text(verbatim: text)
                .font(.system(size: textSize, weight: .regular))
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
