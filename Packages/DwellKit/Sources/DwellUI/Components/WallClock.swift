import SwiftUI

/// A wall clock showing a time of day (Weekly wrap design, "Earliest exit this week"): the
/// designer's face (`Art.Illustration.clockFace`) with its hands drawn in code, so it can show
/// any time. Hour and minute only: it shows a moment that has passed, so nothing ticks and
/// there's no second hand (the user, 13 Nov).
///
/// The hands follow the designer's reference ("Pure White Clock"): white spears that taper
/// from a wide base at the centre to a flat tip a little over half as wide, lit along one side
/// and shaded along the other (`clockHand` to `clockHandShade`), each with a short stub past
/// the centre, lifted off the face by a soft cool shadow falling down and to the right
/// (`clockShadow`), the light staying put as they turn. A brass cap covers the centre
/// (`clockHubLight` to `clockHub`, ringed in `clockHubRim`). Sizes are shares of the clock's
/// width: the minute hand 0.37 long, 0.036 wide at its base; the hour hand 0.25 long, 0.04
/// wide; stubs 0.055; the cap 0.045 across. Colours read from the reference.
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
    ///   - hour: 0 to 23; `nil` with `minute` to show the face with no hands, only its cap.
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
                    hand(length: 0.25, base: 0.04, size: size, degrees: shownMinutes * 0.5)
                    hand(length: 0.37, base: 0.036, size: size, degrees: shownMinutes * 6)
                }
                BrassCap()
                    .frame(width: 0.045 * size, height: 0.045 * size)
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear(perform: sweep)
        .onChange(of: minutes) { sweep() }
        .accessibilityHidden(true)
    }

    private func hand(length: CGFloat, base: CGFloat, size: CGFloat, degrees: Double) -> some View {
        let reach = length * size
        let stub = 0.055 * size
        return TaperedHand(pivot: reach / (reach + stub))
            .fill(LinearGradient(
                colors: [Palette.clockHand, Palette.clockHandShade],
                startPoint: .leading, endPoint: .trailing))
            .frame(width: base * size, height: reach + stub)
            // Its pivot, `stub` up from the bottom, on the clock's centre.
            .offset(y: -(reach - stub) / 2)
            .rotationEffect(.degrees(degrees))
            // After the turn, so the shadow always falls the same way.
            .shadow(color: Palette.clockShadow.opacity(0.3), radius: 3, x: 2.5, y: 3)
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

/// A clock hand pointing up: a flat tip a little over half the base's width, widening to the
/// base at `pivot` (a share of the height down), then a stub of the base's width below it.
nonisolated private struct TaperedHand: Shape {
    let pivot: CGFloat

    func path(in rect: CGRect) -> Path {
        let tip = rect.width * 0.56
        let pivotY = rect.minY + rect.height * pivot
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - tip / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + tip / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: pivotY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: pivotY))
        path.closeSubpath()
        return path
    }
}

/// The brass cap over the hands' pivot: light at its middle, deeper towards a thin darker
/// ring, catching the light at its top left, with a small shadow of its own.
private struct BrassCap: View {
    var body: some View {
        Circle()
            .fill(EllipticalGradient(
                colors: [Palette.clockHubLight, Palette.clockHub],
                center: UnitPoint(x: 0.4, y: 0.35),
                startRadiusFraction: 0,
                endRadiusFraction: 0.6))
            .overlay {
                Circle().strokeBorder(Palette.clockHubRim, lineWidth: 0.75)
            }
            .shadow(color: Palette.clockShadow.opacity(0.35), radius: 1.5, x: 1, y: 1.5)
    }
}
