import CoreLocation
import DwellCore
import DwellUI
import MapKit
import SwiftUI

/// Onboarding, page 2: Your places (screenshot, 13 Nov; brief A.1 #3). A map of Brooklyn with
/// two made-up places on it, under a sheet where the user adds the places that matter: an
/// address, or a spot on the map, saved as home, work or other. Saving a place does not record a
/// visit. All of it optional: Skip saves nothing.
///
/// Measured at 393 × 852: the map fading into onboarding's blue from 110 above the sheet; the
/// sheet (`background`, corners 32) 10.5 in from the sides and 11 up from the bottom edge; inside
/// it the dots 20 down, the title (40) 10 below, the brief's line (16, grey) 2 below, then the
/// address card 8 below and 10 in (raised like the search field, corners 20, 8.5 inside): the
/// address row 39 tall, a dashed line, Save as and the three chips (44), a dashed line, Add more
/// (the soft button) 10.5 below; then a dashed line 12 under the card, Continue (navy) 17 below,
/// Skip under it.
///
/// Derived (the design shows the page at rest): the address row opens a search sheet (MapKit's
/// suggestions); Select on map lets the map move under a pin until Use this place; Add more
/// moves a placed address into the list above and opens the search for the next; the map
/// trades its made-up places for the user's own as they're placed, and frames them.
struct PlacesSetupPage: View {
    @Binding var setup: PlaceSetup
    /// Picking a spot on the map: the pager holds still while the map moves.
    @Binding var isPickingOnMap: Bool
    let isCurrent: Bool
    let insets: PageInsets
    let onContinue: () -> Void
    let onSkip: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var camera: MapCameraPosition = .automatic
    @State private var screen: CGSize = .zero
    @State private var sheetTop: CGFloat = 441
    @State private var panelTop: CGFloat = 700
    @State private var isSearching = false
    @State private var lookup = AddressLookup()

    private static let space = "placesMap"

    var body: some View {
        GeometryReader { proxy in
            MapReader { map in
                ZStack(alignment: .bottom) {
                    OnboardingBackdrop(.sky)
                    placesMap
                    haze(height: proxy.size.height)
                    if isPickingOnMap {
                        pin
                        pickPanel(map)
                            .transition(slide)
                    } else {
                        sheet
                            .transition(slide)
                    }
                }
            }
            .coordinateSpace(.named(Self.space))
            .onChange(of: proxy.size, initial: true) { _, size in
                screen = size
                frameCamera(animated: false)
            }
        }
        .sheet(isPresented: $isSearching) {
            AddressSearchSheet(role: setup.current.role) { fill($0) }
        }
    }

    // MARK: Map

    /// The places on the map: the user's own once any is placed, the example's until then.
    private var placed: [PlaceDraft] {
        (setup.added + [setup.current]).filter { $0.coordinate != nil }
    }

    /// A placed address as the map pins it.
    private struct Pin: Identifiable {
        let id: PlaceDraft.ID
        let name: String
        let role: SetupRole
        let coordinate: CLLocationCoordinate2D
    }

    private var pins: [Pin] {
        placed.compactMap { draft in
            draft.coordinate.map { Pin(id: draft.id, name: draft.name, role: draft.role, coordinate: $0.location) }
        }
    }

