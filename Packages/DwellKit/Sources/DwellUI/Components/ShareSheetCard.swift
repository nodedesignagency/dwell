import SwiftUI

/// The card a share sheet slides up as (Insights design, "Share this insight", 14 Nov): the
/// title centred level with the close button, what's shared as it will look, the ways to
/// share, a dashed line and what sharing never shows. On the page's grey (`background`),
/// corners 32. Present it with `.promptSheet(isPresented:)`, like the other sheets.
///
/// Measured at 393 × 852: the title (28 medium) centred on the close button (44, white with an
/// ink-5% edge, 16 in from the top and side); the preview 9 below that row, 20 from the sides; the buttons
/// 13 below it, in columns 10 in from the sides; 15 to a dashed line 20 in; 15 to the line
/// (14, grey, centred); 18 below. The frame draws the sheet 9 above the screen's edge; it
/// floats where every sheet does, 21 up (QUESTIONS.md).
public struct ShareSheetCard<Preview: View, Targets: View>: View {
    private let title: String
    private let closeLabel: String
    private let privacy: String
    private let onClose: () -> Void
    private let preview: Preview
    private let targets: Targets

    /// - Parameters:
    ///   - privacy: what sharing never shows: "Only categories are shared. Never places or home."
    ///   - preview: what's shared, as it will look.
    ///   - targets: the ways to share.
    public init(
        title: String,
        closeLabel: String,
        privacy: String,
        onClose: @escaping () -> Void,
        @ViewBuilder preview: () -> Preview,
        @ViewBuilder targets: () -> Targets
    ) {
        self.title = title
        self.closeLabel = closeLabel
        self.privacy = privacy
        self.onClose = onClose
        self.preview = preview()
        self.targets = targets()
    }

    public var body: some View {
        VStack(spacing: 0) {
            Text(verbatim: title)
                .textRole(.cardTitle)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 44)
                // Clear of the close button on both sides, so it stays centred.
                .padding(.horizontal, 64)
                .padding(.top, Space.l)
                .accessibilityAddTraits(.isHeader)

            preview
                .padding(.horizontal, Space.screen)
                .padding(.top, 9)

            targets
                .padding(.horizontal, 10)
                .padding(.top, 13)

            DashedDivider()
                .padding(.horizontal, Space.screen)
                .padding(.top, 15)

            Text(verbatim: privacy)
                .textRole(.caption)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Space.screen)
                .padding(.top, 15)
        }
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity)
        .background(Palette.background)
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                CloseCross()
            }
            // Solid, not glass: glass vanishes on the sheet's grey (the user, 14 Nov).
            .buttonStyle(.raisedCircle)
            .accessibilityLabel(closeLabel)
            .padding(Space.l)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
    }
}
