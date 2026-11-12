import SwiftUI

extension View {
    /// A small control on glass (Today design, the sheet's close button: Figma "Glass", light
    /// −45° at 80%, refraction 80, depth 20, dispersion 50, frost 4, over white 70%).
    ///
    /// On iOS 26 and later it is Apple's Liquid Glass, tinted with that white (`glass`) and
    /// interactive, so it lifts and shimmers under a finger as system controls do. Before
    /// iOS 26: a thin material under the same white, with a light rim from the top left.
    public func glassControl<S: InsettableShape>(in shape: S) -> some View {
        modifier(GlassControl(shape: shape))
    }
}

private struct GlassControl<S: InsettableShape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.tint(Palette.glass).interactive(), in: shape)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .background(Palette.glass, in: shape)
                .overlay {
                    // The light, from −45° (top left) at 80%, fading across.
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [Palette.glowRays.opacity(0.8), Palette.glowRays.opacity(0)],
                            startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1)
                }
        }
    }
}
