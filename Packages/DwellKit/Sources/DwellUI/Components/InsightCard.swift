import Charts
import DwellCore
import SwiftUI

/// One insight (Today design, "This week"): a topic label, the sentence in the dial's voice,
/// and its supporting chart or number. Share sits by the topic, since every insight can be
/// shared (brief §7.1).
public struct InsightCard: View {
    private let insight: Insight
    private let onShare: () -> Void

    public init(_ insight: Insight, onShare: @escaping () -> Void) {
        self.insight = insight
        self.onShare = onShare
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            HStack(alignment: .center) {
                if let topic = insight.topic {
                    Text(verbatim: topic)
                        .textRole(.caption)
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer(minLength: Space.s)
                if insight.isShareable {
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .textRole(.caption)
                            .foregroundStyle(Palette.textSecondary)
                            .frame(width: 44, height: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, -14)
                    .padding(.trailing, -Space.m)
                    .accessibilityLabel("Share")
                }
            }

            VoiceText(insight.line)
                .textRole(.voice)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if !insight.week.isEmpty {
                WeekBarsChart(insight.week)
                    .padding(.top, Space.xs)
            } else if let value = insight.value {
                Text(verbatim: value)
                    .textRole(.dataHero)
                    .foregroundStyle(Palette.accent)
            }
        }
        .padding(Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

/// A week of one number as seven bars, labelled by weekday (Today design, "Office hours").
/// A day with nothing gets a faint sliver so the day still reads as a day, at zero.
/// Swift Charts gives each bar a VoiceOver label and the chart an audio graph.
public struct WeekBarsChart: View {
    @Environment(\.calendar) private var calendar
    @ScaledMetric(relativeTo: .subheadline) private var plotHeight: CGFloat = 45
    @ScaledMetric(relativeTo: .subheadline) private var labelSize: CGFloat = 14
    private let values: [DayValue]

    public init(_ values: [DayValue]) {
        self.values = values
    }

    public var body: some View {
        let top = max(values.map(\.value).max() ?? 0, 60)
        Chart(values, id: \.day) { item in
            BarMark(
                x: .value("Day", weekday(item.day, .abbreviated)),
                y: .value("Time", item.value > 0 ? item.value : top * 0.06),
                width: .ratio(0.83))
                .foregroundStyle(Self.fill)
                .cornerRadius(Radius.s)
                .opacity(item.value > 0 ? 1 : 0.4)
                .accessibilityLabel(weekday(item.day, .wide))
                .accessibilityValue(DurationText.spoken(item.value))
        }
        .chartYScale(domain: 0 ... top)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(TextRole.caption.font(size: labelSize))
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .frame(height: plotHeight + labelSize * 2)
    }

    private func weekday(_ day: DwellDay, _ width: Date.FormatStyle.Symbol.Weekday) -> String {
        day.start(in: calendar).formatted(
            Date.FormatStyle(locale: calendar.locale ?? .current, calendar: calendar, timeZone: calendar.timeZone)
                .weekday(width))
    }

    private static let fill = LinearGradient(
        stops: [
            Gradient.Stop(color: Palette.accent, location: 0),
            Gradient.Stop(color: Palette.accent, location: 0.7),
            Gradient.Stop(color: Palette.accent.opacity(0.55), location: 1),
        ],
        startPoint: .top, endPoint: .bottom)
}
