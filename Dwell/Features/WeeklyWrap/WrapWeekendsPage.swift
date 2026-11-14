import DwellCore
import DwellUI
import SwiftUI

/// The wrap's third page (Weekly wrap design, "Weekly Wrap 3", 13 Nov): the weekend's verdict,
/// the week hour by hour with Saturday and Sunday picked out, what the weekend went to, and
/// the biggest change since last weekend.
///
/// The page's colour: a radial fill from peach in the middle to orange at the edges, and the
/// designer's slanted tiles over it at 10%, flowing down the page (`SlantTiles`). Both read from
/// the screenshot and the reference image; the fill's colours wait on Figma's [VALUES NEEDED].
///
/// Measured from the screenshot at 393 × 852:
/// - The title (48 medium, white, lines 48 apart, Figma's 100%), centred and breaking after
///   "Weekends" (at most 300 wide), its top 29 below the progress bar; 8 below, the line (18,
///   white 80%).
/// - 28 below, the card (white, corners 20, 20 from the sides, 16 in): Time's "Every hour of
///   the week" grid without its legend, Monday to Friday's labels faded to a third.
/// - At the foot, 20 from the sides: "What you did instead" (22 medium, white), 14 to a dashed
///   line (white 50%), 20 to the category pills (8 apart each way), 8 to the change since
///   last weekend (16, white 80%), its box 38 above the screen's bottom edge.
///
/// The grid's rows sweep in from 4 AM, then the pills rise in one after another, 8 pt and a
/// fade, no bounce (`.riseIn`); under Reduce Motion the rows fade in and the pills with them,
/// and the tiles hold still. The page is a
/// story page: a tap anywhere moves on, so the grid doesn't take taps. VoiceOver reads the
/// rows and their audio graph, and each pill. At accessibility sizes the title stops at the
/// largest standard size, as on the opener; if the rest outgrows the screen it scrolls.
struct WrapWeekendsPage: View {
    let state: Loadable<WrapWeekends>
    /// Where the header ends, down from the top of the screen.
    let headerBottom: CGFloat
    var onNext: () -> Void = {}
    var onRetry: () -> Void = {}

    @Environment(\.dial) private var dial
    @ScaledMetric(relativeTo: .largeTitle) private var titleWidth: CGFloat = 300

    /// From the progress bar to the title's box, and from the last line's box to the screen's
    /// bottom edge.
    private static let top: CGFloat = 29
    private static let bottom: CGFloat = 38

    var body: some View {
        ZStack {
            WrapBackdrop(
                centre: Palette.wrapWeekendCentre,
                edge: Palette.wrapWeekendEdge,
                middle: UnitPoint(x: 0.5, y: 0.52),
                reach: 0.47,
                glows: false)
            SlantTiles()
                .opacity(0.1)
                .ignoresSafeArea()

            ViewThatFits(in: .vertical) {
                content(spread: true)
                ScrollView {
                    content(spread: false)
                        .padding(.bottom, Space.l)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
            }
            .padding(.top, headerBottom + Self.top)
            .padding(.bottom, Self.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }

    // MARK: Layout

    /// The title, line and card from the top, the weekend's categories from the foot; with
    /// `spread`, the room left over goes between them.
    @ViewBuilder
    private func content(spread: Bool) -> some View {
        switch state {
        case .loaded(let weekends, _):
            VStack(spacing: 0) {
                heading(weekends)
                WeekCard(weekends: weekends)
                    .padding(.top, 28)
                if spread {
                    Spacer(minLength: Space.xl)
                } else {
                    Color.clear.frame(height: Space.xl)
                }
                if !weekends.breakdown.isEmpty {
                    breakdown(weekends)
                }
            }
            .padding(.horizontal, Space.screen)
        case .failed:
            failed
        default:
            loading(spread: spread)
        }
    }

    private func heading(_ weekends: WrapWeekends) -> some View {
        VStack(spacing: 8) {
            LeadedText(WrapCopy.weekendsTitle(weekends.verdict).text(for: dial), role: .storyHeadline, lineHeight: 48)
                .foregroundStyle(.white)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .frame(maxWidth: titleWidth)
                .accessibilityAddTraits(.isHeader)
                .accessibilityAction(named: WrapCopy.nextPage, onNext)
            VoiceText(WrapCopy.weekendsLine(weekends))
                .textRole(.storyLine)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAction(named: WrapCopy.nextPage, onNext)
        }
        .frame(maxWidth: .infinity)
    }

    private func breakdown(_ weekends: WrapWeekends) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: WrapCopy.weekendsBreakdown(weekends.verdict))
                .textRole(.voice)
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)
            DashedDivider(color: .white.opacity(0.5), dash: [3.5, 2])
                .padding(.top, 14)
            FlowLayout(alignment: .leading, spacing: Space.s, lineSpacing: Space.s) {
                ForEach(Array(weekends.breakdown.enumerated()), id: \.element.id) { index, slice in
                    CategoryPill(slice.bucket, duration: slice.total)
                        .riseIn(delay: 0.45 + Double(index) * 0.04)
                }
            }
            .padding(.top, 20)
            if let change = weekends.change {
                VoiceText(WrapCopy.weekendsChange(change))
                    .textRole(.body, weight: .regular)
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Space.s)
                    .accessibilityAction(named: WrapCopy.nextPage, onNext)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: States

    /// The page's shape, waiting for its numbers. The week is on the phone, so this is rarely
    /// seen.
    private func loading(spread: Bool) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                LeadedText(WrapCopy.weekendsTitle(.allYours).plain, role: .storyHeadline, lineHeight: 48)
                    .frame(maxWidth: titleWidth)
                Text(verbatim: WrapCopy.weekendsLine(.allYours, workByDay: []).plain)
                    .textRole(.storyLine)
            }
            .foregroundStyle(.white)
            .redacted(reason: .placeholder)
            .frame(maxWidth: .infinity)
            WeekCard.skeleton
                .padding(.top, 28)
            if spread { Spacer(minLength: 0) }
        }
        .padding(.horizontal, Space.screen)
        .accessibilityHidden(true)
    }

    /// The opener's words and "Retry", should someone tap on past a week that didn't load.
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

/// The white card holding the week, hour by hour (Time's grid, without its legend, Saturday and
/// Sunday picked out).
private struct WeekCard: View {
    let weekends: WrapWeekends

    var body: some View {
        HourGridView(
            weekends.grid,
            // Only the callout says it, and the card takes no taps.
            this: "that week",
            showsLegend: false,
            isInteractive: false,
            pickedOut: Set(weekends.weekend))
            .padding(Space.l)
            .card()
    }

    /// Seven grey rows where the days will be.
    static var skeleton: some View {
        VStack(spacing: Space.xs) {
            ForEach(0..<7, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Palette.gap)
                    .frame(height: 20)
            }
        }
        .padding(.top, 25)
        .padding(Space.l)
        .card()
    }
}
