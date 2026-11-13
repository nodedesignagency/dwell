import DwellCore
import DwellUI
import MapKit
import SwiftUI
import UIKit

/// The postcard (Weekly wrap 7, "Postcard from your week"): the week printed on a stamp, the
/// card that gets shared. Laid out at the stamp SVG's own coordinates (277 × 350):
///
/// - The white perforated stamp (`StampShape`), and inside it the paper (#F8F6F1), 21.6 in
///   from the sides and 21 from the top and bottom (233.3 × 308).
/// - The map of the user's city over the paper's top 170, faded in from 20% at the top to
///   full 80 down and out again just above "My week", as the SVG's mask fades it. City level
///   only, no pins, no names (the user's call, 13 Nov; brief §8.6).
/// - The Dwell logo 11.7 in from the paper's top left.
/// - "My week" (15.5 medium, ink), its baseline 198.5 down; 8.3 below it two tiles (105.6 ×
///   40.5, 4.7 apart, corners 9.4, white, ink 5% edge): the label (9, grey) over the number
///   (10.5 medium, ink), 9 in and 4 apart, centred down the tile; the hero tiles' art in grey
///   (35.5) 2 from the right, a blurred glow behind it (work's pink, yours' green).
/// - Three rows, 25.6 apart (label 10 grey, value 10.5 medium ink, right aligned), a dotted
///   rule (ink 10%) under the first two.
///
/// Fixed size, as print is: it's the shared image, the same for everyone. VoiceOver reads the
/// whole stamp in one go.
struct PostcardStamp: View {
    let postcard: WrapPostcard
    /// The city map, once its snapshot is in; until then the paper shows.
    var map: UIImage?
    /// Loading: the stamp's shape with its numbers waiting.
    var isPlaceholder = false

    @Environment(\.calendar) private var calendar
    @Environment(\.dial) private var dial

    static let size = StampShape.designSize
    static let paper = CGRect(x: 21.583, y: 21, width: 233.333, height: 308)
    /// Where the map sits over the paper.
    static let mapSize = CGSize(width: 233.333, height: 170)

    var body: some View {
        ZStack(alignment: .topLeading) {
            StampShape()
                .fill(.white)
            Rectangle()
                .fill(Palette.stampPaper)
                .frame(width: Self.paper.width, height: Self.paper.height)
                .offset(x: Self.paper.minX, y: Self.paper.minY)
            mapLayer
                .offset(x: Self.paper.minX, y: Self.paper.minY)
            DwellLogo()
                .offset(x: 33.25, y: 32.67)
            Group {
                Text(verbatim: WrapCopy.postcardHeading)
                    .font(stampFont(15.5, .medium))
                    .tracking(-0.02 * 15.5)
                    .foregroundStyle(Palette.textPrimary)
                    .offset(x: 29.75, y: 198.5 - stampAscent(15.5, .medium))
                tiles
                    .offset(x: 29.75, y: 206.79)
                row(WrapCopy.earliestExitRow, WrapCopy.exitValue(postcard.earliestExit, calendar: calendar), baseline: 264.14)
                rule(at: 273.02)
                row(WrapCopy.weekendWorkRow, WrapCopy.weekendWorkValue(postcard.weekendWork), baseline: 289.81)
                rule(at: 298.69)
                row(WrapCopy.newPlacesRow, WrapCopy.newPlacesValue(postcard.newPlaces), baseline: 315.35)
            }
            .redacted(reason: isPlaceholder ? .placeholder : [])
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .dynamicTypeSize(.large)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: spoken))
    }

    // MARK: Map

    private var mapLayer: some View {
        ZStack {
            if let map {
                Image(uiImage: map)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            }
        }
        .frame(width: Self.mapSize.width, height: Self.mapSize.height)
        .clipped()
        .mask {
            // The SVG's mask: nothing at the stamp's top edge (21 above the paper), full
            // 100.9 down the stamp, nothing again at 190.7.
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(21 / 100.9), location: 0),
                    .init(color: .black, location: (100.9 - 21) / Self.mapSize.height),
                    .init(color: .black.opacity(0), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom)
        }
        .motion(Motion.reduced, value: map != nil)
    }

    // MARK: Tiles

    private var tiles: some View {
        HStack(spacing: 4.71) {
            StampTile(
                label: WrapCopy.atWork,
                value: DurationText.short(postcard.work),
                art: Art.heroWork,
                glow: PlaceCategory.work.color,
                glowCentre: CGPoint(x: 101.52, y: 19.78))
            StampTile(
                label: WrapCopy.yours.text(for: dial),
                value: DurationText.short(postcard.yours),
                art: Art.heroYours,
                glow: Palette.yours,
                glowCentre: CGPoint(x: 98.83, y: 19.78))
        }
    }

    // MARK: Rows

    /// A row from x 30.92 to 246.75, its baseline at `baseline` (the value's ascent is the
    /// taller, so it sets the row's top).
    private func row(_ label: String, _ value: String, baseline: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(verbatim: label)
                .font(stampFont(10, .regular))
                .tracking(-0.2)
                .foregroundStyle(Palette.textSecondary)
            Spacer(minLength: 8)
            Text(verbatim: value)
                .font(stampFont(10.5, .medium, monospacedDigits: true))
                .tracking(-0.21)
                .foregroundStyle(Palette.textPrimary)
        }
        .lineLimit(1)
        .frame(width: 215.83)
        .offset(x: 30.92, y: baseline - stampAscent(10.5, .medium))
    }

    /// The SVG's dotted rule: dots 0.66 long, 1.32 apart, 0.66 thick, ink 10%.
    private func rule(at y: CGFloat) -> some View {
        Rectangle()
            .fill(.clear)
            .frame(width: 215.83, height: 0.66)
            .overlay {
                GeometryReader { proxy in
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: proxy.size.height / 2))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height / 2))
                    }
                    .stroke(Palette.separator, style: StrokeStyle(lineWidth: 0.66, dash: [0.66, 1.32]))
                }
            }
            .offset(x: 30.92, y: y - 0.33)
    }

    private var spoken: String {
        let totals = "\(WrapCopy.atWork), \(DurationText.spoken(postcard.work)). \(WrapCopy.yours.text(for: dial)), \(DurationText.spoken(postcard.yours))."
        return WrapCopy.postcardSpoken(postcard, totals: totals, calendar: calendar)
    }
}

