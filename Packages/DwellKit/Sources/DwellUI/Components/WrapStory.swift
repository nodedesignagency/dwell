import DwellCore
import SwiftUI

// The weekly wrap's pieces (S-06, Weekly wrap design): a page's colour, its header with the
// progress bar and close button, and the 3D art that pops out around its words. Built for the
// wrap, shaped so Year in places (S-07) can reuse them. Measured from the "This week."
// screenshot at 393 × 852.

// MARK: - Backdrop

/// A wrap page's colour (Weekly wrap design, "This week."): the invite card's fill and glow
/// drawn over the whole screen, from under the status bar to the bottom edge.
///
/// A radial fill from `centre` to `edge`, centred 51.6% down, reaching the edge colour 80% of
/// the way to the screen's sides (the radius is the screen's own shape, so it reaches further
/// down than across). Over it the invite's glow (`WrapGlow`): the white ramp, 24% at the left
/// to 12% at the right, and the sixteen white rays, meeting 55% down, in the middle of the
/// page's words, turning a full circle every 24 s. Fitted to the screenshot; send Figma's values
/// if it looks off. The same in dark mode.
public struct WrapBackdrop: View {
    private let centre: Color
    private let edge: Color

    /// The opener's blue by default; each page brings its own colours with its design.
    public init(centre: Color = Palette.wrapCentre, edge: Color = Palette.wrapEdge) {
        self.centre = centre
        self.edge = edge
    }

    public var body: some View {
        EllipticalGradient(
            colors: [centre, edge],
            center: UnitPoint(x: 0.5, y: 0.516),
            startRadiusFraction: 0,
            // A fraction of the screen's size: 0.5 would reach its sides.
            endRadiusFraction: 0.4)
            .overlay {
                WrapGlow(center: UnitPoint(x: 0.5, y: 0.55))
            }
            .ignoresSafeArea()
            .environment(\.colorScheme, .light)
    }
}

// MARK: - Header

/// The top of every wrap page (Weekly wrap design): "Your weekly recap" (24 medium) over the
/// week (14), the close button on glass level with them, and 13 below, the progress bar.
/// 16 from the sides, 12 below the status bar. White on the colourful pages; `ink` for a page
/// drawn on a light map.
public struct StoryHeader: View {
    private let title: String
    private let subtitle: String
    private let pageCount: Int
    private let current: Int
    private let clock: StoryClock?
    private let ink: Color
    private let closeLabel: String
    private let onClose: () -> Void
    private let onStep: (AccessibilityAdjustmentDirection) -> Void

    /// - Parameters:
    ///   - subtitle: the week, a plain label: "Oct 19 – 25".
    ///   - current: the page showing, from 0.
    ///   - clock: how far the page has run, when it moves on by itself; `nil` shows it full.
    ///   - onStep: VoiceOver's swipe up or down on the progress bar: the next or previous page.
    public init(
        title: String,
        subtitle: String,
        pageCount: Int,
        current: Int,
        clock: StoryClock? = nil,
        ink: Color = .white,
        closeLabel: String,
        onClose: @escaping () -> Void,
        onStep: @escaping (AccessibilityAdjustmentDirection) -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.pageCount = pageCount
        self.current = current
        self.clock = clock
        self.ink = ink
        self.closeLabel = closeLabel
        self.onClose = onClose
        self.onStep = onStep
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .center, spacing: Space.m) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: title)
                        .textRole(.pageTitle)
                    Text(verbatim: subtitle)
                        .textRole(.caption)
                }
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)

                Button(action: onClose) {
                    StoryCross(ink: ink)
                }
                .buttonStyle(.clearGlassSquare)
                .accessibilityLabel(closeLabel)
            }

            StoryProgress(count: pageCount, current: current, clock: clock, ink: ink)
                .accessibilityAdjustableAction(onStep)
        }
        .padding(.horizontal, Space.l)
        .padding(.top, 12)
    }
}

