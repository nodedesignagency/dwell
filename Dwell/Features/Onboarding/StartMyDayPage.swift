import DwellCore
import DwellUI
import SwiftUI

/// Onboarding, page 4: Start my day (screenshot, 13 Nov; brief A.1 #4). Three photos of example
/// places, each tagged with its time, over the blue turning gold; the brief's fixed line, then
/// the When-In-Use ask. Never Always here: Always is asked a day or two later, in its own moment.
///
/// The design's buttons say "Allow tracking" and "No, don't track"; on the user's call (13 Nov)
/// they say "Allow location" and "Not now" (the brief never says "track", and "Allow Tracking"
/// is Apple's ad-tracking prompt). Allow location shows iOS's own question; either answer, or
/// Not now, moves on, since declining still completes into a degraded state (brief §7.6).
///
/// Measured at 393 × 852: the dots 603.5 down; Allow location on white, Not now in white words
/// 9 below it, its 44-pt button 13.4 above the screen's edge (its words' baseline 29).
struct StartMyDayPage: View {
    let isCurrent: Bool
    let insets: PageInsets
    let onAllow: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        ColorPage(.gold, insets: insets, footInset: 13.4) { room in
            DayPhotos(isCurrent: isCurrent, room: room)
        } foot: {
            PageWords(
                page: .startMyDay,
                title: OnboardingCopy.startTitle,
                line: OnboardingCopy.startLine,
                ink: Palette.textPrimary,
                dots: .onColor
            ) {
                Button(OnboardingCopy.allowLocation, action: onAllow)
                    .buttonStyle(.secondary)
                Button(OnboardingCopy.notNow, action: onNotNow)
                    .buttonStyle(.text(.white))
            }
        }
        .environment(\.colorScheme, .light)
    }
}

/// The example day's three photos and their tags on the design's 393-wide canvas (the screen
/// from 100 to 500 down), scaled to the room above the words. Back to front: Mara's place (the
/// design's "GF's place"), home, Brambleline Café, each with its time on the example day.
///
/// Measured at 393 × 852 (on the canvas): the photos 140 × 200, Mara's place's middle at
/// (110, 186) turned −15°, home's at (199, 186) turned −6.5°, the café's at (281, 237) turned
/// 16°; the tags at (113, 320) turned −14°, (252.5, 62.5) turned 5° and (246.5, 362), each
/// pointing at its photo.
///
/// The first time the page shows, the photos are dealt in from below, one after another, and
/// settle at their angles (`Motion.landing`); then the tags pop in. Under Reduce Motion they
/// fade in where they rest.
private struct DayPhotos: View {
    let isCurrent: Bool
    let room: CGSize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDealt = false

    private static let canvas = CGSize(width: 393, height: 400)
    private static let middle: CGFloat = 300
    private static let designRoom: CGFloat = 603.5
    private static let photo = CGSize(width: 140, height: 200)

    private struct Layout {
        var photo: CGPoint
        var photoAngle: Double
        var tag: CGPoint
        var tagAngle: Double
        var tail: PlaceTag.Tail
    }

    private static func layout(_ photo: OnboardingExample.Spot.Photo) -> Layout {
        switch photo {
        case .friend: Layout(photo: CGPoint(x: 110, y: 186), photoAngle: -15, tag: CGPoint(x: 113, y: 320), tagAngle: -14, tail: .top(0.4))
        case .home: Layout(photo: CGPoint(x: 199, y: 186), photoAngle: -6.5, tag: CGPoint(x: 252.5, y: 62.5), tagAngle: 5, tail: .bottom(0.47))
        case .cafe: Layout(photo: CGPoint(x: 281, y: 237), photoAngle: 16, tag: CGPoint(x: 246.5, y: 362), tagAngle: 0, tail: .top(0.89))
        }
    }

    var body: some View {
        let scale = min(room.width / Self.canvas.width, room.height / Self.designRoom)
        canvas
            .frame(width: Self.canvas.width, height: Self.canvas.height)
            .scaleEffect(scale)
            .position(x: room.width / 2, y: Self.middle * scale)
            .frame(width: room.width, height: room.height)
            .onChange(of: isCurrent, initial: true) { _, isCurrent in
                // Each photo animates itself, a beat after the one before.
                if isCurrent { isDealt = true }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: OnboardingCopy.examplePhotos { DurationText.spoken($0) }))
    }

    private var canvas: some View {
        let spots = OnboardingExample.daySpots
        return ZStack(alignment: .topLeading) {
            ForEach(Array(spots.enumerated()), id: \.element.id) { index, spot in
                let layout = Self.layout(spot.photo)
                let away = !isDealt && !reduceMotion
                PhotoCard(Art.Onboarding.photo(spot.photo), category: spot.category)
                    .frame(width: Self.photo.width, height: Self.photo.height)
                    .rotationEffect(.degrees(away ? 0 : layout.photoAngle))
                    .scaleEffect(away ? 0.9 : 1)
                    .offset(y: away ? 120 : 0)
                    .opacity(isDealt ? 1 : 0)
                    .animation((reduceMotion ? Motion.reduced : Motion.landing).delay(Double(index) * 0.08), value: isDealt)
                    .position(layout.photo)
            }
            if isDealt {
                ForEach(Array(spots.enumerated()), id: \.element.id) { index, spot in
                    let layout = Self.layout(spot.photo)
                    PlaceTag(
                        name: spot.name, time: DurationText.short(spot.time),
                        icon: Art.glyph(spot.category), tail: layout.tail)
                        .rotationEffect(.degrees(layout.tagAngle))
                        .popIn(delay: 0.35 + Double(index) * 0.08)
                        .position(layout.tag)
                }
            }
        }
        .dynamicTypeSize(.large)
    }
}
