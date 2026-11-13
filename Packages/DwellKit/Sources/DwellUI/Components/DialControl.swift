import DwellCore
import SwiftUI

/// The tone dial (brief §6, A.6; You design): an arc from Peace to Grind with a dot at each
/// named stop and its name under it, and a white thumb dragged along the arc.
///
/// Continuous, as the brief asks: the dial sits wherever it's let go, and the nearest stop
/// names it (`Dial.stop`). A tap jumps to the nearest stop. A light tap of feel each time the
/// thumb passes a stop (`Haptic.dialStop`), nothing in between. VoiceOver adjusts it a stop at
/// a time.
///
/// Read from the screenshot (a card 353 wide, so 321 inside): the arc's ends 11 in from each
/// side and 24.5 below its top, a gentle curve; the stops 0, 23.5, 50, 76.5 and 100% of the way
/// across (the design's spacing, slightly wider in the middle than even); track 8, dots 4,
/// thumb 20. Labels 12, grey, centred on their dots and kept inside the control: the middle
/// three share a line 17 below the arc's top, the ends sit 7.5 below their dots. At
/// accessibility sizes only Peace and Grind keep their labels; the card's title names the stop.
public struct DialControl: View {
    @Binding private var position: Double
    private let label: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var labelHeight: CGFloat = 14.5
    @State private var passes = 0

    static let thumb: CGFloat = 20
    static let track: CGFloat = 8
    static let dot: CGFloat = 4
    /// Each stop's share of the way across, in `Dial.Stop.allCases` order.
    static let fractions: [Double] = [0, 0.235, 0.5, 0.765, 1]

    /// - Parameters:
    ///   - position: 0 (Peace) to 100 (Grind), as `Dial.position`.
    ///   - label: what VoiceOver calls it.
    public init(position: Binding<Double>, label: String) {
        _position = position
        self.label = label
    }

    public var body: some View {
        GeometryReader { proxy in
            let arc = DialArc(width: proxy.size.width, top: Self.thumb / 2)
            ZStack(alignment: .topLeading) {
                arc.path
                    .stroke(Palette.dialTrack, style: StrokeStyle(lineWidth: Self.track, lineCap: .round))
                ForEach(Array(Dial.Stop.allCases.enumerated()), id: \.element) { index, _ in
                    Circle()
                        .fill(Palette.dialStop)
                        .frame(width: Self.dot, height: Self.dot)
                        .position(arc.point(at: Self.fractions[index]))
                }
                StopLabels(tops: labeledStops.map { labelTop(for: $0, on: arc) },
                           xs: labeledStops.map { arc.point(at: Self.fraction(of: $0.position)).x }) {
                    ForEach(labeledStops, id: \.self) { stop in
                        Text(verbatim: stop.name)
                            .textRole(.footnote)
                            .foregroundStyle(Palette.textSecondary)
                            .fixedSize()
                    }
                }
                Circle()
                    .fill(Palette.ring)
                    .overlay { Circle().strokeBorder(Palette.outline, lineWidth: 1) }
                    .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
                    .frame(width: Self.thumb, height: Self.thumb)
                    .position(arc.point(at: Self.fraction(of: position)))
            }
            .contentShape(.rect)
            .gesture(drag(on: arc))
        }
        .frame(height: Self.thumb / 2 + 32 + labelHeight)
        .haptic(.dialStop, trigger: passes)
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue("\(stop.name). \(YouCopy.dialDescription(stop))")
        .accessibilityAdjustableAction { direction in
            let stops = Dial.Stop.allCases
            guard let index = stops.firstIndex(of: stop) else { return }
            switch direction {
            case .increment: move(to: stops[min(index + 1, stops.count - 1)].position, animated: true)
            case .decrement: move(to: stops[max(index - 1, 0)].position, animated: true)
            @unknown default: break
            }
        }
    }

    private var stop: Dial.Stop { Dial(position: position).stop }

    private var labeledStops: [Dial.Stop] {
        dynamicTypeSize.isAccessibilitySize ? [.peace, .grind] : Dial.Stop.allCases
    }

    /// The middle labels share a line; the ends drop with the arc.
    private func labelTop(for stop: Dial.Stop, on arc: DialArc) -> CGFloat {
        let dot = arc.point(at: Self.fraction(of: stop.position))
        return max(dot.y + 7.5, arc.top + 17)
    }