    private var placesMap: some View {
        Map(position: $camera, interactionModes: isPickingOnMap ? [.pan, .zoom] : []) {
            if placed.isEmpty, !isPickingOnMap {
                ForEach(OnboardingExample.mapSpots) { spot in
                    Annotation(spot.name, coordinate: spot.coordinate.location, anchor: .center) {
                        ExamplePin(spot: spot, isShown: isCurrent)
                    }
                    .annotationTitles(.hidden)
                }
            }
            ForEach(pins) { pin in
                Annotation(pin.name, coordinate: pin.coordinate, anchor: .bottom) {
                    PlaceTag(name: pin.name, time: nil, icon: Art.Onboarding.role(pin.role), tail: .bottom(0.5))
                        .padding(.bottom, 5)
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll, showsTraffic: false))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: mapLabel))
    }

    private var mapLabel: String {
        if isPickingOnMap { return OnboardingCopy.pickOnMapHint }
        if placed.isEmpty { return OnboardingCopy.exampleMap { DurationText.spoken($0) } }
        return placed.map(\.name).joined(separator: ", ")
    }

    /// The map's edges: onboarding's blue at 25% over the top 100, and from 110 above the sheet
    /// to 10 above it the map fades into the blue the sheet floats on. Gone while picking.
    private func haze(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [Palette.onboardingSky.opacity(0.25), Palette.onboardingSky.opacity(0)], startPoint: .top, endPoint: .bottom)
                .frame(height: 100)
            Spacer(minLength: 0)
            LinearGradient(colors: [Palette.onboardingSky.opacity(0), Palette.onboardingSky], startPoint: .top, endPoint: .bottom)
                .frame(height: 100)
            Palette.onboardingSky
                .frame(height: max(0, height - sheetTop + 10))
        }
        .opacity(isPickingOnMap ? 0 : 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Frames the example's Brooklyn at the design's scale, or the user's places in the map
    /// above the sheet, no closer than the example's scale.
    private func frameCamera(animated: Bool) {
        guard screen.width > 0, screen.height > 0 else { return }
        let points = placed.compactMap(\.coordinate)
        let position: MapCameraPosition
        if points.isEmpty {
            let region = OnboardingExample.Map.region(width: screen.width, height: screen.height)
            position = .region(MKCoordinateRegion(
                center: region.center.location,
                span: MKCoordinateSpan(latitudeDelta: region.latitudeDelta, longitudeDelta: region.longitudeDelta)))
        } else {
            position = .region(region(fitting: points))
        }
        if animated, !reduceMotion {
            withAnimation(Motion.standard) { camera = position }
        } else {
            camera = position
        }
    }

    /// A region with `points` in the middle of the map above the sheet.
    private func region(fitting points: [Coordinate]) -> MKCoordinateRegion {
        let scale = OnboardingExample.Map.pointsPerDegree
        let latitudes = points.map(\.latitude), longitudes = points.map(\.longitude)
        let south = latitudes.min() ?? 0, north = latitudes.max() ?? 0
        let west = longitudes.min() ?? 0, east = longitudes.max() ?? 0
        let room = CGSize(width: screen.width - 120, height: max(120, sheetTop - insets.top - 100))
        // Points to a degree of latitude: the example's, or fewer to fit them all.
        var perDegree = scale.latitude
        if north > south { perDegree = min(perDegree, room.height / (north - south)) }
        if east > west { perDegree = min(perDegree, room.width / ((east - west) * scale.longitude / scale.latitude)) }
        let perLongitude = perDegree * scale.longitude / scale.latitude
        // The places' middle sits halfway between the status bar and the sheet.
        let target = (insets.top + sheetTop) / 2
        let center = Coordinate(
            latitude: (north + south) / 2 - (screen.height / 2 - target) / perDegree,
            longitude: (east + west) / 2)
        return MKCoordinateRegion(
            center: center.location,
            span: MKCoordinateSpan(latitudeDelta: screen.height / perDegree, longitudeDelta: screen.width / perLongitude))
    }

    private var slide: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity)
    }

    // MARK: Sheet

    private var sheet: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .vertical) {
                sheetHead
                ScrollView { sheetHead }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollIndicators(.hidden)
            }
            DashedDivider()
                .padding(.horizontal, 10)
                .padding(.top, Space.m)
            Button(OnboardingCopy.continue, action: onContinue)
                .buttonStyle(.primary(role: .action))
                .padding(.horizontal, 19.5)
                .padding(.top, 17)
            Button(OnboardingCopy.skip, action: onSkip)
                .buttonStyle(.text())
                .padding(.top, -1.5)
                .padding(.bottom, Space.xs)
        }
        .frame(maxWidth: .infinity)
        .background(Palette.background, in: .rect(cornerRadius: Radius.xxl))
        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named(Self.space)).minY } action: { top in
            sheetTop = top
        }
        .padding(.horizontal, 10.5)
        .padding(.top, insets.top + Space.s)
        .padding(.bottom, insets.foot(11.1, floor: 10))
    }

    private var sheetHead: some View {
        VStack(spacing: 0) {
            PageDots(
                count: OnboardingPage.allCases.count, current: OnboardingPage.yourPlaces.rawValue, style: .onLight,
                label: OnboardingCopy.pageLabel(.yourPlaces))
                .padding(.top, Space.screen)
            Text(verbatim: OnboardingCopy.placesTitle)
                .textRole(.display)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 10)
            Text(verbatim: OnboardingCopy.placesLine)
                .textRole(.body, weight: .regular)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 290)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Space.xxs)
            placesCard
                .padding(.top, Space.s)
                .padding(.horizontal, 10)
        }
    }

    /// The raised card: places added so far, the address being entered, what it's saved as,
    /// and Add more.
    private var placesCard: some View {
        VStack(spacing: 0) {
            ForEach(setup.added) { draft in
                AddedPlaceRow(draft: draft) {
                    withAnimation(reduceMotion ? Motion.reduced : Motion.standard) {
                        setup.remove(draft.id)
                    }
                    frameCamera(animated: true)
                }
                DashedDivider()
            }
            addressRow
            DashedDivider()
            saveAsRow
            DashedDivider()
            Button(action: addMore) {
                HStack(spacing: Space.xs) {
                    Image(systemName: "plus")
                    Text(verbatim: OnboardingCopy.addMore)
                }
            }
            .buttonStyle(.soft)
            .padding(.top, 10.5)
        }
        .padding(.horizontal, 8.5)
        .padding(.bottom, 8.5)
        .raisedField(RoundedRectangle(cornerRadius: Radius.xl))
    }

    /// "Enter address" or the address picked, and Select on map.
    private var addressRow: some View {
        let current = setup.current
        let hasAddress = !current.address.isEmpty
        return HStack(spacing: Space.s) {
            Button {
                isSearching = true
            } label: {
                HStack(spacing: Space.s) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Palette.fieldIcon)
                        .accessibilityHidden(true)
                    Text(verbatim: hasAddress ? current.address : OnboardingCopy.enterAddress)
                        .textRole(.body, weight: .regular)
                        .foregroundStyle(hasAddress && current.coordinate != nil ? Palette.textPrimary : Palette.placeholder)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 39)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: hasAddress ? "\(current.role.name), \(current.address)" : OnboardingCopy.enterAddress))
            Button {
                withAnimation(reduceMotion ? Motion.reduced : Motion.standard) {
                    isPickingOnMap = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 16))
                        .accessibilityHidden(true)
                    Text(verbatim: OnboardingCopy.selectOnMap)
                        .textRole(.caption, weight: .medium)
                }
                .foregroundStyle(Palette.link)
                .frame(minHeight: 39)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, Space.xs)
    }

    /// "Save as:" and the three roles. At large text sizes the chips go under the words.
    private var saveAsRow: some View {
        let label = Text(verbatim: OnboardingCopy.saveAs)
            .textRole(.caption)
            .foregroundStyle(Palette.textPrimary)
        let chips = ForEach(SetupRole.allCases) { role in
            ChoiceChip(role.name, icon: Art.Onboarding.role(role), isSelected: setup.current.role == role) {
                setup.current.role = role
            }
        }
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: Space.s) {
                label
                HStack(spacing: Space.xs) { chips }
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: 0) {
                label
                    .padding(.top, Space.s)
                FlowLayout(spacing: Space.xs, lineSpacing: 0) { chips }
            }
        }
        .padding(.leading, 1.5)
        .frame(minHeight: 44)
        .accessibilityElement(children: .contain)
    }

    private func addMore() {
        if setup.canAddMore {
            withAnimation(reduceMotion ? Motion.reduced : Motion.standard) {
                setup.addMore()
            }
        }
        isSearching = true
    }

    private func fill(_ picked: PickedAddress) {
        setup.current.address = picked.address
        setup.current.area = picked.area
        setup.current.coordinate = picked.coordinate
        frameCamera(animated: true)
    }

    // MARK: Picking on the map

    /// Where the pin points: the middle of the map above the panel.
    private var pinPoint: CGPoint {
        CGPoint(x: screen.width / 2, y: (insets.top + panelTop) / 2)
    }

    /// The place's tag pointing at the spot the map will name, with a dot on the spot.
    private var pin: some View {
        ZStack {
            Circle()
                .fill(Palette.textPrimary)
                .frame(width: 8, height: 8)
                .overlay { Circle().strokeBorder(.white, lineWidth: 2) }
                .position(pinPoint)
            PlaceTag(name: setup.current.role.name, time: nil, icon: Art.Onboarding.role(setup.current.role), tail: .bottom(0.5))
                .position(x: pinPoint.x, y: pinPoint.y - 33 / 2 - 5 - 4)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .transition(.opacity)
    }

    private func pickPanel(_ map: MapProxy) -> some View {
        VStack(spacing: 0) {
            Text(verbatim: OnboardingCopy.pickOnMapHint)
                .textRole(.body, weight: .regular)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Space.screen)
                .padding(.top, Space.screen)
            Button(OnboardingCopy.useThisPlace) { usePin(map) }
                .buttonStyle(.primary(role: .action))
                .padding(.horizontal, 19.5)
                .padding(.top, Space.l)
            Button(OnboardingCopy.cancel) {
                withAnimation(reduceMotion ? Motion.reduced : Motion.standard) {
                    isPickingOnMap = false
                }
                frameCamera(animated: true)
            }
            .buttonStyle(.text())
            .padding(.top, -1.5)
            .padding(.bottom, Space.xs)
        }
        .frame(maxWidth: .infinity)
        .background(Palette.background, in: .rect(cornerRadius: Radius.xxl))
        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named(Self.space)).minY } action: { top in
            panelTop = top
        }
        .padding(.horizontal, 10.5)
        .padding(.bottom, insets.foot(11.1, floor: 10))
    }

    /// Places the address being entered where the pin points, then asks the map for its words.
    private func usePin(_ map: MapProxy) {
        guard let point = map.convert(pinPoint, from: .named(Self.space)) else { return }
        let coordinate = Coordinate(latitude: point.latitude, longitude: point.longitude)
        let id = setup.current.id
        setup.current.coordinate = coordinate
        setup.current.address = OnboardingCopy.findingAddress
        setup.current.area = nil
        withAnimation(reduceMotion ? Motion.reduced : Motion.standard) {
            isPickingOnMap = false
        }
        Task {
            let named = await lookup.name(of: coordinate)
            setup.name(id, address: named?.address ?? OnboardingCopy.pinnedPlace, area: named?.area)
        }
    }
}

