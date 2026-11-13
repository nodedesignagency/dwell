import DwellCore
import DwellUI
import SwiftUI

/// The wrap's fifth page (Weekly wrap design, "Earliest exit this week"): the weekday the user
/// left the office earliest, on a wall clock, and how it sat against their usual.
///
/// Figma: the page's fill is radial, #FF67FF at the middle to #7A00F3 at the edge, centred
/// 53.8% down and reaching 45.9% of the screen each way; over it the designer's slanted checks
/// at 4%, drifting. Measured from the screenshot at 393 × 852: the heading (42 medium, white,
/// centred) 35 below the progress bar; the clock 268 across, centred, its middle 285 below the
/// progress bar; the weekday (20, white, in capitals) 35 under the clock; the time (60
/// medium, white) right under it; the line (16, white 80%, lines 2 apart, at most 260 wide)
/// 5 under that.
///
/// The clock's hands sweep to the time and its second hand runs. With no office weekday in the
/// week, the clock keeps only its second hand and the page says so. At accessibility sizes the
/// heading stops at the largest standard size and the words scroll if they outgrow the screen.
struct WrapExitPage: View {
    let state: Loadable<WrapEarliestExit?>
    /// Where the header ends, down from the top of the screen.
    let headerBottom: CGFloat
    var onNext: () -> Void = {}

    @Environment(\.calendar) private var calendar
    @ScaledMetric(relativeTo: .callout) private var lineWidth: CGFloat = 260

    var body: some View {
        ZStack {
            EllipticalGradient(
                colors: [Palette.wrapExitCentre, Palette.wrapExitEdge],
                center: UnitPoint(x: 0.5, y: 0.538),
                startRadiusFraction: 0,
                endRadiusFraction: 0.459)
            SlantedChecks()

            ViewThatFits(in: .vertical) {
                content
                ScrollView {
                    content
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .padding(.top, headerBottom)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea()
    }

    private var exit: WrapEarliestExit? {
        state.value ?? nil
    }

    private var isLoaded: Bool {
        state.value != nil
    }

    private var content: some View {
        VStack(spacing: 0) {
            VoiceText(exit == nil && isLoaded ? WrapCopy.noExitTitle : WrapCopy.earliestExitTitle)
                .textRole(.storyHeading)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, Space.screen)
                .padding(.top, 35)

            clock
                .frame(width: 268, height: 268)
                // 21 in the design; SwiftUI sets the heading's lines further apart than Figma.
                .padding(.top, 16)

            if let exit {
                VStack(spacing: -3) {
                    Text(verbatim: ClockText.weekdayName(exit.day, calendar: calendar).uppercased())
                        .textRole(.title, weight: .regular)
                        .accessibilityLabel(ClockText.weekdayName(exit.day, calendar: calendar))
                    Text(verbatim: ClockText.time(exit.time, calendar: calendar))
                        .textRole(.storyTime)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
                .foregroundStyle(.white)
                .accessibilityElement(children: .combine)
                .padding(.top, 35)
            }

            Group {
                if isLoaded {
                    VoiceText(WrapCopy.earliestExitLine(exit))
                } else {
                    // Loading: the line's shape, waiting.
                    Text(verbatim: "38 minutes earlier than your usual. The evening was yours.")
                        .redacted(reason: .placeholder)
                        .accessibilityHidden(true)
                }
            }
            .textRole(.body, weight: .regular)
            .foregroundStyle(.white.opacity(0.8))
            .lineSpacing(2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: lineWidth)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAction(named: WrapCopy.nextPage, onNext)
            .padding(.top, exit == nil ? 35 : 5)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Space.xl)
    }

    @ViewBuilder
    private var clock: some View {
        if let exit {
            let parts = calendar.dateComponents([.hour, .minute], from: exit.time)
            WallClock(hour: parts.hour, minute: parts.minute, delay: 0.3)
        } else {
            WallClock(hour: nil, minute: nil)
        }
    }
}
