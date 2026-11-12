import Accessibility
import DwellCore
import SwiftUI

/// "Every hour of the week" (Time design): the hours across the top (4AM, 10AM, 4PM, 10PM,
/// 4AM), a row per day with its weekday, each stretch of the day a rounded bar in its
/// category's colour, gaps hatched; a dashed line; the legend.
///
/// Measured from the screenshot (393 pt): weekday labels 14 grey in a 37-pt column; rows 20
/// tall, 4 apart, stretches 2 apart with 4-pt corners; axis labels 14 grey, 8 above the first
/// row; 12 to the dashed line and 12 more to the legend (12 in ink, swatches 12 × 6, 4 to their
/// names, 16 between items, lines 10 apart, 8 in from the rows). A month has a thin row a day
/// (8 tall, 3 apart, labelled on Mondays); a year a row a month (16 tall), each its typical day.
///
/// Stretches keep their time, but never shrink below 5 pt, so a short stop stays visible
/// (`HourGrid.layout`). They carry the day bar's glint, so the two read as one family.
///
/// Tap a stretch to read it ("Work · 8:41 AM – 12:34 PM · 3h 53m"), or a legend item to pick its
/// category out across the grid (brief A.4: tappable, category filters); tap again to let go.
/// The rows sweep in from 4 AM on appear (`Motion.reveal`); under Reduce Motion they fade in.
/// VoiceOver reads each row's time by category and offers an audio graph.
public struct HourGridView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .subheadline) private var labelWidth: CGFloat = 37
    @ScaledMetric(relativeTo: .caption) private var swatchWidth: CGFloat = 12
    @State private var selection: Selection?
    @State private var grown = false

    private let grid: HourGrid
    private let this: String

    /// What's picked out: a category everywhere, and the stretch tapped, if one was.
    struct Selection: Equatable {
        var kind: HourGrid.Kind
        var row: String?
        var index: Int?
    }

    /// - Parameter this: the period in words, for the callout's total: "this week".
    public init(_ grid: HourGrid, this: String) {
        self.grid = grid
        self.this = this
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            axis
            rows
                .padding(.top, Space.s)
            DashedDivider()
                .padding(.top, Space.m)
            if let selection {
                callout(selection)
                    .padding(.top, Space.m)
                    .padding(.horizontal, Space.s)
                    .transition(.opacity)
            }
            legend
                .padding(.top, Space.m)
        }
        .motion(value: selection)
        .onAppear { grown = true }
        .accessibilityElement(children: .contain)
        .accessibilityChartDescriptor(HourGridChartDescriptor(
            title: TimeCopy.gridTitle(grid.period.range),
            rows: grid.rows.map(spokenLabel),
            series: grid.legend.map { kind in
                (name: kind.name, minutes: grid.rows.map { (($0.totals[kind] ?? 0) / 60).rounded(.down) })
            }))
    }

    // MARK: Metrics

    private var rowHeight: CGFloat {
        switch grid.period.range {
        case .day, .week: 20
        case .month: 8
        case .year: 16
        }
    }

    private var rowSpacing: CGFloat {
        grid.period.range == .month ? 3 : Space.xs
    }

    private var corner: CGFloat {
        min(4, rowHeight / 4)
    }

    // MARK: Axis

    private var axis: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: labelWidth, height: 1)
            AxisLayout(fractions: [0, 0.25, 0.5, 0.75, 1]) {
                ForEach(Array([0, 6, 12, 18, 24].enumerated()), id: \.offset) { _, hours in
                    Text(verbatim: ClockText.hour((DwellDay.startHour + hours) % 24, calendar: calendar))
                        .textRole(.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize()
                }
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: Rows

    private var rows: some View {
        VStack(spacing: rowSpacing) {
            ForEach(grid.rows) { row in
                HStack(spacing: 0) {
                    Color.clear
                        .frame(width: labelWidth, height: rowHeight)
                        .overlay(alignment: .leading) {
                            if let label = label(row) {
                                Text(verbatim: label)
                                    .textRole(grid.period.range == .month ? .footnote : .caption)
                                    .foregroundStyle(Palette.textSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    bar(row)
                        .frame(height: rowHeight)
                        .scaleEffect(x: grown || reduceMotion ? 1 : 0.001, anchor: .leading)
                        .opacity(grown ? 1 : 0)
                        .motion(Motion.reveal, value: grown)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(spokenLabel(row))
                .accessibilityValue(spokenValue(row))
            }
        }
    }

    private func bar(_ row: HourGrid.Row) -> some View {
        GeometryReader { proxy in
            let spans = HourGrid.layout(row.segments, width: Double(proxy.size.width), minWidth: 5, spacing: 2)
            ZStack(alignment: .topLeading) {
                ForEach(Array(row.segments.enumerated()), id: \.offset) { index, segment in
                    let span = spans[index]
                    GridSegment(kind: segment.kind, radius: corner)
                        .frame(width: CGFloat(max(0, span.upperBound - span.lowerBound)), height: proxy.size.height)
                        .offset(x: CGFloat(span.lowerBound))
                        .opacity(isDimmed(segment.kind) ? 0.25 : 1)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .contentShape(.rect)
            .onTapGesture { location in
                let x = Double(location.x)
                guard let index = spans.firstIndex(where: { $0.lowerBound - 1 <= x && x <= $0.upperBound + 1 }) else {
                    selection = nil
                    return
                }
                let picked = Selection(kind: row.segments[index].kind, row: row.id, index: index)
                selection = picked == selection ? nil : picked
            }
        }
    }

    private func isDimmed(_ kind: HourGrid.Kind) -> Bool {
        guard let selection else { return false }
        return selection.kind != kind
    }

    // MARK: Legend and callout

    private var legend: some View {
        FlowLayout(alignment: .leading, spacing: Space.l, lineSpacing: 10) {
            ForEach(grid.legend) { kind in
                Button {
                    let picked = Selection(kind: kind)
                    selection = selection == picked ? nil : picked
                } label: {
                    HStack(spacing: Space.xs) {
                        GridSegment(kind: kind, radius: swatchWidth / 4)
                            .frame(width: swatchWidth, height: swatchWidth / 2)
                        Text(verbatim: kind.name)
                            .textRole(.footnote)
                            .foregroundStyle(Palette.textPrimary)
                    }
                    .opacity(isDimmed(kind) ? 0.4 : 1)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(kind.name)
                .accessibilityHint("Picks it out in the chart") // [COPY NEEDED]
                .accessibilityAddTraits(selection?.kind == kind ? .isSelected : [])
            }
        }
        .padding(.horizontal, Space.s)
    }

    private func callout(_ selection: Selection) -> some View {
        HStack(spacing: Space.xs) {
            GridSegment(kind: selection.kind, radius: swatchWidth / 4)
                .frame(width: swatchWidth, height: swatchWidth / 2)
            Text(verbatim: selection.kind.name)
                .textRole(.footnote)
                .foregroundStyle(Palette.textPrimary)
            Text(verbatim: "· \(detail(selection))")
                .textRole(.footnote, monospacedDigits: true)
                .foregroundStyle(Palette.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    /// A stretch's times and length, or the category's whole time in the period.
    private func detail(_ selection: Selection) -> String {
        if let rowID = selection.row, let index = selection.index,
           let row = grid.rows.first(where: { $0.id == rowID }), row.segments.indices.contains(index) {
            let segment = row.segments[index]
            if let span = segment.span {
                return "\(ClockText.span(from: span.start, to: span.end, calendar: calendar)) · \(DurationText.short(span.duration))"
            }
            let start = row.day.start(in: calendar)
            let from = start.addingTimeInterval(segment.start * 86_400)
            let to = start.addingTimeInterval(segment.end * 86_400)
            return "usually \(ClockText.span(from: from, to: to, calendar: calendar))" // [COPY NEEDED]
        }
        let total = grid.rows.reduce(0) { $0 + ($1.totals[selection.kind] ?? 0) }
        return "\(DurationText.short(total)) \(this)"
    }

    // MARK: Words

    /// "Mon" for a day, "1" or "5" on the first and on Mondays in a month, "Jan" for a year.
    private func label(_ row: HourGrid.Row) -> String? {
        let date = row.day.start(in: calendar)
        switch grid.period.range {
        case .day, .week:
            return date.formatted(style.weekday(.abbreviated))
        case .month:
            let weekday = calendar.component(.weekday, from: date)
            return weekday == 2 || row.day.day == 1 ? "\(row.day.day)" : nil
        case .year:
            return date.formatted(style.month(.abbreviated))
        }
    }

    private func spokenLabel(_ row: HourGrid.Row) -> String {
        let date = row.day.start(in: calendar)
        switch grid.period.range {
        case .day, .week, .month: return date.formatted(style.weekday(.wide).month(.wide).day())
        case .year: return "A typical day in \(date.formatted(style.month(.wide)))" // [COPY NEEDED]
        }
    }

    private func spokenValue(_ row: HourGrid.Row) -> String {
        guard !row.isEmpty else { return TimeCopy.notRecorded }
        return grid.legend
            .compactMap { kind in
                guard let total = row.totals[kind], total >= 60 else { return nil }
                return "\(kind.name), \(DurationText.spoken(total))"
            }
            .joined(separator: "; ")
    }

    private var style: Date.FormatStyle {
        Date.FormatStyle(locale: calendar.locale ?? .current, calendar: calendar, timeZone: calendar.timeZone)
    }
}

/// One stretch of a row, or a legend swatch: the category's colour with the day bar's glint,
/// Everything else its grey, a gap hollow with grey stripes (Time design: "Gap").
struct GridSegment: View {
    let kind: HourGrid.Kind
    let radius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius)
        switch kind {
        case .bucket(.category(let category)):
            shape.fill(DayBarView.shaded(category.color, glint: category.glint))
        case .bucket(.everythingElse):
            shape.fill(DayBarView.shaded(Palette.everythingElse, glint: Palette.everythingElseGlint))
        case .gap:
            shape
                .fill(Palette.surface)
                .overlay {
                    DiagonalStripes(spacing: 4)
                        .stroke(Palette.unmapped, lineWidth: 0.8)
                        .clipShape(shape)
                }
                .overlay {
                    shape.strokeBorder(Palette.unmapped, lineWidth: 0.75)
                }
        }
    }
}

/// Places each label centred on its share of the width, nudged in at the ends so the first
/// sits at the start and the last at the end (4AM … 4AM).
private struct AxisLayout: Layout {
    let fractions: [CGFloat]

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let height = subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (index, subview) in subviews.enumerated() where fractions.indices.contains(index) {
            let size = subview.sizeThatFits(.unspecified)
            let centre = bounds.minX + fractions[index] * bounds.width
            let x = min(max(bounds.minX, centre - size.width / 2), bounds.maxX - size.width)
            subview.place(at: CGPoint(x: x, y: bounds.minY), proposal: ProposedViewSize(size))
        }
    }
}

/// The grid as an audio graph: one series per legend item, minutes per row.
nonisolated private struct HourGridChartDescriptor: AXChartDescriptorRepresentable {
    let title: String
    let rows: [String]
    let series: [(name: String, minutes: [Double])]

    func makeChartDescriptor() -> AXChartDescriptor {
        let top = series.flatMap(\.minutes).max() ?? 0
        let xAxis = AXCategoricalDataAxisDescriptor(title: "Day", categoryOrder: rows)
        let yAxis = AXNumericDataAxisDescriptor(
            title: "Minutes",
            range: 0 ... max(top, 1),
            gridlinePositions: []
        ) { value in "\(Int(value)) minutes" }
        let described = series.map { item in
            AXDataSeriesDescriptor(
                name: item.name,
                isContinuous: false,
                dataPoints: zip(rows, item.minutes).map { AXDataPoint(x: $0, y: $1) })
        }
        return AXChartDescriptor(title: title, summary: nil, xAxis: xAxis, yAxis: yAxis, additionalAxes: [], series: described)
    }
}