/// The progress bar along a wrap's top: a capsule per page, 4 tall and 4 apart, filling the
/// width. Pages seen are `ink`; pages to come, `ink` at 40%. The page showing fills from its
/// leading end as its clock runs, like an Instagram story, and holds still while paused;
/// without a clock (a page that waits, or VoiceOver on) it shows full. Going to another page,
/// the capsules it passes fill or empty with `Motion.standard`. The fill is a progress bar, so
/// it runs under Reduce Motion too. VoiceOver reads it as "Page, 1 of 7"; give it an
/// adjustable action to move between pages from it.
public struct StoryProgress: View {
    private let count: Int
    private let current: Int
    private let clock: StoryClock?
    private let ink: Color

    public init(count: Int, current: Int, clock: StoryClock? = nil, ink: Color = .white) {
        self.count = count
        self.current = current
        self.clock = clock
        self.ink = ink
    }

    public var body: some View {
        // Redraws every frame only while the clock runs.
        TimelineView(.animation(minimumInterval: nil, paused: !(clock?.isRunning ?? false))) { context in
            let fill = clock?.fraction(at: context.date) ?? 1
            HStack(spacing: Space.xs) {
                ForEach(0..<count, id: \.self) { index in
                    let share = index < current ? 1 : index == current ? fill : 0
                    Capsule()
                        .fill(ink.opacity(0.4))
                        .overlay {
                            Rectangle()
                                .fill(ink)
                                .scaleEffect(x: share, anchor: .leading)
                        }
                        .clipShape(.capsule)
                }
            }
        }
        .frame(height: 4)
        .motion(value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(WrapCopy.progress)
        .accessibilityValue(WrapCopy.progressValue(page: current + 1, of: count))
    }
}

/// The close button's cross (Weekly wrap design, Figma): white 100%, two strokes 1.3 wide with
/// round ends, their ends 11 apart each way, so the cross reads 12 across in its 20 box.
/// Measured from the Figma render.
private struct StoryCross: View {
    let ink: Color

    var body: some View {
        CrossShape()
            .stroke(ink, style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
            .frame(width: 11, height: 11)
            .frame(width: 20, height: 20)
    }
}

nonisolated private struct CrossShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}

/// A square button on glass over a colourful page (the wrap's close button, Figma): 40 × 40,
/// padding 10, corners 13, fill white 20%, no stroke, and Figma's Glass effect: light −45° at
/// 80%, refraction 80, depth 20, dispersion 50, frost 4, splay 0. Drawn the same on every iOS,
/// never the system's Liquid Glass, which takes none of those values. Tappable over 44; sinks
/// to 92% pressed.
///
/// SwiftUI has no refraction, depth or dispersion, so the button draws what they make of it in
/// Figma's render (`LitGlass`). Frost 4 blurs what's behind a little, which on a smooth page
/// shows nothing, so it isn't drawn.
public struct ClearGlassSquareButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(10)
            .background {
                LitGlass(cornerRadius: Radius.m)
            }
            .contentShape(Rectangle().inset(by: -2))
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .motion(value: configuration.isPressed)
    }
}

/// Figma's Glass over a colourful page, as its render draws it (the wrap's close button,
/// measured at 4.6× from the design):
///
/// - The fill, white 20%, which the glass's light turns a little: 17% at the top left, 23.5%
///   at the bottom right.
/// - The rim: a line of light 0.75 wide just inside the edge, added to the colour below
///   (plus-lighter), so on blue it reads cyan white, as the dispersion draws it. It follows
///   the light at −45°: strongest at the top-left corner (45%), about 30% along the left and
///   top edges, 30% again at the bottom-right corner, faint along the right and bottom (17%),
///   and gone at the top-right and bottom-left corners. The strengths are read every 15°
///   around the button.
struct LitGlass: View {
    let cornerRadius: CGFloat

