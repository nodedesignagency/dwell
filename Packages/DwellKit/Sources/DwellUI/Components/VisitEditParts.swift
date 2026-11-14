import DwellCore
import SwiftUI

/// A sheet's grab handle (Visit edit): a grey capsule 44 × 5, 9 from the sheet's top. The
/// sheet closes with a swipe down; VoiceOver closes it with the escape gesture.
public struct SheetGrabber: View {
    public init() {}

    public var body: some View {
        Capsule()
            .fill(Palette.grabber)
            .frame(width: 44, height: 5)
            .accessibilityHidden(true)
    }
}

/// A category named beside its swatch (Visit edit's header: "▬ Work"): the day bar's shaded
/// capsule, 16 × 8, then the name at 12 medium. Colour is never alone: the name goes with it.
public struct CategoryMark: View {
    @ScaledMetric(relativeTo: .caption) private var swatchWidth: CGFloat = 16
    private let category: PlaceCategory

    public init(_ category: PlaceCategory) {
        self.category = category
    }

    public var body: some View {
        HStack(spacing: Space.xs) {
            Capsule()
                .fill(DayBarView.shaded(category.color, glint: category.glint))
                .frame(width: swatchWidth, height: swatchWidth / 2)
            Text(verbatim: category.name)
                .textRole(.footnote, weight: .medium)
                .foregroundStyle(Palette.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}

/// One of a sheet's actions as a tile (Visit edit: "Change place", "Split this visit",
/// "Merge with next visit"): white, corners 20, the card's shadow; its glyph in a well 12 from
/// the top, the name under it (14 medium, centred, up to two lines), 12 from the foot. On (a
/// split or merge waiting for Save) it turns navy with white words, as a filter chip does;
/// unavailable, it dims. Measured from the screenshot at 393 × 852: 91 tall, three to a row,
/// 6.7 apart.
public struct ActionTile: View {
    @ScaledMetric(relativeTo: .subheadline) private var minHeight: CGFloat = 91
    private let title: String
    private let glyph: Image
    private let isOn: Bool
    private let hint: String?
    private let action: () -> Void

    public init(_ title: String, glyph: Image, isOn: Bool = false, hint: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.glyph = glyph
        self.isOn = isOn
        self.hint = hint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: Space.xs) {
                IconWell {
                    glyph
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Palette.textPrimary)
                }
                Text(verbatim: title)
                    .textRole(.caption, weight: .medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(isOn ? Palette.inverseText : Palette.textPrimary)
            }
            .padding(.top, 12)
            .padding(.bottom, 12)
            .padding(.horizontal, Space.xs)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .contentShape(.rect(cornerRadius: Radius.xl))
        }
        .buttonStyle(ActionTileStyle(isOn: isOn))
        .accessibilityLabel(title)
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityHint(hint.map { Text(verbatim: $0) } ?? Text(verbatim: ""))
    }
}

private struct ActionTileStyle: ButtonStyle {
    let isOn: Bool
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .card(radius: Radius.xl, fill: isOn ? Palette.inverseSurface : Palette.surface)
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
            .motion(value: isOn)
    }
}

/// A place's neighbourhood as a cluster of cells around it (Visit edit, 14 Nov): 37 pointy-top
/// hexagons in rings round the place, deepest at the middle, seams of the page's white between
/// them. Measured from the screenshot: 18.9 across (circumradius 10.9), rows 16.4 apart, seven
/// rows; the middle cell and the first ring take the deep shade, the second ring the middle
/// one, the outside ring the light one.
///
/// Work's three pinks are the design's (`visitCellDeep`, `…Mid`, `…Light`); other categories
/// derive theirs from their own colour until their designs say. The cells grow in from the
/// middle, ring by ring, when the cluster appears (`Motion.reveal`); under Reduce Motion they
/// fade in together.
public struct HexCluster: View {
    /// The cells' circumradius.
    public static let radius: CGFloat = 10.9
    public static let rings = 3
    /// The cluster's size: seven cells across, seven rows down.
    public static var size: CGSize {
        let pitch = radius * 3.squareRoot()
        return CGSize(width: pitch * CGFloat(2 * rings + 1), height: radius * 1.5 * CGFloat(2 * rings) + radius * 2)
    }

    private let category: PlaceCategory
    @Environment(\.self) private var environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    public init(_ category: PlaceCategory) {
        self.category = category
    }

    public var body: some View {
        let shades = shades
        let size = Self.size
        ZStack {
            ForEach(Self.cells.indices, id: \.self) { index in
                let cell = Self.cells[index]
                HexCell()
                    .fill(shades[min(max(cell.ring - 1, 0), shades.count - 1)])
                    .overlay {
                        HexCell().stroke(Palette.surface, lineWidth: 1)
                    }
                    .frame(width: Self.radius * 3.squareRoot(), height: Self.radius * 2)
                    .scaleEffect(shown || reduceMotion ? 1 : 0.4)
                    .opacity(shown ? 1 : 0)
                    .animation(
                        reduceMotion ? Motion.reduced : Motion.reveal.delay(Double(cell.ring) * 0.07),
                        value: shown)
                    .position(x: size.width / 2 + cell.center.x, y: size.height / 2 + cell.center.y)
            }
        }
        .frame(width: size.width, height: size.height)
        .onAppear { shown = true }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Deep (the middle and the first ring), middle, light.
    private var shades: [Color] {
        if category == .work {
            return [Palette.visitCellDeep, Palette.visitCellMid, Palette.visitCellLight]
        }
        let base = category.color.resolve(in: environment)
        return [Self.mix(base, toward: 0, by: 0.22), Self.mix(base, toward: 0, by: 0.1), Self.mix(base, toward: 1, by: 0.25)]
    }

    /// The colour moved toward black (0) or white (1), in linear light.
    private static func mix(_ color: Color.Resolved, toward target: Float, by amount: Float) -> Color {
        func blend(_ value: Float) -> Float { value + (target - value) * amount }
        return Color(Color.Resolved(
            colorSpace: .sRGBLinear,
            red: blend(color.linearRed), green: blend(color.linearGreen), blue: blend(color.linearBlue),
            opacity: color.opacity))
    }

    private nonisolated struct Cell {
        var center: CGPoint
        var ring: Int
    }

    /// Every cell within `rings` of the middle, on axial coordinates.
    private static let cells: [Cell] = {
        var cells: [Cell] = []
        let pitch = radius * 3.squareRoot()
        for row in -rings...rings {
            for column in max(-rings, -row - rings)...min(rings, -row + rings) {
                let ring = max(abs(column), abs(row), abs(column + row))
                let x = pitch * (CGFloat(column) + CGFloat(row) / 2)
                let y = radius * 1.5 * CGFloat(row)
                cells.append(Cell(center: CGPoint(x: x, y: y), ring: ring))
            }
        }
        return cells
    }()
}

/// A pointy-top hexagon filling its frame's height.
nonisolated private struct HexCell: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = rect.height / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        for corner in 0..<6 {
            let angle = (Double(corner) * 60 - 90) * .pi / 180
            let point = CGPoint(x: center.x + radius * CGFloat(cos(angle)), y: center.y + radius * CGFloat(sin(angle)))
            if corner == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

#Preview("Cluster · work and food & drink") {
    HStack {
        HexCluster(.work)
        HexCluster(.foodAndDrink)
    }
    .padding()
    .background(Color(white: 0.96))
}
