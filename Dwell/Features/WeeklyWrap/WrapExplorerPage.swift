import CoreLocation
import DwellCore
import DwellUI
import MapKit
import SwiftUI

/// The wrap's sixth page (Weekly wrap design, "Weekly Wrap 6", 14 Nov): the week's new places
/// tagged on a map, the cells it uncovered, and "2 new places. 1 new corner." on the green that
/// rises over the map.
///
/// The map fills the screen behind everything: the user's city on MapKit, with no points of
/// interest and no routes (brief §8.2), held still. It's framed on the new places and cells,
/// between the header and the green, never on home. Each place first visited that week wears a
/// tag ("Pioneer Works | NEW", `PlaceTag`'s map look), at most three; private and personal
/// places count but are never on it (`WrapExplorer.tagged`). The week's new cells are the
/// scratch map's lilac with a white seam and a faint haze, as on You. The design's map is a
/// static image; this one is real, the user's call to use a map as a stand-in until the Map
/// page connects MapKit (14 Nov).
///
/// Over the map, measured from the screenshot at 393 × 852 [VALUES NEEDED: Figma's fills]:
/// - At the top, the page's green at 26% fading out by 200 down, so the header reads.
/// - The green: #0C9B01 with a lime glow (#5CE644), an ellipse 166 across and 310 down from its
///   middle (312 above the bottom edge), full to 18% of the way out. It fades in from 482 above
///   the bottom edge to full at 327.
/// - The designer's stepped waves at 20% (`SteppedWavesLive`), fading in from 362 above the
///   bottom to full at 292.
/// - At the foot, centred, white: "EXPLORER WEEK" (20, in capitals), right under it the title
///   (48 medium, lines 48 apart, a line a sentence), 10 below the line (16, white 80%), its box
///   38 above the bottom edge.
///
/// The header is the app's ink on this page (`WrapPage.headerInk`), the map being light.
///
/// Motion: the tags pop out of their tails one after another as the page opens, and the
/// pattern rolls; under Reduce Motion the tags fade in and the pattern holds still. The page
/// is a story page: the map takes no touches, a tap anywhere moves on. VoiceOver reads the map
/// as a list of the new places, then the words. At accessibility sizes the title stops at the
/// largest standard size and the words grow up over the green.
struct WrapExplorerPage: View {
    let state: Loadable<WrapExplorer>
    /// Where the header ends, down from the top of the screen.
    let headerBottom: CGFloat
    var onNext: () -> Void = {}
    var onRetry: () -> Void = {}

    @Environment(\.dial) private var dial
    @ScaledMetric(relativeTo: .largeTitle) private var titleWidth: CGFloat = 340

