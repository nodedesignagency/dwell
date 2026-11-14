import DwellCore
import SwiftUI

// The pieces onboarding is built from (onboarding flow, 13 Nov), measured from the
// screenshots at 393 × 852: the page dots, the buttons on colour, the role chips, the example
// art's tags and photos, and the pages' colour.

// MARK: - Page dots

/// Where the user is in a run of pages: the page showing as a capsule 28 × 8, the others dots
/// of 8, 3 apart. On colour the dots are white, the ones not showing at 50%; on a light sheet
/// the page showing is onboarding's blue and the others grey (`pageDot`). One VoiceOver element
/// ("Page 2 of 4"). Decorative size: it doesn't grow with the text.
public struct PageDots: View {
    public enum Style: Sendable {
        /// On a coloured page: white.
        case onColor
        /// On a light sheet: blue and grey.
        case onLight
    }

    private let count: Int
    private let current: Int
    private let style: Style
    private let label: String

    /// - Parameters:
    ///   - current: the page showing, from 0.
    ///   - label: what VoiceOver says: "Page 2 of 4".
    public init(count: Int, current: Int, style: Style, label: String) {
        self.count = count
        self.current = current
        self.style = style
        self.label = label
    }

    public var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<count, id: \.self) { index in
                let isCurrent = index == current
                Capsule()
                    .fill(isCurrent ? activeColor : restColor)
                    .frame(width: isCurrent ? 28 : 8, height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: label))
    }

    private var activeColor: Color {
        switch style {
        case .onColor: .white
        case .onLight: Palette.onboardingSky
        }
    }

    private var restColor: Color {
        switch style {
        case .onColor: .white.opacity(0.5)
        case .onLight: Palette.pageDot
        }
    }
}

// MARK: - Buttons on colour

/// A capsule of clear glass on a coloured page: "I already have an account" (onboarding, My
/// world). 44 tall, full width, the label 18 medium in white. Read from the screenshot (no
/// Figma values yet): the blue under it greys a little (white 8%, then black 4%), and a 1-pt
/// rim of light is added to the colour below (plus-lighter at 50%, so it reads pale cyan on
/// blue). Pressed, it dims.
public struct ClearGlassCapsuleButtonStyle: ButtonStyle {
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 44

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textRole(.action)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Space.l)
            .frame(maxWidth: .infinity, minHeight: height)
            .background {
                Capsule()
                    .fill(.white.opacity(0.08))
                    .overlay { Capsule().fill(.black.opacity(0.04)) }
                    .overlay {
                        Capsule()
                            .strokeBorder(.white.opacity(0.5), lineWidth: 1)
                            .blendMode(.plusLighter)
                    }
            }
            .contentShape(.capsule)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == ClearGlassCapsuleButtonStyle {
    public static var clearGlass: ClearGlassCapsuleButtonStyle { ClearGlassCapsuleButtonStyle() }
}

/// A button that is only its words: "Skip", "Not now" (onboarding). 18 medium in the colour
/// given, 44 to tap; dims pressed.
public struct TextButtonStyle: ButtonStyle {
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 44
    private let color: Color

    public init(color: Color) {
        self.color = color
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textRole(.action)
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Space.l)
            .frame(minHeight: height)
            .contentShape(.rect)
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

extension ButtonStyle where Self == TextButtonStyle {
    /// Words only, in ink unless given another colour (white on a coloured page).
    public static func text(_ color: Color = Palette.textPrimary) -> TextButtonStyle {
        TextButtonStyle(color: color)
    }
}

// MARK: - Choice chips

/// One of a few options as a pill: "Save as: Home · Work · Other" (onboarding's Your places).
/// 24 tall, a glyph 14, 6 to the label (14 medium), 12 across; chosen: `chipSelected` with ink
/// on it (ink in dark mode too, on the same blue); not chosen: the field's fill outlined in
/// ink 10%. The tap area is 44 tall. A button with the selected trait; the choice changes
/// with `Motion.standard`.
public struct ChoiceChip: View {
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .subheadline) private var height: CGFloat = 24
    @ScaledMetric(relativeTo: .subheadline) private var iconSize: CGFloat = 14
    private let title: String
    private let icon: Image
    private let isSelected: Bool
    private let action: () -> Void

