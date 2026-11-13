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
    /// Light passing across a card that's waiting for an answer, left to right, on a loop.
    public static let sweep = Animation.linear(duration: 2.4)
    /// A card arriving from below (the confirmation card, a bottom sheet): smooth, no bounce.
    public static let arrive = Animation.spring(duration: 0.5, bounce: 0)
    /// A bottom sheet leaving: quicker than it came, gathering speed as it goes.
    public static let leave = Animation.easeIn(duration: 0.25)
    /// The live dot's ring, spreading out and fading, on a loop.
    public static let pulse = Animation.easeOut(duration: 1.6)
    /// One half turn of an icon shuffle: gathers speed as the icon turns away, eases off as
    /// the next one turns to face you. No overshoot.
    public static let flip = Animation.timingCurve(0.6, 0, 0.4, 1, duration: 0.5)
    /// The rays behind a hero tile's icon turning a full circle, on a loop.
    public static let spin = Animation.linear(duration: 24)
    /// 3D art popping out from behind a wrap page's title to its place: quick, with a bounce.
    public static let pop = Animation.spring(duration: 0.6, bounce: 0.4)
    /// Art drifting where it rests, up and back, on a loop: slow enough to read as floating.
    public static let float = Animation.easeInOut(duration: 2.8)
    /// What any of the above becomes under Reduce Motion: a short cross-fade, no movement.
    public static let reduced = Animation.easeInOut(duration: 0.2)
    /// The sky turning from one phase to the next: slow enough to watch the sun travel.
    public static let skyChange = Animation.easeInOut(duration: 2.6)
    /// The sky settling in each time the app opens.
    public static let skySettle = Animation.easeOut(duration: 1.4)
    /// A sky change under Reduce Motion: a cross-fade, long enough not to flash a whole header.
    public static let skyFade = Animation.easeInOut(duration: 0.8)
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