/// A hero tile as the stamp prints it: Today's "At work" and "Yours" tiles, small.
private struct StampTile: View {
    let label: String
    let value: String
    let art: Image
    let glow: Color
    /// The glow's middle in the tile (the SVG's 90-wide disc, blurred 22.5, at 50%).
    let glowCentre: CGPoint

    static let size = CGSize(width: 105.554, height: 40.548)

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 9.41)
        ZStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: label)
                    .font(stampFont(9, .regular))
                    .tracking(-0.18)
                    .foregroundStyle(Palette.textSecondary)
                Text(verbatim: value)
                    .font(stampFont(10.5, .medium, monospacedDigits: true))
                    .tracking(-0.21)
                    .foregroundStyle(Palette.textPrimary)
            }
            .lineLimit(1)
            .padding(.leading, 9)
            art
                .resizable()
                .scaledToFit()
                .grayscale(1)
                .frame(width: 35.5, height: 35.5)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 2)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .background {
            ZStack(alignment: .topLeading) {
                Color.white
                Circle()
                    .fill(LinearGradient(colors: [glow, glow.opacity(0)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 90.08, height: 90.08)
                    .blur(radius: 11.2)
                    .opacity(0.5)
                    .position(glowCentre)
            }
            .clipShape(shape)
        }
        .overlay {
            shape.strokeBorder(Palette.outline, lineWidth: 0.67)
        }
    }
}

/// The stamp's type: the app's rounded face at a fixed size, as print.
private func stampFont(_ size: CGFloat, _ weight: Font.Weight, monospacedDigits: Bool = false) -> Font {
    let font = Font.system(size: size, weight: weight, design: .rounded)
    return monospacedDigits ? font.monospacedDigit() : font
}

/// How far a line of stamp type reaches above its baseline, so text can sit on the SVG's
/// baselines: a `Text`'s top is this far above its baseline.
private func stampAscent(_ size: CGFloat, _ weight: UIFont.Weight) -> CGFloat {
    let system = UIFont.systemFont(ofSize: size, weight: weight)
    guard let rounded = system.fontDescriptor.withDesign(.rounded) else { return system.ascender }
    return UIFont(descriptor: rounded, size: size).ascender
}

// MARK: - The city map

/// A still map of the user's city for the stamp (MapKit's snapshot, not a live map, so the
/// shared image can carry it): centred on the city's middle (`Profile.cityCenter`, never home),
/// about 16 km across, Apple's standard map muted and flat, without points of interest, in
/// light, at 3x. No pins and no place names of the user's are ever drawn on it.
enum PostcardMap {
    /// Metres to a point across the stamp's map: city level.
    static let metresPerPoint = 70.0

    static func snapshot(of city: Coordinate) async -> UIImage? {
        let options = MKMapSnapshotter.Options()
        let size = PostcardStamp.mapSize
        options.region = MKCoordinateRegion(
            center: city.location,
            latitudinalMeters: Double(size.height) * metresPerPoint,
            longitudinalMeters: Double(size.width) * metresPerPoint)
        options.size = size
        let configuration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
        configuration.pointOfInterestFilter = .excludingAll
        options.preferredConfiguration = configuration
        options.traitCollection = UITraitCollection { traits in
            traits.userInterfaceStyle = .light
            traits.displayScale = 3
        }
        do {
            return try await MKMapSnapshotter(options: options).start().image
        } catch {
            return nil
        }
    }
}
