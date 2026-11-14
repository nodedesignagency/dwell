import DwellCore
import DwellUI
import SwiftUI

/// What the visit edit sheet opens on: the visit's draft, the day it's in as Today shows it,
/// and the moment it opened (a visit still going ends then). Nonisolated: it rides in Today's
/// `TodayPrompt`, whose Hashable conformance isn't on the main actor.
nonisolated struct VisitEditRequest: Hashable {
    var draft: VisitDraft
    var snapshot: DaySnapshot
    var now: Date
}

/// Visit edit (Visit Edit design, 14 Nov; brief §7.1 "Long-press to edit", A.7): slides up
/// over Today when a visit in "Your day" is held. The visit's place and when; the place on a
/// map; its time on the day's track, dragged at either end; the day's work and yours as this
/// visit's changes leave them; Change place, Split this visit, Merge with next visit; Working
/// from home and Keep this visit private; Save and Delete.
///
/// Nothing changes until Save (`VisitDraft` holds the changes and their rules); a swipe down
/// or a tap outside lets them go. Delete asks first. Change place opens the place picker
/// (`PlacePickerScreen`); its choice waits for Save too. The map is the design's picture until MapKit draws the
/// place's own (the user's call, 14 Nov); its cluster and tag are drawn here, so they stay.
///
/// Measured at 393 × 852 (`docs/DESIGN.md`): the sheet 10.5 in and 20 up, 730 tall, the
/// page's grey, corners 32; the grabber 9 from the top; the header 16 in, its well level with
/// the title's capitals; the map 207 tall from under the header, edge to edge; the track 3
/// below it; the tiles 6 below the hours; then 10 between the rest; Save and Delete 20 above
/// the sheet's foot.
struct VisitEditSheet: View {
    let request: VisitEditRequest
    /// Saves the draft and closes the sheet; throws when it didn't reach the engine.
    let onSave: @MainActor (VisitDraft) async throws -> Void
    /// Deletes the visit and closes the sheet; throws when it didn't reach the engine.
    let onDelete: @MainActor (VisitID) async throws -> Void

    @Environment(\.calendar) private var calendar
    @Environment(\.dial) private var dial
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var draft: VisitDraft
    @State private var isSaving: Bool
    @State private var failed: Bool
    @State private var isConfirmingDelete = false
    @State private var isPickingPlace = false

    /// - Parameters:
    ///   - failed, saving: open as if Save had failed or were under way (previews).
    init(
        request: VisitEditRequest,
        onSave: @escaping @MainActor (VisitDraft) async throws -> Void,
        onDelete: @escaping @MainActor (VisitID) async throws -> Void,
        failed: Bool = false,
        saving: Bool = false
    ) {
        self.request = request
        self.onSave = onSave
        self.onDelete = onDelete
        _draft = State(initialValue: request.draft)
        _failed = State(initialValue: failed)
        _isSaving = State(initialValue: saving)
    }

    private var snapshot: DaySnapshot { request.snapshot }
    private var now: Date { request.now }

