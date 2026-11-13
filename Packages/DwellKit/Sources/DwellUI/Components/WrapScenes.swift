import DwellCore
import SwiftUI

// The scenery of the weekly wrap's "Work vs yours" page (Weekly wrap design, 13 Nov): wavy
// stripes drawn in code from the designer's reference image, the water that splits work from
// yours, and the puffy bubble title floating on it. Built to be reused by later wrap pages.

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

// MARK: - Bubble title

/// A title set as a puffy sticker (Weekly wrap design, "Work vs yours", the designer's art
/// rebuilt in type): white letters shaded like soft plastic, lighter at the top and greying
/// towards the bottom, each tipped a few degrees for a hand-placed look; a navy outline round
/// them that fills the gaps between letters (`bubbleOutline`, about 3.5 wide) and a white rim
/// round that (about 3 more). Two lines: everything but the last word, then the last word,
/// centred.
///
/// The type is SF Pro Rounded Black at 39 with tight tracking, the nearest system face to the
/// art's lettering; a display face could get closer (QUESTIONS.md). The outlines are the
/// letters blurred and cut off at a low opacity, so they swell evenly with round corners.
/// Measured from the art at 162 × 94 on the page; a fixed size, as art is.
///
/// It pops in once the page is up: from 30% and turned −10°, springing to full size
/// (`Motion.pop`) after `delay`. Under Reduce Motion it fades in. VoiceOver reads the title
/// as a header.
public struct BubbleTitle: View {
    @Environment(\.dial) private var dial
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false
    private let line: VoicedLine
    private let delay: Double

    public init(_ line: VoicedLine, delay: Double = 0) {
        self.line = line
        self.delay = delay
    }

    public var body: some View {
        let text = line.text(for: dial)
        let letters = BubbleLetters(lines: Self.lines(text))
        letters
            .padding(12)
            .background { Swollen(by: 3.5, color: Palette.bubbleOutline) { letters } }
            .background { Swollen(by: 6.5, color: .white) { letters } }
            .scaleEffect(isShown || reduceMotion ? 1 : 0.3)
            .rotationEffect(.degrees(isShown || reduceMotion ? 0 : -10))
            .opacity(isShown ? 1 : 0)
            .animation((reduceMotion ? Motion.reduced : Motion.pop).delay(delay), value: isShown)
            .onAppear { isShown = true }
            .onDisappear { isShown = false }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
            .accessibilityAddTraits(.isHeader)
    }

    /// "Work vs yours" → ["Work vs", "yours"].
    static func lines(_ text: String) -> [String] {
        let words = text.split(separator: " ")
        guard words.count > 1 else { return [text] }
        return [words.dropLast().joined(separator: " "), String(words[words.count - 1])]
    }
}

/// The bubble title's letters, one by one so each can tip and sit a little high or low.
private struct BubbleLetters: View {
    let lines: [String]

    /// Each letter's tip and lift, in turn: enough to look placed by hand, never enough to
    /// read as a wobble.
    private static let tips: [Double] = [-6, 4, -3, 5, -4, 3, -5, 4, -2, 6]
    private static let lifts: [CGFloat] = [0, -1.5, 1, -1, 1.5, 0, -1, 1]

    var body: some View {
        VStack(spacing: -10) {
            ForEach(Array(lines.enumerated()), id: \.offset) { row, line in
                HStack(spacing: -1.5) {
                    ForEach(Array(line.enumerated()), id: \.offset) { column, letter in
                        let turn = row * 5 + column
                        if letter == " " {
                            Color.clear.frame(width: 9, height: 1)
                        } else {
                            Text(String(letter))
                                .font(.system(size: 39, weight: .black, design: .rounded))
                                .foregroundStyle(Self.puffy)
                                .rotationEffect(.degrees(Self.tips[turn % Self.tips.count]))
                                .offset(y: Self.lifts[turn % Self.lifts.count])
                        }
                    }
                }
            }
        }
        .fixedSize()
    }

    /// White at the top, greying towards the bottom (`bubbleShade`), with a soft shade along
    /// each letter's lower edge and a bright line along its upper one: soft plastic.
    private static var puffy: some ShapeStyle {
        LinearGradient(
            stops: [
                .init(color: .white, location: 0.4),
                .init(color: Palette.bubbleShade, location: 1),
            ],
            startPoint: .top, endPoint: .bottom)
            .shadow(.inner(color: Palette.bubbleOutline.opacity(0.35), radius: 1.2, x: 0, y: -1.6))
            .shadow(.inner(color: .white, radius: 0.8, x: 0, y: 1.2))
    }
}

/// Its content swollen by about `by` points all round, in one colour, its corners rounded:
/// the content blurred, then kept wherever it's more than 10% there. Fills the space it's
/// given, the content centred in it.
private struct Swollen<Content: View>: View {
    let by: CGFloat
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        let color = color
        let radius = by / 1.28
        Canvas { context, size in
            // A blurred edge passes 10% about 1.28 blur radii out.
            context.addFilter(.alphaThreshold(min: 0.1, color: color))
            context.addFilter(.blur(radius: radius))
            context.drawLayer { layer in
                if let letters = layer.resolveSymbol(id: 0) {
                    layer.draw(letters, at: CGPoint(x: size.width / 2, y: size.height / 2))
                }
            }
        } symbols: {
            content.tag(0)
        }
        .accessibilityHidden(true)
    }
}
