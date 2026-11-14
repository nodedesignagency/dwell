import DwellUI
import SwiftUI

/// The explorer page's pattern (Weekly wrap 6, "Explorer week"): the designer's reference image
/// of wavy grey and white stripes cut into columns, each column's stripes sheared so they step
/// back up at the next, redrawn in code (`SteppedWaves.metal`, a pixel at a time on the GPU)
/// from the image's pixels. Placed as Figma places the image (628 × 659 at −117, 239 on the
/// 393 × 852 frame), hanging from the bottom of the screen, scaled with the width. The shader
/// file has the measurements.
///
/// Moving (the wrap's patterns all move, the user, 13 Nov; "feel like a wave", 14 Nov): the
/// columns rise and fall in turn, each whole, 7 up and down, a little after the one to its left,
/// so a swell runs across them from left to right, one every 4.5 s, eight columns from crest
/// to crest. The stripes keep their shape: nothing tips or turns (the first version rolled the
/// wave sideways under the columns, which read as turning, and the user didn't like it). A
/// steady loop with no seam, starting where the design draws it. Under Reduce Motion it holds
/// still there. Full strength: set its opacity where it's used (Figma's 20% on the explorer
/// page).
struct SteppedWavesLive: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now

    /// Seconds for one swell to pass a column.
    private static let period: Double = 4.5

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: reduceMotion)) { context in
            let elapsed = reduceMotion ? 0 : context.date.timeIntervalSince(start)
            let swell = (elapsed / Self.period).truncatingRemainder(dividingBy: 1)
            GeometryReader { proxy in
                Rectangle()
                    .colorEffect(ShaderLibrary.steppedWaves(
                        .float2(proxy.size),
                        .float(swell),
                        .color(Palette.wrapStep),
                        .color(Palette.wrapStepDeep)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
