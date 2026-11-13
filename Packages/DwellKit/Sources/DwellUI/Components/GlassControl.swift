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
        if #available(iOS 26.0, macOS 26.0, *) {
            label
                // Lifted: Figma's white 65% over the glass, under the icon.
                .background {
                    if lifted {
                        shape.fill(Palette.glassPill)
                    }
                }
                .glassEffect(.regular.interactive(), in: shape)
                .background {
                    if lifted {
                        GlassDropShadow(shape: shape)
                    }
                }
                .contentShape(Rectangle().inset(by: -2))
        } else {
            label
                .background {
                    if lifted {
                        LiftedGlass(shape: shape)
                    } else {
                        DrawnGlass(shape: shape, fill: Palette.glassControl)
                            .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                    }
                }
                .contentShape(Rectangle().inset(by: -2))
                .scaleEffect(configuration.isPressed ? 0.92 : 1)
                .motion(value: configuration.isPressed)
        }
    }
}

extension ButtonStyle where Self == GlassSquareButtonStyle {
    public static var glassSquare: GlassSquareButtonStyle { GlassSquareButtonStyle() }

    /// Time's share button (Figma, 13 Nov): the back button's Glass (light −45° at 80%,
    /// refraction 80, depth 20, dispersion 50, frost 4, splay 0) over white 65% (`glassPill`),
    /// with a drop shadow, y 5, blur 10, #1B1C1D at 5% (`glassShadow`), shown behind the glass.
    /// On iOS 26 and later the white 65% is laid over Liquid Glass, as Figma lays its fill.
    public static var liftedGlassSquare: GlassSquareButtonStyle {
        GlassSquareButtonStyle(lifted: true)
    }
}

/// Figma's Glass over white 65% with its drop shadow shown behind it (Time, 13 Nov: the share
/// button and the selected pills): Glass light −45° at 80%, refraction 80, depth 20,
/// dispersion 50, frost 4, splay 0; fill white 65% (`glassPill`); drop shadow y 5, blur 10,
/// #1B1C1D at 5% (`glassShadow`); no border. On iOS 26 and later it's Liquid Glass in the
/// shape with the white 65% laid over it, as Figma lays its fill (the user, 13 Nov: the tab's
/// colour is white 65%; the bare glass read grey on the track); before, the drawn glass over
/// the white 65%.
struct LiftedGlass<S: InsettableShape>: View {
    let shape: S

    var body: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            shape
                .fill(Palette.glassPill)
                .glassEffect(.regular, in: shape)
                .background { GlassDropShadow(shape: shape) }
        } else {
            ZStack {
                GlassDropShadow(shape: shape)
                DrawnGlass(shape: shape, fill: Palette.glassPill)
            }
        }
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
