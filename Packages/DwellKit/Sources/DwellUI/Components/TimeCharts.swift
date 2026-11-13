import Accessibility
import Charts
import DwellCore
import SwiftUI

/// Work and yours, period by period (Time design, "Work and Yours"): a pair of bars for each of
/// the last four weeks, work in its pink and yours in green, the earlier ones faded to 40% and
/// the one being shown at full strength, its label in ink. Two numbers side by side, never a
/// ratio (brief §7.3).
///
/// Measured from the screenshot: bars 24 wide, 2 apart in a pair, 6-pt corners; labels 14 grey.
/// Swift Charts gives each bar a VoiceOver label and the chart an audio graph.
public struct TrendBars: View {
    public struct Period: Identifiable, Hashable, Sendable {
        public var id: String
        /// "Oct 5", "This week".
        public var label: String
        public var work: TimeInterval
        public var yours: TimeInterval
        /// The period Time is showing: drawn at full strength.
        public var isShown: Bool

        public init(id: String, label: String, work: TimeInterval, yours: TimeInterval, isShown: Bool) {
            self.id = id
            self.label = label
            self.work = work
            self.yours = yours
            self.isShown = isShown
        }
    }

    @ScaledMetric(relativeTo: .subheadline) private var plotHeight: CGFloat = 112
    @ScaledMetric(relativeTo: .subheadline) private var labelSize: CGFloat = 14
    private let periods: [Period]
    private let workName: String
    private let yoursName: String

    /// - Parameter yoursName: "Yours", or "Off" in Grind's voice (brief §7.3).
    public init(_ periods: [Period], workName: String, yoursName: String) {
        self.periods = periods
        self.workName = workName
        self.yoursName = yoursName
    }

    public var body: some View {
        let top = max(periods.flatMap { [$0.work, $0.yours] }.max() ?? 0, 3600)
        let shown = Set(periods.filter(\.isShown).map(\.label))
        Chart {
            ForEach(periods) { period in
                bar(period, kind: workName, value: period.work, top: top, color: PlaceCategory.work.color)
                bar(period, kind: yoursName, value: period.yours, top: top, color: Palette.yoursChart)
            }
        }
        .chartYScale(domain: 0 ... top)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(verbatim: label)
                            .font(TextRole.caption.font(size: labelSize))
                            .foregroundStyle(shown.contains(label) ? Palette.textPrimary : Palette.textSecondary)
                    }
                }
            }
        }
        .frame(height: plotHeight + labelSize * 2)
    }

    private func bar(_ period: Period, kind: String, value: TimeInterval, top: TimeInterval, color: Color) -> some ChartContent {
        BarMark(
            x: .value("Period", period.label),
            // A period with none of it keeps a sliver, so it still reads as a period, at zero.
            y: .value("Time", value > 0 ? value : top * 0.03),
            width: .fixed(24))
            .position(by: .value("Kind", kind), span: .fixed(50))
            .cornerRadius(6)
            .foregroundStyle(color.opacity(period.isShown ? 1 : 0.4))
            .accessibilityLabel("\(period.label), \(kind)")
            .accessibilityValue(DurationText.spoken(value))
    }
}

/// Calendar vs reality's ring (Time design): one round-ended mark per meeting, laid clockwise
/// from twelve o'clock in the order given, with "6/8 meetings" in the middle.
///
/// Measured from the ring's Figma crop (13 Nov): 106 across, marks 12 thick with 6.2 between
/// their ends. Pink marks catch light along their top edge: Figma's four inner shadows in
/// `meetingGlint`. A mark without a glint (elsewhere) is flat, as in the design.
///
/// The marks are SwiftUI shapes rather than Swift Charts marks, as on the day bar: Charts
/// doesn't draw inner shadows, and `SectorMark` can't give round ends with this gap. VoiceOver
/// reads the ring as one element and offers an audio graph of the count in each state.
public struct MeetingRing: View {
    public struct Meeting: Identifiable, Hashable, Sendable {
        public var id: String
        /// Attended, Left early, Elsewhere, No match.
        public var state: String
        public var color: Color
        /// The tint the mark catches along its top edge; nil draws it flat.
        public var glint: Color?

        public init(id: String, state: String, color: Color, glint: Color? = nil) {
            self.id = id
            self.state = state
            self.color = color
            self.glint = glint
        }
    }

    @ScaledMetric(relativeTo: .title) private var size: CGFloat = 106
    private let meetings: [Meeting]
    private let attended: Int
    private let caption: String
    private let title: String

    /// The design's marks: 12 thick and 6.2 apart at 106 across.
    static let thickness: CGFloat = 12
    static let gap: CGFloat = 6.2

    /// - Parameters:
    ///   - caption: under the count: "meetings".
    ///   - title: what the ring is of, for the audio graph: "Calendar vs reality".
    public init(_ meetings: [Meeting], attended: Int, caption: String, title: String) {
        self.meetings = meetings
        self.attended = attended
        self.caption = caption
        self.title = title
    }

