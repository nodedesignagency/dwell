import SwiftUI

/// The dot by a live line ("At Kestriva Labs since 1:31 PM", "Mapping right now."), from the
/// Today design. The design's soft halo stands for the pulse: while something is live, a disc
/// of the dot's colour spreads from it and fades, on a loop, and there is no halo at rest. The
/// dot keeps the halo's 14-pt footprint, so the text sits where the design puts it. Under
/// Reduce Motion, and when nothing is live, the dot is still.
public struct LiveDot: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .callout) private var size: CGFloat = 8
    private let color: Color
    private let pulses: Bool

    public init(color: Color, pulses: Bool) {
        self.color = color
        self.pulses = pulses
    }

    public var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .padding(size * 0.375)
            .background {
                if pulses && !reduceMotion {
                    Circle()
                        .fill(color)
                        .phaseAnimator([false, true]) { ring, spread in
                            // From the dot's own size (8 of the 14-pt footprint) out to 26.
                            ring
                                .scaleEffect(spread ? 1.9 : 0.57)
                                .opacity(spread ? 0 : 0.4)
                        } animation: { spread in
                            spread ? Motion.pulse : nil
                        }
                }
            }
            .accessibilityHidden(true)
    }
}

/// A live dot and its line, the dot centred on the line's first row of capitals as in the
/// design. Sized for 16-pt text (`TextRole.body`).
public struct LiveLabel<Label: View>: View {
    /// Half the cap height of 16-pt text.
    @ScaledMetric(relativeTo: .callout) private var capHalf: CGFloat = 5.6
    private let color: Color
    private let pulses: Bool
    private let label: Label

    public init(color: Color, pulses: Bool, @ViewBuilder label: () -> Label) {
        self.color = color
        self.pulses = pulses
        self.label = label()
    }

    public var body: some View {
        let half = capHalf
        HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
            LiveDot(color: color, pulses: pulses)
                .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + half }
            label
        }
    }
}