    private func drag(on arc: DialArc) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                move(to: Self.dialPosition(atFraction: arc.fraction(atX: value.location.x)), animated: false)
            }
            .onEnded { value in
                // A tap rather than a drag: settle on the nearest stop.
                if abs(value.translation.width) < 4, abs(value.translation.height) < 4 {
                    move(to: stop.position, animated: true)
                }
            }
    }

    private func move(to target: Double, animated: Bool) {
        let new = min(max(target, Dial.range.lowerBound), Dial.range.upperBound)
        let old = position
        guard new != old else { return }
        let passed = Dial.Stop.allCases.contains { stop in
            old < new ? (old < stop.position && stop.position <= new) : (new <= stop.position && stop.position < old)
        }
        if passed { passes += 1 }
        if animated, !reduceMotion {
            withAnimation(Motion.standard) { position = new }
        } else {
            position = new
        }
    }

    /// A dial position as a share of the way across: straight lines between the stops.
    static func fraction(of position: Double) -> Double {
        let stops = Dial.Stop.allCases
        let p = min(max(position, Dial.range.lowerBound), Dial.range.upperBound)
        for index in 1..<stops.count where p <= stops[index].position {
            let from = stops[index - 1].position
            let t = (p - from) / (stops[index].position - from)
            return fractions[index - 1] + t * (fractions[index] - fractions[index - 1])
        }
        return 1
    }

    /// The reverse of `fraction(of:)`.
    static func dialPosition(atFraction fraction: Double) -> Double {
        let stops = Dial.Stop.allCases
        let f = min(max(fraction, 0), 1)
        for index in 1..<stops.count where f <= fractions[index] {
            let t = (f - fractions[index - 1]) / (fractions[index] - fractions[index - 1])
            return stops[index - 1].position + t * (stops[index].position - stops[index - 1].position)
        }
        return Dial.range.upperBound
    }
}

/// The dial's curve: a shallow arch, highest in the middle, its ends `sag` lower. Drawn as a
/// quadratic curve, so it's exactly the parabola `point(at:)` walks.
struct DialArc {
    static let inset: CGFloat = 11
    /// The design's 24.5 drop over a half-width of 149.5.
    static let sagPerHalfWidth: CGFloat = 24.5 / 149.5

    let width: CGFloat
    /// The y of the arch's highest point.
    let top: CGFloat

    private var start: CGFloat { Self.inset }
    private var end: CGFloat { max(width - Self.inset, Self.inset + 1) }
    private var half: CGFloat { (end - start) / 2 }
    private var sag: CGFloat { half * Self.sagPerHalfWidth }

    func point(at fraction: Double) -> CGPoint {
        let x = start + (end - start) * fraction
        let u = (x - (start + half)) / half
        return CGPoint(x: x, y: top + sag * u * u)
    }

    func fraction(atX x: CGFloat) -> Double {
        Double(min(max((x - start) / (end - start), 0), 1))
    }

    var path: Path {
        Path { path in
            path.move(to: point(at: 0))
            // The control point that makes the curve pass through the top at the middle.
            path.addQuadCurve(to: point(at: 1), control: CGPoint(x: start + half, y: top - sag))
        }
    }
}

/// Puts each stop's name under its dot, centred on it but kept inside the control, so Peace
/// and Grind never hang off the card.
private struct StopLabels: Layout {
    let tops: [CGFloat]
    let xs: [CGFloat]

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (index, subview) in subviews.enumerated() where index < xs.count {
            let size = subview.sizeThatFits(.unspecified)
            let half = size.width / 2
            let x = min(max(xs[index], half), max(bounds.width - half, half))
            subview.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + tops[index]), anchor: .top, proposal: .unspecified)
        }
    }
}

/// The current stop's art (You design): Peace's sprout, Calm's sun behind clouds, Plain's three
/// pills, Push's lightning bolt, Grind's flame. As the dial is dragged into another stop's half,
/// the new art grows in from the bottom as the old one shrinks away (`Motion.standard`); under
/// Reduce Motion they cross-fade.
///
/// Sized like the Plain render in the design: at most 75 tall and 125 wide, standing on the
/// line 129 below the card's top (the 80 under the label, with 1 to spare).
public struct DialArt: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let stop: Dial.Stop
    static let maxSize = CGSize(width: 125, height: 75)

    public init(position: Double) {
        stop = Dial(position: position).stop
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Art.dial(stop)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: Self.maxSize.width, maxHeight: Self.maxSize.height, alignment: .bottom)
                .id(stop)
                .transition(reduceMotion
                    ? .opacity
                    : .opacity.combined(with: .scale(scale: 0.8, anchor: .bottom)))
        }
        .padding(.bottom, 1)
        .frame(height: 80, alignment: .bottom)
        .animation(reduceMotion ? Motion.reduced : Motion.standard, value: stop)
        .accessibilityHidden(true)
    }
}

/// The dial card's sky (You design, Figma): a blue glow and faint white rays turning slowly
/// (still under Reduce Motion), both centred behind the art: 60 below the card's top, just
/// under the top of the dark pill, where the rays meet.
///
/// Read from the Figma screenshot (13 Nov): #D6ECFA, even out to 40 from the centre, then
/// fading to the card's white about 200 out, so the card's top edge is still blue and its
/// corners and the arc are white. The rays are faint, about a tenth of white where they're
/// brightest.
public struct DialGlow: View {
    /// The glow and the rays' centre, below the card's top.
    static let centre: CGFloat = 60
    static let reach: CGFloat = 200

    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                RadialGradient(
                    stops: [
                        .init(color: Palette.dialSky, location: 0),
                        .init(color: Palette.dialSky, location: 40 / Self.reach),
                        .init(color: Palette.dialSky.opacity(0), location: 1),
                    ],
                    center: .center, startRadius: 0, endRadius: Self.reach)
                    .frame(width: Self.reach * 2, height: Self.reach * 2)
                    .offset(y: Self.centre - Self.reach)
                TurningRays(color: Palette.glowRays, size: 560, fadeRadius: 280)
                    .opacity(0.25)
                    .frame(width: 560, height: 560)
                    .offset(y: Self.centre - 280)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
