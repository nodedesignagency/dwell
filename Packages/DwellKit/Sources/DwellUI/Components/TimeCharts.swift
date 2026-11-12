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

/// Calendar vs reality's ring (Time design): one rounded mark per meeting, attended in deep
/// pink, left early in light pink, elsewhere in grey, with "6/8 meetings" in the middle.
///
/// Measured from the screenshot: 106 across, the ring 15 thick, 3° between marks. Swift Charts
/// (`SectorMark`), so VoiceOver reads each meeting's state and the ring has an audio graph.
public struct MeetingRing: View {
    public struct Meeting: Identifiable, Hashable, Sendable {
        public var id: String
        /// Attended, Left early, Elsewhere, No match.
        public var state: String
        public var color: Color

        public init(id: String, state: String, color: Color) {
            self.id = id
            self.state = state
            self.color = color
        }
    }

    @ScaledMetric(relativeTo: .title) private var size: CGFloat = 106
    private let meetings: [Meeting]
    private let attended: Int
    private let caption: String

    /// - Parameter caption: under the count: "meetings".
    public init(_ meetings: [Meeting], attended: Int, caption: String) {
        self.meetings = meetings
        self.attended = attended
        self.caption = caption
    }

    public var body: some View {
        Chart(meetings) { meeting in
            SectorMark(angle: .value("Meeting", 1), innerRadius: .ratio(0.72), angularInset: meetings.count > 1 ? 3 : 0)
                .cornerRadius(7)
                .foregroundStyle(meeting.color)
                .accessibilityLabel(meeting.state)
        }
        .chartLegend(.hidden)
        .frame(width: size, height: size)
        .overlay {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(verbatim: "\(attended)")
                        .textRole(.cardTitle, monospacedDigits: true)
                        .foregroundStyle(Palette.textPrimary)
                    Text(verbatim: "/\(meetings.count)")
                        .textRole(.body, monospacedDigits: true)
                        .foregroundStyle(Palette.textSecondary)
                }
                Text(verbatim: caption)
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
            .accessibilityHidden(true)
        }
    }
}