    public init(_ title: String, icon: Image, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .accessibilityHidden(true)
                Text(verbatim: title)
                    .textRole(.caption, weight: .medium)
                    .lineLimit(1)
            }
            .foregroundStyle(Palette.textPrimary)
            .environment(\.colorScheme, isSelected ? .light : colorScheme)
            .padding(.horizontal, Space.m)
            .frame(minHeight: height)
            .background {
                Capsule()
                    .fill(isSelected ? Palette.chipSelected : Palette.field)
                    .overlay {
                        Capsule().strokeBorder(isSelected ? .clear : Palette.separator, lineWidth: 1)
                    }
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .motion(value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Example art: tags and photos

/// A place's name and time on a light pill, pointing at the place (onboarding's example art:
/// "Brambleline Café | 2h"): a glyph 16, 6 to the name (16 medium, ink), then, when there's a
/// time, 7 to a hairline 14 tall and 7 to the time (16 regular, grey); 33 tall, 10 across, on
/// `tag` with a soft shadow (black 8%, radius 8, y 4, estimated); a tail 10 wide and 5 deep
/// on one edge points at the place. A place saved in onboarding has no time yet, so its tag is
/// the name alone. Print on the art: the light scheme always, at its own size whatever the
/// text size. Hidden from VoiceOver: the art's caption says it.
///
/// On a map (Weekly wrap 6, "Pioneer Works | NEW", `init(name:mark:icon:tail:)`): smaller and
/// rimmed. 34 tall: `mapTag` inside a 1-pt `mapTagRim`, its tail 12 wide and 8 deep in the
/// rim's white, no shadow; 8 in, the glyph 16, 6 to the name (14 medium), 4 to a hairline 16
/// tall, 6 to the mark (14 medium, `newPlace`, in capitals), 12 to the end. Measured from the
/// screenshot at 393 wide (the tag is 175 across for "Pioneer Works").
public struct PlaceTag: View {
    /// Which edge the tail leaves from, and how far along it (0 is the leading or top end).
    public nonisolated enum Tail: Hashable, Sendable {
        case none
        case top(CGFloat)
        case bottom(CGFloat)
        case leading(CGFloat)
    }

    private nonisolated enum Look: Hashable {
        case example
        case map
    }

    private let name: String
    private let time: String?
    private let icon: Image
    private let tail: Tail
    private let look: Look

    public init(name: String, time: String?, icon: Image, tail: Tail = .none) {
        self.name = name
        self.time = time
        self.icon = icon
        self.tail = tail
        self.look = .example
    }

    /// A place on a map with a word beside it: "Pioneer Works | NEW".
    /// - Parameter mark: shown in capitals, in `newPlace`'s green.
    public init(name: String, mark: String, icon: Image, tail: Tail = .none) {
        self.name = name
        self.time = mark
        self.icon = icon
        self.tail = tail
        self.look = .map
    }

    /// How far the tail reaches past the pill: pad by this on its side to take it in.
    public static func tailDepth(onMap: Bool) -> CGFloat {
        onMap ? 8 : 5
    }

    public var body: some View {
        switch look {
        case .example: example
        case .map: onMap
        }
    }

    private var example: some View {
        HStack(spacing: 0) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text(verbatim: name)
                .textRole(.body)
                .padding(.leading, 6)
            if let time {
                Rectangle()
                    .fill(Palette.separator)
                    .frame(width: 1, height: 14)
                    .padding(.horizontal, 7)
                Text(verbatim: time)
                    .textRole(.body, weight: .regular)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .foregroundStyle(Palette.textPrimary)
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 10)
        .frame(height: 33)
        .background {
            TagShape(tail: tail)
                .fill(Palette.tag)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
        .environment(\.colorScheme, .light)
        .dynamicTypeSize(.large)
        .accessibilityHidden(true)
    }

    private var onMap: some View {
        HStack(spacing: 0) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text(verbatim: name)
                .textRole(.caption, weight: .medium)
                .padding(.leading, 6)
            if let time {
                Rectangle()
                    .fill(Palette.separator)
                    .frame(width: 1, height: 16)
                    .padding(.leading, 4)
                    .padding(.trailing, 6)
                Text(verbatim: time.uppercased())
                    .textRole(.caption, weight: .medium)
                    .foregroundStyle(Palette.newPlace)
            }
        }
        .foregroundStyle(Palette.textPrimary)
        .lineLimit(1)
        .fixedSize()
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .frame(height: 34)
        .background {
            // The rim and the tail in one white shape, the tag's grey inside the rim.
            TagShape(tail: tail, width: 12, depth: Self.tailDepth(onMap: true))
                .fill(Palette.mapTagRim)
                .overlay {
                    Capsule()
                        .fill(Palette.mapTag)
                        .padding(1)
                }
        }
        .environment(\.colorScheme, .light)
        .dynamicTypeSize(.large)
        .accessibilityHidden(true)
    }
}

/// A capsule with a small triangular tail on one edge.
nonisolated private struct TagShape: Shape {
    let tail: PlaceTag.Tail
    var width: CGFloat = 10
    var depth: CGFloat = 5

    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: rect.height / 2)
        let half = width / 2
        switch tail {
        case .none:
            break
        case .top(let along):
            let x = rect.minX + clamp(along) * rect.width
            path.move(to: CGPoint(x: x - half, y: rect.minY + 1))
            path.addLine(to: CGPoint(x: x, y: rect.minY - depth))
            path.addLine(to: CGPoint(x: x + half, y: rect.minY + 1))
            path.closeSubpath()
        case .bottom(let along):
            let x = rect.minX + clamp(along) * rect.width
            path.move(to: CGPoint(x: x - half, y: rect.maxY - 1))
            path.addLine(to: CGPoint(x: x, y: rect.maxY + depth))
            path.addLine(to: CGPoint(x: x + half, y: rect.maxY - 1))
            path.closeSubpath()
        case .leading(let along):
            let y = rect.minY + along * rect.height
            path.move(to: CGPoint(x: rect.minX + 1, y: y - half))
            path.addLine(to: CGPoint(x: rect.minX - depth, y: y))
            path.addLine(to: CGPoint(x: rect.minX + 1, y: y + half))
            path.closeSubpath()
        }
        return path
    }

    /// Keeps the tail off the capsule's round ends.
    private func clamp(_ along: CGFloat) -> CGFloat {
        min(max(along, 0.15), 0.85)
    }
}

/// A photo printed with a white edge (onboarding's example art): white 3 all round, corners
/// 12 outside and 9 inside, a soft shadow (black 12%, radius 12, y 6, estimated). Without its
/// photo, a placeholder: the category's glyph on grey [ASSET NEEDED]. Fills the frame it's
/// given. Hidden from VoiceOver: the art's caption says it.
public struct PhotoCard: View {
    private let image: Image?
    private let category: PlaceCategory

