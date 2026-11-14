import SwiftUI

/// A round button on glass (Today design, the sheet's close button: Figma "Glass", light −45°
/// at 80%, over white 70%, 44 with 10 of padding). Drawn to match the design rather than
/// with the system's Liquid Glass, which rendered it solid white: white 70%, so the card
/// shows through faintly, a bright rim strongest top left and bottom right, and a little
/// shade just inside it. Pressed, it sinks a touch.
public struct GlassCircleButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(10)
            .background {
                DrawnGlass(shape: Circle(), fill: Palette.glass)
            }
            .contentShape(.circle)
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .motion(value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassCircleButtonStyle {
    public static var glassCircle: GlassCircleButtonStyle { GlassCircleButtonStyle() }
}

/// A round button on the page's grey (Share this insight's close button). The glass's white
/// 70% vanishes on #F9F9FB, so this one is solid: the card's white (`surface`) with a 1-pt edge
/// of ink 5% (`outline`), the user's call (14 Nov); in dark, the dark card and the white-8%
/// edge. 44 with 10 of padding; pressed, it sinks a touch.
public struct RaisedCircleButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(10)
            .background {
                Circle()
                    .fill(Palette.surface)
                    .overlay { Circle().strokeBorder(Palette.outline, lineWidth: 1) }
            }
            .contentShape(.circle)
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .motion(value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == RaisedCircleButtonStyle {
    public static var raisedCircle: RaisedCircleButtonStyle { RaisedCircleButtonStyle() }
}

/// A square button on glass (Your places' back button: Figma "Glass", light −45° at 80%,
/// refraction 80, depth 20, dispersion 50, frost 4, over white 80%; 40 with 10 of padding,
/// corners 13). Tappable over 44.
///
/// On iOS 26 and later it's the system's Liquid Glass in that shape, like the system's own
/// back button, which reads as glass on a light page (the user, 12 Nov). The white 80% is
/// left to the glass's own frost: tinting with it is what turned the close button solid
/// white. Before iOS 26, the close button's drawn glass over white 80%, with a soft shadow so
/// it lifts off a light page; pressed, it sinks a touch.
public struct GlassSquareButtonStyle: ButtonStyle {
    private let lifted: Bool

    public init() {
        self.init(lifted: false)
    }

    fileprivate init(lifted: Bool) {
        self.lifted = lifted
    }

    @ViewBuilder
    public func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.m)
        let label = configuration.label.padding(10)
        if lifted {
            // Drawn on every iOS: Liquid Glass didn't look like Figma's (the user, 13 Nov).
            pressable(label.background { LiftedGlass(shape: shape) }, configuration: configuration)
        } else {
            backButton(label, shape: shape, configuration: configuration)
        }
    }

    @ViewBuilder
    private func backButton(_ label: some View, shape: RoundedRectangle, configuration: Configuration) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            label
                .glassEffect(.regular.interactive(), in: shape)
                .contentShape(Rectangle().inset(by: -2))
        } else {
            pressable(
                label.background {
                    DrawnGlass(shape: shape, fill: Palette.glassControl)
                        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                },
                configuration: configuration)
        }
    }

    /// Pressed, it sinks a touch.
    private func pressable(_ view: some View, configuration: Configuration) -> some View {
        view
            .contentShape(Rectangle().inset(by: -2))
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .motion(value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassSquareButtonStyle {
    public static var glassSquare: GlassSquareButtonStyle { GlassSquareButtonStyle() }

    /// Time's share button (Figma, 13 Nov): the back button's Glass (light −45° at 80%,
    /// refraction 80, depth 20, dispersion 50, frost 4, splay 0) over white 65% (`glassPill`),
    /// with a drop shadow, y 5, blur 10, #1B1C1D at 5% (`glassShadow`), shown behind the glass.
    /// Drawn (`LiftedGlass`) on every iOS, never Liquid Glass.
    public static var liftedGlassSquare: GlassSquareButtonStyle {
        GlassSquareButtonStyle(lifted: true)
    }
}

/// Figma's Glass over white 65% with its drop shadow shown behind it (Time, 13 Nov: the share
/// button and the selected pills). Figma: Glass light −45° at 80%, refraction 80, depth 20,
/// dispersion 50, frost 4, splay 0; fill white 65% (`glassPill`); drop shadow y 5, blur 10,
/// #1B1C1D at 5% (`glassShadow`); no border.
///
/// Drawn the same on every iOS (the user, 13 Nov: Liquid Glass didn't look like Figma's).
/// Figma's Glass is replaced by what it draws on a light page, fitted to the Figma render of
/// the Weekday pill (to half a grey level on average): the light from the top left leaves a
/// faint shade inside the top and left edges (black 3%, x 2, y 2, blur 6) and catches the
/// bottom and right ones (white 30%, x −2.5, y −3, blur 4), and a 0.75 white rim runs all
/// round. Dark mode takes the light at a third (derived).
struct LiftedGlass<S: InsettableShape>: View {
    let shape: S

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let light = colorScheme == .dark ? 1.0 / 3 : 1
        ZStack {
            GlassDropShadow(shape: shape)
            shape.fill(Palette.glassPill)
            InnerShadow(shape: shape, color: .black.opacity(0.03), blur: 6, x: 2, y: 2)
            InnerShadow(shape: shape, color: Palette.glowRays.opacity(0.3 * light), blur: 4, x: -2.5, y: -3)
            shape.strokeBorder(Palette.glowRays.opacity(light), lineWidth: 0.75)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Figma's inner shadow, drawn on its own: `color` inside the shape wherever the shape, moved by
/// (x, y) and blurred, doesn't reach. SwiftUI's own inner shadow (`.shadow(.inner)`) takes its
/// shape from the fill's opacity, and on a 65% fill it would shade the whole inside, not the
/// edges. `blur` is Figma's; SwiftUI's blur radius is half of it.
private struct InnerShadow<S: Shape>: View {
    let shape: S
    let color: Color
    let blur: CGFloat
    let x: CGFloat
    let y: CGFloat

    var body: some View {
        Rectangle()
            .fill(color)
            .mask {
                Rectangle()
                    .overlay {
                        shape
                            .offset(x: x, y: y)
                            .fill(Color.black)
                            .blur(radius: blur / 2)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
            }
            .clipShape(shape)
    }
}

/// Figma's drop shadow on glass with "Show behind transparent areas" on: y 5, blur 10, in
/// `glassShadow` (#1B1C1D at 5%). Drawn as the shape itself, moved down and blurred, rather than
/// with `.shadow`: SwiftUI's shadow would come off the icon too, and would fade with the glass's
/// 65% fill, where Figma's keeps its full 5% and shows through the glass. SwiftUI's blur radius,
/// like its shadow radius, is half Figma's blur.
private struct GlassDropShadow<S: Shape>: View {
    let shape: S

    var body: some View {
        shape
            .fill(Palette.glassShadow)
            .offset(y: 5)
            .blur(radius: 10 / 2)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// A square button on the close button's glass (You's settings button, the user's call, 13 Nov:
/// the sheet's close-button values on You): white 70%, the white rim and the faint shade
/// inside it, drawn in every iOS version (never Liquid Glass), lifted off the page by
/// `glassLift()`. 40 with 10 of padding, corners 13, as the back button. Tappable over 44.
public struct DrawnGlassSquareButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(10)
            .background {
                DrawnGlass(shape: RoundedRectangle(cornerRadius: Radius.m), fill: Palette.glass)
                    .glassLift()
            }
            .contentShape(Rectangle().inset(by: -2))
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .motion(value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == DrawnGlassSquareButtonStyle {
    public static var drawnGlassSquare: DrawnGlassSquareButtonStyle { DrawnGlassSquareButtonStyle() }
}

extension View {
    /// The soft shadow that lifts glass off a light page (You design, Figma: the pills and the
    /// settings button). Read from the Figma screenshot: about 9% darker just under the edge,
    /// gone 12 below and 8 to the sides, so black 10%, radius 8, 4 down.
    public func glassLift() -> some View {
        shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

/// The design's glass, drawn: the fill, so what's behind shows through faintly, a faint shade
/// just inside the edge, and a 1.5 rim of white strongest top left and bottom right (Figma's
/// light at −45°).
struct DrawnGlass<S: InsettableShape>: View {
    let shape: S
    let fill: Color

    var body: some View {
        shape
            .fill(fill.shadow(.inner(color: .black.opacity(0.05), radius: 2, y: 0)))
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Palette.glowRays, location: 0),
                            .init(color: Palette.glowRays.opacity(0.25), location: 0.5),
                            .init(color: Palette.glowRays.opacity(0.9), location: 1),
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.5)
            }
    }
}
