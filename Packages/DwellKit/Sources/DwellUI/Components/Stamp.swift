import SwiftUI

// The postcard stamp (Weekly wrap 7, "Postcard from your week", 13 Nov): its perforated
// outline and the Dwell logo printed on it. Built from the designer's stamp SVG (277 × 350).

// MARK: - Outline

/// A postage stamp's outline: a rectangle with round bites all along its edges, as a sheet of
/// stamps tears (the stamp SVG): seven bites across the top and bottom, nine down each side,
/// 25.7 across (half circles, radius 12.85), the corners square. Measured from the SVG's path
/// at 277 × 350 and scaled to the rect it's given.
nonisolated public struct StampShape: Shape {
    /// The SVG's size; the bites sit where it draws them, scaled to the rect.
    public static let designSize = CGSize(width: 277, height: 350)
    static let radius: CGFloat = 12.85
    /// The bites' middles along the top and bottom, and down the sides, in the SVG's points.
    static let across: [CGFloat] = [26.49, 63.69, 100.88, 138.08, 175.28, 212.47, 249.67]
    static let down: [CGFloat] = [32.34, 67.95, 103.57, 139.18, 174.87, 210.56, 246.24, 281.93, 317.62]
    /// A quarter circle as a cubic Bézier: how far along its tangents the handles sit.
    static let handle: CGFloat = 0.5523

    public init() {}

    public func path(in rect: CGRect) -> Path {
        let sx = rect.width / Self.designSize.width
        let sy = rect.height / Self.designSize.height
        let r = Self.radius * min(sx, sy)
        let k = Self.handle * r
        let (left, top, right, bottom) = (rect.minX, rect.minY, rect.maxX, rect.maxY)
        var path = Path()
        path.move(to: CGPoint(x: left, y: top))
        // Along the top, left to right, each bite dipping in.
        for middle in Self.across.map({ left + $0 * sx }) {
            path.addLine(to: CGPoint(x: middle - r, y: top))
            path.addCurve(to: CGPoint(x: middle, y: top + r),
                          control1: CGPoint(x: middle - r, y: top + k), control2: CGPoint(x: middle - k, y: top + r))
            path.addCurve(to: CGPoint(x: middle + r, y: top),
                          control1: CGPoint(x: middle + k, y: top + r), control2: CGPoint(x: middle + r, y: top + k))
        }
        path.addLine(to: CGPoint(x: right, y: top))
        // Down the right side.
        for middle in Self.down.map({ top + $0 * sy }) {
            path.addLine(to: CGPoint(x: right, y: middle - r))
            path.addCurve(to: CGPoint(x: right - r, y: middle),
                          control1: CGPoint(x: right - k, y: middle - r), control2: CGPoint(x: right - r, y: middle - k))
            path.addCurve(to: CGPoint(x: right, y: middle + r),
                          control1: CGPoint(x: right - r, y: middle + k), control2: CGPoint(x: right - k, y: middle + r))
        }
        path.addLine(to: CGPoint(x: right, y: bottom))
        // Along the bottom, right to left.
        for middle in Self.across.reversed().map({ left + $0 * sx }) {
            path.addLine(to: CGPoint(x: middle + r, y: bottom))
            path.addCurve(to: CGPoint(x: middle, y: bottom - r),
                          control1: CGPoint(x: middle + r, y: bottom - k), control2: CGPoint(x: middle + k, y: bottom - r))
            path.addCurve(to: CGPoint(x: middle - r, y: bottom),
                          control1: CGPoint(x: middle - k, y: bottom - r), control2: CGPoint(x: middle - r, y: bottom - k))
        }
        path.addLine(to: CGPoint(x: left, y: bottom))
        // Up the left side.
        for middle in Self.down.reversed().map({ top + $0 * sy }) {
            path.addLine(to: CGPoint(x: left, y: middle + r))
            path.addCurve(to: CGPoint(x: left + r, y: middle),
                          control1: CGPoint(x: left + k, y: middle + r), control2: CGPoint(x: left + r, y: middle + k))
            path.addCurve(to: CGPoint(x: left, y: middle - r),
                          control1: CGPoint(x: left + r, y: middle - k), control2: CGPoint(x: left + k, y: middle - r))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Logo

/// The Dwell logo as the stamp prints it: the sun mark (23.33), 3.85, the wordmark (17.53
/// tall). VoiceOver reads "Dwell". Fixed size: it's print on a stamp, not text.
public struct DwellLogo: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 3.85) {
            DwellMark()
                .frame(width: 23.33, height: 23.33)
            Art.Brand.wordmark
                .resizable()
                .scaledToFit()
                .frame(height: 17.53)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "Dwell"))
    }
}

/// The sun mark: a round blue sky, hazy white low down and warm at the bottom, a white sun
/// rising with eleven short rays. A stand-in drawn from the stamp SVG's shapes (its blurs
/// don't survive outside Figma); the designer's own mark replaces it [ICON NEEDED].
public struct DwellMark: View {
    public init() {}

    public var body: some View {
        Canvas { context, size in
            let unit = size.width / 23.33
            let disc = Path(ellipseIn: CGRect(origin: .zero, size: size))
            context.clip(to: disc)
            context.fill(disc, with: .color(Palette.brandSky))
            context.fill(disc, with: .linearGradient(
                Gradient(stops: [
                    .init(color: .white.opacity(0), location: 0.22),
                    .init(color: .white.opacity(0.9), location: 0.55),
                    .init(color: Palette.brandSun, location: 0.86),
                    .init(color: Palette.brandSunset, location: 1),
                ]),
                startPoint: CGPoint(x: size.width / 2, y: 0),
                endPoint: CGPoint(x: size.width / 2, y: size.height)))
            // The sun, its middle low in the disc so it rises over the bottom edge.
            let sun = CGPoint(x: 11.7 * unit, y: 21.84 * unit)
            let sunRadius = 9.13 * unit
            for step in 0..<11 {
                let angle = Angle.degrees(-165 + Double(step) * 15).radians
                let inner = 10.6 * unit
                let outer = 13.1 * unit
                var ray = Path()
                ray.move(to: CGPoint(x: sun.x + cos(angle) * inner, y: sun.y + sin(angle) * inner))
                ray.addLine(to: CGPoint(x: sun.x + cos(angle) * outer, y: sun.y + sin(angle) * outer))
                context.stroke(ray, with: .color(.white.opacity(0.95)), style: StrokeStyle(lineWidth: 0.93 * unit, lineCap: .round))
            }
            context.fill(
                Path(ellipseIn: CGRect(x: sun.x - sunRadius, y: sun.y - sunRadius, width: sunRadius * 2, height: sunRadius * 2)),
                with: .radialGradient(
                    Gradient(colors: [.white, Color(white: 1).opacity(0.96), Palette.brandSun.opacity(0.9)]),
                    center: sun, startRadius: 0, endRadius: sunRadius))
        }
        .accessibilityHidden(true)
    }
}
