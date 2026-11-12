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
    public init() {}

    @ViewBuilder
    public func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.m)
        let label = configuration.label.padding(10)
        if #available(iOS 26.0, macOS 26.0, *) {
            label
                .glassEffect(.regular.interactive(), in: shape)
                .contentShape(Rectangle().inset(by: -2))
        } else {
            label
                .background {
                    DrawnGlass(shape: shape, fill: Palette.glassControl)
                        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                }
                .contentShape(Rectangle().inset(by: -2))
                .scaleEffect(configuration.isPressed ? 0.92 : 1)
                .motion(value: configuration.isPressed)
        }
    }
}

extension ButtonStyle where Self == GlassSquareButtonStyle {
    public static var glassSquare: GlassSquareButtonStyle { GlassSquareButtonStyle() }
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
