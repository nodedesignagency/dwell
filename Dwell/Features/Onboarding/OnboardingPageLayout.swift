import DwellCore
import DwellUI
import SwiftUI

/// The screen's edges as the pager hands them to each page. Pages run edge to edge, under the
/// status bar and the home indicator, so each lays itself out from these.
struct PageInsets: Equatable {
    var top: CGFloat
    var bottom: CGFloat

    /// The design's distance from a page's last control to the screen's bottom edge, measured
    /// on a phone with a home indicator (34 high), moved with the inset this phone has and never
    /// closer than `floor` (a phone with a home button has none).
    func foot(_ design: CGFloat, floor: CGFloat = Space.l) -> CGFloat {
        max(floor, bottom + design - 34)
    }
}

/// A coloured onboarding page (My world, See where it all goes, Start my day): its colour edge
/// to edge, its art in the room above its words, and at the foot the dots, the title, the line
/// and the buttons. When the words outgrow the screen (the largest text sizes) they scroll, and
/// the art steps back once there's no room left for it.
struct ColorPage<Art: View, Foot: View>: View {
    let backdrop: OnboardingBackdrop.Style
    let insets: PageInsets
    /// The design's distance from the last control to the screen's bottom edge.
    let footInset: CGFloat
    /// Draws the art in the room above the foot, from the screen's top edge, given its size.
    let art: (CGSize) -> Art
    let foot: () -> Foot

    @State private var footHeight: CGFloat = 0

    init(
        _ backdrop: OnboardingBackdrop.Style,
        insets: PageInsets,
        footInset: CGFloat,
        @ViewBuilder art: @escaping (CGSize) -> Art,
        @ViewBuilder foot: @escaping () -> Foot
    ) {
        self.backdrop = backdrop
        self.insets = insets
        self.footInset = footInset
        self.art = art
        self.foot = foot
    }

    var body: some View {
        GeometryReader { proxy in
            let bottom = insets.foot(footInset)
            let room = CGSize(width: proxy.size.width, height: max(0, proxy.size.height - bottom - footHeight))
            ZStack(alignment: .top) {
                OnboardingBackdrop(backdrop)
                art(room)
                    .frame(width: room.width, height: room.height)
                    .opacity(room.height > insets.top + 140 ? 1 : 0)
                    .allowsHitTesting(false)
                ScrollView {
                    foot()
                        .padding(.horizontal, Space.screen)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                            footHeight = height
                        }
                        .padding(.top, insets.top + Space.l)
                        .padding(.bottom, bottom)
                        .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .bottom)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
            }
        }
    }
}

/// The words at an onboarding page's foot, as measured on all four screenshots: the dots, 14 to
/// the title (40, `display`, lines 39 apart), 6 to the line (16 regular, lines 22 apart, at
/// most 290 wide), then the page's buttons 20 below, 9 apart.
struct PageWords<Buttons: View>: View {
    let page: OnboardingPage
    let title: String
    /// Where the title breaks: My world's "See where your / time goes" (the rest are one line).
    var titleWidth: CGFloat? = nil
    let line: String
    /// The title's ink; the line takes it at 70% (white on My world, ink on the others).
    let ink: Color
    let dots: PageDots.Style
    @ViewBuilder let buttons: () -> Buttons

    @ScaledMetric(relativeTo: .callout) private var lineSpacing: CGFloat = 3.2

    var body: some View {
        VStack(spacing: 0) {
            PageDots(
                count: OnboardingPage.allCases.count, current: page.rawValue, style: dots,
                label: OnboardingCopy.pageLabel(page))
            LeadedText(title, role: .display, lineHeight: 39)
                .frame(maxWidth: titleWidth)
                .foregroundStyle(ink)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 14)
            Text(verbatim: line)
                .textRole(.body, weight: .regular)
                .lineSpacing(lineSpacing)
                .multilineTextAlignment(.center)
                .foregroundStyle(ink.opacity(0.7))
                .frame(maxWidth: 290)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            VStack(spacing: 9) {
                buttons()
            }
            .padding(.top, Space.screen)
        }
        .frame(maxWidth: .infinity)
    }
}
