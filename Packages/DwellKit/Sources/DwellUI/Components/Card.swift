import SwiftUI

extension View {
    /// A white card on the sheet (Today: the live card, insight cards, the day card).
    /// A soft shadow in light mode; in dark mode, where shadows vanish, a hairline edge.
    ///
    /// The shadow belongs to the card's shape alone. On the whole view, every box, tile and
    /// line of text inside would cast one too, greying the white around them (the day bar box
    /// and hero tiles did, until 12 Nov).
    public func card(radius: CGFloat = Radius.xl) -> some View {
        background {
            RoundedRectangle(cornerRadius: radius)
                .fill(Palette.surface)
                .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
        }
        .overlay {
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(Palette.cardStroke, lineWidth: 1)
        }
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
            .textRole(.label, tracking: -0.01)
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

/// The navy capsule for a sheet's one action: "Yes, turn on" (Today design, "Turn Location").
/// 44 tall, full width, the label 20 medium in white, with the confirmation card's top light
/// and its streaks sweeping across on a loop; pressed, it dims.
public struct PrimaryButtonStyle: ButtonStyle {
    @ScaledMetric(relativeTo: .title3) private var height: CGFloat = 44

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textRole(.title)
            .foregroundStyle(Palette.inverseText)
            .padding(.horizontal, Space.l)
            .frame(maxWidth: .infinity, minHeight: height)
            .background {
                Capsule()
                    .fill(Palette.inverseSurface)
                    .overlay { InverseGlow().clipShape(Capsule()) }
                    .overlay { SweepingSheen().clipShape(Capsule()) }
            }
            .contentShape(.capsule)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
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

/// The warm light along the top of the navy surfaces (the confirmation card, the primary
/// button): the design's five inner shadows in #FAEFD5, read from the screenshot as 15% at
/// the edge fading to about 1% at the bottom. Replace with the five Figma inner shadows once
/// their values are in. [VALUES NEEDED]
struct InverseGlow: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Palette.inverseGlow.opacity(0.15), location: 0),
                .init(color: Palette.inverseGlow.opacity(0.11), location: 0.1),
                .init(color: Palette.inverseGlow.opacity(0.08), location: 0.2),
                .init(color: Palette.inverseGlow.opacity(0.055), location: 0.35),
                .init(color: Palette.inverseGlow.opacity(0.038), location: 0.5),
                .init(color: Palette.inverseGlow.opacity(0.018), location: 0.7),
                .init(color: Palette.inverseGlow.opacity(0.009), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// Two streaks of light sweeping across a navy surface left to right on a steady loop, so it
/// reads as waiting for an answer (the confirmation card, the primary button). Each pass starts just off the leading edge and ends off the
/// trailing one, so the jump back is never seen. Under Reduce Motion they rest where the
/// design draws them.
struct SweepingSheen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            Sheen()
        } else {
            Sheen()
                .phaseAnimator(SweepPhase.allCases) { content, phase in
                    let shift = phase.shift
                    content.visualEffect { content, proxy in
                        content.offset(x: shift * proxy.size.width)
                    }
                } animation: { phase in
                    switch phase {
                    case .after: Motion.sweep
                    case .before: nil // off the card on both sides, so the jump is never seen
                    }
                }
        }
    }
}

nonisolated private enum SweepPhase: CaseIterable {
    case before, after

    /// Where the streaks sit, as a share of the card's width from where the design draws them.
    var shift: CGFloat {
        switch self {
        case .before: -0.5
        case .after: 1
        }
    }
}