/// A made-up place on the example map, as the design pins it: its photo tilted on the spot and
/// its tag beside it, pointing at the photo. Pops in when the page shows.
///
/// Measured at 393 × 852: Mara's place (the design's "GF's place") 70 × 84 turned −10.7°, its
/// tag 99 right and 37 up, pointing left; the café 70 × 80 turned 15.6°, its tag 51.5 left and
/// 69 down, pointing up.
private struct ExamplePin: View {
    let spot: OnboardingExample.Spot
    let isShown: Bool

    var body: some View {
        let layout = layout
        ZStack {
            if isShown {
                PhotoCard(Art.Onboarding.photo(spot.photo), category: spot.category)
                    .frame(width: layout.size.width, height: layout.size.height)
                    .rotationEffect(.degrees(layout.angle))
                    .popIn(delay: layout.delay)
                PlaceTag(name: spot.name, time: DurationText.short(spot.time), icon: Art.glyph(spot.category), tail: layout.tail)
                    .offset(layout.tag)
                    .popIn(delay: layout.delay + 0.12)
            }
        }
        .frame(width: layout.size.width, height: layout.size.height)
        .accessibilityHidden(true)
    }

    private var layout: (size: CGSize, angle: Double, tag: CGSize, tail: PlaceTag.Tail, delay: Double) {
        switch spot.photo {
        case .cafe: (CGSize(width: 70, height: 80), 15.6, CGSize(width: -51.5, height: 69), .top(0.87), 0.38)
        default: (CGSize(width: 70, height: 84), -10.7, CGSize(width: 99, height: -37), .leading(0.5), 0.3)
        }
    }
}

/// A place added with Add more: its role's glyph, its name over its address, and a button to
/// take it out of the list. Not in the design (it shows one place being entered).
private struct AddedPlaceRow: View {
    let draft: PlaceDraft
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Space.s) {
            Art.Onboarding.role(draft.role)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(Palette.textPrimary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Space.xxs) {
                Text(verbatim: draft.role == .other ? draft.role.name : draft.name)
                    .textRole(.body)
                    .foregroundStyle(Palette.textPrimary)
                Text(verbatim: [draft.address, draft.area].compactMap(\.self).joined(separator: ", "))
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.textSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: OnboardingCopy.remove(draft)))
        }
        .padding(.leading, Space.xs)
        .padding(.vertical, Space.xs)
    }
}
