import DwellCore
import SwiftUI

/// A card that says what a section is waiting for, and for how long, instead of leaving a
/// hole (brief §3.1: "If the data cannot support an insight yet, the app says what it is
/// waiting for and how long").
///
/// Today design, "after a few minutes of getting started": "Waiting for your insights ·
/// Please wait for the end of the week." under the 3D chart. Measured from the screenshot
/// with the chart's own margins: art 64 square, 24 below the card's top; 6 to the title (22
/// medium); 4 to the line (16, grey); 18 to the bottom; centred, 161 tall in all. Both lines
/// are an empty state, so both follow the dial.
public struct WaitingCard<Artwork: View>: View {
    @ScaledMetric(relativeTo: .title3) private var artSize: CGFloat = 64
    private let title: VoicedLine
    private let detail: VoicedLine
    private let art: Artwork

    public init(title: VoicedLine, detail: VoicedLine, @ViewBuilder art: () -> Artwork) {
        self.title = title
        self.detail = detail
        self.art = art()
    }

    public var body: some View {
        VStack(spacing: 0) {
            art
                .frame(width: artSize, height: artSize)
                .accessibilityHidden(true)
            VoiceText(title)
                .textRole(.voice)
                .foregroundStyle(Palette.textPrimary)
                .padding(.top, 6)
            VoiceText(detail)
                .textRole(.body)
                .foregroundStyle(Palette.textSecondary)
                .padding(.top, Space.xs)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, Space.l)
        .padding(.top, Space.xl)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity)
        .card()
        .accessibilityElement(children: .combine)
    }
}
