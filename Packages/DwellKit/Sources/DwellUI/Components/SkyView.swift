import DwellCore
import SwiftUI

/// One phase's colours, generated from design/tokens.json ("sky") as `SkyPhase.colors`.
public struct SkyColors {
    /// Top to bottom, over the whole sky.
    public var sky: [Gradient.Stop]
    /// From the horizon line to the bottom edge; empty when the sky runs to the edge.
    public var horizon: [Gradient.Stop]
    /// The sun (the moon at night), lit side at the top, shaded side at the bottom.
    public var body: Color
    public var bodyEdge: Color
    /// The halo around it.
    public var glow: Color

    public init(sky: [Gradient.Stop], horizon: [Gradient.Stop], body: Color, bodyEdge: Color, glow: Color) {
        self.sky = sky
        self.horizon = horizon
        self.body = body
        self.bodyEdge = bodyEdge
        self.glow = glow
    }
}

/// Today's header sky, drawn in code: sunrise, day, sunset and night, by the clock.
///
/// When the phase changes, live or since the user last opened the app, the skies cross-fade
/// while the sun and moon travel: the moon climbs away as the sun rises at the horizon, the
/// sun arcs up to its afternoon place, sinks back to the horizon at sunset, and drops below
/// it as the moon comes down into a starry sky. Every time the app opens, the scene settles
/// in even with no change: the sun or moon lifts a few points into place, its glow blooms,
/// and the stars come out one by one. Under Reduce Motion, both are cross-fades in place.
public struct SkyView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("sky.lastPhase") private var lastPhase = ""
    @State private var shown: SkyPhase?
    @State private var settled = false

    private let phase: SkyPhase
    private let horizonInset: CGFloat
    private let remembersPhase: Bool

    /// - Parameters:
    ///   - horizonInset: how far above the bottom edge the horizon sits. Today's sheet covers
    ///     the bottom 32 pt, so the half sun peeks over the sheet's edge as in the design.
    ///   - remembersPhase: plays the change since the last open. Off for side-by-side previews.
    public init(_ phase: SkyPhase, horizonInset: CGFloat = 26, remembersPhase: Bool = true) {
        self.phase = phase
        self.horizonInset = horizonInset
        self.remembersPhase = remembersPhase
    }

    public var body: some View {
        GeometryReader { proxy in
            let scene = SkyLayout(size: proxy.size, horizonInset: horizonInset)
            let drawn = shown ?? phase
            ZStack(alignment: .topLeading) {
                ForEach(SkyPhase.allCases) { sky in
                    LinearGradient(stops: sky.colors.sky, startPoint: .top, endPoint: .bottom)
                        .opacity(sky == drawn ? 1 : 0)
                }
                stars(scene, drawn)
                sun(scene, drawn)
                    .id(reduceMotion ? "sun-\(drawn)" : "sun")
                    .transition(.opacity)
                moon(scene, drawn)
                    .id(reduceMotion ? "moon-\(drawn)" : "moon")
                    .transition(.opacity)
                ForEach(SkyPhase.allCases) { sky in
                    if !sky.colors.horizon.isEmpty {
                        LinearGradient(stops: sky.colors.horizon, startPoint: .top, endPoint: .bottom)
                            .frame(width: proxy.size.width, height: horizonInset)
                            .offset(y: scene.horizon)
                            .opacity(sky == drawn ? 1 : 0)
                    }
                }
            }
        }
        .clipped()
        // The sky's last colour runs on below it, hidden under the sheet, so pulling the
        // sheet down shows more sky rather than a gap.
        .background(alignment: .bottom) {
            Rectangle()
                .fill(bottomColor)
                .frame(height: Self.runOn)
                .offset(y: Self.runOn)
        }
        .accessibilityHidden(true)
        .onAppear(perform: arrive)
        .onChange(of: phase) { _, new in turn(to: new) }
        .onChange(of: scenePhase) { old, new in
            if old == .background, new == .active { settle() }
        }
    }

    /// Deeper than any pull-down, short of the bottom of a scrolled-to-the-end page.
    private static let runOn: CGFloat = 400

    private var bottomColor: Color {
        let colors = (shown ?? phase).colors
        return (colors.horizon.last ?? colors.sky.last)?.color ?? .clear
    }

    // MARK: Animation

    /// First appearance: play the change since last time, or settle in.
    private func arrive() {
        guard shown == nil else { return }
        let last = remembersPhase ? SkyPhase(rawValue: lastPhase) : nil
        remember(phase)
        guard let last, last != phase else {
            shown = phase
            settle()
            return
        }
        shown = last
        settled = true
        Task { @MainActor in
            // Let the old sky show for a moment so the change reads as a change.
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(reduceMotion ? Motion.skyFade : Motion.skyChange) { shown = phase }
        }
    }

    private func turn(to new: SkyPhase) {
        remember(new)
        withAnimation(reduceMotion ? Motion.skyFade : Motion.skyChange) { shown = new }
    }

    /// The small lift and bloom on every open.
    private func settle() {
        var still = Transaction()
        still.disablesAnimations = true
        withTransaction(still) { settled = false }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            withAnimation(reduceMotion ? Motion.skyFade : Motion.skySettle) { settled = true }
        }
    }

    private func remember(_ phase: SkyPhase) {
        if remembersPhase { lastPhase = phase.rawValue }
    }

    // MARK: Sun

    private func sun(_ scene: SkyLayout, _ drawn: SkyPhase) -> some View {
        // At night the sun is below the horizon, keeping sunset's colours as it goes.
        let colors = (drawn == .night ? SkyPhase.sunset : drawn).colors
        let place = scene.sun(drawn)
        let radius = place.radius
        let lift = settled || reduceMotion ? 0 : radius * 0.25
        return ZStack {
            Circle()
                .fill(colors.glow)
                .frame(width: radius * 3.4, height: radius * 3.4)
                .blur(radius: radius * (drawn == .day ? 1.1 : 0.7))
                .opacity(settled ? 0.85 : 0.4)
            Circle()
                .fill(LinearGradient(colors: [colors.body, colors.bodyEdge], startPoint: .top, endPoint: .bottom))
                .frame(width: radius * 2, height: radius * 2)
                .blur(radius: drawn == .day ? radius * 0.15 : 0.6)
        }
        .position(x: place.center.x, y: place.center.y + lift)
        .opacity(place.isVisible ? 1 : 0)
    }

    // MARK: Moon

    private func moon(_ scene: SkyLayout, _ drawn: SkyPhase) -> some View {
        let colors = SkyPhase.night.colors
        let place = scene.moon(drawn)
        let radius = place.radius
        let lift = settled || reduceMotion ? 0 : radius * 0.35
        return ZStack {
            Circle()
                .fill(colors.glow)
                .frame(width: radius * 3, height: radius * 3)
                .blur(radius: radius * 0.8)
                .opacity(settled ? 0.35 : 0.1)
            Crescent()
                .fill(LinearGradient(colors: [colors.body, colors.bodyEdge], startPoint: .topTrailing, endPoint: .bottomLeading))
                .frame(width: radius * 2, height: radius * 2)
                .shadow(color: colors.glow.opacity(0.6), radius: radius * 0.3)
        }
        .position(x: place.center.x, y: place.center.y + lift)
        .opacity(place.isVisible ? 1 : 0)
    }

    // MARK: Stars

    private func stars(_ scene: SkyLayout, _ drawn: SkyPhase) -> some View {
        ForEach(Array(Self.stars.enumerated()), id: \.offset) { index, star in
            Circle()
                .fill(.white)
                .frame(width: star.size, height: star.size)
                .shadow(color: .white.opacity(0.8), radius: star.size)
                .position(scene.point(star.x, star.y))
                .opacity(drawn.starOpacity * (settled ? 1 : 0.15))
                .animation(
                    reduceMotion ? Motion.skyFade : Motion.skySettle.delay(Double(index) * 0.09),
                    value: settled)
        }
    }

    private struct Star {
        /// Shares of the width and of the sky's height above the horizon.
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
    }

    /// Placed as in the sunset and night images.
    private static let stars: [Star] = [
        Star(x: 0.13, y: 0.15, size: 2.5), Star(x: 0.24, y: 0.21, size: 1.5), Star(x: 0.20, y: 0.22, size: 2),
        Star(x: 0.11, y: 0.40, size: 2.5), Star(x: 0.29, y: 0.44, size: 2), Star(x: 0.50, y: 0.29, size: 1.5),
        Star(x: 0.59, y: 0.22, size: 2.5), Star(x: 0.67, y: 0.27, size: 2), Star(x: 0.75, y: 0.12, size: 3),
        Star(x: 0.88, y: 0.14, size: 2.5), Star(x: 0.94, y: 0.34, size: 2), Star(x: 0.93, y: 0.47, size: 2),
    ]

    // MARK: Layout

    /// Where everything sits, as shares of the header so it holds at any height.
    private struct SkyLayout {
        struct Body {
            var center: CGPoint
            var radius: CGFloat
            var isVisible: Bool
        }

        let size: CGSize
        let horizonInset: CGFloat

        var horizon: CGFloat { size.height - horizonInset }

        /// `x` a share of the width, `y` a share of the sky above the horizon.
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: size.width * x, y: horizon * y)
        }

        func sun(_ phase: SkyPhase) -> Body {
            let width = size.width
            switch phase {
            case .sunrise:
                return Body(center: CGPoint(x: width * 0.5, y: horizon), radius: width * 0.14, isVisible: true)
            case .day:
                return Body(center: point(0.79, 0.3), radius: width * 0.055, isVisible: true)
            case .sunset:
                return Body(center: CGPoint(x: width * 0.5, y: horizon), radius: width * 0.12, isVisible: true)
            case .night:
                return Body(center: CGPoint(x: width * 0.5, y: size.height + width * 0.2), radius: width * 0.12, isVisible: false)
            }
        }

        func moon(_ phase: SkyPhase) -> Body {
            let radius = size.width * 0.046
            return phase == .night
                ? Body(center: point(0.77, 0.3), radius: radius, isVisible: true)
                : Body(center: point(0.86, -0.25), radius: radius, isVisible: false)
        }
    }
}

