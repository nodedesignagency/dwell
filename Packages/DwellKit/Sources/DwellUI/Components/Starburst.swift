import SwiftUI

// MARK: - Starburst

/// The most-time page's pattern (Weekly wrap 4, 14 Nov): the designer's reference image of
/// spiky rings, pink, purple and indigo, round a pink star, redrawn in code and set moving.
/// Placed as Figma places it (721 × 1080 at −164, −114 on the 393-wide frame, at 30%), so the
/// star sits in the middle of the screen, scaled with the width.
///
/// Every ring is the same star drawn larger, its points lined up with the star's, so each
/// outline is a radius for every direction from the middle. Five of them, read from the
/// image every 2° (the points between are a smooth curve through them), match the image to
/// 98.5% of its pixels, the rest along the anti-aliased edges. Pink inside the first, then
/// purple, indigo, pink and purple.
///
/// Moving (the wrap's patterns all move, the user, 13 Nov): the rings flow outward, each
/// growing into the place of the one outside it and taking on its shape as it goes, while a
/// new star grows out of the middle, a ring every 5 s at a steady pace. The colours come round
/// every three rings, so the loop never shows a seam. It starts where the design draws it, and
/// under Reduce Motion, or `isMoving` off, it holds still there. Draw it at full strength and
/// set its opacity where it's used (30% on the most-time page).
public struct Starburst: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now
    private let colors: [Color]
    private let isMoving: Bool

    /// - Parameter colors: the middle's colour, then the next two out (pink, purple, indigo).
    public init(
        colors: [Color] = [Palette.wrapBurstPink, Palette.wrapBurstPurple, Palette.wrapBurstIndigo],
        isMoving: Bool = true
    ) {
        self.colors = colors
        self.isMoving = isMoving
    }

    public var body: some View {
        let still = reduceMotion || !isMoving
        TimelineView(.animation(minimumInterval: nil, paused: still)) { context in
            // The colours repeat every three rings: keep the count small.
            let flow = still ? 0 : (context.date.timeIntervalSince(start) / Self.period).truncatingRemainder(dividingBy: 3)
            let colors = colors
            Canvas { canvas, size in
                Self.draw(in: &canvas, size: size, flow: flow, colors: colors)
            }
        }
        // Rasterised by Metal, not on the CPU each frame.
        .drawingGroup()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Seconds for a ring to take the place of the one outside it.
    nonisolated public static let period: Double = 5

    /// The image as placed on the 393-wide frame: 1335 pixels drawn 721 wide.
    nonisolated private static let pointsPerPixel = 721.0 / 1335.0
    /// Directions drawn round each outline: every half degree.
    nonisolated private static let directions = 720

    /// The five outlines, in the image's pixels from its middle, every 2° anticlockwise from
    /// 3 o'clock: the star, then each ring out. Read from the reference image; the outer two
    /// run past its edges in places, where they follow the ring inside them, scaled.
    nonisolated private static let rings: [[Int]] = [
        [
            296, 298, 306, 326, 355, 394, 404, 360, 321, 293, 286, 292, 314, 350, 395, 400, 360, 338,
            330, 337, 358, 383, 398, 368, 326, 300, 286, 282, 288, 303, 325, 346, 366, 367, 341, 309,
            288, 282, 286, 294, 308, 327, 353, 385, 410, 382, 310, 283, 270, 264, 264, 269, 276, 290,
            312, 347, 388, 390, 360, 325, 304, 286, 274, 270, 272, 280, 292, 317, 358, 400, 384, 354,
            326, 299, 282, 272, 266, 262, 262, 265, 268, 278, 291, 314, 348, 386, 410, 374, 334, 308,
            300, 303, 318, 342, 382, 408, 380, 339, 308, 290, 283, 286, 302, 330, 369, 402, 393, 351,
            318, 300, 296, 302, 330, 368, 394, 372, 340, 318, 300, 292, 290, 300, 323, 353, 369, 359,
            339, 316, 297, 280, 274, 275, 284, 303, 332, 372, 404, 383, 350, 316, 292, 278, 272, 272,
            281, 302, 339, 381, 394, 366, 333, 309, 292, 280, 270, 266, 267, 274, 288, 312, 350, 396,
            402, 368, 330, 304, 285, 274, 268, 264, 267, 274, 287, 307, 337, 369, 394, 374, 336, 305,
        ],
        [
            454, 451, 454, 466, 490, 529, 584, 583, 494, 460, 452, 456, 476, 512, 573, 584, 516, 472,
            456, 458, 476, 510, 556, 591, 522, 472, 454, 452, 452, 454, 464, 491, 535, 570, 535, 486,
            461, 453, 452, 451, 451, 456, 471, 498, 544, 598, 556, 482, 459, 452, 452, 453, 452, 458,
            478, 518, 571, 574, 510, 474, 458, 453, 452, 452, 454, 454, 467, 500, 558, 582, 524, 486,
            464, 454, 454, 452, 454, 454, 453, 454, 454, 453, 456, 464, 490, 536, 582, 566, 498, 467,
            455, 455, 466, 492, 544, 598, 548, 492, 462, 455, 454, 454, 460, 478, 514, 566, 587, 517,
            475, 458, 456, 468, 496, 546, 592, 558, 492, 464, 454, 454, 458, 476, 524, 584, 580, 532,
            486, 464, 454, 453, 452, 452, 454, 464, 486, 537, 590, 560, 499, 468, 455, 454, 454, 454,
            456, 468, 500, 556, 586, 530, 483, 460, 452, 452, 452, 452, 452, 452, 458, 478, 528, 590,
            570, 508, 472, 457, 452, 452, 452, 452, 452, 451, 452, 458, 476, 512, 564, 576, 510, 470,
        ],
        [
            576, 576, 575, 575, 582, 611, 674, 728, 628, 584, 574, 576, 582, 606, 664, 714, 623, 585,
            576, 576, 579, 600, 642, 702, 666, 593, 576, 576, 576, 576, 578, 594, 638, 688, 650, 598,
            578, 576, 576, 576, 579, 577, 578, 590, 630, 692, 686, 604, 580, 578, 578, 576, 577, 576,
            584, 611, 672, 700, 624, 584, 578, 575, 577, 578, 578, 576, 582, 605, 658, 714, 643, 591,
            577, 578, 578, 578, 578, 578, 578, 578, 578, 578, 577, 578, 588, 628, 727, 707, 613, 583,
            578, 578, 579, 597, 679, 747, 650, 596, 580, 577, 578, 578, 578, 582, 606, 656, 712, 637,
            590, 577, 578, 578, 590, 624, 693, 696, 610, 580, 576, 577, 577, 589, 636, 714, 702, 625,
            588, 578, 578, 577, 578, 578, 578, 578, 590, 633, 708, 674, 604, 581, 578, 577, 578, 578,
            578, 582, 603, 664, 713, 638, 591, 577, 576, 578, 576, 576, 576, 577, 578, 589, 627, 690,
            688, 606, 581, 576, 576, 576, 576, 576, 576, 576, 576, 575, 580, 607, 704, 719, 628, 587,
        ],
        [
            666, 666, 668, 670, 672, 676, 850, 917, 692, 700, 708, 718, 728, 740, 754, 768, 785, 737,
            730, 730, 730, 733, 762, 838, 842, 752, 732, 731, 731, 732, 731, 736, 774, 845, 808, 745,
            731, 732, 732, 731, 732, 732, 732, 733, 756, 836, 852, 759, 734, 732, 732, 732, 732, 732,
            732, 748, 812, 860, 772, 736, 732, 732, 732, 733, 732, 732, 734, 741, 798, 864, 788, 742,
            734, 734, 733, 734, 734, 733, 728, 728, 728, 728, 727, 728, 741, 791, 916, 890, 772, 734,
            728, 728, 729, 752, 856, 941, 818, 751, 731, 727, 728, 728, 728, 735, 742, 827, 897, 803,
            746, 734, 736, 734, 736, 754, 811, 874, 772, 737, 735, 735, 734, 740, 780, 884, 846, 766,
            736, 734, 734, 734, 734, 734, 734, 733, 736, 765, 855, 839, 756, 734, 734, 734, 733, 734,
            733, 734, 746, 819, 850, 772, 738, 732, 732, 732, 732, 732, 732, 732, 732, 733, 755, 824,
            823, 763, 733, 732, 732, 732, 728, 718, 708, 700, 692, 686, 680, 676, 887, 906, 668, 666,
        ],
        [
            815, 815, 817, 819, 823, 827, 1040, 1122, 848, 857, 867, 879, 892, 906, 923, 941, 961, 803,
            823, 845, 869, 896, 912, 958, 995, 920, 902, 900, 900, 900, 899, 900, 916, 982, 992, 906,
            898, 898, 899, 898, 898, 897, 897, 898, 905, 974, 1043, 914, 896, 896, 896, 896, 896, 895,
            896, 900, 961, 1017, 923, 896, 895, 895, 896, 894, 894, 894, 894, 897, 977, 1057, 965, 908,
            898, 898, 897, 899, 898, 897, 891, 891, 891, 891, 890, 891, 908, 968, 1121, 1090, 945, 899,
            891, 891, 893, 921, 1047, 1151, 1002, 920, 895, 890, 891, 891, 891, 900, 908, 1012, 1098, 982,
            913, 899, 901, 899, 906, 908, 950, 1070, 952, 910, 908, 908, 909, 908, 939, 1058, 1014, 923,
            911, 910, 910, 911, 911, 911, 911, 912, 912, 927, 1047, 996, 922, 913, 913, 913, 914, 912,
            914, 914, 922, 981, 1040, 934, 915, 916, 914, 915, 915, 916, 916, 916, 916, 896, 869, 1009,
            1007, 803, 785, 896, 895, 896, 892, 879, 867, 857, 848, 840, 833, 827, 1086, 1109, 817, 815,
        ],
    ]

    /// The outlines every half degree, with one more at each end for the curve through them:
    /// the middle's point (and its mirror below it), then the five, then one further out by
    /// the last ring's spacing.
    nonisolated private static let table: [[Double]] = {
        let fine = rings.map { ring in
            (0..<directions).map { index in
                smooth(ring.map { Double($0) }, at: Double(index) * Double(ring.count) / Double(directions))
            }
        }
        let zero = [Double](repeating: 0, count: directions)
        let outer = zip(fine[4], fine[3]).map { $0 + ($0 - $1) }
        return [fine[0].map { -$0 }, zero] + fine + [outer]
    }()

    nonisolated private static let unitCircle: [CGPoint] = (0..<directions).map { index in
        let angle = Double(index) / Double(directions) * 2 * .pi
        // Anticlockwise, as the image was read: y grows downward on screen.
        return CGPoint(x: cos(angle), y: -sin(angle))
    }

    nonisolated private static func draw(in context: inout GraphicsContext, size: CGSize, flow: Double, colors: [Color]) {
        guard colors.count == 3 else { return }
        let scale: Double = pointsPerPixel * Double(size.width) / 393
        let middle = CGPoint(x: size.width / 2, y: size.height / 2)
        let step = Int(flow.rounded(.down))
        let along = flow - Double(step)
        func color(_ band: Int) -> Color {
            colors[((band - step) % 3 + 3) % 3]
        }

        // Past the last outline drawn, the colour of the band inside it; then each outline
        // filled with the band inside it, from the outside in.
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(color(4)))
        for outline in stride(from: 4, through: 0, by: -1) {
            let position = Double(outline) + along
            guard position > 0 else { continue }
            var path = Path()
            for index in 0..<directions {
                let distance = CGFloat(Self.radius(at: position, direction: index) * scale)
                let point = CGPoint(
                    x: middle.x + unitCircle[index].x * distance,
                    y: middle.y + unitCircle[index].y * distance)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            context.fill(path, with: .color(color(outline - 1)))
        }
    }

    /// The outline at `position` (0 is the middle's point, 1 the star, 5 the last ring), a
    /// smooth curve through the outlines either side, so rings grow at a steady pace and land
    /// exactly on the image's at each whole step. Never shrinks as `position` grows.
    nonisolated private static func radius(at position: Double, direction: Int) -> Double {
        let index = min(max(Int(position.rounded(.down)), 0), 4)
        let t = position - Double(index)
        // `table` starts one outline before the middle's point.
        let p0 = table[index][direction]
        let p1 = table[index + 1][direction]
        let p2 = table[index + 2][direction]
        let p3 = table[index + 3][direction]
        return catmullRom(p0, p1, p2, p3, t)
    }

    /// A ring's radius between its samples, a smooth curve through them, round the circle.
    nonisolated private static func smooth(_ samples: [Double], at position: Double) -> Double {
        let count = samples.count
        let index = Int(position.rounded(.down))
        func at(_ i: Int) -> Double { samples[((i % count) + count) % count] }
        return catmullRom(at(index - 1), at(index), at(index + 1), at(index + 2), position - Double(index))
    }

    nonisolated private static func catmullRom(_ p0: Double, _ p1: Double, _ p2: Double, _ p3: Double, _ t: Double) -> Double {
        let t2 = t * t
        let t3 = t2 * t
        return 0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
    }
}