    /// Heights above the bottom edge, from the screenshot.
    private enum Rise {
        static let words: CGFloat = 38
        static let greenStart: CGFloat = 482
        static let greenFull: CGFloat = 327
        static let patternStart: CGFloat = 362
        static let patternFull: CGFloat = 292
        static let glow: CGFloat = 312
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack(alignment: .bottom) {
                Group {
                    if let explorer = state.value {
                        ExplorerMap(explorer: explorer, size: size, focus: focus(in: size))
                    } else {
                        Palette.stampPaper
                    }
                }
                .allowsHitTesting(false)

                topWash
                green(in: size)
                SteppedWavesLive()
                    .opacity(0.2)
                    .mask { ramp(from: Rise.patternStart, to: Rise.patternFull, in: size) }

                words
                    .padding(.bottom, Rise.words)
            }
            .frame(width: size.width, height: size.height)
        }
        .ignoresSafeArea()
    }

    /// Where the new places should sit: clear of the header (and the tags' tails) above, and
    /// of the green below, with room either side for the tags (a little more on the right,
    /// where a tag hangs a quarter of its width past its place).
    private func focus(in size: CGSize) -> CGRect {
        let top = headerBottom + 30
        let bottom = max(size.height - Rise.greenStart + 12, top + 60)
        return CGRect(x: 40, y: top, width: max(size.width - 96, 1), height: bottom - top)
    }

    // MARK: Fills

    /// The page's green over the top of the map, so the header reads: 26% at the top, gone by
    /// 200 down.
    private var topWash: some View {
        LinearGradient(
            stops: [
                .init(color: Palette.wrapExplorerEdge.opacity(0.26), location: 0),
                .init(color: Palette.wrapExplorerEdge.opacity(0.11), location: 0.3),
                .init(color: Palette.wrapExplorerEdge.opacity(0.06), location: 0.7),
                .init(color: Palette.wrapExplorerEdge.opacity(0), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom)
            .frame(height: 200)
            .frame(maxHeight: .infinity, alignment: .top)
            .allowsHitTesting(false)
    }

    /// The green and its lime glow, fading in over the map.
    private func green(in size: CGSize) -> some View {
        // Stops run from the middle (0) to the ellipse's edge (1).
        let stops: [Gradient.Stop] = [
            .init(color: Palette.wrapExplorerCentre, location: 0),
            .init(color: Palette.wrapExplorerCentre, location: 0.18),
            .init(color: Palette.wrapExplorerEdge, location: 1),
        ]
        return Palette.wrapExplorerEdge
            .overlay(alignment: .bottom) {
                EllipticalGradient(stops: stops, center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5)
                    .frame(width: 2 * 166, height: 2 * 310)
                    .offset(y: 310 - Rise.glow)
            }
            .clipped()
            .mask { ramp(from: Rise.greenStart, to: Rise.greenFull, in: size) }
            .allowsHitTesting(false)
    }

    /// Clear down to `start` above the bottom edge, full from `full` above it.
    private func ramp(from start: CGFloat, to full: CGFloat, in size: CGSize) -> some View {
        let height = max(size.height, 1)
        let stops: [Gradient.Stop] = [
            .init(color: .clear, location: max(0, (height - start) / height)),
            .init(color: .black, location: max(0, (height - full) / height)),
        ]
        return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
    }

    // MARK: Words

    @ViewBuilder
    private var words: some View {
        switch state {
        case .loaded(let explorer, _):
            VStack(spacing: 0) {
                if explorer.isExplorerWeek {
                    Text(verbatim: WrapCopy.explorerWeek.uppercased())
                        .textRole(.title, weight: .regular)
                        .accessibilityLabel(WrapCopy.explorerWeek)
                }
                LeadedText(WrapCopy.explorerTitle(explorer).text(for: dial), role: .storyHeadline, lineHeight: 48)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .frame(maxWidth: titleWidth)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityAction(named: WrapCopy.nextPage, onNext)
                if let line = WrapCopy.explorerLine(explorer) {
                    VoiceText(line)
                        .textRole(.body, weight: .regular)
                        .foregroundStyle(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                        .accessibilityAction(named: WrapCopy.nextPage, onNext)
                }
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Space.screen)
        case .failed:
            failed
        default:
            // Loading: the words' shape, waiting. The week is on the phone, so it's rarely seen.
            VStack(spacing: 0) {
                Text(verbatim: WrapCopy.explorerWeek.uppercased())
                    .textRole(.title, weight: .regular)
                LeadedText("2 new places.\n1 new corner.", role: .storyHeadline, lineHeight: 48)
                Text(verbatim: "Your map grew by one cell in Red Hook.")
                    .textRole(.body, weight: .regular)
                    .padding(.top, 10)
            }
            .foregroundStyle(.white)
            .redacted(reason: .placeholder)
            .accessibilityHidden(true)
        }
    }

    /// The opener's words and "Retry", should someone tap on past a week that didn't load.
    private var failed: some View {
        VStack(spacing: Space.m) {
            Text(verbatim: WrapCopy.failed)
                .textRole(.storyLine)
                .foregroundStyle(.white)
            Button(action: onRetry) {
                Text(verbatim: WrapCopy.retry)
                    .textRole(.action)
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, Space.screen)
                    .padding(.vertical, Space.s)
                    .background(.white, in: .capsule)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Space.screen)
        .padding(.bottom, 80)
    }
}

// MARK: - The map

/// The city behind the explorer page, framed on the week's new places and cells: MapKit's
/// standard map, flat, without points of interest or traffic, held still. With nothing new on
/// it, the middle of the city; without a city either, the stamp's plain paper.
private struct ExplorerMap: View {
    let explorer: WrapExplorer
    /// The screen the map fills.
    let size: CGSize
    /// Where the new places and cells should sit on it.
    let focus: CGRect

    /// The closest the map comes: about a neighborhood across the screen, like the design.
    private static let closest: Double = 18
    private static let metresPerDegree = 111_320.0

    /// A tagged place and how its tag points at it.
    private nonisolated struct Pin: Identifiable {
        let place: WrapExplorer.NewPlace
        let coordinate: Coordinate
        let tail: PlaceTag.Tail
        let anchor: UnitPoint
        /// Between the place and the tail's tip: the tag points at the edge of a new cell the
        /// place sits in, so the cell shows whole (the design's "Red Hook spot").
        let gap: CGFloat
        let order: Int
        var id: PlaceID { place.id }
    }

    /// A cell's inner radius, centre to the middle of an edge: about 108 m for a 250 m cell.
    private static let cellInnerRadius = 108.0

    var body: some View {
        if let camera = camera {
            Map(position: .constant(.region(camera.region)), interactionModes: []) {
                // The haze first, so the cells sit on it.
                ForEach(cells) { cell in
                    MapPolygon(coordinates: ProfileMap.grown(cell.boundary, by: 1.9).map(\.location))
                        .foregroundStyle(Palette.scratchCell.opacity(0.15))
                }
                ForEach(cells) { cell in
                    MapPolygon(coordinates: cell.boundary.map(\.location))
                        .foregroundStyle(Palette.scratchCell)
                        .stroke(Palette.ring, lineWidth: 2)
                }
                ForEach(pins(around: camera.centre, metres: camera.metres)) { pin in
                    Annotation(pin.place.name, coordinate: pin.coordinate.location, anchor: pin.anchor) {
                        ExplorerTag(place: pin.place, tail: pin.tail, gap: pin.gap, delay: 0.35 + 0.12 * Double(pin.order))
                    }
                    .annotationTitles(.hidden)
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll, showsTraffic: false))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: WrapCopy.explorerMap(explorer)))
        } else {
            Palette.stampPaper
                .accessibilityHidden(true)
        }
    }

    private var cells: [ScratchCell] {
        explorer.cells ?? []
    }

    /// The new places' tags: pointing from the left at a place on the map's left half, so the
    /// tag reads to its right; hanging below one on the right half, its tail three quarters
    /// along, so it stays on the screen (the design's two).
    /// - Parameter metres: metres to the point on the map.
    private func pins(around centre: Coordinate, metres: Double) -> [Pin] {
        explorer.tagged.enumerated().compactMap { order, place in
            guard let coordinate = place.mapCoordinate else { return nil }
            let gap = isInNewCell(coordinate) ? CGFloat(Self.cellInnerRadius / metres) + 2 : 0
            if coordinate.longitude <= centre.longitude {
                return Pin(place: place, coordinate: coordinate, tail: .leading(0.5),
                           anchor: UnitPoint(x: 0, y: 0.5), gap: gap, order: order)
            }
            return Pin(place: place, coordinate: coordinate, tail: .top(0.75),
                       anchor: UnitPoint(x: 0.75, y: 0), gap: gap, order: order)
        }
    }

    /// Whether a place sits inside one of the week's new cells: within the inner radius of a
    /// cell's middle.
    private func isInNewCell(_ coordinate: Coordinate) -> Bool {
        let perLongitude = Self.metresPerDegree * cos(coordinate.latitude * .pi / 180)
        return cells.contains { cell in
            guard !cell.boundary.isEmpty else { return false }
            let count = Double(cell.boundary.count)
            let latitude = cell.boundary.map(\.latitude).reduce(0, +) / count
            let longitude = cell.boundary.map(\.longitude).reduce(0, +) / count
            let north = (coordinate.latitude - latitude) * Self.metresPerDegree
            let east = (coordinate.longitude - longitude) * perLongitude
            return (north * north + east * east).squareRoot() < Self.cellInnerRadius
        }
    }

    /// Where the map looks and how close: the new places and cells inside `focus`, at
    /// `closest` metres to the point or further out to fit them; with nothing new, the middle
    /// of the city in the middle of `focus`.
    private var camera: (region: MKCoordinateRegion, centre: Coordinate, metres: Double)? {
        let points = explorer.pointsOnMap
        let centre: Coordinate
        var metres = Self.closest
        if let south = points.map(\.latitude).min(), let north = points.map(\.latitude).max(),
           let west = points.map(\.longitude).min(), let east = points.map(\.longitude).max() {
            centre = Coordinate(latitude: (south + north) / 2, longitude: (west + east) / 2)
            let perLongitude = Self.metresPerDegree * cos(centre.latitude * .pi / 180)
            let across = (east - west) * perLongitude / Double(max(focus.width, 1))
            let down = (north - south) * Self.metresPerDegree / Double(max(focus.height, 1))
            metres = max(metres, across, down)
        } else if let city = explorer.city {
            centre = city
        } else {
            return nil
        }
        let perLongitude = Self.metresPerDegree * cos(centre.latitude * .pi / 180)
        // Move the camera so the centre lands in the middle of the focus, not of the screen.
        let right = Double(focus.midX - size.width / 2)
        let down = Double(focus.midY - size.height / 2)
        let middle = CLLocationCoordinate2D(
            latitude: centre.latitude + down * metres / Self.metresPerDegree,
            longitude: centre.longitude - right * metres / perLongitude)
        let region = MKCoordinateRegion(
            center: middle,
            latitudinalMeters: Double(max(size.height, 1)) * metres,
            longitudinalMeters: Double(max(size.width, 1)) * metres)
        return (region, centre, metres)
    }
}

