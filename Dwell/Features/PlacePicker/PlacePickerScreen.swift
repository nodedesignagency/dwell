import CoreLocation
import DwellCore
import DwellUI
import MapKit
import SwiftUI

/// What the place picker chooses for: a visit, and the place it's at now (its own, or one
/// already picked in Visit edit).
struct PlacePickerRequest: Identifiable {
    let visit: Visit
    var placeID: PlaceID?
    var placeName: String
    /// When the picker opened: a visit still going runs to then.
    var now: Date

    var id: VisitID { visit.id }

    init(visit: Visit, placeID: PlaceID? = nil, placeName: String? = nil, now: Date) {
        self.visit = visit
        self.placeID = placeID ?? visit.placeID
        self.placeName = placeName ?? visit.placeName
        self.now = now
    }
}

/// The place picker (Place picker design, 14 Nov; brief A.7: "nearby, search, somewhere
/// else"): the map full screen, the place picked on it with its tag, under a floating sheet:
/// "Where were you?", when and how long, Search places, the nearby places as a list to choose
/// one from, Somewhere else, and "Select" with the place's name.
///
/// Opened from Today's confirmation card (Pick another), a visit's "Review this place" and
/// Visit edit's Change place. Choosing a row moves the map to it; Select hands the choice back
/// (`onSelect`), which saves it or, in Visit edit, waits for Save. Somewhere else opens a
/// stand-in until its design. The map is MapKit, with no points of interest and no private
/// or personal place on it (brief §7.2).
///
/// Measured at 393 × 852: the sheet (`background`, corners 32) 10.5 in and 11 up; the title
/// (28) 20 in and level with the close button (44, 16 from the corner); the span (18, grey) 3
/// below; the search field 16.5 below and 20 in (white in a hairline); "NEARBY PLACES" 16
/// below; the rows 4.5 below it, 8 apart, 20 in; a dashed line 18.5 below them; Somewhere else
/// 13.5 below that; a dashed line 11.5 below; Select 13.5 below and 10 in, 16 above the sheet's
/// foot. The map fades into `mapFrame` beside the sheet from 58 to 196 below its top, and has
/// that blue at 25% over its top 100.
struct PlacePickerScreen: View {
    let request: PlacePickerRequest
    /// Takes the choice; throws when it didn't reach the engine (the sheet says so).
    let onSelect: @MainActor (PlaceCandidate) async throws -> Void
    let onClose: () -> Void

    @Environment(\.repository) private var repository
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private nonisolated enum Phase: Equatable {
        case loading
        case loaded([PlaceCandidate])
        case failed
    }

    @State private var nearby: Phase = .loading
    @State private var results: Phase?
    @State private var query: String
    @State private var chosen: PlaceCandidate?
    @State private var attempt = 0
    @State private var isSaving: Bool
    @State private var failed: Bool
    @State private var isNaming = false
    @State private var camera: MapCameraPosition = .automatic
    @State private var screen: CGSize = .zero
    @State private var topInset: CGFloat = 54
    @State private var sheetTop: CGFloat = 286
    @State private var listHeight: CGFloat = 340

    /// The map's scale: about 4,650 pt to a degree of latitude, as onboarding's map of
    /// Brooklyn and Is this home? (the design's Greenpoint to Bedford).
    private static let pointsPerDegree: Double = 4650

