import SwiftUI

extension View {
    /// A white card on the sheet (Today: the live card, insight cards, the day card).
    /// A soft shadow in light mode; in dark mode, where shadows vanish, a hairline edge.
    public func card(radius: CGFloat = Radius.xl) -> some View {
        background(Palette.surface, in: .rect(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(Palette.cardStroke, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
    }
}

/// The dashed hairline between Today's sections and between timeline rows.
public struct DashedDivider: View {
    public init() {}

    public var body: some View {
        HorizontalLine()
            .stroke(Palette.separator, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

nonisolated private struct HorizontalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// Two soft diagonal streaks near the leading edge, like light on glass. Decoration only:
/// on the confirmation card and the soft button (Today design).
public struct Sheen: View {
    private let color: Color

    public init(color: Color = .white.opacity(0.1)) {
        self.color = color
    }

    public var body: some View {
        GeometryReader { proxy in
            let height = max(proxy.size.height, 44) * 4
            ZStack(alignment: .topLeading) {
                streak(width: 18, height: height).offset(x: 72, y: -height / 2.6)
                streak(width: 7, height: height).offset(x: 44, y: -height / 2.6)
            }
            .blur(radius: 2)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func streak(width: CGFloat, height: CGFloat) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: height)
            .rotationEffect(.degrees(32))
    }
}

/// A full-width capsule button on a card: "View more" (Today design).
public struct SoftButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textRole(.label)
            .foregroundStyle(Palette.textPrimary)
            .padding(.horizontal, Space.l)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Palette.background, in: .capsule)
            .overlay {
                Sheen(color: Palette.separator)
                    .clipShape(.capsule)
            }
            .overlay {
                Capsule().strokeBorder(Palette.separator, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

extension ButtonStyle where Self == SoftButtonStyle {
    public static var soft: SoftButtonStyle { SoftButtonStyle() }
}

/// A section title with its icon and an optional control on the trailing side:
/// "This week ← →", "Your day".
public struct SectionHeader<Trailing: View>: View {
    @ScaledMetric(relativeTo: .title3) private var iconSize: CGFloat = 20
    private let title: String
    private let icon: Image
    private let trailing: Trailing

    public init(_ title: String, icon: Image, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.icon = icon
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: Space.xs) {
            icon
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Palette.textSecondary)
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)
            Text(verbatim: title)
                .textRole(.title)
                .foregroundStyle(Palette.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Space.s)
            trailing
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    public init(_ title: String, icon: Image) {
        self.init(title, icon: icon) { EmptyView() }
    }
}
