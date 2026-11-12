import DwellCore
import SwiftUI

/// A category's glyph on a disc of its colour (Time design: "All categories", "Places over
/// time"): 32 across, the flat glyph 18 in navy. The glyph stays navy in dark mode, where the
/// disc keeps a light enough colour to carry it. Decorative: the row always names the category.
public struct CategoryBadge: View {
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 32
    @ScaledMetric(relativeTo: .body) private var glyph: CGFloat = 18
    private let category: PlaceCategory

    public init(_ category: PlaceCategory) {
        self.category = category
    }

    public var body: some View {
        Circle()
            .fill(category.color)
            .frame(width: size, height: size)
            .overlay {
                CategoryIcon(category, style: .glyph)
                    .foregroundStyle(Palette.textPrimary)
                    .frame(width: glyph, height: glyph)
                    .environment(\.colorScheme, .light)
            }
            .accessibilityHidden(true)
    }
}

/// "↑ 2h 44m longer than usual" (Time design): an arrow 8 from the words, 14, grey. A plain
/// line, the same at every dial position, like a timeline row.
public struct DeltaLine: View {
    public enum Direction: Sendable {
        case up
        case down
        /// No arrow: the same as usual, or not a change at all ("Not since Sep 26").
        case flat
    }

    private let text: String
    private let direction: Direction

    public init(_ text: String, direction: Direction) {
        self.text = text
        self.direction = direction
    }

    /// The line for a signed change from usual: up, down, or the same.
    public init(delta: TimeInterval) {
        self.init(TimeCopy.delta(delta), direction: abs(delta) < 60 ? .flat : delta > 0 ? .up : .down)
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.s) {
            if direction != .flat {
                Image(systemName: direction == .up ? "arrow.up" : "arrow.down")
                    .accessibilityHidden(true)
            }
            Text(verbatim: text)
        }
        .textRole(.caption)
        .foregroundStyle(Palette.textSecondary)
    }
}

/// A category's row in Time's "All categories" (Time design): its badge, the name (18 medium)
/// over how it compares with usual, and its time (the clock, then 18 medium) at the trailing
/// edge, the two lines centred on the badge. A category whose places say more (Food & drink:
/// Coffee, Drinks, Food) has a chevron by its time that opens them under it, joined to the
/// badge by a dashed line.
///
/// Measured from the design at 4×: badge 32, 8 to the text; the name's and the delta's
/// baselines 24 apart; breakdown rows 26 apart (16 medium, their glyph 18), 14 below the delta.
/// Tapping the row opens the category; the chevron only opens and closes it. At accessibility
/// sizes the time moves under the name.
public struct CategoryRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var lineHeight: CGFloat = 22
    @ScaledMetric(relativeTo: .callout) private var partGlyph: CGFloat = 18
    @ScaledMetric(relativeTo: .callout) private var clock: CGFloat = 14
    @Binding private var isExpanded: Bool
    private let line: TimeReport.Line
    private let onOpen: () -> Void

    public init(_ line: TimeReport.Line, isExpanded: Binding<Bool>, onOpen: @escaping () -> Void) {
        self.line = line
        _isExpanded = isExpanded
        self.onOpen = onOpen
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                Button(action: onOpen) { summary }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(spokenSummary)
                    .accessibilityHint("Opens \(line.category.name)")
                if !line.parts.isEmpty {
                    chevron
                }
            }
            if isExpanded, !line.parts.isEmpty {
                parts
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .motion(value: isExpanded)
    }

    private var summary: some View {
        let large = dynamicTypeSize.isAccessibilitySize
        let total = DurationText.short(line.total)
        return HStack(alignment: .center, spacing: Space.s) {
            CategoryBadge(line.category)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: Space.s) {
                    Text(verbatim: line.category.name)
                        .textRole(.rowTitle)
                        .foregroundStyle(Palette.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !large {
                        DurationTrail(total, showsChevron: false, isLarge: true)
                    }
                }
                if large {
                    DurationTrail(total, showsChevron: false, isLarge: true)
                }
                if let delta = line.delta {
                    DeltaLine(delta: delta)
                }
            }
        }
        .contentShape(.rect)
    }

    /// The design's thin chevron, 6 from the time, on the name's line; 44 to tap.
    private var chevron: some View {
        Button {
            isExpanded.toggle()
        } label: {
            Image(systemName: "chevron.up")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Palette.textSecondary)
                .rotationEffect(.degrees(isExpanded ? 0 : 180))
                .frame(width: 28, height: lineHeight)
                .frame(minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(.top, (lineHeight - 44) / 2)
        .padding(.trailing, -6)
        .accessibilityLabel(isExpanded ? "Hide \(line.category.name)'s places" : "Show \(line.category.name)'s places") // [COPY NEEDED]
        .accessibilityAddTraits(isExpanded ? .isSelected : [])
    }

    private var parts: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(line.parts) { part in
                HStack(spacing: Space.s) {
                    SubcategoryGlyph(part.subcategory)
                        .frame(width: partGlyph, height: partGlyph)
                    Text(verbatim: part.subcategory.name)
                        .textRole(.body)
                        .foregroundStyle(Palette.textPrimary)
                    Spacer(minLength: Space.s)
                    HStack(spacing: 6) {
                        Art.clock
                            .resizable()
                            .scaledToFit()
                            .frame(width: clock, height: clock)
                            .accessibilityHidden(true)
                        Text(verbatim: DurationText.short(part.total))
                            .textRole(.body, monospacedDigits: true)
                    }
                    .foregroundStyle(Palette.textPrimary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(part.subcategory.name), \(DurationText.spoken(part.total))")
            }
        }
        .padding(.leading, 40)
        .padding(.top, 14)
        .padding(.bottom, Space.xs)
        .background(alignment: .topLeading) {
            // From under the badge down the breakdown, through the badge's middle.
            VerticalDashedLine()
                .frame(width: 1)
                .frame(maxHeight: .infinity)
                .padding(.leading, 15.5)
                .padding(.top, -6)
        }
    }

    private var spokenSummary: String {
        var parts = [line.category.name, DurationText.spoken(line.total)]
        if let delta = line.delta {
            parts.append(TimeCopy.delta(delta))
        }
        return parts.joined(separator: ", ")
    }
}

