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
                Circle()
                    .fill(Palette.glass.shadow(.inner(color: .black.opacity(0.05), radius: 2, y: 0)))
                    .overlay {
                        Circle().strokeBorder(
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
            .contentShape(.circle)
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .motion(value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassCircleButtonStyle {
    public static var glassCircle: GlassCircleButtonStyle { GlassCircleButtonStyle() }
}
