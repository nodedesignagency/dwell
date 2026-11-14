import DwellUI
import SwiftUI

/// The postcard page's swirl stripes as they move on screen: DwellUI's `SwirlStripes` field,
/// drawn on the GPU by a Metal shader (`SwirlStripes.metal`), a pixel at a time, so a frame
/// costs next to nothing. The Canvas version drew a few thousand pieces each frame and ran at
/// about 30 fps (the user's recording, 14 Nov: "too heavy"); it now only draws the still
/// shared image.
///
/// The same look and motion: the stripes flow along their bends toward the bottom left, a
/// light and a dark stripe every 5 s, starting where the design draws them; still under
/// Reduce Motion. Full strength: set its opacity where it's used (10% on the postcard).
struct SwirlStripesLive: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now

    /// The field's weights for the shader, row by row.
    private static let weights: [Float] = SwirlStripes.weights.flatMap { $0.map(Float.init) }

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: reduceMotion)) { context in
            let elapsed = reduceMotion ? 0 : context.date.timeIntervalSince(start)
            // Two whole steps make a light and a dark stripe, so the pattern repeats every 2.
            let flow = (2 * elapsed / SwirlStripes.period).truncatingRemainder(dividingBy: 2)
            GeometryReader { proxy in
                Rectangle()
                    .colorEffect(ShaderLibrary.swirlStripes(
                        .float2(proxy.size),
                        .float(flow),
                        .floatArray(Self.weights),
                        .color(Palette.wrapSwirl),
                        .color(Palette.wrapSwirlDeep)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
