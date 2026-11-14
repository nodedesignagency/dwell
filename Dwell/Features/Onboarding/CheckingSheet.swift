import CoreLocation
import DwellCore
import DwellUI
import MapKit
import SwiftUI

/// Checking (onboarding flow, "Returning user": "Finding the account"; screenshot, 14 Nov): a
/// card from the bottom over Welcome back. "Getting your world ready", "Checking your account.
/// This takes only a moment.", and under them a map with a field of scratch cells around the
/// Dwell sun, four clusters of cells raised and coloured in. Brief A.1's account state
/// "Checking", with its "Try again".
///
/// While the check runs, the clusters rise and colour in one after another, the way cells do
/// when they're uncovered; under Reduce Motion they hold still, as drawn. If the check fails,
/// the line says so, the clusters settle, and Try again (navy) comes up at the card's foot.
/// The close button, a swipe down or a tap outside stops the check.
///
/// Measured at 393 × 852: the card 609 tall, 10 in and 21 up like every card from the bottom;
/// the map fills the 447 under the words. A shorter screen gets a shorter map, so the card
/// keeps clear of the status bar; at the largest text sizes the card scrolls.
struct CheckingCard: View {
    /// The whole screen's height, status bar and home indicator included.
    let screenHeight: CGFloat
    let didFail: Bool
    let onTryAgain: () -> Void
    let onClose: () -> Void

    var body: some View {
        SheetCard(
            title: AccountCopy.checkingTitle,
            titleWidth: 250,
            lines: didFail ? AccountCopy.checkFailedLines : AccountCopy.checkingLines,
            closeLabel: AccountCopy.stopChecking,
            onClose: onClose
        ) {
            WorldReadyMap(isWaiting: !didFail)
                .frame(height: mapHeight)
                .overlay(alignment: .bottom) {
                    if didFail {
                        Button(AccountCopy.tryAgain, action: onTryAgain)
                            .buttonStyle(.primary)
                            .padding(.horizontal, 10.5)
                            .padding(.bottom, Space.l)
                            .transition(.opacity)
                    }
                }
        }
        .environment(\.colorScheme, .light)
        .motion(value: didFail)
    }

    /// The design's 447 on an 852-tall screen: the card's top 223 down, its words 162, its foot
    /// 21 up. Never under 240.
    private var mapHeight: CGFloat {
        min(WorldReadyMap.designHeight, max(WorldReadyMap.leastHeight, screenHeight - 406))
    }
}

/// The picture under Checking's words. The map is the example world onboarding shows (Brooklyn,
/// at Your places' scale: about 4,650 pt to a degree of latitude), since no account is open yet
/// to say where the user lives; no points of interest, nothing to touch. It fades in under the
/// words and out above the card's foot. Over it, the field of scratch cells in the scratch
/// map's lilac at 22% with white seams, four clusters raised over the field in four shades, and
/// the Dwell sun (80) in the middle. Decoration: hidden from VoiceOver, which reads the words.
struct WorldReadyMap: View {
    static let designHeight: CGFloat = 447
    static let leastHeight: CGFloat = 240

    /// Whether the check is running: the clusters move while it is.
    let isWaiting: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let sun = CGPoint(x: size.width / 2, y: size.height * WorldReady.sunHeight)
            ZStack {
                Map(initialPosition: .region(WorldReady.region(size: size, sun: sun)), interactionModes: [])
                    .mapStyle(.standard(pointsOfInterest: .excludingAll, showsTraffic: false))
                    .mask { mapFade(height: size.height) }
                Canvas { context, _ in
                    drawField(in: context, sun: sun)
                }
                TimelineView(.animation(paused: !animates)) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(start)
                    Canvas { context, _ in
                        drawClusters(in: context, sun: sun, elapsed: animates ? elapsed : nil)
                    }
                }
                DwellMark()
                    .frame(width: 80, height: 80)
                    .position(sun)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var animates: Bool {
        isWaiting && !reduceMotion
    }

