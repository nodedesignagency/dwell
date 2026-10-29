import Accessibility
import Charts
import DwellCore
import SwiftUI

/// The day bar (brief §7.1, Today design): the day so far as a strip of slim ticks, one colour
/// per category in display order, unmapped time hatched at the end, and a legend.
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
        VStack(spacing: Space.s) {
            GeometryReader { proxy in
                let count = Int((proxy.size.width + Self.tickSpacing) / (Self.tickWidth + Self.tickSpacing))
                ticks(bar.ticks(max(count, 1)), width: proxy.size.width)
            }
            .frame(height: Self.height)
            .padding(.bottom, Space.xs)

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
        .padding(9)
        .overlay {
            RoundedRectangle(cornerRadius: Radius.l)
                .strokeBorder(Palette.separator, lineWidth: 1)
        }
        .onAppear { grown = true }
        .motion(Motion.reveal, value: grown)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(spokenParts)
        .accessibilityChartDescriptor(DayBarChartDescriptor(title: title, parts: bar.parts))
    }

    // MARK: Ticks

    private struct Tick: Identifiable {
        let id: Int
        let segment: DayBar.Segment
    }

    private func ticks(_ segments: [DayBar.Segment], width: CGFloat) -> some View {
        let ticks = segments.enumerated().map { Tick(id: $0.offset, segment: $0.element) }
        let count = max(ticks.count, 1)
        // Under Reduce Motion the bar never grows; the fade is the whole transition.
        let height = grown || reduceMotion ? 1.0 : 0.0
        return Chart(ticks) { tick in
            BarMark(
                x: .value("Time of day", Double(tick.id)),
                yStart: .value("Base", 0),
                yEnd: .value("Top", height),
                width: .fixed(Self.tickWidth))
                .foregroundStyle(Self.style(for: tick.segment))
                .cornerRadius(Self.tickWidth / 2)
                .opacity(selection == nil || selection == tick.segment ? 1 : 0.25)
        }
        .chartXScale(domain: -0.5 ... Double(count) - 0.5)
        .chartYScale(domain: 0 ... 1)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .opacity(grown ? 1 : 0)
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
        Capsule()
            .fill(Self.style(for: segment))
            .frame(width: swatchWidth, height: swatchWidth / 2)
    }

    // MARK: Colour

    /// Category colour; "Everything else" its own grey; unmapped a pale hatch, so a gap
    /// never looks like a category. Names always travel with these in the legend.
    static func style(for segment: DayBar.Segment) -> AnyShapeStyle {
        switch segment {
        case .bucket(.category(let category)): AnyShapeStyle(category.color)
        case .bucket(.everythingElse): AnyShapeStyle(Palette.everythingElse)
        case .unmapped: AnyShapeStyle(hatch)
        }
    }

    private static let hatch: LinearGradient = {
        let bands = 14
        let stops = (0..<bands).flatMap { band -> [Gradient.Stop] in
            let color = band.isMultiple(of: 2) ? Palette.gap : Palette.gap.opacity(0.4)
            return [
                Gradient.Stop(color: color, location: Double(band) / Double(bands)),
                Gradient.Stop(color: color, location: Double(band + 1) / Double(bands)),
            ]
        }
        return LinearGradient(stops: stops, startPoint: .topLeading, endPoint: .bottomTrailing)
    }()

    private var spokenParts: String {
        bar.parts.map { "\($0.segment.name), \(DurationText.spoken($0.duration))" }.joined(separator: "; ")
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