    public var body: some View {
        let scale = size / 106
        ZStack {
            ZStack {
                ForEach(Array(meetings.enumerated()), id: \.element.id) { index, meeting in
                    RingMark(index: index, count: meetings.count, thickness: Self.thickness * scale, gap: Self.gap * scale)
                        .fill(meeting.glint.map { AnyShapeStyle(Self.shaded(meeting.color, glint: $0)) } ?? AnyShapeStyle(meeting.color))
                }
            }
            .drawingGroup()

            count
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityChartDescriptor(MeetingRingChartDescriptor(title: title, meetings: meetings))
    }

    /// "6/8" (28 semibold, then 16 medium in grey) over "meetings" (14 regular, grey), all SF
    /// Pro Rounded at -2% (Figma, 13 Nov). Figma's boxes are trimmed to the cap height with 8
    /// between them, so the baselines are 18 apart; SwiftUI's line boxes already leave 20.
    private var count: some View {
        VStack(spacing: -2) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(verbatim: "\(attended)")
                    .textRole(.cardTitle, weight: .semibold, monospacedDigits: true)
                    .foregroundStyle(Palette.textPrimary)
                Text(verbatim: "/\(meetings.count)")
                    .textRole(.body, monospacedDigits: true)
                    .foregroundStyle(Palette.textSecondary)
            }
            Text(verbatim: caption)
                .textRole(.caption)
                .foregroundStyle(Palette.textSecondary)
        }
        // Figma centres from the 6's cap height to the caption's baseline; SwiftUI's line boxes
        // reach 7 above the one and 3.5 below the other, which would sit the text 1.75 low.
        .padding(.bottom, 3.5)
        .accessibilityHidden(true)
    }

    /// Figma's inner shadows, all at x 0 and spread 0: y 13 blur 4 at 1%, y 8 blur 3 at 5%,
    /// y 5 blur 3 at 18%, y 2 blur 2 at 30%. Figma blur is twice SwiftUI's shadow radius. The
    /// marks are drawn in place rather than rotated, so the light always falls from above.
    static func shaded(_ fill: Color, glint: Color) -> some ShapeStyle {
        fill
            .shadow(.inner(color: glint.opacity(0.01), radius: 2, x: 0, y: 13))
            .shadow(.inner(color: glint.opacity(0.05), radius: 1.5, x: 0, y: 8))
            .shadow(.inner(color: glint.opacity(0.18), radius: 1.5, x: 0, y: 5))
            .shadow(.inner(color: glint.opacity(0.30), radius: 1, x: 0, y: 2))
    }
}

/// One meeting's mark: an arc of the ring with round ends, its slot clockwise from twelve.
/// The gap between two marks' ends is `gap`, or a sixth of the slot when the slots get short
/// (as at eight meetings), so a month of meetings still reads as marks. When round ends no
/// longer fit, the marks go square-ended and the ring reads as bands.
nonisolated private struct RingMark: Shape {
    var index: Int
    var count: Int
    var thickness: CGFloat
    var gap: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = (min(rect.width, rect.height) - thickness) / 2
        guard count > 0, radius > 0 else { return Path() }
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        var arc = Path()
        guard count > 1 else {
            arc.addEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2))
            return arc.strokedPath(StrokeStyle(lineWidth: thickness))
        }
        let slot = 2 * Double.pi / Double(count)
        let gapAngle = min(Double(gap), Double(radius) * slot / 6) / Double(radius)
        let capAngle = Double(thickness / 2 / radius)
        let middle = -Double.pi / 2 + slot * (Double(index) + 0.5)
        var half = slot / 2 - gapAngle / 2 - capAngle
        var cap = CGLineCap.round
        if half <= 0 {
            half = slot / 2 - gapAngle / 2
            cap = .butt
        }
        arc.addArc(center: centre, radius: radius, startAngle: .radians(middle - half), endAngle: .radians(middle + half), clockwise: false)
        return arc.strokedPath(StrokeStyle(lineWidth: thickness, lineCap: cap))
    }
}

/// The ring as an audio graph: one point per state, in the ring's order, meetings on the y-axis.
nonisolated private struct MeetingRingChartDescriptor: AXChartDescriptorRepresentable {
    let title: String
    let states: [String]
    let counts: [Double]

    @MainActor
    init(title: String, meetings: [MeetingRing.Meeting]) {
        self.title = title
        var states: [String] = []
        var counts: [String: Double] = [:]
        for meeting in meetings {
            if counts[meeting.state] == nil { states.append(meeting.state) }
            counts[meeting.state, default: 0] += 1
        }
        self.states = states
        self.counts = states.map { counts[$0] ?? 0 }
    }

    func makeChartDescriptor() -> AXChartDescriptor {
        let xAxis = AXCategoricalDataAxisDescriptor(title: "State", categoryOrder: states)
        let yAxis = AXNumericDataAxisDescriptor(
            title: "Meetings",
            range: 0 ... max(counts.max() ?? 0, 1),
            gridlinePositions: []
        ) { value in "\(Int(value))" }
        let series = AXDataSeriesDescriptor(
            name: title,
            isContinuous: false,
            dataPoints: zip(states, counts).map { AXDataPoint(x: $0, y: $1) })
        return AXChartDescriptor(title: title, summary: nil, xAxis: xAxis, yAxis: yAxis, additionalAxes: [], series: [series])
    }
}
