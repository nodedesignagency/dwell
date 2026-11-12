import SwiftUI

/// Sixteen rays from a centre, fading out from it, turning slowly: a full circle every 24 s.
/// Figma's "Frame 2147239465" glow, behind the hero tiles' icons (ink) and a sheet's art
/// (light). Under Reduce Motion they hold still.
struct TurningRays: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let color: Color
    /// The square the rays are drawn in.
    let size: CGFloat
    /// Where the gradient reaches nothing: 50% of `color` at the centre, 0 here.
    let fadeRadius: CGFloat

    var body: some View {
        let drawn = Rays(count: 16, share: 0.6)
            .fill(RadialGradient(
                colors: [color.opacity(0.5), color.opacity(0)],
                center: .center, startRadius: 0, endRadius: fadeRadius))
            .frame(width: size, height: size)
            // Drawn once, then turned: cheaper than redrawing the wedges every frame.
            .drawingGroup()
        if reduceMotion {
            drawn
        } else {
            // 0° and 360° look the same, so the jump back between turns is never seen.
            drawn.phaseAnimator([0.0, 360.0]) { content, angle in
                content.rotationEffect(.degrees(angle))
            } animation: { angle in
                angle == 360 ? Motion.spin : nil
            }
        }
    }
}

/// Wedges from the centre out to the edge, evenly spaced, each filling `share` of its slice.
nonisolated struct Rays: Shape {
    var count: Int
    var share: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let step = 2 * Double.pi / Double(count)
        let half = step * share / 2
        var path = Path()
        for index in 0..<count {
            let middle = Double(index) * step - Double.pi / 2
            path.move(to: center)
            path.addLine(to: CGPoint(x: center.x + radius * cos(middle - half), y: center.y + radius * sin(middle - half)))
            path.addLine(to: CGPoint(x: center.x + radius * cos(middle + half), y: center.y + radius * sin(middle + half)))
            path.closeSubpath()
        }
        return path
    }
}