/// A subcategory's glyph: the design's takeaway cup, cocktail glass and doughnut.
/// [ICON NEEDED] SF Symbols stand in until the design's glyphs arrive.
public struct SubcategoryGlyph: View {
    private let subcategory: PlaceSubcategory

    public init(_ subcategory: PlaceSubcategory) {
        self.subcategory = subcategory
    }

    public var body: some View {
        Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Palette.textPrimary)
            .accessibilityHidden(true)
    }

    private var symbol: String {
        switch subcategory {
        case .coffee: "mug.fill"
        case .drinks: "wineglass.fill"
        case .food: "fork.knife"
        }
    }
}

/// A place in "Places over time" (Time design): its category's badge, the name over its time in
/// the last four weeks, and the change at the trailing edge ("↑ 40%"), or "Paused" with a
/// pause mark and "Not since Sep 26" for a place you stopped going to.
public struct PlaceTrendRow: View {
    @Environment(\.calendar) private var calendar
    private let trend: PlaceTrend

    public init(_ trend: PlaceTrend) {
        self.trend = trend
    }

    public var body: some View {
        HStack(alignment: .center, spacing: Space.s) {
            CategoryBadge(trend.category)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: Space.s) {
                    Text(verbatim: trend.name)
                        .textRole(.body)
                        .foregroundStyle(Palette.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    trailing
                }
                detail
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    @ViewBuilder
    private var trailing: some View {
        if trend.isPaused {
            HStack(spacing: Space.xs) {
                Image(systemName: "pause.circle")
                    .accessibilityHidden(true)
                Text(verbatim: TimeCopy.paused)
            }
            .textRole(.body)
            .foregroundStyle(Palette.textPrimary)
        } else if let change = trend.change {
            HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
                Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                    .textRole(.caption, weight: .medium)
                    .accessibilityHidden(true)
                Text(verbatim: TimeCopy.change(change))
                    .textRole(.body, monospacedDigits: true)
            }
            .foregroundStyle(Palette.textPrimary)
        }
    }

    @ViewBuilder
    private var detail: some View {
        if trend.isPaused, let lastSeen = trend.lastSeen {
            DeltaLine(TimeCopy.notSince(lastSeen, calendar: calendar), direction: .flat)
        } else {
            DeltaLine(TimeCopy.recent(trend.recent), direction: (trend.change ?? 0) >= 0 ? .up : .down)
        }
    }

    private var spoken: String {
        if trend.isPaused, let lastSeen = trend.lastSeen {
            return "\(trend.name), \(TimeCopy.paused), \(TimeCopy.notSince(lastSeen, calendar: calendar))"
        }
        let change = trend.change.map { "\($0 >= 0 ? "up" : "down") \(TimeCopy.change($0))" } ?? ""
        return [trend.name, change, "\(DurationText.spoken(trend.recent)) in the last 4 weeks"]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

/// A dashed line down: the breakdown's thread back to its badge. 1 pt, dash 3/3, `separator`.
public struct VerticalDashedLine: View {
    public init() {}

    public var body: some View {
        VerticalLine()
            .stroke(Palette.separator, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            .accessibilityHidden(true)
    }
}

nonisolated private struct VerticalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}
