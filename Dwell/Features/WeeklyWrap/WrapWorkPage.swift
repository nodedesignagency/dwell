import DwellCore
import DwellUI
import SwiftUI

/// The wrap's second page (Weekly wrap design, "Work vs yours"): the week's hours at work over
/// the hours that were yours, split by a line of water.
///
/// The designer's idea (13 Nov): work's purple fills the top and yours' water the bottom, and
/// the water settles where the two hours put it: work's share of the screen's height, so a
/// week that was mostly work is mostly purple. The line never comes nearer the two numbers
/// than the title needs, so both always read on their own colour. "Work vs yours" (the
/// designer's art, 165 wide) pops in and floats on the surface. Over everything, the wavy stripes at 10% (the design's reference
/// image, redrawn and moving).
///
/// Measured from the screenshot at 393 × 852: "At work" (18, white 80%) 36 below the progress
/// bar, 20 from the left, the number (64 medium, white) under it; "Yours" and its number at
/// the bottom, the number's box 23 above the screen's bottom edge. The numbers are Time's, so
/// the two always agree. Grind calls yours "Off" (brief §7.3). At accessibility sizes the
/// labels grow, and the numbers stop at the largest standard size and shrink to fit one line.
struct WrapWorkPage: View {
    let state: Loadable<WrapWorkAndYours>
    /// Where the header ends, down from the top of the screen.
    let headerBottom: CGFloat
    var onNext: () -> Void = {}

    @State private var workBottom: CGFloat = 270
    @State private var yoursTop: CGFloat = 720
    @State private var titleHeight: CGFloat = 95

    var body: some View {
        GeometryReader { proxy in
            WaterSplit(top: Palette.wrapWork, water: Palette.wrapYours, level: level(height: proxy.size.height)) {
                WavyStripes()
                    .opacity(0.1)
            } floating: {
                // The designer's art, as they asked (13 Nov): it pops in once the water is up.
                Art.Illustration.workVsYours
                    .resizable()
                    .scaledToFit()
                    .frame(width: 165)
                    .popIn(delay: 0.9)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { titleHeight = $0 }
                    .accessibilityLabel(WrapCopy.workVsYours)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityAction(named: WrapCopy.nextPage, onNext)
            }
            .overlay(alignment: .topLeading) {
                block(label: Text(verbatim: WrapCopy.atWork), value: state.value?.work)
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).maxY } action: { workBottom = $0 }
                    .padding(.top, headerBottom + 36)
            }
            .overlay(alignment: .bottomLeading) {
                block(label: VoiceText(WrapCopy.yours), value: state.value?.yours)
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { yoursTop = $0 }
                    .padding(.bottom, 23)
            }
        }
        .ignoresSafeArea()
    }

    /// Where the water settles: work's share of the height, kept clear of both numbers by
    /// half the title and 12 more, so the title never covers them.
    private func level(height: CGFloat) -> CGFloat {
        let wanted = height * (state.value?.workShare ?? 0.5)
        let room = titleHeight / 2 + 12
        let highest = workBottom + room
        let lowest = yoursTop - room
        guard highest <= lowest else { return (workBottom + yoursTop) / 2 }
        return min(max(wanted, highest), lowest)
    }

    private func block(label: some View, value: TimeInterval?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            label
                .textRole(.storyLine)
                .foregroundStyle(.white.opacity(0.8))
            Group {
                if let value {
                    Text(verbatim: DurationText.short(value))
                } else {
                    // Loading: the number's shape, waiting.
                    Text(verbatim: "00h 00m")
                        .redacted(reason: .placeholder)
                }
            }
            .textRole(.storyNumber)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .padding(.horizontal, Space.screen)
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: WrapCopy.nextPage, onNext)
    }
}