    /// The rim's strength every 15° around the centre, clockwise from the trailing edge.
    private static let rim: [Double] = [
        0.165, 0.165, 0.295, 0.30, 0.33, 0.165, 0.165, 0.18, // right, bottom-right, bottom
        0.03, 0, 0.035, 0.32, 0.32, 0.32, 0.42, 0.45,         // bottom-left, left, top-left
        0.41, 0.28, 0.28, 0.28, 0, 0, 0.03, 0.17,             // top, top-right
    ]

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        shape
            .fill(LinearGradient(
                colors: [.white.opacity(0.17), .white.opacity(0.235)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                shape
                    .strokeBorder(
                        AngularGradient(
                            stops: (Self.rim + [Self.rim[0]]).enumerated().map { index, strength in
                                Gradient.Stop(
                                    color: .white.opacity(strength),
                                    location: Double(index) / Double(Self.rim.count))
                            },
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)),
                        lineWidth: 0.75)
                    .blendMode(.plusLighter)
            }
            .allowsHitTesting(false)
    }
}

extension ButtonStyle where Self == ClearGlassSquareButtonStyle {
    public static var clearGlassSquare: ClearGlassSquareButtonStyle { ClearGlassSquareButtonStyle() }
}

// MARK: - Popping art

/// 3D art popping out from behind a wrap page's words to its spot around them, then floating
/// there (Weekly wrap design, "This week.": the alarm clock, briefcase, flame and trophy; the
/// motion is the designer's description, 13 Nov).
///
/// Each piece starts small and hidden at the middle of the words, then springs out to its
/// spot, growing and turning to its angle (`Motion.pop`), 0.08 s after the one before; the
/// first goes 0.3 s after the page appears, once it has settled. Then each drifts up and down
/// by 4 and turns by 2° on its own slow loop (`Motion.float`), so they never move together.
/// Under Reduce Motion each fades in at its spot and stays still. Decorative: hidden from
/// VoiceOver, never in the way of a tap. Fills the space it's given; lay it over the whole
/// screen so the spots land where the design draws them.
public struct StickerBurst: View {
    /// One piece of art and where it comes to rest.
    public struct Item: Identifiable {
        public let id: String
        public let image: Image
        /// Across the screen, as a share of its width.
        public let x: CGFloat
        /// Down from the middle of the words, in points.
        public let y: CGFloat
        /// The square the art is drawn in.
        public let size: CGFloat
        /// How far it's turned once it rests.
        public let angle: Angle

        public init(id: String, image: Image, x: CGFloat, y: CGFloat, size: CGFloat, angle: Angle) {
            self.id = id
            self.image = image
            self.x = x
            self.y = y
            self.size = size
            self.angle = angle
        }
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isOut = false
    private let items: [Item]
    private let originOffset: CGFloat

    /// - Parameter originOffset: how far the middle of the words sits from the middle of the
    ///   space, in points (negative is up).
    public init(items: [Item], originOffset: CGFloat = 0) {
        self.items = items
        self.originOffset = originOffset
    }

    public var body: some View {
        GeometryReader { proxy in
            let origin = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2 + originOffset)
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let spot = CGPoint(x: proxy.size.width * item.x, y: origin.y + item.y)
                let shown = isOut || reduceMotion
                Floating(index: index, isOn: !reduceMotion) {
                    item.image
                        .resizable()
                        .scaledToFit()
                        .frame(width: item.size, height: item.size)
                }
                .rotationEffect(shown ? item.angle : .zero)
                .scaleEffect(shown ? 1 : 0.2)
                .opacity(isOut ? 1 : 0)
                .position(shown ? spot : origin)
                .animation(
                    (reduceMotion ? Motion.reduced : Motion.pop).delay(0.3 + Double(index) * 0.08),
                    value: isOut)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { isOut = true }
        .onDisappear { isOut = false }
    }
}

/// Drifts its content up and down by 4 and turns it by 2°, each piece on a loop of its own
/// length so they never move together. Still when off.
private struct Floating<Content: View>: View {
    let index: Int
    let isOn: Bool
    @ViewBuilder let content: Content

    var body: some View {
        if isOn {
            content.phaseAnimator([false, true]) { view, isUp in
                view
                    .offset(y: isUp ? -4 : 4)
                    .rotationEffect(.degrees(isUp ? 2 : -2))
            } animation: { _ in
                Motion.float.speed(2.8 / (2.8 + Double(index % 4) * 0.35))
            }
        } else {
            content
        }
    }
}