/// A new place's tag on the map, popping out of its tail as the page opens (`Motion.pop`,
/// after `delay`); under Reduce Motion it fades in. Padded on its tail's side so the tail's tip
/// is the edge the map anchors to the place.
private struct ExplorerTag: View {
    let place: WrapExplorer.NewPlace
    let tail: PlaceTag.Tail
    /// Clear space between the place and the tail's tip.
    let gap: CGFloat
    let delay: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false

    var body: some View {
        let depth = PlaceTag.tailDepth(onMap: true) + gap
        let away = !isShown && !reduceMotion
        PlaceTag(name: place.name, mark: WrapCopy.newTag, icon: Art.glyph(place.category), tail: tail)
            .padding(.top, pointsUp ? depth : 0)
            .padding(.leading, pointsUp ? 0 : depth)
            .scaleEffect(away ? 0.4 : 1, anchor: tip)
            .opacity(isShown ? 1 : 0)
            .animation((reduceMotion ? Motion.reduced : Motion.pop).delay(delay), value: isShown)
            .onAppear { isShown = true }
    }

    /// The tail on the top edge: the tag hangs below its place.
    private var pointsUp: Bool {
        switch tail {
        case .top: true
        case .none, .bottom, .leading: false
        }
    }

    /// The tail's tip, where the tag grows from: the same point the map anchors to the place.
    private var tip: UnitPoint {
        pointsUp ? UnitPoint(x: 0.75, y: 0) : UnitPoint(x: 0, y: 0.5)
    }
}