    var body: some View {
        let recap = snapshot.applying(draft).recap(now: now)
        let duration = draft.duration(in: snapshot, now: now)
        VStack(spacing: 0) {
            SheetGrabber()
                .padding(.top, 9)

            header(duration: duration)
                .padding(.top, 13)
                .padding(.horizontal, Space.l)

            VisitMap(
                name: draft.placeName,
                time: DurationText.short(duration),
                category: draft.placeCategory,
                isHidden: draft.isHiddenFromMaps)

            VisitSpanTrack(
                day: snapshot.interval,
                arrival: draft.arrival,
                end: draft.end(in: snapshot, now: now),
                endsNow: draft.endsNow(in: snapshot),
                split: draft.splitTime,
                movable: movable,
                calendar: calendar
            ) { handle, date in
                move(handle, to: date)
            }
            .padding(.top, 3)
            .padding(.horizontal, Space.l)

            tiles(recap)
                .padding(.top, 6)
                .padding(.horizontal, Space.l)

            actions
                .padding(.top, 10)
                .padding(.horizontal, Space.l)

            switches
                .padding(.top, 10)
                .padding(.horizontal, Space.l)

            if failed {
                Text(verbatim: VisitEditCopy.saveFailed)
                    .textRole(.caption, weight: .medium)
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.horizontal, Space.l)
                    .transition(.opacity)
            }

            buttons
                .padding(.top, 10)
                .padding(.horizontal, Space.l)
                .padding(.bottom, Space.screen)
        }
        .frame(maxWidth: .infinity)
        .background(Palette.background)
        .clipShape(.rect(cornerRadius: Radius.xxl))
        .motion(value: failed)
        .fullScreenCover(isPresented: $isPickingPlace) {
            PlacePickerScreen(
                request: PlacePickerRequest(
                    visit: draft.original, placeID: draft.placeID, placeName: draft.placeName, now: now),
                onSelect: { candidate in
                    // Waits for Save, like every change here.
                    change { draft.choose(candidate) }
                    isPickingPlace = false
                },
                onClose: { isPickingPlace = false })
        }
    }

    // MARK: Header

    /// The place's glyph in a well, its name over when and how long, and what the visit counts
    /// as ("Work" for work from home, shown at home).
    private func header(duration: TimeInterval) -> some View {
        let subtitle = VisitEditCopy.subtitle(arrival: draft.arrival, duration: duration, now: now, calendar: calendar)
        return HStack(alignment: .top, spacing: Space.s) {
            HStack(spacing: Space.s) {
                IconWell {
                    Art.glyph(draft.placeCategory)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Palette.textPrimary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: draft.placeName)
                        .textRole(.body)
                        .foregroundStyle(Palette.textPrimary)
                    Text(verbatim: subtitle)
                        .textRole(.caption, monospacedDigits: true)
                        .foregroundStyle(Palette.textSecondary)
                        .contentTransition(.numericText())
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Space.s)
            CategoryMark(draft.category)
                .padding(.top, 1)
                .contentTransition(.opacity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: The day's numbers

    /// The day's work and yours as the changes leave them, so the user sees what Save does.
    /// Plain labels; Grind calls yours "Off" (brief §7.3), as Time's tiles do.
    private func tiles(_ recap: DayRecap) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Space.s))
            : AnyLayout(HStackLayout(spacing: Space.s))
        return layout {
            StatTile(
                value: DurationText.short(recap.work), label: TimeCopy.atWork,
                spokenValue: DurationText.spoken(recap.work), tint: PlaceCategory.work.color,
                labelFirst: true
            ) { art(Art.heroWork) }
            StatTile(
                value: DurationText.short(recap.yours), label: TimeCopy.yours.text(for: dial),
                spokenValue: DurationText.spoken(recap.yours), tint: Palette.yours,
                labelFirst: true
            ) { art(Art.heroYours) }
        }
        .contentTransition(.numericText())
    }

    private func art(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
    }

    // MARK: Actions

    /// Change place, Split this visit, Merge with next visit. Split and merge wait for Save and
    /// show as on (navy) until then; a second tap takes them back. [ICON NEEDED] the design
    /// draws the house glyph on all three; SF Symbols stand in.
    private var actions: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 7))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 7))
        let isSplit = draft.splitTime != nil
        let isMerged = draft.change == .mergeWithNext
        let canSplit = isSplit || canSplitUnmerged
        let canMerge = draft.canMerge(in: snapshot)
        return layout {
            ActionTile(
                VisitEditCopy.changePlace, glyph: Image(systemName: "mappin.and.ellipse"),
                hint: VisitEditCopy.changePlaceHint
            ) {
                isPickingPlace = true
            }
            ActionTile(
                VisitEditCopy.split, glyph: Image(systemName: "scissors"), isOn: isSplit,
                hint: canSplit ? VisitEditCopy.splitHint : VisitEditCopy.tooShortToSplit
            ) {
                change { draft.toggleSplit(in: snapshot, now: now) }
            }
            .disabled(!canSplit)
            ActionTile(
                VisitEditCopy.merge, glyph: Image(systemName: "arrow.triangle.merge"), isOn: isMerged,
                hint: canMerge ? VisitEditCopy.mergeHint : VisitEditCopy.noNextVisit
            ) {
                change { draft.toggleMerge(in: snapshot) }
            }
            .disabled(!canMerge)
        }
    }

    /// Whether the visit, without any merge, is long enough to split.
    private var canSplitUnmerged: Bool {
        var unmerged = draft
        unmerged.change = .none
        return unmerged.canSplit(in: snapshot, now: now)
    }

    // MARK: Switches

    /// Working from home only means something at home, so elsewhere it shows off and can't be
    /// turned on, saying why (the design draws it on at Kestriva Labs: QUESTIONS.md).
    /// [ICON NEEDED] the design's eye for private; an SF Symbol stands in.
    private var switches: some View {
        // Disabled, the row shows off whatever the draft says, and Save ignores it away from home.
        VStack(alignment: .leading, spacing: Space.m) {
            Toggle(isOn: $draft.isWorkFromHome) {
                ToggleRowLabel(
                    VisitEditCopy.workFromHome,
                    detail: draft.isAtHome ? VisitEditCopy.workFromHomeDetail : VisitEditCopy.workFromHomeElsewhere,
                    glyph: Art.glyph(.home))
            }
            .toggleStyle(.row)
            .disabled(!draft.isAtHome)

            DashedDivider()

            Toggle(isOn: $draft.isPrivate) {
                ToggleRowLabel(
                    VisitEditCopy.keepPrivate,
                    detail: VisitEditCopy.keepPrivateDetail,
                    glyph: Image(systemName: "eye.fill"))
            }
            .toggleStyle(.row)
        }
        .padding(Space.l)
        .card()
    }

    // MARK: Save and Delete

    private var buttons: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Space.m))
            : AnyLayout(HStackLayout(spacing: Space.m))
        return layout {
            Button {
                save()
            } label: {
                ZStack {
                    Text(verbatim: VisitEditCopy.save)
                        .opacity(isSaving ? 0 : 1)
                    if isSaving {
                        ProgressView()
                            .tint(Palette.inverseText)
                    }
                }
            }
            .buttonStyle(.primary(role: .action))
            .accessibilityLabel(VisitEditCopy.save)

            Button {
                isConfirmingDelete = true
            } label: {
                Text(verbatim: VisitEditCopy.delete)
                    .foregroundStyle(Palette.destructive)
            }
            .buttonStyle(.secondary)
        }
        .disabled(isSaving)
        .confirmationDialog(
            VisitEditCopy.deleteTitle,
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button(VisitEditCopy.deleteConfirm, role: .destructive) { delete() }
            Button(VisitEditCopy.cancel, role: .cancel) {}
        } message: {
            Text(verbatim: VisitEditCopy.deleteMessage)
        }
    }

    private func save() {
        guard !isSaving else { return }
        failed = false
        isSaving = true
        let draft = draft
        Task {
            do {
                try await onSave(draft)
            } catch {
                failed = true
            }
            isSaving = false
        }
    }

    private func delete() {
        failed = false
        isSaving = true
        let id = draft.original.id
        Task {
            do {
                try await onDelete(id)
            } catch {
                failed = true
            }
            isSaving = false
        }
    }

    // MARK: Moving

    private var movable: Set<VisitSpanTrack.Handle> {
        var handles: Set<VisitSpanTrack.Handle> = []
        if draft.canMoveArrival(in: snapshot) { handles.insert(.arrival) }
        if draft.canMoveDeparture(in: snapshot) { handles.insert(.departure) }
        if draft.splitTime != nil { handles.insert(.split) }
        return handles
    }

    /// Follows the finger exactly: no animation while dragging.
    private func move(_ handle: VisitSpanTrack.Handle, to date: Date) {
        switch handle {
        case .arrival: draft.moveArrival(to: date, in: snapshot, now: now)
        case .departure: draft.moveDeparture(to: date, in: snapshot, now: now)
        case .split: draft.moveSplit(to: date, in: snapshot, now: now)
        }
    }

    /// Split and merge move the track's ends and the numbers: a spring, or a cross-fade under
    /// Reduce Motion.
    private func change(_ body: () -> Void) {
        withAnimation(reduceMotion ? Motion.reduced : Motion.standard, body)
    }
}

