import DwellCore
import SwiftUI

/// A card that says what a section is waiting for, and for how long, instead of leaving a
/// hole (brief §3.1: "If the data cannot support an insight yet, the app says what it is
/// waiting for and how long").
///
/// Today design, "after a few minutes of getting started": "Waiting for your insights ·
/// Please wait for the end of the week." under a 3D chart. Measured from the screenshot:
/// art 64 × 50, 28 below the card's top; 16 to the title (22 medium); 4 to the line (16,
/// grey); 18 to the bottom; centred. Both lines are an empty state, so both follow the dial.
public struct WaitingCard<Art: View>: View {
    @ScaledMetric(relativeTo: .title3) private var artWidth: CGFloat = 64
    @ScaledMetric(relativeTo: .title3) private var artHeight: CGFloat = 50
    private let title: VoicedLine
    private let detail: VoicedLine
    private let art: Art

    public init(title: VoicedLine, detail: VoicedLine, @ViewBuilder art: () -> Art) {
        self.title = title
        self.detail = detail
        self.art = art()
    }

    public var body: some View {
        VStack(spacing: 0) {
            art
                .frame(width: artWidth, height: artHeight)
                .accessibilityHidden(true)
            VoiceText(title)
                .textRole(.voice)
                .foregroundStyle(Palette.textPrimary)
                .padding(.top, Space.l)
            VoiceText(detail)
                .textRole(.body)
                .foregroundStyle(Palette.textSecondary)
                .padding(.top, Space.xs)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, Space.l)
        .padding(.top, 28)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity)
        .card()
        .accessibilityElement(children: .combine)
    }
}