    /// - Parameters:
    ///   - query, failed, saving: open mid-search, or as if Select had failed or were under way
    ///     (previews).
    init(
        request: PlacePickerRequest,
        query: String = "",
        failed: Bool = false,
        saving: Bool = false,
        onSelect: @escaping @MainActor (PlaceCandidate) async throws -> Void,
        onClose: @escaping () -> Void
    ) {
        self.request = request
        self.onSelect = onSelect
        self.onClose = onClose
        _query = State(initialValue: query)
        _failed = State(initialValue: failed)
        _isSaving = State(initialValue: saving)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            map
                .ignoresSafeArea()
                .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                    screen = size
                    frameCamera(animated: false)
                }
            haze
                .ignoresSafeArea()
            sheet
                .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { top in
                    sheetTop = top
                    frameCamera(animated: false)
                }
                .padding(.horizontal, 10.5)
                .padding(.top, Space.s)
                .padding(.bottom, 11)
                .ignoresSafeArea(.container, edges: .bottom)
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { topInset = proxy.frame(in: .global).minY }
            }
        }
        .background(Palette.mapFrame)
        .task(id: attempt) { await loadNearby() }
        .task(id: query) { await search() }
        .sheet(isPresented: $isNaming) {
            PendingView(title: PlacePickerCopy.somewhereElse, systemImage: "mappin.and.ellipse")
                .presentationDetents([.medium])
        }
    }

    // MARK: Map

    private var map: some View {
        Map(position: $camera, interactionModes: [.pan, .zoom]) {
            if let chosen, let coordinate = chosen.coordinate, !chosen.isHiddenFromMaps {
                Annotation(chosen.name, coordinate: coordinate.location, anchor: .leading) {
                    // The tail's tip on the place, as the design points it.
                    PlaceTag(
                        mapName: chosen.name, time: DurationText.short(duration),
                        icon: Art.glyph(chosen.category), tail: .leading(0.5))
                        .padding(.leading, PlaceTag.tailDepth(onMap: true))
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll, showsTraffic: false))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: PlacePickerCopy.mapLabel(chosen?.name ?? request.placeName)))
    }

    /// `mapFrame` at 25% over the top 100; beside the sheet the map fades into it from 58 to
    /// 196 below the sheet's top, solid from there down.
    private var haze: some View {
        let top: [Gradient.Stop] = [
            Gradient.Stop(color: Palette.mapFrame.opacity(0.25), location: 0),
            Gradient.Stop(color: Palette.mapFrame.opacity(0), location: 1),
        ]
        let foot: [Gradient.Stop] = [
            Gradient.Stop(color: Palette.mapFrame.opacity(0), location: 0),
            Gradient.Stop(color: Palette.mapFrame, location: 1),
        ]
        return VStack(spacing: 0) {
            LinearGradient(stops: top, startPoint: .top, endPoint: .bottom)
                .frame(height: 100)
            Color.clear
                .frame(height: max(0, sheetTop + 58 - 100))
            LinearGradient(stops: foot, startPoint: .top, endPoint: .bottom)
                .frame(height: 138)
            Palette.mapFrame
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The place picked a quarter of the way across and halfway between the status bar and
    /// the sheet, where the design has it, so its tag reads to the right.
    private func frameCamera(animated: Bool) {
        guard screen.width > 0, screen.height > 0, let target = (chosen ?? firstOnMap)?.coordinate else { return }
        let perLatitude = Self.pointsPerDegree
        let perLongitude = perLatitude * cos(target.latitude * .pi / 180)
        let x = Double(screen.width) * 0.25
        let y = Double(topInset + sheetTop) / 2
        let center = CLLocationCoordinate2D(
            latitude: target.latitude + (y - Double(screen.height) / 2) / perLatitude,
            longitude: target.longitude + (Double(screen.width) / 2 - x) / perLongitude)
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: Double(screen.height) / perLatitude,
                longitudeDelta: Double(screen.width) / perLongitude))
        if animated, !reduceMotion {
            withAnimation(Motion.standard) { camera = .region(region) }
        } else {
            camera = .region(region)
        }
    }

    /// Where to look before anything is picked: the first nearby place that may go on a map.
    private var firstOnMap: PlaceCandidate? {
        guard case .loaded(let places) = nearby else { return nil }
        return places.first { $0.coordinate != nil && !$0.isHiddenFromMaps }
    }

    // MARK: Sheet

    private var sheet: some View {
        VStack(spacing: 0) {
            header

            SearchField(PlacePickerCopy.searchPrompt, text: $query, look: .outlined)
                .padding(.horizontal, Space.screen)
                .padding(.top, 16.5)

            // The list scrolls when it outgrows the room: at large text, with the keyboard up.
            ScrollView {
                list
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { listHeight = $0 }
            }
            .frame(maxHeight: listHeight)
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.immediately)

            DashedDivider()
                .padding(.horizontal, Space.screen)
                .padding(.top, 11.5)

            if failed {
                Text(verbatim: PlacePickerCopy.saveFailed)
                    .textRole(.caption, weight: .medium)
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Space.screen)
                    .padding(.top, Space.m)
                    .transition(.opacity)
            }

            selectButton
                .padding(.horizontal, 10)
                .padding(.top, 13.5)
                .padding(.bottom, Space.l)
        }
        .frame(maxWidth: .infinity)
        .background(Palette.background, in: .rect(cornerRadius: Radius.xxl))
        .motion(value: failed)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .center, spacing: Space.s) {
                Text(verbatim: request.visit.isOngoing ? PlacePickerCopy.titleNow : PlacePickerCopy.title)
                    .textRole(.cardTitle)
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                RaisedCloseButton(label: PlacePickerCopy.close, action: onClose)
            }
            Text(verbatim: PlacePickerCopy.subtitle(
                arrival: request.visit.arrival, departure: request.visit.departure,
                now: request.now, calendar: calendar))
                .textRole(.action, weight: .regular)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, Space.screen)
        .padding(.trailing, Space.l)
        .padding(.top, Space.l)
    }

    /// The nearby places, or search results while there are words in the field, then
    /// Somewhere else.
    private var list: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(isSearching ? PlacePickerCopy.results : PlacePickerCopy.nearby)
                .padding(.top, Space.l)

            rows(results ?? nearby)
                .padding(.top, 4.5)

            DashedDivider()
                .padding(.top, 18.5)

            ChevronCard(
                title: PlacePickerCopy.somewhereElse,
                detail: PlacePickerCopy.somewhereElseDetail,
                // [ICON NEEDED] the design draws the house glyph; an SF Symbol stands in.
                glyph: Image(systemName: "mappin.and.ellipse")
            ) {
                isNaming = true
            }
            .padding(.top, 13.5)
        }
        .padding(.horizontal, Space.screen)
    }

    @ViewBuilder
    private func rows(_ phase: Phase) -> some View {
        switch phase {
        case .loading:
            VStack(spacing: Space.s) {
                ForEach(0..<3, id: \.self) { _ in
                    PlaceChoiceRow(name: "Loading place", facts: "Food & drink · 40 m", glyph: Art.glyph(.other), isSelected: false) {}
                        .redacted(reason: .placeholder)
                        .disabled(true)
                }
            }
            .accessibilityHidden(true)
        case .failed:
            notice(PlacePickerCopy.failed, retry: true)
        case .loaded(let places) where places.isEmpty:
            notice(isSearching ? PlacePickerCopy.noMatches(query) : PlacePickerCopy.noNearby, retry: false)
        case .loaded(let places):
            VStack(spacing: Space.s) {
                ForEach(places) { place in
                    PlaceChoiceRow(
                        name: place.name,
                        facts: PlacePickerCopy.facts(place, locale: calendar.locale ?? locale),
                        glyph: Art.glyph(place.category),
                        isSelected: chosen?.id == place.id
                    ) {
                        choose(place)
                    }
                }
            }
        }
    }

    private func notice(_ text: String, retry: Bool) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(verbatim: text)
                .textRole(.caption)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if retry {
                Button(PlacePickerCopy.tryAgain) {
                    attempt += 1
                }
                .buttonStyle(.text())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Space.s)
    }

    private var selectButton: some View {
        Button {
            select()
        } label: {
            ZStack {
                Text(verbatim: chosen.map { PlacePickerCopy.select($0.name) } ?? PlacePickerCopy.pickAPlace)
                    .lineLimit(1)
                    .opacity(isSaving ? 0 : 1)
                if isSaving {
                    ProgressView()
                        .tint(Palette.inverseText)
                }
            }
        }
        .buttonStyle(.primary(role: .action))
        .disabled(chosen == nil || isSaving)
        .opacity(chosen == nil ? 0.5 : 1)
    }

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// How long the visit was, or has been so far: the tag's time.
    private var duration: TimeInterval {
        max(0, (request.visit.departure ?? request.now).timeIntervalSince(request.visit.arrival))
    }

    // MARK: Choosing

    private func choose(_ place: PlaceCandidate) {
        chosen = place
        frameCamera(animated: true)
    }

    private func select() {
        guard let chosen, !isSaving else { return }
        failed = false
        isSaving = true
        Task {
            do {
                try await onSelect(chosen)
            } catch {
                failed = true
            }
            isSaving = false
        }
    }

    // MARK: Loading

    private func loadNearby() async {
        if case .loaded = nearby, attempt == 0 { return }
        nearby = .loading
        do {
            let places = try await repository.nearbyPlaces(for: request.visit)
            nearby = .loaded(places)
            // The place the visit is at now, chosen to start, as the design shows the guess.
            if chosen == nil {
                chosen = places.first { $0.isSame(placeID: request.placeID, name: request.placeName) }
            }
            frameCamera(animated: false)
        } catch is CancellationError {
            return
        } catch {
            nearby = .failed
        }
    }

    /// Searches a quarter of a second after the typing stops.
    private func search() async {
        guard isSearching else {
            results = nil
            return
        }
        do {
            try await Task.sleep(for: .milliseconds(250))
        } catch {
            return
        }
        if results == nil { results = .loading }
        do {
            results = .loaded(try await repository.searchPlaces(query, for: request.visit))
        } catch is CancellationError {
            return
        } catch {
            results = .failed
        }
    }
}
