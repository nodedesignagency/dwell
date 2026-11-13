import DwellCore
import SwiftUI

// The scenery of the weekly wrap's "Work vs yours" page (Weekly wrap design, 13 Nov): wavy
// stripes drawn in code from the designer's reference image, the water that splits work from
// yours, and the pop that brings its art in. Built to be reused by later wrap pages.

// MARK: - Wavy stripes

/// Op-art stripes that bend and fold (the designer's Pinterest reference, placed in Figma at
/// 10%, 736 × 1121 at −145, −134 on the 393-wide frame), redrawn in code and set moving.
///
/// The stripes are curves, every other gap filled: they run gently downhill to the right,
/// then rise through a soft step and pack closer (about 150 apart before it, 95 after, in the
/// reference's pixels), the step sitting further left the lower the stripe. A diagonal fold
/// swaps the two colours on its left, as a chequered flag does. Fitted to the reference by
/// eye, not traced.
///
/// Moving: each stripe's step sways left and right by about 22 pt, a little behind the one
/// above, so a ripple runs down the page (one sway every 7.9 s), and the fold leans a little
/// with it (every 12.6 s). Under Reduce Motion it holds still. Draw it at full strength and
/// set its opacity where it's used (10% on Work vs yours).
public struct WavyStripes: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now
    private let light: Color
    private let deep: Color

    public init(light: Color = Palette.wrapStripe, deep: Color = Palette.wrapStripeDeep) {
        self.light = light
        self.deep = deep
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: reduceMotion)) { context in
            let time = reduceMotion ? 0 : context.date.timeIntervalSince(start)
            let light = light
            let deep = deep
            Canvas { canvas, size in
                Self.draw(in: &canvas, size: size, time: time, light: light, deep: deep)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The reference image's pixels, as placed on the 393-wide frame.
    nonisolated private static let imageWidth: Double = 1313
    nonisolated private static let placedWidth: Double = 736
    nonisolated private static let placedAt = CGPoint(x: -145, y: -134)
    /// Where the curves are sampled across, in the reference's pixels: the part of the image
    /// the screen shows, and a little either side.
    nonisolated private static let samples = stride(from: 180.0, through: 1060.0, by: 10.0).map { $0 }

    nonisolated private static func draw(in context: inout GraphicsContext, size: CGSize, time: Double, light: Color, deep: Color) {
        // Into the reference's pixels, scaled with the screen's width.
        let unit = size.width / 393
        context.translateBy(x: placedAt.x * unit, y: placedAt.y * unit)
        let scale = placedWidth / imageWidth * unit
        context.scaleBy(x: scale, y: scale)

        let curves = (-2..<26).map { boundary($0, time: time) }
        var bands = Path()
        for index in stride(from: 0, to: curves.count - 1, by: 2) {
            let upper = curves[index]
            let lower = curves[index + 1]
            bands.move(to: upper[0])
            for point in upper.dropFirst() { bands.addLine(to: point) }
            for point in lower.reversed() { bands.addLine(to: point) }
            bands.closeSubpath()
        }

        let everywhere = Path(CGRect(x: -200, y: -800, width: 1700, height: 4000))
        context.fill(everywhere, with: .color(light))
        context.fill(bands, with: .color(deep))

        // Left of the fold the colours swap.
        let lean = 30 * sin(time * 0.5)
        var fold = Path()
        fold.move(to: CGPoint(x: -200, y: 150))
        fold.addLine(to: CGPoint(x: 615 + lean, y: 150))
        fold.addLine(to: CGPoint(x: 0 + lean, y: 1990))
        fold.addLine(to: CGPoint(x: -615 + lean, y: 3830))
        fold.addLine(to: CGPoint(x: -200, y: 3830))
        fold.closeSubpath()
        context.drawLayer { layer in
            layer.clip(to: fold)
            layer.fill(everywhere, with: .color(deep))
            layer.fill(bands, with: .color(light))
        }
    }

    /// One stripe edge, `index` down from the top: where it starts at the left, how far its
    /// step rises (further for lower stripes, so they pack closer on the right), and where
    /// the step sits (further left for lower stripes, swaying with time).
    nonisolated private static func boundary(_ index: Int, time: Double) -> [CGPoint] {
        let j = Double(index)
        let centre = 1080 - 26 * j + 40 * sin(time * 0.8 + j * 0.45)
        let width = max(60, 150 + 10 * j)
        let rise = 70 + j * (50 - 0.3 * j)
        var y = 60 + j * (150 - 0.5 * j) + 0.14 * samples[0]
        var points: [CGPoint] = []
        points.reserveCapacity(samples.count)
        var previousX = samples[0]
        for x in samples {
            let step = smoothstep(centre - width, centre + width, x)
            // Downhill before the step, a little uphill after it.
            y += (0.14 - 0.30 * step) * (x - previousX)
            previousX = x
            points.append(CGPoint(x: x, y: y - rise * step))
        }
        return points
    }

    nonisolated private static func smoothstep(_ low: Double, _ high: Double, _ x: Double) -> Double {
        let t = min(max((x - low) / (high - low), 0), 1)
        return t * t * (3 - 2 * t)
    }
}

// MARK: - Water

/// Two colours split by a line of water (Weekly wrap design, "Work vs yours", the designer's
/// idea: "a watery wave that divides at work and yours"): `top` above, `water` below.
///
/// The surface is two waves added together (300 and 170 wide, 5 and 2.5 high), running
/// opposite ways, with a paler wave a little behind it (the water at 45%, 7 higher) for depth.
/// When it appears the water rises from below the screen to `level` on a soft spring that
/// overshoots a little and settles in about 1.4 s, sloshing higher at first and calming as it
/// settles. `overlay` lies over both colours (the stripes); `floating` rides the surface at
/// the middle, bobbing and tipping with the wave. Under Reduce Motion the water is still and
/// already at its level.
public struct WaterSplit<Overlay: View, Floating: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now
    private let top: Color
    private let water: Color
    private let level: CGFloat
    private let overlay: Overlay
    private let floating: Floating

    /// - Parameter level: where the surface settles, down from the top of the space.
    public init(
        top: Color,
        water: Color,
        level: CGFloat,
        @ViewBuilder overlay: () -> Overlay,
        @ViewBuilder floating: () -> Floating
    ) {
        self.top = top
        self.water = water
        self.level = level
        self.overlay = overlay()
        self.floating = floating()
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: reduceMotion)) { context in
            let time = reduceMotion ? 0 : context.date.timeIntervalSince(start)
            GeometryReader { proxy in
                let size = proxy.size
                let rest = reduceMotion ? level : Self.rising(from: size.height + 24, to: level, at: time)
                let slosh = reduceMotion ? 0 : exp(-1.2 * max(0, time - Self.delay))
                let middle = size.width / 2
                let top = top
                let water = water
                ZStack(alignment: .topLeading) {
                    Canvas { canvas, size in
                        canvas.fill(Path(CGRect(origin: .zero, size: size)), with: .color(top))
                        canvas.fill(
                            Self.surfacePath(size: size, level: rest - 7, time: -time * 0.8 + 1.2, slosh: slosh),
                            with: .color(water.opacity(0.45)))
                        canvas.fill(
                            Self.surfacePath(size: size, level: rest, time: time, slosh: slosh),
                            with: .color(water))
                    }
                    overlay
                    floating
                        .rotationEffect(.radians(atan(Self.slope(at: middle, time: time, slosh: slosh)) * 0.6))
                        .position(x: middle, y: rest + Self.surface(at: middle, time: time, slosh: slosh))
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// The page settles before the water moves.
    nonisolated private static var delay: Double { 0.2 }

    /// The surface's height above or below its level at `x`.
    nonisolated private static func surface(at x: CGFloat, time: Double, slosh: Double) -> CGFloat {
        let long = 2 * Double.pi * Double(x) / 300
        let short = 2 * Double.pi * Double(x) / 170
        return CGFloat((5 + 12 * slosh) * sin(long + time * 1.6) + (2.5 + 5 * slosh) * sin(short - time * 2.3))
    }

    nonisolated private static func slope(at x: CGFloat, time: Double, slosh: Double) -> Double {
        let long = 2 * Double.pi / 300
        let short = 2 * Double.pi / 170
        return (5 + 12 * slosh) * long * cos(long * Double(x) + time * 1.6)
            + (2.5 + 5 * slosh) * short * cos(short * Double(x) - time * 2.3)
    }

    nonisolated private static func surfacePath(size: CGSize, level: CGFloat, time: Double, slosh: Double) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        var x: CGFloat = 0
        while x <= size.width + 4 {
            path.addLine(to: CGPoint(x: x, y: level + surface(at: x, time: time, slosh: slosh)))
            x += 4
        }
        path.addLine(to: CGPoint(x: size.width + 4, y: size.height))
        path.closeSubpath()
        return path
    }

    /// From below the screen to `level` on a damped spring: a little past it, then back.
    nonisolated private static func rising(from bottom: CGFloat, to level: CGFloat, at time: Double) -> CGFloat {
        let t = time - delay
        guard t > 0 else { return bottom }
        let damping = 0.55
        let omega = 2 * Double.pi / 1.1
        let damped = omega * (1 - damping * damping).squareRoot()
        let progress = 1 - exp(-damping * omega * t) * (cos(damped * t) + damping * omega / damped * sin(damped * t))
        return bottom + (level - bottom) * CGFloat(progress)
    }
}

// MARK: - Popping in

extension View {
    /// Pops in once it appears (the weekly wrap's art, "Work vs yours"): from 30% and turned
    /// −10°, springing to full size with a little overshoot (`Motion.pop`) after `delay`.
    /// Under Reduce Motion it fades in.
    public func popIn(delay: Double = 0) -> some View {
        modifier(PopIn(delay: delay))
    }
}

private struct PopIn: ViewModifier {
    let delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false

    func body(content: Content) -> some View {
        let away = !isShown && !reduceMotion
        content
            .scaleEffect(away ? 0.3 : 1)
            .rotationEffect(.degrees(away ? -10 : 0))
            .opacity(isShown ? 1 : 0)
            .animation((reduceMotion ? Motion.reduced : Motion.pop).delay(delay), value: isShown)
            .onAppear { isShown = true }
            .onDisappear { isShown = false }
    }
}

// MARK: - Slanted checks

/// A chequer of slanted tiles drifting up the page (the designer's pattern, "Group 1216257344",
/// Weekly wrap 5, "Earliest exit this week"): white at 4%, cells 28.714 wide and 28.5 tall,
/// every other one filled, each row 0.35 of its height further left than the one above, so the
/// tiles lean like the SVG's. Drawn in code to fill any screen, not from the file.
///
/// Moving (the wrap's patterns all move, the user, 13 Nov): the chequer drifts up along its
/// slant, one repeat (two rows) every 6 s, on a loop that never jumps. Under Reduce Motion it
/// holds still.
public struct SlantedChecks: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now
    private let color: Color
    private let opacity: Double

    public init(color: Color = .white, opacity: Double = 0.04) {
        self.color = color
        self.opacity = opacity
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: reduceMotion)) { context in
            let time = reduceMotion ? 0 : context.date.timeIntervalSince(start)
            let tint = color.opacity(opacity)
            Canvas { canvas, size in
                canvas.fill(Self.tiles(in: size, time: time), with: .color(tint))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    nonisolated private static let cellWidth: Double = 28.714
    nonisolated private static let cellHeight: Double = 28.5
    /// How far left a row sits, per point down.
    nonisolated private static let lean: Double = 0.35
    nonisolated private static let repeatSeconds: Double = 6

    nonisolated private static func tiles(in size: CGSize, time: Double) -> Path {
        let w = cellWidth, h = cellHeight
        // One repeat up the slant: two rows up, and the lean's worth right, so every tile
        // lands where another was.
        let progress = (time / repeatSeconds).truncatingRemainder(dividingBy: 1)
        let shiftX = 2 * h * lean * progress
        let shiftY = -2 * h * progress
        var path = Path()
        let firstRow = Int(((-shiftY) / h).rounded(.down)) - 1
        let lastRow = Int(((Double(size.height) - shiftY) / h).rounded(.up)) + 1
        for row in firstRow...lastRow {
            let top = Double(row) * h
            // Columns that reach the screen at this row, in the unslanted grid.
            let firstColumn = Int(((lean * top - shiftX - w) / w).rounded(.down)) - 1
            let lastColumn = Int(((Double(size.width) + lean * (top + h) - shiftX + w) / w).rounded(.up)) + 1
            for column in firstColumn...lastColumn where (row + column).isMultiple(of: 2) {
                let left = Double(column) * w + shiftX
                let y0 = top + shiftY
                path.move(to: CGPoint(x: left - lean * top, y: y0))
                path.addLine(to: CGPoint(x: left + w - lean * top, y: y0))
                path.addLine(to: CGPoint(x: left + w - lean * (top + h), y: y0 + h))
                path.addLine(to: CGPoint(x: left - lean * (top + h), y: y0 + h))
                path.closeSubpath()
            }
        }
        return path
    }
}