// MARK: - Map

/// The place on a map: the design's picture for now (`Art.StandIn.map`), the place's cluster
/// of cells over it, a dot on the place and its tag pointing at it from the right: name and
/// the visit's time, or the name alone where the time won't fit before the map's edge, or
/// the name cut short. Private and personal places never go on a map (brief §7.2): the map
/// blurs and says so instead. In dark mode the picture is turned dark (inverted, its hues
/// turned back) until MapKit's own dark map replaces it. Fades in at its top and out at its
/// foot over 16, into the sheet's grey.
private struct VisitMap: View {
    let name: String
    let time: String
    let category: PlaceCategory
    let isHidden: Bool

    static let height: CGFloat = 207
    /// The tag starts this far right of the place, its tail's tip 5 short of it (measured).
    private static let tagGap: CGFloat = 13

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let place = Self.place(in: proxy.size)
            ZStack(alignment: .topLeading) {
                Art.StandIn.map
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .modifier(DarkPicture(isOn: colorScheme == .dark))
                    .blur(radius: isHidden ? 10 : 0)

                if isHidden {
                    hiddenNote
                        .frame(width: proxy.size.width, height: proxy.size.height)
                } else {
                    HexCluster(category)
                        .position(place)
                    PlaceDot(color: category.color)
                        .position(place)
                    tag(place: place, width: proxy.size.width)
                }
            }
        }
        .frame(height: Self.height)
        .mask { fade }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: isHidden ? VisitEditCopy.hiddenFromMaps : VisitEditCopy.mapLabel(name)))
    }

    private func tag(place: CGPoint, width: CGFloat) -> some View {
        let start = place.x + Self.tagGap
        let room = max(0, width - Space.l - start)
        let icon = Art.glyph(category)
        return ViewThatFits(in: .horizontal) {
            PlaceTag(mapName: name, time: time, icon: icon, tail: .leading(0.5))
            PlaceTag(mapName: name, time: nil, icon: icon, tail: .leading(0.5))
            PlaceTag(mapName: name, time: nil, icon: icon, tail: .leading(0.5), truncates: true)
        }
        .frame(width: room, alignment: .leading)
        // The design's tag sits 3.5 above the place.
        .position(x: start + room / 2, y: place.y - 3.5)
    }

    private var hiddenNote: some View {
        VStack(spacing: Space.s) {
            Art.Glyph.lock
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(Palette.privacyText)
            Text(verbatim: VisitEditCopy.hiddenFromMaps)
                .textRole(.caption, weight: .medium)
                .foregroundStyle(Palette.privacyText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Space.xl)
    }

    private var fade: some View {
        let edge = 16 / Self.height
        let stops: [Gradient.Stop] = [
            Gradient.Stop(color: .clear, location: 0),
            Gradient.Stop(color: .black, location: edge),
            Gradient.Stop(color: .black, location: 1 - edge),
            Gradient.Stop(color: .clear, location: 1),
        ]
        return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
    }

    /// Where the design's place falls once the picture fills the frame.
    private static func place(in size: CGSize) -> CGPoint {
        let picture = Art.StandIn.mapSize
        let scale = max(size.width / picture.width, size.height / picture.height)
        let width = picture.width * scale
        let height = picture.height * scale
        let originX = (size.width - width) / 2
        let originY = (size.height - height) / 2
        return CGPoint(
            x: originX + width * Art.StandIn.mapPlace.x,
            y: originY + height * Art.StandIn.mapPlace.y)
    }
}

/// The light picture turned dark for dark mode: inverted, its hues turned back round.
private struct DarkPicture: ViewModifier {
    let isOn: Bool

    func body(content: Content) -> some View {
        if isOn {
            content
                .colorInvert()
                .hueRotation(.degrees(180))
        } else {
            content
        }
    }
}

/// The place itself, in the cluster's middle cell: a dot of its category's colour in a white
/// ring, mostly under the tag's tail as the design draws it.
private struct PlaceDot: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(Palette.ring)
            .frame(width: 10, height: 10)
            .overlay {
                Circle()
                    .fill(color)
                    .padding(2.5)
            }
            .shadow(color: .black.opacity(0.15), radius: 1.5, y: 1)
    }
}
