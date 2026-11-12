import Accessibility
import DwellCore
import SwiftUI

/// The day bar (brief §7.1, Today design): the day so far as a strip of slim ticks, one colour
/// per category in display order, gaps as hollow striped ticks at the end, and a legend, in a
/// box with an ink-5% border.
///
/// Each tick (and legend swatch) carries the design's five stacked inner shadows in its
/// category's glint, so it catches light along its top edge. The ticks are SwiftUI shapes
/// rather than Swift Charts marks: inner shadows are a SwiftUI shape style Charts doesn't
/// draw, and the bar's VoiceOver and audio graph were already its own.
///
/// Tap or scrub (press, then slide) to swap the legend for a callout with that part's time.
/// The ticks grow in when the bar appears; under Reduce Motion they fade in instead.
/// VoiceOver reads every part and offers an audio graph.
public struct DayBarView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .caption) private var swatchWidth: CGFloat = 12
    @State private var selection: DayBar.Segment?
    @State private var grown = false

    private let bar: DayBar
    private let title: String

    static let tickWidth: CGFloat = 4
    static let tickSpacing: CGFloat = 2
    static let height: CGFloat = 32

    /// - Parameter title: what the bar is of, for VoiceOver: "Today so far".
    public init(_ bar: DayBar, title: String) {
        self.bar = bar
        self.title = title
    }

    public var body: some View {
        VStack(spacing: 10) {
            GeometryReader { proxy in
                let count = Int((proxy.size.width + Self.tickSpacing) / (Self.tickWidth + Self.tickSpacing))
                ticks(bar.ticks(max(count, 1)), width: proxy.size.width)
            }
            .frame(height: Self.height)

            DashedDivider()

            Group {
                if let selection, let part = bar.parts.first(where: { $0.segment == selection }) {
                    callout(part)
                } else {
                    legend
                }
            }
            .frame(minHeight: 16)
        }
        .padding(Space.s)
        .background(Palette.surface, in: .rect(cornerRadius: Radius.box))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.box)
                .strokeBorder(Palette.outline, lineWidth: 1)
        }
        .onAppear { grown = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(spokenParts)
        .accessibilityChartDescriptor(DayBarChartDescriptor(title: title, parts: bar.parts))
    }

    // MARK: Ticks

    private func ticks(_ segments: [DayBar.Segment], width: CGFloat) -> some View {
        // Under Reduce Motion the bar never grows; the fade is the whole transition.
        let height = grown || reduceMotion ? 1.0 : 0.001
        return HStack(spacing: Self.tickSpacing) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                Self.capsule(segment)
                    .frame(width: Self.tickWidth)
                    .scaleEffect(x: 1, y: height, anchor: .bottom)
                    .opacity(selection == nil || selection == segment ? 1 : 0.25)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .drawingGroup()
        .opacity(grown ? 1 : 0)
        // Only the ticks animate: on the whole box, its first layout grew in too.
        .motion(Motion.reveal, value: grown)
        .contentShape(.rect)
        .onTapGesture { location in
            let segment = segment(at: location.x, width: width, in: segments)
            selection = segment == selection ? nil : segment
        }
        .gesture(
            LongPressGesture(minimumDuration: 0.2)
                .sequenced(before: DragGesture(minimumDistance: 0))
                .onChanged { value in
                    if case .second(true, let drag?) = value {
                        selection = segment(at: drag.location.x, width: width, in: segments)
                    }
                })
    }

    private func segment(at x: CGFloat, width: CGFloat, in segments: [DayBar.Segment]) -> DayBar.Segment? {
        guard !segments.isEmpty, width > 0 else { return nil }
        let index = Int(x / width * CGFloat(segments.count))
        return segments[min(max(index, 0), segments.count - 1)]
    }

    // MARK: Legend and callout

    private var legend: some View {
        FlowLayout(alignment: .center, spacing: Space.s, lineSpacing: Space.xs) {
            ForEach(bar.parts) { part in
                HStack(spacing: Space.xs) {
                    swatch(part.segment)
                    Text(verbatim: part.segment.name)
                        .textRole(.footnote)
                        .foregroundStyle(Palette.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func callout(_ part: DayBar.Part) -> some View {
        HStack(spacing: Space.xs) {
            swatch(part.segment)
            Text(verbatim: part.segment.name)
                .textRole(.footnote)
                .foregroundStyle(Palette.textPrimary)
            Text(verbatim: "· \(DurationText.short(part.duration))")
                .monospacedDigit()
                .textRole(.footnote)
                .foregroundStyle(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func swatch(_ segment: DayBar.Segment) -> some View {
        Self.capsule(segment)
            .frame(width: swatchWidth, height: swatchWidth / 2)
    }

    // MARK: Colour

    /// A tick or swatch: the category's colour with its glint; "Everything else" its own grey;
    /// unmapped hollow and striped, so it never looks like a category. Names always travel
    /// with these in the legend.
    @ViewBuilder
    static func capsule(_ segment: DayBar.Segment) -> some View {
        switch segment {
        case .bucket(.category(let category)):
            Capsule().fill(shaded(category.color, glint: category.glint))
        case .bucket(.everythingElse):
            Capsule().fill(shaded(Palette.everythingElse, glint: Palette.everythingElseGlint))
        case .unmapped:
            UnmappedCapsule()
        }
    }

    /// The design's tick: five inner shadows in the glint, all at x 0 and spread 0, stacked
    /// from a faint wash 13 pt down to a crisp 1 pt line at the top edge. Figma blur is twice
    /// SwiftUI's shadow radius.
    private static func shaded(_ fill: Color, glint: Color) -> some ShapeStyle {
        fill
            .shadow(.inner(color: glint.opacity(0.01), radius: 2, x: 0, y: 13))
            .shadow(.inner(color: glint.opacity(0.05), radius: 1.5, x: 0, y: 8))
            .shadow(.inner(color: glint.opacity(0.18), radius: 1.5, x: 0, y: 5))
            .shadow(.inner(color: glint.opacity(0.30), radius: 1, x: 0, y: 2))
            .shadow(.inner(color: glint.opacity(0.35), radius: 0.5, x: 0, y: 1))
    }

    private var spokenParts: String {
        bar.parts.map { "\($0.segment.name), \(DurationText.spoken($0.duration))" }.joined(separator: "; ")
    }
}

/// Unmapped time (Today design): a hollow capsule with diagonal stripes, outline and stripes
/// both #DADADA at 80% (`Palette.unmapped`).
private struct UnmappedCapsule: View {
    var body: some View {
        Capsule()
            .fill(Palette.surface)
            .overlay {
                DiagonalStripes(spacing: 2.6)
                    .stroke(Palette.unmapped, lineWidth: 0.8)
                    .clipShape(Capsule())
            }
            .overlay {
                Capsule().strokeBorder(Palette.unmapped, lineWidth: 0.75)
            }
    }
}

/// Parallel lines running down to the right at 45°, `spacing` apart along the width.
nonisolated private struct DiagonalStripes: Shape {
    var spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var x = rect.minX - rect.height
        while x < rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x + rect.height, y: rect.maxY))
            x += spacing
        }
        return path
    }
}

/// The day bar as an audio graph: one point per part, minutes on the y-axis.
nonisolated private struct DayBarChartDescriptor: AXChartDescriptorRepresentable {
    let title: String
    let names: [String]
    let minutes: [Double]

    init(title: String, parts: [DayBar.Part]) {
        self.title = title
        names = parts.map(\.segment.name)
        minutes = parts.map { ($0.duration / 60).rounded(.down) }
    }

    func makeChartDescriptor() -> AXChartDescriptor {
        let xAxis = AXCategoricalDataAxisDescriptor(title: "Part of the day", categoryOrder: names)
        let yAxis = AXNumericDataAxisDescriptor(
            title: "Minutes",
            range: 0 ... max(minutes.max() ?? 0, 1),
            gridlinePositions: []
        ) { value in "\(Int(value)) minutes" }
        let series = AXDataSeriesDescriptor(
            name: title,
            isContinuous: false,
            dataPoints: zip(names, minutes).map { AXDataPoint(x: $0, y: $1) })
        return AXChartDescriptor(title: title, summary: nil, xAxis: xAxis, yAxis: yAxis, additionalAxes: [], series: [series])
    }
}