    /// The map clear under the words and fading in from 35 to 75 below the map's top; fading out
    /// from 57 to 16 above its foot. Read from the screenshot.
    private func mapFade(height: CGFloat) -> LinearGradient {
        let full = max(height, 160)
        let stops: [Gradient.Stop] = [
            Gradient.Stop(color: .clear, location: 0),
            Gradient.Stop(color: .clear, location: 35 / full),
            Gradient.Stop(color: .black, location: 75 / full),
            Gradient.Stop(color: .black, location: 1 - 57 / full),
            Gradient.Stop(color: .clear, location: 1 - 16 / full),
            Gradient.Stop(color: .clear, location: 1),
        ]
        return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
    }

    /// The field: every cell the design fills, flat-topped, 8.4 from middle to corner.
    private func drawField(in context: GraphicsContext, sun: CGPoint) {
        let size = WorldReady.fieldSize
        var cells = Path()
        for cell in WorldReady.field {
            cells.addPath(WorldReady.hexagon(at: WorldReady.point(of: cell, size: size, from: sun), size: size, tilt: 0))
        }
        context.fill(cells, with: .color(Palette.scratchCell.opacity(0.22)))
        context.stroke(cells, with: .color(.white.opacity(0.8)), lineWidth: 0.8)
    }

    /// The four clusters, each cell as raised as `WorldReady.lift` says: at 1 it's the design's
    /// (9.6 from middle to corner, a little larger than the field's, and in its shade); at 0 it's
    /// sunk back into the field. Still (`elapsed` nil), every cell is raised.
    private func drawClusters(in context: GraphicsContext, sun: CGPoint, elapsed: TimeInterval?) {
        for (number, cluster) in WorldReady.clusters.enumerated() {
            let origin = CGPoint(x: sun.x + cluster.offset.width, y: sun.y + cluster.offset.height)
            for (index, cell) in cluster.cells.enumerated() {
                let lift: Double = elapsed.map { WorldReady.lift(at: $0, cluster: number, cell: index) } ?? 1
                guard lift > 0.01 else { continue }
                let scale = WorldReady.sunkScale + (1 - WorldReady.sunkScale) * CGFloat(lift)
                let centre = WorldReady.point(of: cell.hex, size: WorldReady.clusterSize, tilt: cluster.tilt, from: origin)
                let hexagon = WorldReady.hexagon(at: centre, size: WorldReady.clusterSize * scale, tilt: cluster.tilt)
                var layer = context
                layer.opacity = lift
                layer.fill(hexagon, with: .color(color(cell.shade)))
                layer.stroke(hexagon, with: .color(.white), lineWidth: 1.2)
            }
        }
    }

    private func color(_ shade: WorldReady.Shade) -> Color {
        switch shade {
        case .pale: Palette.worldCellPale
        case .light: Palette.worldCellLight
        case .mid: Palette.worldCellMid
        case .deep: Palette.worldCellDeep
        }
    }
}

