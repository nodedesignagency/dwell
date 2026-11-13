import SwiftUI

/// A wall clock showing a time of day (Weekly wrap design, "Earliest exit this week"): the
/// designer's face (`Art.Illustration.clockFace`) with its hands drawn in code, so it can show
/// any time. Hour and minute only: it shows a moment that has passed, so nothing ticks and
/// there's no second hand (the user, 13 Nov).
///
/// The hands follow the small black clock in the designer's reference (the user's pick): slim
/// black bars (`clockHand`) with round ends, both starting at the centre with nothing past it,
/// tapering a little towards the tip, resting on the face with a faint shadow that keeps its
/// light as they turn. Measured from the reference as shares of the clock's width: the minute
/// hand reaches 0.43 from the centre, the hour hand 0.285; both 0.056 wide at the centre,
/// the minute hand 0.046 at its tip, the hour hand 0.05.
///
/// Motion: once it appears, the hands sweep forward from 12:00 to the time, the minute hand
/// round and round, and settle with a little give (`Motion.clockSweep`) after `delay`; then
/// they stay still. Under Reduce Motion they're at the time from the start. Decorative: the
/// page says the time in words.
public struct WallClock: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownMinutes: Double = 0
    private let minutes: Double?
    private let delay: Double

    /// - Parameters:
    ///   - hour: 0 to 23; `nil` with `minute` to show the face alone.
    ///   - delay: how long after appearing the hands start their sweep.
    public init(hour: Int?, minute: Int?, delay: Double = 0) {
        if let hour, let minute {
            minutes = Double((hour % 12) * 60 + minute)
        } else {
            minutes = nil
        }
        self.delay = delay
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                Art.Illustration.clockFace
                    .resizable()
                    .scaledToFit()
                if minutes != nil {
                    // Hour: half a degree a minute. Minute: six.
                    hand(reach: 0.285, base: 0.056, tip: 0.05, size: size, degrees: shownMinutes * 0.5)
                    hand(reach: 0.43, base: 0.056, tip: 0.046, size: size, degrees: shownMinutes * 6)
                }
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear(perform: sweep)
        .onChange(of: minutes) { sweep() }
        .accessibilityHidden(true)
    }

    private func hand(reach: CGFloat, base: CGFloat, tip: CGFloat, size: CGFloat, degrees: Double) -> some View {
        let length = reach * size
        let width = base * size
        return SlimHand(tipShare: tip / base, pivot: length / (length + width / 2))
            .fill(Palette.clockHand)
            .frame(width: width, height: length + width / 2)
            // Its pivot, the centre of its round base, on the clock's centre.
            .offset(y: -(length - width / 2) / 2)
            .rotationEffect(.degrees(degrees))
            // After the turn, so the shadow always falls the same way.
            .shadow(color: .black.opacity(0.18), radius: 1.5, x: 1, y: 1.5)
    }

    private func sweep() {
        guard let minutes else { return }
        if reduceMotion {
            shownMinutes = minutes
        } else {
            withAnimation(Motion.clockSweep.delay(delay)) { shownMinutes = minutes }
        }
    }
}

/// A clock hand pointing up: round at both ends, the full width at its base (centred at
/// `pivot`, a share of the height down) narrowing to `tipShare` of it at the tip.
nonisolated private struct SlimHand: Shape {
    let tipShare: CGFloat
    let pivot: CGFloat

    func path(in rect: CGRect) -> Path {
        let base = rect.width / 2
        let tip = base * tipShare
        let pivotY = rect.minY + rect.height * pivot
        let tipY = rect.minY + tip
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - base, y: pivotY))
        path.addLine(to: CGPoint(x: rect.midX - tip, y: tipY))
        path.addArc(
            center: CGPoint(x: rect.midX, y: tipY), radius: tip,
            startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.midX + base, y: pivotY))
        path.addArc(
            center: CGPoint(x: rect.midX, y: pivotY), radius: base,
            startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        path.closeSubpath()
        return path
    }
}
