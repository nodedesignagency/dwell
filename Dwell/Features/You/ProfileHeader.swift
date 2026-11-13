import DwellCore
import DwellUI
import MapKit
import SwiftUI

/// The profile on its map (You design): the picture as a pin over a faded map of the city with
/// the cells uncovered so far, two facts on glass beside it ("41 places", "3.2% mapped"), then
/// the name and "@maya • Brooklyn".
///
/// Read from the Figma frame (13 Nov): the ring 133 across with its tail 12.7 below and a soft
/// shadow where its tip meets the map; the two facts on top of the picture: "41 places" ending
/// on the ring's left edge (60.5 left of its centre), its middle 28 below the ring's; "3.2%
/// mapped" starting 46.5 right of the centre, its middle 52.5 below, so its top corner crosses
/// the ring; 8 to the name (28 medium), 4 to the handle and city
/// (16, grey, 12 to the dot). At accessibility sizes the two facts leave the pin and sit in a
/// row under the city, where they have room.
struct ProfileHeader: View {
    let profile: Profile
    let placeCount: Int
    let coverage: ScratchCoverage?
    let cells: [ScratchCell]
    var openPlaces: () -> Void = {}
    var openCoverage: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let large = dynamicTypeSize.isAccessibilitySize
        VStack(spacing: 0) {
            pin(withFacts: !large)
                .background {
                    // Centred on the picture, reaching up behind the page title as drawn.
                    ProfileMap(center: profile.cityCenter, cells: cells)
                        .frame(width: ProfileMap.size.width, height: ProfileMap.size.height)
                        .offset(y: AvatarPinMetrics.centre - AvatarPinMetrics.height / 2)
                }
            Text(verbatim: profile.name)
                .textRole(.profileName)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, Space.s)
            DotLine([YouCopy.handle(profile.username), profile.city], spacing: Space.m, alignment: .center)
                .textRole(.body, weight: .regular)
                .foregroundStyle(Palette.textSecondary)
                .padding(.top, Space.xs)
            if large {
                FlowLayout(alignment: .center, spacing: Space.s, lineSpacing: Space.s) {
                    placesPill
                    mappedPill
                }
                .padding(.top, Space.m)
            }
        }
        .padding(.horizontal, Space.screen)
    }

    /// The picture, and beside it the two facts when they fit.
    private func pin(withFacts: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // The facts sit on top of the picture, as in Figma.
            Group {
                if withFacts {
                    placesPill
                        .fixedSize()
                        .offset(x: 6)
                        .padding(.top, 74)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .zIndex(1)
            AvatarPin(Art.sampleAvatar)
            Group {
                if withFacts {
                    mappedPill
                        .fixedSize()
                        .offset(x: -20)
                        .padding(.top, 99)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .zIndex(1)
        }
        .padding(.horizontal, -Space.screen)
    }

    private var placesPill: some View {
        Button(action: openPlaces) {
            StatPill(PlacesCopy.count(placeCount), art: Art.Illustration.pushpin)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Shows your places")
    }

    private var mappedPill: some View {
        Button(action: openCoverage) {
            StatPill(YouCopy.mapped(coverage), art: Art.Illustration.globe)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(YouCopy.spokenMapped(coverage, city: profile.city))
        .accessibilityHint("Shows your scratch map")
    }
}

/// Where the pin's parts sit, for laying the map under it.
private enum AvatarPinMetrics {
    /// The ring's centre, from the pin's top.
    static let centre: CGFloat = 133 / 2
    /// The ring and its tail.
    static let height: CGFloat = 133 + 12.7
}

/// The map behind the profile: the user's city, faded out towards its edges, with the cells
/// they've uncovered in the scratch map's lilac. No points of interest, no routes, nothing to
/// touch. The picture sits over the middle of the city, never over home or where the user is
/// now (brief §8.2).
///
/// Matched to the Figma screenshot (13 Nov): the design's map is a close-up shrunk down, so its
/// streets read as blocks and its labels are tiny. Drawn the same way: the map at 2.2 times the
/// size, then shrunk, so a 250 m cell comes out about 10.5 across (24 m to the point) and the
/// labels about 5 pt. Nearly full strength round the picture out to 92 from its centre, fading
/// to nothing at 125, a circle like Figma's (13 Nov: it reaches about 95 up and down and 115
/// to the left). The
/// cells solid (#D698F9) with thin white seams, over a faint lilac haze around them.
struct ProfileMap: View {
    static let size = CGSize(width: 330, height: 250)
    /// Metres to a point, as seen.
    static let metresPerPoint = 23.8
    /// How much larger the map is drawn before it's shrunk to `size`.
    static let zoom: CGFloat = 2.2

    let center: Coordinate
    let cells: [ScratchCell]

    var body: some View {
        Map(position: .constant(camera), interactionModes: []) {
            // The haze first, so the cells sit on it.
            ForEach(cells) { cell in
                MapPolygon(coordinates: Self.grown(cell.boundary, by: 1.9).map(\.location))
                    .foregroundStyle(Palette.scratchCell.opacity(0.1))
            }
            ForEach(cells) { cell in
                MapPolygon(coordinates: cell.boundary.map(\.location))
                    .foregroundStyle(Palette.scratchCell)
                    .stroke(Palette.ring, lineWidth: 2)
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll, showsTraffic: false))
        .frame(width: Self.size.width * Self.zoom, height: Self.size.height * Self.zoom)
        .scaleEffect(1 / Self.zoom)
        .frame(width: Self.size.width, height: Self.size.height)
        .opacity(0.9)
        .mask {
            // As in Figma: a circle round the picture, full to 92 from its centre, gone by 125.
            RadialGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 92 / 125),
                    .init(color: .clear, location: 1),
                ],
                center: .center, startRadius: 0, endRadius: 125)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var camera: MapCameraPosition {
        .region(MKCoordinateRegion(
            center: center.location,
            latitudinalMeters: Double(Self.size.height) * Self.metresPerPoint,
            longitudinalMeters: Double(Self.size.width) * Self.metresPerPoint))
    }

    /// A cell's outline pushed out from its middle: the haze around it.
    static func grown(_ boundary: [Coordinate], by factor: Double) -> [Coordinate] {
        guard !boundary.isEmpty else { return boundary }
        let latitude = boundary.map(\.latitude).reduce(0, +) / Double(boundary.count)
        let longitude = boundary.map(\.longitude).reduce(0, +) / Double(boundary.count)
        return boundary.map { corner in
            Coordinate(
                latitude: latitude + (corner.latitude - latitude) * factor,
                longitude: longitude + (corner.longitude - longitude) * factor)
        }
    }
}

extension Coordinate {
    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
