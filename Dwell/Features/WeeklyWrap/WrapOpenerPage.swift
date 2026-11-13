import DwellCore
import DwellUI
import SwiftUI

/// The wrap's first page (Weekly wrap design, "This week."): the week in one line, with its
/// 3D art popping out around it.
///
/// Measured from the screenshot at 393 × 852: the title (60 medium, white) and the line under
/// it (18 regular, white 80%, at most 280 wide, so it breaks after "every hour in"), 5 apart,
/// their middle 6 above the screen's. "Tap to continue" (14, white, in capitals) 30 above the
/// screen's bottom edge. The art sits where the design draws it, as a share of the screen's
/// width across and in points from the words' middle down: the alarm clock top left, the
/// briefcase on the right, the flame bottom left, the trophy bottom right.
///
/// At accessibility text sizes the art steps aside (it would sit on the bigger words) and the
/// title stops growing at the largest standard size: at 60 pt it's already display type, and
/// beyond that a word like "Receipts" would break mid-word. The line under it scales all the
/// way; if the words outgrow the screen they scroll.
struct WrapOpenerPage: View {
    let state: Loadable<WrapOpener>
    /// Room kept clear above the words for the header, and the same below, so they stay
    /// centred on the screen.
    let reserve: CGFloat
    var onNext: () -> Void = {}
    var onRetry: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var lineWidth: CGFloat = 280

    /// The words' middle sits this far above the screen's, as drawn.
    private static let lift: CGFloat = -6

    var body: some View {
        ZStack {
            if let opener = state.value, !typeSize.isAccessibilitySize {
                StickerBurst(items: Self.stickers(opener.stickers), originOffset: Self.lift)
            }

            ViewThatFits(in: .vertical) {
                words
                ScrollView {
                    words.padding(.vertical, Space.l)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .offset(y: Self.lift)
            .padding(.vertical, reserve)

            Text(verbatim: WrapCopy.tapToContinue.uppercased())
                .textRole(.caption)
                .foregroundStyle(.white)
                .accessibilityLabel(WrapCopy.tapToContinue)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { onNext() }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }

    private var words: some View {
        VStack(spacing: 5) {
            VoiceText(WrapCopy.openerTitle)
                .textRole(.storyTitle)
                .foregroundStyle(.white)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .accessibilityAddTraits(.isHeader)
            line
                .frame(maxWidth: lineWidth)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, Space.screen)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var line: some View {
        switch state {
        case .loaded(let opener, _):
            VoiceText(WrapCopy.openerLine(opener))
                .textRole(.storyLine)
                .foregroundStyle(.white.opacity(0.8))
                .accessibilityAction(named: WrapCopy.nextPage, onNext)
        case .failed:
            VStack(spacing: Space.m) {
                Text(verbatim: WrapCopy.failed)
                    .textRole(.storyLine)
                    .foregroundStyle(.white.opacity(0.8))
                Button(action: onRetry) {
                    // The invite's "Let's go" capsule.
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
        default:
            // Loading: the line's shape, waiting for its numbers. The week is on the phone,
            // so this is rarely seen.
            Text(verbatim: WrapCopy.openerLine(WrapOpener(days: 7, places: 9)).plain)
                .textRole(.storyLine)
                .foregroundStyle(.white.opacity(0.8))
                .redacted(reason: .placeholder)
                .accessibilityHidden(true)
        }
    }

    /// The design's four spots, filled in the order the week's art comes in.
    private static let spots: [(x: CGFloat, y: CGFloat, size: CGFloat, angle: Double)] = [
        (x: 0.147, y: -164, size: 58, angle: -20),  // top left: the alarm clock
        (x: 0.906, y: -101, size: 56, angle: 15),   // right: the briefcase
        (x: 0.131, y: 98, size: 54, angle: -8),     // bottom left: the flame
        (x: 0.776, y: 136, size: 56, angle: 15),    // bottom right: the trophy
    ]

    private static func stickers(_ art: [WrapSticker]) -> [StickerBurst.Item] {
        zip(art, spots).map { sticker, spot in
            StickerBurst.Item(
                id: sticker.rawValue,
                image: Art.sticker(sticker),
                x: spot.x,
                y: spot.y,
                size: spot.size,
                angle: .degrees(spot.angle))
        }
    }
}
