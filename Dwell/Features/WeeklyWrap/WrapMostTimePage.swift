import CoreLocation
import DwellCore
import DwellUI
import MapKit
import SwiftUI

/// The wrap's fourth page (Weekly wrap design, "Weekly Wrap 4", 14 Nov): the place the week
/// went to most, on a map, and a card with its time that week, its visits and when it was last
/// seen (`WrapMostTime`: home, private and personal places left out).
///
/// The page's colour, measured from the screenshot under the pattern [VALUES NEEDED: Figma's
/// fill]: a radial fill, warm (#EADB5B) in the middle to blue (#007DF3) at the edge, centred
/// 53.8% down and reaching 45.9% of the screen, as on page 5; over it the designer's starburst
/// at 30% (Figma: 721 × 1080 at −164, −114), redrawn in code and turning (`Starburst`).
/// Then the map, fading in under the title and out above the card.
///
/// Measured from the screenshot at 393 × 852:
/// - The title (42 medium, white, centred, breaking after "spent") 35 below the progress bar,
///   as page 5's.
/// - The map: MapKit, the place's neighbourhood at about 24 m to the point, no points of
///   interest, nothing to touch; clear 30 above the title's foot, full strength from 42% to
///   60% of the way down, clear again 13 below the card's top. The place sits 41% of the way
///   down (425 on the design's screen), mid-screen, the white tag beside it, its tail on the
///   place ("Kestriva Labs | 31h"); a long name moves the place left so the tag stays on screen.
/// - The card: 17 from the sides, 21 above the screen's bottom edge, corners 20: the name (20
///   medium), 6 below it the live dot and "Visiting since: March 12, 2026" (16, grey), a dashed
///   line 10 below, then 16 below that the tiles, 10 in from the card's edge and 10 apart.
///
/// The tiles: the design's three side by side cut their labels short on the phone, so they're
/// two to a row at Today's size (the user, 14 Nov), with a fourth the user asked for from the
/// brief's place page ("total", §7.2): the place's time all told. On top the place's time, this
/// week (the alarm clock) and all time (the chart), in its category's colour; below, the visits
/// (the briefcase, yours' green) and last seen (the sunrise, home's blue).
///
/// The starburst turns a full circle every 40 s (the user, 14 Nov). The tag pops in onto the
/// place and the card rises in; under Reduce Motion they fade in and the starburst holds
/// still. The live dot pulses while the user is there, or left in the last
/// quarter of an hour. A week with no place to show keeps the map of the city with no tag and
/// no card. At accessibility sizes the title stops at the largest standard size, the tiles
/// stack, and the page scrolls with a shorter map if it outgrows the screen. A tap anywhere
/// moves the story on: the map takes none.
struct WrapMostTimePage: View {
    let state: Loadable<WrapMostTime?>
    /// The middle of the user's city: the map when there's no place to show.
    let city: Coordinate?
    /// Where the header ends, down from the top of the screen.
    let headerBottom: CGFloat
    var onNext: () -> Void = {}
    var onRetry: () -> Void = {}

    @Environment(\.calendar) private var calendar
    @Environment(\.fixedNow) private var fixedNow
    @Environment(\.clockOffset) private var clockOffset
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// From the progress bar to the title's box (page 5's).
    private static let titleTop: CGFloat = 35
    /// The card's sides, and its foot above the screen's bottom edge.
    private static let cardSide: CGFloat = 17
    private static let cardBottom: CGFloat = 21
    /// How far the map reaches up behind the title and down behind the card.
    private static let mapUnderTitle: CGFloat = 30
    private static let mapUnderCard: CGFloat = 13
    /// Between the tiles, either way.
    private static let tileGap: CGFloat = 10
    /// The least room the map gets between the title and the card before the page scrolls,
    /// and its height when it does (accessibility sizes).
    private static let leastMap: CGFloat = 150
    private static let shortMap: CGFloat = 220
    /// Left this long ago or less, the user is still there as far as the dot goes.
    private static let hereWindow: TimeInterval = 15 * 60