/// Checking's picture, measured from the screenshot (14 Nov) at 2.347 px to the point: where the
/// sun sits, the field's cells, and the four clusters. Positions are in points from the sun's
/// middle, so the picture stays centred on any screen. Pure geometry, so nonisolated.
nonisolated enum WorldReady {
    /// A cell on a flat-topped hexagon grid, in axial steps: `q` across, `r` down.
    nonisolated struct Hex: Hashable, Sendable {
        let q: Int
        let r: Int
    }

    nonisolated enum Shade: Sendable {
        case pale, light, mid, deep
    }

    nonisolated struct Cell: Sendable {
        let hex: Hex
        let shade: Shade
    }

    nonisolated struct Cluster: Sendable {
        let cells: [Cell]
        /// From the sun's middle to the cluster's first cell.
        let offset: CGSize
        /// Its turn on the page, in degrees, clockwise.
        let tilt: Double
    }

    /// The sun's middle, 206 down the design's 447 (46%).
    static let sunHeight: CGFloat = 206.0 / 447.0
    /// The point on the example world under the sun: Crown Heights.
    static let sunLatitude = 40.6774
    static let sunLongitude = -73.9309
    /// Your places' scale.
    static let pointsPerDegree = 4650.0

    /// The field's cells, middle to corner.
    static let fieldSize: CGFloat = 8.4
    /// The clusters' cells, middle to corner: raised a little larger than the field's.
    static let clusterSize: CGFloat = 9.6
    /// How small a cluster cell is when it's sunk back into the field.
    static let sunkScale: CGFloat = fieldSize / clusterSize

    /// The map's middle and span, so the sun's point sits under the sun at Your places' scale.
    static func region(size: CGSize, sun: CGPoint) -> MKCoordinateRegion {
        let perLongitude = pointsPerDegree * cos(sunLatitude * .pi / 180)
        // Never an empty span, even before the first layout.
        let width = Double(max(size.width, 100))
        let height = Double(max(size.height, 100))
        let rise = Double(size.height / 2 - sun.y)
        let center = CLLocationCoordinate2D(
            latitude: sunLatitude - rise / pointsPerDegree,
            longitude: sunLongitude)
        let span = MKCoordinateSpan(
            latitudeDelta: height / pointsPerDegree,
            longitudeDelta: width / perLongitude)
        return MKCoordinateRegion(center: center, span: span)
    }


    /// A cell's middle: `size` from middle to corner, the grid turned by `tilt` degrees.
    static func point(of hex: Hex, size: CGFloat, tilt: Double = 0, from origin: CGPoint) -> CGPoint {
        let x = 1.5 * size * CGFloat(hex.q)
        let y = CGFloat(3).squareRoot() * size * (CGFloat(hex.r) + CGFloat(hex.q) / 2)
        let angle = CGFloat(tilt * .pi / 180)
        return CGPoint(
            x: origin.x + x * cos(angle) - y * sin(angle),
            y: origin.y + x * sin(angle) + y * cos(angle))
    }

    /// A flat-topped hexagon, turned by `tilt` degrees.
    static func hexagon(at centre: CGPoint, size: CGFloat, tilt: Double) -> Path {
        var path = Path()
        for corner in 0..<6 {
            let angle = CGFloat((Double(corner) * 60 + tilt) * .pi / 180)
            let point = CGPoint(x: centre.x + size * cos(angle), y: centre.y + size * sin(angle))
            if corner == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    // MARK: The clusters moving

    /// One cluster's turn: up in 0.5 s, held 1.7 s, down in 0.5 s, 0.5 s sunk. The clusters
    /// go a quarter of a turn apart, top, right, bottom left, left; within one, each cell
    /// 0.05 s after the last, so they ripple up.
    static let period = 3.2
    private static let rise = 0.5
    private static let hold = 1.7
    private static let fall = 0.5

    /// How raised a cluster's cell is, 0 to 1, `elapsed` seconds into the check.
    static func lift(at elapsed: TimeInterval, cluster: Int, cell: Int) -> Double {
        let delay = Double(cluster) * period / 4 + Double(cell) * 0.05
        let phase = (elapsed - delay).truncatingRemainder(dividingBy: period)
        let time = phase < 0 ? phase + period : phase
        let value: Double
        if time < rise {
            let t = time / rise
            value = 1 - (1 - t) * (1 - t)
        } else if time < rise + hold {
            value = 1
        } else if time < rise + hold + fall {
            let t = (time - rise - hold) / fall
            value = 1 - t * t
        } else {
            value = 0
        }
        return value
    }

    // MARK: The design's cells

    /// The cells three of the clusters share: a deep diagonal from upper right to lower left,
    /// pale above it, mid and light below.
    private static let spread: [Cell] = [
        Cell(hex: Hex(q: 0, r: 0), shade: .deep),
        Cell(hex: Hex(q: 1, r: -1), shade: .deep),
        Cell(hex: Hex(q: -1, r: 1), shade: .deep),
        Cell(hex: Hex(q: 0, r: -1), shade: .pale),
        Cell(hex: Hex(q: -1, r: 0), shade: .pale),
        Cell(hex: Hex(q: 1, r: 0), shade: .mid),
        Cell(hex: Hex(q: 0, r: 1), shade: .mid),
        Cell(hex: Hex(q: 1, r: 1), shade: .light),
        Cell(hex: Hex(q: 0, r: 2), shade: .light),
        Cell(hex: Hex(q: -1, r: 2), shade: .light),
    ]

    /// The left cluster's own: three deep on its left, two mid, three light.
    private static let wedge: [Cell] = [
        Cell(hex: Hex(q: 0, r: 0), shade: .deep),
        Cell(hex: Hex(q: 1, r: -1), shade: .deep),
        Cell(hex: Hex(q: 1, r: 0), shade: .deep),
        Cell(hex: Hex(q: 2, r: -2), shade: .mid),
        Cell(hex: Hex(q: 2, r: -1), shade: .mid),
        Cell(hex: Hex(q: 3, r: -2), shade: .light),
        Cell(hex: Hex(q: 3, r: -1), shade: .light),
        Cell(hex: Hex(q: 2, r: 0), shade: .light),
    ]

    /// Top, right, bottom left, left: the order they rise in.
    static let clusters: [Cluster] = [
        Cluster(cells: spread, offset: CGSize(width: 10.7, height: -140.6), tilt: 6),
        Cluster(cells: spread, offset: CGSize(width: 133.8, height: 20.9), tilt: 84.5),
        Cluster(cells: spread, offset: CGSize(width: -110.8, height: 158.5), tilt: 6),
        Cluster(cells: wedge, offset: CGSize(width: -103.5, height: 18.3), tilt: 6),
    ]

    /// The field as the design fills it: 233 cells around the sun, reaching up to the top
    /// cluster, out to the left and right ones and down to the bottom left one. "q,r" pairs.
    static let field: [Hex] = parse("""
        -1,-10 1,-11 0,-10 2,-11 -1,-9 1,-10 0,-9 2,-10 4,-11 1,-9 3,-10 5,-11 0,-8 2,-9
        4,-10 1,-8 3,-9 0,-7 2,-8 -1,-6 1,-7 3,-8 -2,-5 0,-6 2,-7 4,-8 -1,-5 1,-6 3,-7 0,-5
        2,-6 4,-7 -1,-4 1,-5 3,-6 5,-7 0,-4 2,-5 4,-6 1,-4 3,-5 0,-3 2,-4 -1,-2 1,-3 3,-4
        -2,-1 0,-2 2,-3 -1,-1 1,-2 3,-3 -6,2 -4,1 -2,0 0,-1 2,-2 4,-3 -7,3 -5,2 -3,1 -1,0
        1,-1 3,-2 5,-3 9,-5 -6,3 -4,2 -2,1 0,0 2,-1 4,-2 6,-3 8,-4 10,-5 -7,4 -5,3 -3,2 -1,1
        1,0 3,-1 5,-2 7,-3 9,-4 11,-5 -8,5 -6,4 -4,3 -2,2 0,1 2,0 4,-1 6,-2 8,-3 10,-4 12,-5
        -7,5 -5,4 -3,3 -1,2 1,1 3,0 5,-1 7,-2 9,-3 11,-4 -8,6 -6,5 -4,4 -2,3 0,2 2,1 4,0
        6,-1 8,-2 10,-3 12,-4 -9,7 -7,6 -5,5 -3,4 -1,3 1,2 3,1 5,0 7,-1 9,-2 11,-3 -8,7 -6,6
        -4,5 -2,4 0,3 2,2 4,1 6,0 8,-1 10,-2 -7,7 -5,6 -3,5 -1,4 3,2 5,1 7,0 9,-1 -8,8 -6,7
        -4,6 -2,5 2,3 4,2 6,1 8,0 10,-1 -7,8 -5,7 -3,6 -1,5 1,4 3,3 5,2 7,1 9,0 -8,9 -6,8
        -4,7 -2,6 0,5 2,4 6,2 8,1 10,0 -3,7 -1,6 1,5 3,4 5,3 9,1 -8,10 -6,9 -4,8 -2,7 0,6
        4,4 6,3 10,1 -9,11 -7,10 -5,9 -3,8 -1,7 1,6 5,4 -8,11 -6,10 -4,9 0,7 6,4 -9,12 -7,11
        -5,10 -3,9 -8,12 -6,11 -4,10 -9,13 -7,12 -5,11 -3,10 -8,13 -6,12 -4,11 -2,10 -9,14
        -7,13 -5,12 -10,15 -8,14 -6,13 -9,15 -7,14 -5,13 -10,16 -8,15 -6,14 -9,16 -7,15
        -5,14 -8,16 -9,17 -7,16 -8,17
        """)

    private static func parse(_ pairs: String) -> [Hex] {
        var cells: [Hex] = []
        for pair in pairs.split(whereSeparator: \.isWhitespace) {
            let parts = pair.split(separator: ",")
            guard parts.count == 2, let q = Int(parts[0]), let r = Int(parts[1]) else { continue }
            cells.append(Hex(q: q, r: r))
        }
        return cells
    }
}