extension SkyPhase {
    /// Stars show at night and start to show at sunset.
    var starOpacity: Double {
        switch self {
        case .night: 1
        case .sunset: 0.7
        case .sunrise, .day: 0
        }
    }
}

/// A thin crescent, lit on the right, like the night image's moon.
nonisolated private struct Crescent: Shape {
    func path(in rect: CGRect) -> Path {
        let shadow = rect.offsetBy(dx: -rect.width * 0.3, dy: -rect.height * 0.14)
        return Path(ellipseIn: rect).subtracting(Path(ellipseIn: shadow))
    }
}

#Preview("Four skies") {
    VStack(spacing: 0) {
        ForEach(SkyPhase.allCases) { phase in
            SkyView(phase, remembersPhase: false)
                .frame(height: 210)
        }
    }
    .ignoresSafeArea()
}

#Preview("Tap to change phase") {
    @Previewable @State var phase = SkyPhase.night
    SkyView(phase, remembersPhase: false)
        .frame(height: 300)
        .overlay(alignment: .bottom) {
            Text(verbatim: "\(phase.rawValue) · tap for the next phase")
                .textRole(.caption)
                .padding(Space.s)
                .background(.thinMaterial, in: .capsule)
                .padding(.bottom, Space.xxl)
        }
        .onTapGesture {
            let all = SkyPhase.allCases
            phase = all[(all.firstIndex(of: phase)! + 1) % all.count]
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
}
