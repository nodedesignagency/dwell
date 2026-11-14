import SwiftUI

/// A wall clock showing a time of day (Weekly wrap design, "Earliest exit this week"): the
/// designer's face (`Art.Illustration.clockFace`) with its hands drawn in code, so it can show
/// any time.
///
/// The hands are the design's own (the user's call, 14 Nov, after trying the reference's white
/// and black ones): flat charcoal bars (`clockHand`) with square ends, each running on past
/// the centre, resting on the face with a soft shadow that keeps its light as they turn; and
/// the thin red second hand (`clockSecond`) with a disc at its tip, standing still, since the
/// clock shows a moment that has passed: pointing down as drawn, or, when a hand is already
/// there, into the clearest gap (`secondDegrees`). Measured from the design as
/// shares of the clock's width (268): the minute hand reaches 0.343 with 0.112 past the
/// centre, 0.032 wide; the hour hand 0.228 with 0.093, 0.035 wide; the second hand 0.0065 wide,
/// its disc (0.041 across) centred 0.2245 below the centre, 0.096 above it.
///
/// Motion: once it appears, the hour and minute hands sweep forward from 12:00 to the time,
/// the minute hand round and round, and settle with a little give (`Motion.clockSweep`) after
/// `delay`; then nothing moves. Under Reduce Motion they're at the time from the start.
/// Decorative: the page says the time in words.
public struct WallClock: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownMinutes: Double = 0
    private let minutes: Double?
    private let delay: Double

    /// - Parameters:
    ///   - hour: 0 to 23; `nil` with `minute` to show no time, only the still second hand.
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
                    bar(reach: 0.228, past: 0.093, width: 0.035, size: size, degrees: shownMinutes * 0.5)
                    bar(reach: 0.343, past: 0.112, width: 0.032, size: size, degrees: shownMinutes * 6)
                }
                SecondHand(size: size)
                    .rotationEffect(.degrees(secondDegrees))
                    .shadow(color: .black.opacity(0.25), radius: 1.5, x: 0, y: 1.5)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear(perform: sweep)
        .onChange(of: minutes) { sweep() }
        .accessibilityHidden(true)
    }

    /// An hour or minute hand: a bar `reach` up from the centre and `past` below it.
    private func bar(reach: CGFloat, past: CGFloat, width: CGFloat, size: CGFloat, degrees: Double) -> some View {
        let up = reach * size
        let down = past * size
        return Rectangle()
            .fill(Palette.clockHand)
            .frame(width: width * size, height: up + down)
            // Its pivot, `down` up from the bottom, on the clock's centre.
            .offset(y: -(up - down) / 2)
            .rotationEffect(.degrees(degrees))
            // After the turn, so the shadow always falls the same way.
            .shadow(color: .black.opacity(0.25), radius: 1.5, x: 0, y: 1.5)
    }

    /// Where the still second hand rests: pointing down, as the design draws it, unless the
    /// hour or minute hand is within 20° of that (5:52 puts the hour hand there); then in the
    /// middle of the widest gap between them, so the three never lie on top of each other.
    private var secondDegrees: Double {
        guard let minutes else { return 180 }
        let hour = (minutes * 0.5).truncatingRemainder(dividingBy: 360)
        let minute = (minutes * 6).truncatingRemainder(dividingBy: 360)
        func apart(_ a: Double, _ b: Double) -> Double {
            let difference = abs(a - b).truncatingRemainder(dividingBy: 360)
            return min(difference, 360 - difference)
        }
        if apart(180, hour) > 20, apart(180, minute) > 20 { return 180 }
        let low = min(hour, minute)
        let high = max(hour, minute)
        let between = high - low
        return between >= 360 - between
            ? (low + high) / 2
            : ((high + low + 360) / 2).truncatingRemainder(dividingBy: 360)
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

/// The red second hand pointing up, a disc at its tip; the clock turns it to where it rests.
private struct SecondHand: View {
    let size: CGFloat

    var body: some View {
        let disc = 0.041 * size
        let reach = 0.2245 * size
        let past = 0.096 * size
        ZStack(alignment: .top) {
            Rectangle()
                .fill(Palette.clockSecond)
                .frame(width: 0.0065 * size, height: reach + past)
            Circle()
                .fill(Palette.clockSecond)
                .frame(width: disc, height: disc)
                // Centred on the hand's tip.
                .offset(y: -disc / 2)
        }
        .frame(width: disc, height: reach + past, alignment: .top)
        // Its pivot, `past` up from the bottom, on the clock's centre.
        .offset(y: -(reach - past) / 2)
    }
}
