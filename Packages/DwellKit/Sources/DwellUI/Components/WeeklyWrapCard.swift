import DwellCore
import SwiftUI

/// The weekly wrap invite (Today design, "Weekly Wrap"): a blue card at the top of Today once
/// last week's wrap is ready, until it's opened.
///
/// Figma: 361 wide (fill), 224 tall, radius 20, clip content; a radial fill from #67D7FF in the
/// middle to #00A3F3 at the edge (centred, a little below the middle, reaching 46% of the card
/// each way); the card shadow every card has. Inside, centred: the week (14, white 90%), the
/// voiced title (32 medium, white, two lines), 12 to "Let's go" (18 medium, ink, on a white
/// capsule, 20 × 8). Behind them the design's glow component, white this time (`WrapGlow`).
/// Text sizes and spacing are measured from the screenshot.
public struct WeeklyWrapCard: View {
    @ScaledMetric(relativeTo: .largeTitle) private var titleWidth: CGFloat = 280
    private let label: String
    private let title: VoicedLine
    private let action: String
    private let onOpen: () -> Void

    /// - Parameters:
    ///   - label: the week, a plain label: "Oct 19 – 25".
    ///   - title: the voiced invite.
    public init(label: String, title: VoicedLine, action: String, onOpen: @escaping () -> Void) {
        self.label = label
        self.title = title
        self.action = action
        self.onOpen = onOpen
    }

    public var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Space.xxs) {
                Text(verbatim: label)
                    .textRole(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                // Narrower than the card, so the title breaks after "your" as in the design.
                VoiceText(title)
                    .textRole(.voiceDisplay)
                    .foregroundStyle(.white)
                    .frame(maxWidth: titleWidth)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Button(action: onOpen) {
                Text(verbatim: action)
                    .textRole(.action)
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, Space.screen)
                    .padding(.vertical, Space.s)
                    .background(.white, in: .capsule)
                    // A 44-pt tap target around the 38-pt capsule.
                    .frame(minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens last week's wrap")
            // 12 from the title to the capsule, less the tap target's extra.
            .padding(.top, 9)
        }
        .padding(.horizontal, Space.l)
        .padding(.vertical, Space.xl)
        .frame(maxWidth: .infinity, minHeight: 224)
        .background {
            WrapGlow()
                .clipShape(.rect(cornerRadius: Radius.xl))
        }
        .card(fill: EllipticalGradient(
            colors: [Palette.wrapCentre, Palette.wrapEdge],
            center: UnitPoint(x: 0.5, y: 0.537),
            startRadiusFraction: 0,
            endRadiusFraction: 0.46))
        // The same blue card in dark mode, and the capsule's ink stays dark on white.
        .environment(\.colorScheme, .light)
    }
}

/// The glow behind the invite: the design's glow component ("Frame 2147239465", the one behind
/// the hero tiles) at 2036.66 pt, centred on the card, turned 180° and white.
///
/// - Vector: the sixteen rays, white, radial from 50% at the centre to nothing at the edge
///   (the tiles' stops; the screenshots don't show these), fill 30%, layer 50%. Only the part
///   that reaches the card's corners is drawn, then turned like the tiles' rays: a full circle
///   every 24 s, still under Reduce Motion.
/// - Ellipse 39: 726 pt, white fading out to the right (the instance is turned), layer 50%,
///   layer blur 362 (scaled from the tiles'; the screenshots don't show it, and the card
///   matches it). Through the card only its middle shows, a soft ramp from 24% white at the
///   left to 12% at the right, so it's drawn as that ramp, computed from those values: a
///   blur 362 pt wide would cost far more for the same pixels.
private struct WrapGlow: View {
    static let size: CGFloat = 2036.66
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let reach = hypot(proxy.size.width, proxy.size.height) / 2 + 2
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.236), location: 0),
                        .init(color: .white.opacity(0.238), location: 0.25),
                        .init(color: .white.opacity(0.212), location: 0.5),
                        .init(color: .white.opacity(0.169), location: 0.75),
                        .init(color: .white.opacity(0.122), location: 1),
                    ],
                    startPoint: .leading, endPoint: .trailing)
                rays(reach: reach)
                    .frame(width: reach * 2, height: reach * 2)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func rays(reach: CGFloat) -> some View {
        // The gradient runs to the vector's own edge (1018 pt); drawn only to `reach`.
        let edge = 0.5 * (1 - reach / (Self.size / 2))
        let drawn = Rays(count: 16, share: 0.6)
            .fill(RadialGradient(
                colors: [.white.opacity(0.5), .white.opacity(max(0, edge))],
                center: .center, startRadius: 0, endRadius: reach))
            .opacity(0.3 * 0.5)
            // Drawn once, then turned.
            .drawingGroup()
        if reduceMotion {
            drawn
        } else {
            drawn.phaseAnimator([0.0, 360.0]) { content, angle in
                content.rotationEffect(.degrees(angle))
            } animation: { angle in
                angle == 360 ? Motion.spin : nil
            }
        }
    }
}