    public init(_ image: Image?, category: PlaceCategory) {
        self.image = image
        self.category = category
    }

    public var body: some View {
        Rectangle()
            .fill(Palette.gap)
            .overlay {
                if let image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    CategoryIcon(category, style: .glyph)
                        .frame(width: 32, height: 32)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            .clipShape(.rect(cornerRadius: 9))
            .padding(3)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
            }
            .environment(\.colorScheme, .light)
            .accessibilityHidden(true)
    }
}

// MARK: - The pages' colour

/// The colour of an onboarding page, edge to edge: onboarding's blue at the top paling through
/// the middle to pink (See where it all goes) or gold (Start my day) at the foot, deepest at
/// the middle of the foot. Stops read from the screenshots down the screen's edge (60, 220,
/// 380, 540, 700 and 852 of 852), the glow from its middle column. The same in dark: the
/// page's colour is the design's.
public struct OnboardingBackdrop: View {
    public enum Style: Sendable {
        /// Onboarding's blue alone: under My world's sky and around Your places' sheet.
        case sky
        /// Blue to pink: See where it all goes.
        case blush
        /// Blue to gold: Start my day.
        case gold
    }

    private let style: Style

    public init(_ style: Style) {
        self.style = style
    }

    public var body: some View {
        Group {
            switch style {
            case .sky:
                Palette.onboardingSky
            case .blush:
                fade(middle: Palette.onboardingHaze, low: Palette.onboardingBlush, foot: Palette.onboardingBlushEdge, glow: Palette.onboardingBlushDeep)
            case .gold:
                fade(middle: Palette.onboardingCream, low: Palette.onboardingGold, foot: Palette.onboardingGoldEdge, glow: Palette.onboardingGoldDeep)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func fade(middle: Color, low: Color, foot: Color, glow: Color) -> some View {
        LinearGradient(
            stops: [
                .init(color: Palette.onboardingSky, location: 0.07),
                .init(color: Palette.onboardingSkyLight, location: 0.258),
                .init(color: Palette.onboardingSkyPale, location: 0.446),
                .init(color: middle, location: 0.634),
                .init(color: low, location: 0.822),
                .init(color: foot, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom)
            .overlay {
                GeometryReader { proxy in
                    // Deeper at the middle of the foot: gone about a third of the way up the
                    // screen, and almost gone by the sides, whose colour the stops already give.
                    RadialGradient(
                        colors: [glow.opacity(0.8), glow.opacity(0)],
                        center: .bottom,
                        startRadius: 0,
                        endRadius: proxy.size.width * 0.75)
                        .scaleEffect(x: 0.7, y: 1, anchor: .bottom)
                }
            }
    }
}
