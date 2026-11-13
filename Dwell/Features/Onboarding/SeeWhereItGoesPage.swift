import DwellCore
import DwellUI
import SwiftUI

/// Onboarding, page 3: See where it all goes (screenshot, 13 Nov). Not one of the brief's four
/// steps: it shows what Time does before Dwell asks for anything. Two of Time's cards, tilted and
/// stacked, on the blue paling to pink: "Every hour of the week" in front and a breakdown by
/// category behind, with the 3D alarm clock, briefcase, trophy and flame around them.
///
/// The cards are Time's own (`HourGridView`, `CategoryRow`), drawn on the example week (the
/// sample's last full week) at 80% of their size and still: a picture, not a chart. They come
/// in the first time the page shows: the grid's rows sweep in and the art pops out.
struct SeeWhereItGoesPage: View {
    let isCurrent: Bool
    let insets: PageInsets
    let onContinue: () -> Void

    var body: some View {
        ColorPage(.blush, insets: insets, footInset: 31.5) { room in
            WeekArt(isCurrent: isCurrent, room: room)
        } foot: {
            PageWords(
                page: .seeWhereItGoes,
                title: OnboardingCopy.seeTitle,
                line: OnboardingCopy.seeLine,
                ink: Palette.textPrimary,
                dots: .onColor
            ) {
                Button(OnboardingCopy.continue, action: onContinue)
                    .buttonStyle(.secondary)
            }
        }
        .environment(\.colorScheme, .light)
    }
}

/// The example week's two cards and the art around them, laid out on the design's 393-wide
/// canvas (the screen from 90 to 530 down) and scaled to the room above the words.
///
/// Measured at 393 × 852: the breakdown card's middle at (255.5, 171) on the canvas, turned 10°;
/// the grid card's at (133.5, 256), turned −5°; both 327 wide before they're drawn at 80%. The
/// alarm clock at (87, 106), 56, −20°; the briefcase (356, 40), 57, 15°; the trophy (285, 356),
/// 57, 15°; the flame (40, 398), 55, −8° (the weekly wrap's art, stand-ins until it arrives).
private struct WeekArt: View {
    let isCurrent: Bool
    let room: CGSize

    @State private var hasShown = false

    private static let canvas = CGSize(width: 393, height: 440)
    /// The canvas's middle on the design's screen, and the room above its words.
    private static let middle: CGFloat = 310
    private static let designRoom: CGFloat = 638.5
    private static let cardScale: CGFloat = 0.8
    private static let cardWidth: CGFloat = 327

    /// The example week as Time shows it, worked out once.
    private static let overview = TimeOverview.sample(OnboardingExample.week(calendar: SampleData.calendar))

    var body: some View {
        let scale = min(room.width / Self.canvas.width, room.height / Self.designRoom)
        ZStack {
            if hasShown {
                canvas
                    .frame(width: Self.canvas.width, height: Self.canvas.height)
                    .scaleEffect(scale)
                    .position(x: room.width / 2, y: Self.middle * scale)
            }
        }
        .frame(width: room.width, height: room.height)
        .onChange(of: isCurrent, initial: true) { _, isCurrent in
            if isCurrent { hasShown = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: OnboardingCopy.exampleWeek))
    }

    private var canvas: some View {
        ZStack(alignment: .topLeading) {
            BreakdownCard(report: Self.overview.report)
                .frame(width: Self.cardWidth)
                .scaleEffect(Self.cardScale)
                .rotationEffect(.degrees(10))
                .position(x: 255.5, y: 171)
            EveryHourCard(grid: Self.overview.grid)
                .frame(width: Self.cardWidth)
                .scaleEffect(Self.cardScale)
                .rotationEffect(.degrees(-5))
                .position(x: 133.5, y: 256)
            sticker(.alarmClock, x: 87, y: 106, size: 56, angle: -20, delay: 0.25)
            sticker(.briefcase, x: 356, y: 40, size: 57, angle: 15, delay: 0.33)
            sticker(.trophy, x: 285, y: 356, size: 57, angle: 15, delay: 0.41)
            sticker(.flame, x: 40, y: 398, size: 55, angle: -8, delay: 0.49)
        }
        .dynamicTypeSize(.large)
    }

    private func sticker(_ sticker: WrapSticker, x: CGFloat, y: CGFloat, size: CGFloat, angle: Double, delay: Double) -> some View {
        Art.sticker(sticker)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .rotationEffect(.degrees(angle))
            .popIn(delay: delay)
            .position(x: x, y: y)
    }
}

/// Time's "Every hour of the week" card (Time design), as the picture shows it: the caption,
/// the title, a dashed line and the grid with its legend, nothing to tap.
private struct EveryHourCard: View {
    let grid: HourGrid

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: TimeCopy.gridCaption(.week, calendar: SampleData.calendar))
                .textRole(.body, weight: .regular)
                .foregroundStyle(Palette.textSecondary)
            Text(verbatim: TimeCopy.gridTitle(.week))
                .textRole(.cardTitle)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Space.xs)
            DashedDivider()
                .padding(.top, Space.xs)
            HourGridView(grid, this: OnboardingCopy.exampleThis, isInteractive: false)
                .padding(.top, Space.m)
        }
        .padding(.horizontal, Space.l)
        .padding(.top, Space.m)
        .padding(.bottom, Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

/// The breakdown behind it: "Breakdown" with the 3D calendar, the week's four largest
/// categories as Time's rows (each with its change from usual), and the line about the gaps.
private struct BreakdownCard: View {
    let report: TimeReport

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(OnboardingCopy.breakdown, icon: Art.thisWeek)
            DashedDivider()
                .padding(.top, 10)
            ForEach(Array(report.lines.prefix(4).enumerated()), id: \.element.id) { index, line in
                if index > 0 {
                    DashedDivider()
                        .padding(.leading, 32)
                }
                CategoryRow(line, isExpanded: .constant(false), onOpen: {})
                    .padding(.vertical, Space.m)
            }
            if report.unmapped >= 60 {
                DashedDivider()
                VoiceText(TimeCopy.asleep(report.unmapped, this: OnboardingCopy.exampleThis))
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
            }
        }
        .padding(Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
