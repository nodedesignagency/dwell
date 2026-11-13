import SwiftUI

/// A wall clock showing a time of day (Weekly wrap design, "Earliest exit this week"): the
/// designer's face (`Art.Illustration.clockFace`) with its hands drawn in code, so it can show
/// any time.
///
/// The hands follow the design's placeholder ones: flat charcoal bars (`clockHand`) with
/// square ends, each running a little past the centre, casting a soft shadow on the face; the
/// minute hand 0.335 of the clock long and 0.03 wide, the hour hand 0.215 long and 0.034 wide,
/// both 0.065 past the centre. The second hand is a thin red line (`clockSecond`, 0.007 wide)
/// with a disc at its tip (0.048 across), 0.25 long and 0.07 past the centre, as on a railway
/// clock. Sizes are shares of the clock's width.
///
/// Motion: once it appears, the hands sweep forward from 12:00 to the time, the minute hand
/// round and round, settling with a little give (`Motion.clockSweep`) after `delay`; the
/// second hand sweeps on round the face, a turn a minute, starting from 6 where the design
/// draws it. Under Reduce Motion the hands are at the time from the start and the second hand
/// holds still. Decorative: the page says the time in words.
public struct WallClock: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownMinutes: Double = 0
    private let minutes: Double?
    private let delay: Double

    /// - Parameters:
    ///   - hour: 0 to 23; `nil` with `minute` to show no time, only the running second hand.
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
                    // The shadows fall after the turn, so the light stays where it is.
                    Hand(length: 0.215 * size, tail: 0.065 * size, width: 0.034 * size)
                        .rotationEffect(.degrees(shownMinutes * 0.5))
                        .shadow(color: .black.opacity(0.25), radius: 1.5, x: 0, y: 1.5)
                    Hand(length: 0.335 * size, tail: 0.065 * size, width: 0.03 * size)
                        .rotationEffect(.degrees(shownMinutes * 6))
                        .shadow(color: .black.opacity(0.25), radius: 1.5, x: 0, y: 1.5)
                }
                SecondHand(size: size)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear(perform: sweep)
        .onChange(of: minutes) { sweep() }
        .accessibilityHidden(true)
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

/// An hour or minute hand pointing at 12, pivoting on the clock's centre.
private struct Hand: View {
    let length: CGFloat
    let tail: CGFloat
    let width: CGFloat

    var body: some View {
        Rectangle()
            .fill(Palette.clockHand)
            .frame(width: width, height: length + tail)
            // Its pivot, `tail` up from the bottom, on the frame's centre.
            .offset(y: -(length - tail) / 2)
    }
}

/// The red second hand, sweeping a turn a minute from 6, as the design draws it.
private struct SecondHand: View {
    let size: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: reduceMotion)) { context in
            let seconds = 30 + (reduceMotion ? 0 : context.date.timeIntervalSince(start))
            let length = 0.25 * size
            let tail = 0.07 * size
            let disc = 0.048 * size
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(Palette.clockSecond)
                    .frame(width: 0.007 * size, height: length + tail)
                Circle()
                    .fill(Palette.clockSecond)
                    .frame(width: disc, height: disc)
                    .offset(y: -disc / 2)
            }
            .frame(width: disc, height: length + tail, alignment: .top)
            .offset(y: -(length - tail) / 2)
            .rotationEffect(.degrees(seconds * 6))
            .shadow(color: .black.opacity(0.25), radius: 1.5, x: 0, y: 1.5)
        }
    }
}
