import SwiftUI

/// Motion with purpose (brief §5): a timer that ticks, a bar that fills, a cell that
/// scratches off, a record that lands with weight. Placeholder curves until the motion
/// specs land in docs/DESIGN.md.
public enum Motion {
    /// Most state changes.
    public static let standard = Animation.spring(duration: 0.35, bounce: 0.1)
    /// Bars filling, cells revealing.
    public static let reveal = Animation.spring(duration: 0.6, bounce: 0.15)
    /// Records, badges, streaks landing.
    public static let landing = Animation.spring(duration: 0.5, bounce: 0.35)
    /// What any of the above becomes under Reduce Motion: a short cross-fade, no movement.
    public static let reduced = Animation.easeInOut(duration: 0.2)
}

extension View {
    /// Animates changes to `value`, swapping to `Motion.reduced` when Reduce Motion is on.
    ///
    /// A cross-fade is only a real fallback when the change is visual, not spatial. For moves,
    /// scales and reveals, also swap the transition itself (see docs/DESIGN.md, Motion).
    public func motion<V: Equatable>(_ animation: Animation = Motion.standard, value: V) -> some View {
        modifier(MotionModifier(animation: animation, value: value))
    }
}

private struct MotionModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? Motion.reduced : animation, value: value)
    }
}
