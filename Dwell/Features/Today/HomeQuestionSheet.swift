import CoreLocation
import DwellCore
import DwellUI
import MapKit
import SwiftUI

/// Is this home? (screenshot, 14 Nov; brief §3.1 day 1, A.2, Appendix B): slides up over Today
/// after the first night, while no home is saved. The title is Appendix B's, in the dial's
/// voice ("Looks like home. Is it?" at Peace, "Home? Confirm it." at Grind); under the line,
/// a map of the night's place with a "Home?" tag on it; "Looks right" saves it as home (a light
/// tap), "Pick another" opens the place picker, the close button asks later.
///
/// The line is the design's reworded on the user's call (14 Nov), since the brief never says
/// "location". The map leaves out points of interest, as every map in Dwell (the design shows
/// Barclays Center and two parks), and takes no touches: the sheet's swipe stays the sheet's.
///
/// Measured at 393 × 852: the card as `PromptCard` lays it out; the map 243 tall, edge to
/// edge, from under the line to the button's top, fading in over its top 40 and out over its
/// last 28; the place a little below its middle (17), the tag 3 above it; Looks right 16 in
/// from the card's sides, Pick another (18, grey) right under it.
struct HomeQuestionSheet: View {
    let question: HomeQuestion
    let onLooksRight: () -> Void
    let onPickAnother: () -> Void
    let onClose: () -> Void

    @Environment(\.dial) private var dial

    var body: some View {
        let title = HomeQuestionCopy.title.text(for: dial)
        PromptCard(
            title: Text(verbatim: title),
            titleLabel: title,
            message: HomeQuestionCopy.message,
            actionTitle: HomeQuestionCopy.looksRight,
            actionInset: Space.l,
            secondaryTitle: HomeQuestionCopy.pickAnother,
            closeLabel: HomeQuestionCopy.close,
            onAction: onLooksRight,
            onSecondary: onPickAnother,
            onClose: onClose
        ) {
            HomeQuestionMap(coordinate: question.coordinate)
                .frame(height: 243)
        }
    }
}

/// The night's place on a map: neighbourhoods and streets, no points of interest, the place a
/// blue dot with the "Home?" tag pointing at it. About 4,650 pt to a degree of latitude, as
/// onboarding's map of Brooklyn, so a few neighbourhoods show around it.
private struct HomeQuestionMap: View {
    let coordinate: Coordinate

    private static let pointsPerDegree: Double = 4650
    /// The place sits this far below the map's middle, so the tag above it is centred.
    private static let drop: CGFloat = 17

    var body: some View {
        GeometryReader { proxy in
            let height = max(proxy.size.height, 80)
            Map(initialPosition: .region(region(for: proxy.size)), interactionModes: []) {
                Annotation(HomeQuestionCopy.tag, coordinate: coordinate.location, anchor: .bottom) {
                    VStack(spacing: 3) {
                        PlaceTag(
                            name: HomeQuestionCopy.tag, time: nil,
                            icon: Art.glyph(.home), tail: .bottom(0.5))
                        HomeDot()
                    }
                    // The anchor is the dot's middle, on the place.
                    .padding(.bottom, -HomeDot.size / 2)
                }
                .annotationTitles(.hidden)
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 40 / height),
                        .init(color: .black, location: 1 - 28 / height),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: HomeQuestionCopy.mapLabel))
    }

    /// The place `drop` below the middle, at the map's scale.
    private func region(for size: CGSize) -> MKCoordinateRegion {
        let perLatitude = Self.pointsPerDegree
        let perLongitude = perLatitude * cos(coordinate.latitude * .pi / 180)
        let center = CLLocationCoordinate2D(
            latitude: coordinate.latitude + Double(Self.drop) / perLatitude,
            longitude: coordinate.longitude)
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: Double(max(size.height, 1)) / perLatitude,
                longitudeDelta: Double(max(size.width, 1)) / perLongitude))
    }
}

/// The place on the map: a blue dot (onboarding's blue) ringed in white inside, 11 across, as
/// the design draws it.
private struct HomeDot: View {
    static let size: CGFloat = 11

    var body: some View {
        Circle()
            .fill(Palette.onboardingSky)
            .overlay {
                Circle()
                    .strokeBorder(.white, lineWidth: 1.5)
                    .padding(1.5)
            }
            .frame(width: Self.size, height: Self.size)
            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
    }
}
