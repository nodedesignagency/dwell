import DwellUI
import SwiftUI

/// The tab bar from the Today design (Figma "tabPills"): a glass bar across the bottom with
/// large rounded top corners, white 20% over frosted glass and an ink-10% border, and a white
/// pill behind the selected tab that slides between tabs.
///
/// Replaces the system bar's look; `RootView` keeps the system `TabView` for the screens.
/// Icons are outlined SF Symbols until the design's tab icons are exported. [ICON NEEDED]
struct DwellTabBar: View {
    @Binding var selection: RootView.Tab

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var pill
    @ScaledMetric(relativeTo: .footnote) private var iconSize: CGFloat = 22

    /// Figma: tabs 54 tall from 12 below the bar's top, 11.5 in from its sides.
    private static let corner: CGFloat = 44

    var body: some View {
        HStack(spacing: 0) {
            ForEach(RootView.Tab.allCases, id: \.self) { tab in
                button(tab)
            }
        }
        .padding(.horizontal, 11.5)
        .padding(.top, Space.m)
        .padding(.bottom, Space.xs)
        .background {
            let shape = UnevenRoundedRectangle(topLeadingRadius: Self.corner, topTrailingRadius: Self.corner)
            ZStack {
                shape.fill(Palette.tabBar)
                shape.strokeBorder(Palette.separator, lineWidth: 1)
            }
            .modifier(TabBarGlass(shape: shape))
            .ignoresSafeArea(edges: .bottom)
        }
        .motion(value: selection)
    }

    private func button(_ tab: RootView.Tab) -> some View {
        let isSelected = tab == selection
        return Button {
            selection = tab
        } label: {
            VStack(spacing: Space.xs) {
                Image(systemName: tab.symbol)
                    .resizable()
                    .scaledToFit()
                    .symbolVariant(.none)
                    .fontWeight(.medium)
                    .frame(width: iconSize, height: iconSize)
                Text(verbatim: tab.title)
                    .textRole(.tab, weight: isSelected ? .medium : .regular, tracking: 0)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isSelected ? Palette.textPrimary : Palette.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background {
                if isSelected {
                    selectedPill
                        .padding(.horizontal, -4)
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

/// Figma's glass: Liquid Glass on iOS 26, an ultra-thin material before it.
private struct TabBarGlass<S: Shape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content.background(.ultraThinMaterial, in: shape)
        }
    }
}