    var body: some View {
        ZStack {
            WrapBackdrop(
                centre: Palette.wrapMostCentre,
                edge: Palette.wrapMostEdge,
                middle: UnitPoint(x: 0.5, y: 0.538),
                reach: 0.459,
                glows: false)
            Starburst()
                .opacity(0.3)
                .ignoresSafeArea()

            switch state {
            case .failed:
                failed
            case .loaded(let most, _):
                ViewThatFits(in: .vertical) {
                    content(most, spread: true)
                    ScrollView {
                        content(most, spread: false)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollIndicators(.hidden)
                }
                .padding(.top, headerBottom)
                .padding(.bottom, Self.cardBottom)
            default:
                loading
                    .padding(.top, headerBottom)
                    .padding(.bottom, Self.cardBottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }

    private var now: Date {
        fixedNow ?? Date.now.addingTimeInterval(clockOffset)
    }

    // MARK: Layout

    /// The title at the top, the card at the foot, the map between them reaching under both;
    /// with `spread`, the map takes the room left over.
    private func content(_ most: WrapMostTime?, spread: Bool) -> some View {
        VStack(spacing: 0) {
            heading(most == nil ? WrapCopy.noMostTimeTitle : WrapCopy.mostTimeTitle)
                .zIndex(1)
            Color.clear
                .frame(
                    maxWidth: .infinity,
                    minHeight: spread ? Self.leastMap : Self.shortMap,
                    maxHeight: spread ? .infinity : Self.shortMap)
                .background {
                    map(most)
                        .padding(.top, -Self.mapUnderTitle)
                        .padding(.bottom, -Self.mapUnderCard)
                }
            if let most {
                card(most)
                    .padding(.horizontal, Self.cardSide)
                    .riseIn(delay: 0.1)
                    .zIndex(1)
            }
        }
    }

    private func heading(_ title: VoicedLine) -> some View {
        VoiceText(title)
            .textRole(.storyHeading)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityAddTraits(.isHeader)
            .accessibilityAction(named: WrapCopy.nextPage, onNext)
            .padding(.horizontal, Space.screen)
            .padding(.top, Self.titleTop)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func map(_ most: WrapMostTime?) -> some View {
        if let most, let coordinate = most.place.coordinate {
            MostTimeMap(
                center: coordinate,
                tag: MostTimeMap.Tag(
                    name: most.place.name,
                    time: DurationText.total(most.total),
                    category: most.place.category))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: WrapCopy.mostTimeMap(
                    most.place.name, total: DurationText.spokenTotal(most.total))))
                .accessibilityAction(named: WrapCopy.nextPage, onNext)
        } else if let city {
            // No place to pin (or the engine hasn't placed it): the city, as You's map.
            MostTimeMap(center: city, tag: nil)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: WrapCopy.mostTimeCityMap))
        }
    }

    // MARK: The card

    private func card(_ most: WrapMostTime) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: most.place.name)
                    .textRole(.title)
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if let first = most.place.firstSeen {
                    LiveLabel(color: Palette.live, pulses: isHere(most)) {
                        Text(verbatim: WrapCopy.visitingSince(first, calendar: calendar))
                            .textRole(.body, weight: .regular)
                            .foregroundStyle(Palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            // The words sit 13 in from the card's edge, the tiles 10.
            .padding(.horizontal, 3)

            DashedDivider()
                .padding(.top, 10)

            tiles(most)
                .padding(.top, 16)
        }
        .padding(.horizontal, 10)
        .padding(.top, 11)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    /// Two to a row, the place's time on top and the visits below; one to a row at
    /// accessibility sizes.
    private func tiles(_ most: WrapMostTime) -> some View {
        let row = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Self.tileGap))
            : AnyLayout(HStackLayout(spacing: Self.tileGap))
        // Never less all told than this week, whatever the engine's lifetime says.
        let allTime = max(most.place.lifetimeTotal, most.total)
        return VStack(spacing: Self.tileGap) {
            row {
                StatTile(
                    value: DurationText.total(most.total),
                    label: WrapCopy.thisWeek,
                    spokenValue: DurationText.spokenTotal(most.total),
                    tint: most.place.category.color
                ) { art(.alarmClock) }
                StatTile(
                    value: DurationText.total(allTime),
                    label: WrapCopy.allTime,
                    spokenValue: DurationText.spokenTotal(allTime),
                    tint: most.place.category.color
                ) { art(.chart) }
            }
            row {
                StatTile(
                    value: "\(most.visits)",
                    label: WrapCopy.visitsLabel(most.visits),
                    tint: Palette.yours
                ) { art(.briefcase) }
                if let last = most.place.lastSeen {
                    StatTile(
                        value: WrapCopy.lastSeenValue(last, now: now, calendar: calendar),
                        label: WrapCopy.lastSeen,
                        tint: PlaceCategory.home.color
                    ) { art(.sunrise) }
                }
            }
        }
    }

