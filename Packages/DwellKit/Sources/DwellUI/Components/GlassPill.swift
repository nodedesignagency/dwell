import SwiftUI

extension View {
    /// A capsule of glass behind the view (You design: "41 places", "3.2% mapped", "Your
    /// dial"): the sheet's close-button glass (the user's call, 13 Nov): white 70%, so what's
    /// behind shows through faintly, the white rim strongest top left and bottom right, a faint
    /// shade inside it; lifted off the map or the card by `glassLift()`.
    public func glassPill() -> some View {
        background {
            DrawnGlass(shape: Capsule(), fill: Palette.glass)
                .glassLift()
        }
    }
}

/// A fact on glass with its art (You design: the 3D pin and "41 places", the globe and "3.2%
/// mapped"): art 20, 8 to the words (14 medium), 10 across and 9 down, so 38 tall. Plain words,
/// never voiced.
public struct StatPill: View {
    @ScaledMetric(relativeTo: .subheadline) private var artSize: CGFloat = 20
    private let text: String
    private let art: Image

    public init(_ text: String, art: Image) {
        self.text = text
        self.art = art
    }

    public var body: some View {
        HStack(spacing: Space.s) {
            art
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Palette.textSecondary)
                .frame(width: artSize, height: artSize)
                .accessibilityHidden(true)
            Text(verbatim: text)
                .textRole(.caption, weight: .medium)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .glassPill()
        .contentShape(.capsule)
    }
}

/// A card's label on glass (You design: "Your dial" at the top of the dial card): 14 medium,
/// 16 across and 8 down, so 32 tall.
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
