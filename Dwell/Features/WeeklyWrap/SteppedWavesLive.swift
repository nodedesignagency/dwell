import DwellUI
import SwiftUI

/// The explorer page's pattern (Weekly wrap 6, "Explorer week"): the designer's reference image
/// of wavy grey and white stripes cut into columns, each column's stripes sheared so they step
/// back up at the next, redrawn in code (`SteppedWaves.metal`, a pixel at a time on the GPU)
/// from the image's pixels. Placed as Figma places the image (628 × 659 at −117, 239 on the
/// 393 × 852 frame), hanging from the bottom of the screen, scaled with the width. The shader
/// file has the measurements.
///
/// Moving (the wrap's patterns all move, the user, 13 Nov): the wave rolls to the right under
/// the columns, one wavelength (612) every 45 s, so the steps rise and fall across the page like
/// a swell; steady, so the loop never shows a seam. It starts where the design draws it. Under
/// Reduce Motion it holds still there. Full strength: set its opacity where it's used (Figma's
/// 20% on the explorer page).
struct SteppedWavesLive: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now

    /// The wave's length, in points of the 393-wide frame; the same as the shader's.
    private static let wavelength: Double = 611.67
    /// Seconds for the wave to roll one wavelength.
    private static let period: Double = 45

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: reduceMotion)) { context in
            let elapsed = reduceMotion ? 0 : context.date.timeIntervalSince(start)
            let travel = (elapsed / Self.period).truncatingRemainder(dividingBy: 1) * Self.wavelength
            GeometryReader { proxy in
                Rectangle()
                    .colorEffect(ShaderLibrary.steppedWaves(
                        .float2(proxy.size),
                        .float(travel),
                        .color(Palette.wrapStep),
                        .color(Palette.wrapStepDeep)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
