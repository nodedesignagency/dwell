import DwellUI
import SwiftUI

/// The tab bar from the Today design (Figma "tabPills"): a frosted bar across the bottom with
/// large rounded top corners, white 20% over a frosted material and an ink-10% border, and a
/// white pill behind the selected tab that slides between tabs. Frosted, not Liquid Glass:
/// Liquid Glass refracts what's behind it (the week chart's blue bars showed through); the
/// design's bar blurs it to a soft white.
///
/// Figma: the tabs sit 12 below the bar's top and 12 in from its sides, and stand 24 above the
/// screen's bottom edge, so they reach 10 pt into the home indicator's strip on a Face ID phone.
/// The bar's own frame stops at the safe area (what screens clear with `.clearsTabBar()`); the
/// tabs hang below it by the difference and the glass runs on to the bottom edge.
///
/// Replaces the system bar's look; `RootView` keeps the system `TabView` for the screens.
/// Icons are outlined SF Symbols until the design's tab icons are exported. [ICON NEEDED]
struct DwellTabBar: View {
    @Binding var selection: RootView.Tab

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var pill
    @ScaledMetric(relativeTo: .footnote) private var iconSize: CGFloat = 22
    /// Figma: labels 12 on a 16 line.
    @ScaledMetric(relativeTo: .footnote) private var labelLine: CGFloat = 16
    /// The home indicator's strip under the bar (0 on phones with a Home button).
    @State private var homeIndicator: CGFloat = 0

    private static let corner: CGFloat = 44
    /// Figma: 12 from the bar's top and sides to the tabs, 24 from the tabs to the screen's bottom.
    private static let inset: CGFloat = 12
    private static let bottom: CGFloat = 24
    /// Figma tab: 101 wide, 54 tall (hug), padding 8 across and 6 down, 4 between icon and label.
    private static let tabWidth: CGFloat = 101
    private static let tabHeight: CGFloat = 54

    var body: some View {
        TabStrip {
            ForEach(RootView.Tab.allCases, id: \.self) { tab in
                button(tab)
            }
        }
        .padding(.horizontal, Self.inset)
        .padding(.top, Self.inset)
        .padding(.bottom, Self.bottom - homeIndicator)
        .background {
            let shape = UnevenRoundedRectangle(topLeadingRadius: Self.corner, topTrailingRadius: Self.corner)
            ZStack {
                shape.fill(Palette.tabBar)
                shape.strokeBorder(Palette.tabBarStroke, lineWidth: 1)
            }
            .background(.regularMaterial, in: shape)
            .ignoresSafeArea(edges: .bottom)
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: { homeIndicator = $0 }
        .motion(value: selection)
    }

    private func button(_ tab: RootView.Tab) -> some View {
        let isSelected = tab == selection
        return Button {
            selection = tab
        } label: {
            VStack(spacing: Space.xs) {
                // Ink on every tab, as in the design; only the label greys out.
                Image(systemName: tab.symbol)
                    .resizable()
                    .scaledToFit()
                    .symbolVariant(.none)
                    .fontWeight(.medium)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundStyle(Palette.textPrimary)
                Text(verbatim: tab.title)
                    .textRole(.tab, weight: isSelected ? .medium : .regular, tracking: 0)
                    .foregroundStyle(isSelected ? Palette.textPrimary : Palette.tabInactive)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(minHeight: labelLine)
            }
            .padding(.horizontal, Space.s)
            .padding(.vertical, 6)
            .frame(width: Self.tabWidth)
            .frame(minHeight: Self.tabHeight)
            // Figma: clip content. The pill and its shadows sit outside the clip.
            .clipped()
            .background {
                if isSelected {
                    selectedPill
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// Figma: white 80%, a 1 pt #F6F6F6 border inside, four soft drop shadows (y 26.05,
    /// 14.37, 5.86, 1.2; blur 10.78, 8.36, 5.86, 3.59; black 1, 2, 4, 4%). SwiftUI's shadow
    /// radius is half of Figma's blur. Under Reduce Motion it appears in place.
    @ViewBuilder
    private var selectedPill: some View {
        let shape = Capsule()
            .fill(Palette.tabPill)
            .overlay { Capsule().strokeBorder(Palette.tabPillStroke, lineWidth: 1) }
            .shadow(color: .black.opacity(0.01), radius: 5.39, y: 26.05)
            .shadow(color: .black.opacity(0.02), radius: 4.18, y: 14.37)
            .shadow(color: .black.opacity(0.04), radius: 2.93, y: 5.86)
            .shadow(color: .black.opacity(0.04), radius: 1.8, y: 1.2)
        if reduceMotion {
            shape
        } else {
            shape.matchedGeometryEffect(id: "pill", in: pill)
        }
    }
}

/// Figma's "space between" row: the first tab flush with the leading edge, the last flush with
/// the trailing edge, the rest evenly spaced between. Each tab keeps its own width (101), so
/// on phones narrower than 428 pt, where four don't fit side by side, they overlap by a few
/// points; only the selected tab draws a pill, so the overlap never shows.
private struct TabStrip: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return CGSize(
            width: proposal.width ?? sizes.reduce(0) { $0 + $1.width },
            height: sizes.map(\.height).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        guard let first = sizes.first, let last = sizes.last else { return }
        let start = bounds.minX + first.width / 2
        let end = bounds.maxX - last.width / 2
        let step = sizes.count > 1 ? (end - start) / CGFloat(sizes.count - 1) : 0
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: start + step * CGFloat(index), y: bounds.midY),
                anchor: .center,
                proposal: ProposedViewSize(width: sizes[index].width, height: bounds.height))
        }
    }
}

extension EnvironmentValues {
    /// How tall `DwellTabBar` stands above the home indicator, measured by `RootView`.
    /// Zero where there's no bar (previews of a single screen, sheets).
    @Entry var tabBarHeight: CGFloat = 0
}

extension View {
    /// Keeps a tab's content clear of `DwellTabBar` by adding the bar's height to the bottom
    /// safe area: scroll views end above the bar and still scroll up behind its glass, and
    /// anything inset at the bottom (the confirmation card) floats above it.
    ///
    /// Apply inside the screen's `NavigationStack`, on its root and on each pushed page, never
    /// on a sheet (sheets cover the bar).
    func clearsTabBar() -> some View {
        modifier(TabBarClearance())
    }
}

private struct TabBarClearance: ViewModifier {
    @Environment(\.tabBarHeight) private var height

    func body(content: Content) -> some View {
        content.safeAreaPadding(.bottom, height)
    }
}
