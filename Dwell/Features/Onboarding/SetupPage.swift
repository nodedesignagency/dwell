import DwellCore
import DwellUI
import SwiftUI

/// An account step's page (Save your world, the birthday, One last thing; screens, 14 Nov):
/// its colour edge to edge, the back button, the art with the title and line under it, and the
/// step's sheet at the foot. Light in every scheme, as all of onboarding.
///
/// Measured at 393 × 852: the back button 16 in and 17 below the status bar (Your places'
/// own); the art's top 140 below the back button where there's room, less on a shorter screen;
/// the sheet (`background`, corners 32) 10.5 from the sides and 11 from the bottom edge, as on
/// Your places. When it all doesn't fit (the largest text sizes, small phones) the page
/// scrolls, back button and all, and the art steps back.
struct SetupPage<ArtView: View, Sheet: View>: View {
    let backdrop: SetupBackdrop.Style
    let insets: PageInsets
    let title: String
    let line: String
    /// Where the line breaks: Save your world's at 290 ("…stay with / you, even on a new
    /// phone."); the others run the screen's width.
    var lineWidth: CGFloat? = nil
    let onBack: () -> Void
    @ViewBuilder let art: () -> ArtView
    @ViewBuilder let sheet: () -> Sheet

    var body: some View {
        ZStack {
            SetupBackdrop(backdrop)
            ViewThatFits(in: .vertical) {
                page
                ScrollView { page }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollIndicators(.hidden)
            }
        }
        .environment(\.colorScheme, .light)
    }

    /// Room shared out top-down: up to 140 above the art (the design's), the rest above the
    /// sheet. In a scroll view both shrink to their least.
    private var page: some View {
        VStack(spacing: 0) {
            BackButton(action: onBack)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, Space.l)
                .padding(.top, insets.top + 17)
            Spacer(minLength: Space.l)
                .frame(maxHeight: 140)
            SetupWords(title: title, line: line, lineWidth: lineWidth, art: art)
                .padding(.horizontal, Space.screen)
            Spacer(minLength: Space.xl)
            sheet()
                .frame(maxWidth: .infinity)
                .background(Palette.background, in: .rect(cornerRadius: Radius.xxl))
                .padding(.horizontal, 10.5)
                .padding(.bottom, insets.foot(11.1, floor: 10))
        }
    }
}

/// The art, title and line of an account step, centred (screens, 14 Nov): the art 80 square,
/// 14 to the title (`setupTitle`, 37, ink), 6 to the line (16 regular, lines 22 apart, ink at
/// 70%, as on onboarding's pages). The art is decoration (hidden from VoiceOver) and steps back
/// at accessibility text sizes, where the words need the room.
struct SetupWords<ArtView: View>: View {
    let title: String
    let line: String
    var lineWidth: CGFloat? = nil
    @ViewBuilder let art: () -> ArtView

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .callout) private var lineSpacing: CGFloat = 3.2

    var body: some View {
        VStack(spacing: 0) {
            if !dynamicTypeSize.isAccessibilitySize {
                art()
                    .frame(width: 80, height: 80)
                    .accessibilityHidden(true)
                    .padding(.bottom, 14)
            }
            Text(verbatim: title)
                .textRole(.setupTitle)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: line)
                .textRole(.body, weight: .regular)
                .lineSpacing(lineSpacing)
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.textPrimary.opacity(0.7))
                .frame(maxWidth: lineWidth)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
    }
}

/// An account step's art as an image, scaled into its 80-pt square.
struct SetupArt: View {
    let image: Image

    init(_ image: Image) {
        self.image = image
    }

    var body: some View {
        image
            .resizable()
            .scaledToFit()
    }
}
