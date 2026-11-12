import DwellCore
import DwellUI
import MapKit
import SwiftUI

/// The profile on its map (You design): the picture as a pin over a faded map of the city with
/// the cells uncovered so far, two facts on glass beside it ("41 places", "3.2% mapped"), then
/// the name and "@maya • Brooklyn".
///
/// Read from the screenshot: the ring 133 across with its tail 14 below; "41 places" tucked
/// under the ring's left edge, its middle 28 below the ring's; "3.2% mapped" 18 into the
/// ring's frame on the right, 51 below; 8 to the name (28 medium), 4 to the handle and city
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
            Group {
                if withFacts {
                    placesPill
                        .fixedSize()
                        .offset(x: 6)
                        .padding(.top, 75)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            AvatarPin(Art.sampleAvatar)
                .zIndex(1)
            Group {
                if withFacts {
                    mappedPill
                        .fixedSize()
                        .offset(x: -18)
                        .padding(.top, 98)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
    static let height: CGFloat = 133 + 14
}

/// The map behind the profile: the user's city, faded out towards its edges, with the cells
/// they've uncovered in the scratch map's lilac. No points of interest, no routes, nothing to
/// touch. The picture sits over the middle of the city, never over home or where the user is
/// now (brief §8.2).
///
/// Read from the screenshot: about 20 m to the point (a 250 m cell is 12 across), muted, at
/// about half strength, fading to nothing 165 out from the picture's centre.
struct ProfileMap: View {
    static let size = CGSize(width: 330, height: 250)
    static let metresPerPoint = 20.0

    let center: Coordinate
    let cells: [ScratchCell]

    var body: some View {
        Map(position: .constant(camera), interactionModes: []) {
            ForEach(cells) { cell in
                MapPolygon(coordinates: cell.boundary.map(\.location))
                    .foregroundStyle(Palette.scratchCell.opacity(0.75))
                    .stroke(Palette.ring.opacity(0.7), lineWidth: 1)
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll, showsTraffic: false))
        .opacity(0.55)
        .mask {
            EllipticalGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black.opacity(0.7), location: 0.5),
                    .init(color: .clear, location: 1),
                ],
                center: .center)
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
}

extension Coordinate {
    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