    /// The Insights tiles' 3D art, as the design draws this card's.
    private func art(_ icon: InsightStat.Icon) -> some View {
        Art.insightStat(icon)
            .resizable()
            .scaledToFit()
    }

    private func isHere(_ most: WrapMostTime) -> Bool {
        guard let last = most.place.lastSeen else { return false }
        return now.timeIntervalSince(last) <= Self.hereWindow
    }

    // MARK: States

    /// The page's shape, waiting for its numbers: the title and the card in grey. The week is
    /// on the phone, so this is rarely seen.
    private var loading: some View {
        VStack(spacing: 0) {
            heading(WrapCopy.mostTimeTitle)
                .redacted(reason: .placeholder)
            Spacer(minLength: Space.xl)
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 4).fill(Palette.gap).frame(width: 140, height: 20)
                RoundedRectangle(cornerRadius: 4).fill(Palette.gap).frame(width: 220, height: 16)
                VStack(spacing: Self.tileGap) {
                    ForEach(0..<2, id: \.self) { _ in
                        HStack(spacing: Self.tileGap) {
                            ForEach(0..<2, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: Radius.l).fill(Palette.gap).frame(height: 66)
                            }
                        }
                    }
                }
                .padding(.top, 16)
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
            .padding(.horizontal, Self.cardSide)
        }
        .accessibilityHidden(true)
    }

    /// The week didn't load, or the places didn't, so no place can be named: the opener's words
    /// and Retry.
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - The map

/// The place's neighbourhood on a map, fading in from the top and out at the foot, with the
/// place's tag beside it: MapKit, no points of interest, no routes, nothing to touch (brief
/// §7.2). Without a tag, the map is centred on `center` (the city).
///
/// The tag is drawn over the map, not as a map annotation, so it can be measured: the place
/// sits mid-screen as the design puts it, or further left if the tag would run off the edge.
private struct MostTimeMap: View {
    struct Tag {
        var name: String
        var time: String
        var category: PlaceCategory
    }

    let center: Coordinate
    let tag: Tag?

    /// About 24 m to the point: the design's Brooklyn, Williamsburg to Canarsie.
    private static let metresPerPoint = 24.0
    /// The place this far down the map.
    private static let placeDown: CGFloat = 0.41
    /// The tag's tail reaches this far left of the tag (`PlaceTag`).
    private static let tail: CGFloat = 5
    /// The nearest a tag may come to the screen's edge.
    private static let margin: CGFloat = 16

    @State private var tagSize = CGSize(width: 160, height: 33)

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let place = placePoint(in: size)
            if size.width > 0, size.height > 0 {
                Map(position: .constant(.region(region(size: size, place: place))), interactionModes: [])
                    .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll, showsTraffic: false))
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black, location: 0.42),
                                .init(color: .black, location: 0.6),
                                .init(color: .clear, location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom)
                    }
                    .overlay(alignment: .topLeading) {
                        if let tag {
                            PlaceTag(name: tag.name, time: tag.time, icon: Art.glyph(tag.category), tail: .leading(0.5))
                                .onGeometryChange(for: CGSize.self) { $0.size } action: { tagSize = $0 }
                                .popIn(delay: 0.4)
                                .offset(x: place.x + Self.tail, y: place.y - tagSize.height / 2)
                        }
                    }
            }
        }
        .allowsHitTesting(false)
    }

    /// Where the place sits: mid-screen, or left of it when the tag needs the room.
    private func placePoint(in size: CGSize) -> CGPoint {
        var x = size.width / 2
        if tag != nil {
            x = min(x, size.width - Self.margin - tagSize.width - Self.tail)
            x = max(x, Self.margin + Self.tail)
        }
        return CGPoint(x: x, y: size.height * Self.placeDown)
    }

    /// The map's region, at its scale, with `center` at `place`.
    private func region(size: CGSize, place: CGPoint) -> MKCoordinateRegion {
        let metresPerDegree = 111_320.0
        let perLatitude = metresPerDegree
        let perLongitude = metresPerDegree * cos(center.latitude * .pi / 180)
        let middle = CLLocationCoordinate2D(
            latitude: center.latitude + Double(place.y - size.height / 2) * Self.metresPerPoint / perLatitude,
            longitude: center.longitude - Double(place.x - size.width / 2) * Self.metresPerPoint / perLongitude)
        return MKCoordinateRegion(
            center: middle,
            latitudinalMeters: Double(size.height) * Self.metresPerPoint,
            longitudinalMeters: Double(size.width) * Self.metresPerPoint)
    }
}
