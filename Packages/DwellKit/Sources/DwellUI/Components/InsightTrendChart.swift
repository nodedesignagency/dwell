import Charts
import DwellCore
import SwiftUI

/// The weeks behind an insight as bars (Insights design, 13 Nov): one a week, the insight's own
/// week at full strength and the rest faded to 40%, each with a light along its top edge (the
/// day bar's glint), labels under them, the insight's in grey and the rest fainter.
///
/// Measured from the screenshot (393 pt): bars 61.4 wide in 80-pt slots (77%), 4-pt corners;
/// the tallest 114 tall; labels 14 regular at -2% (Figma), their capitals 12.7 below the bars; the glint fades into
/// the bar over its top 8 pt. The design's pink reads #E75ECB; the bars take the insight's
/// category colour (Work, #FA51D0), as the category colour means the category on every page
/// (QUESTIONS.md).
///
/// Scrub or touch a bar to pick it out: it turns full strength and a callout gives its week
/// and time. Weeks before Dwell was recording keep their slot with no bar. Swift Charts gives
/// each bar a VoiceOver label and the chart an audio graph. Bars grow from the baseline when
/// the chart appears (`Motion.reveal`); under Reduce Motion they're simply there.
public struct InsightTrendChart: View {
    public struct Bar: Identifiable, Hashable, Sendable {
        public var id: String
        /// Under the bar: "Oct 5", "Last week". `nil` for none (3M labels months only).
        public var label: String?
        /// The week, for VoiceOver and the callout: "Oct 12 – 18".
        public var name: String
        /// `nil` before Dwell was recording: no bar.
        public var value: TimeInterval?
        /// The insight's own week: drawn in full.
        public var isFocus: Bool

        public init(id: String, label: String?, name: String, value: TimeInterval?, isFocus: Bool) {
            self.id = id
            self.label = label
            self.name = name
            self.value = value
            self.isFocus = isFocus
        }
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .subheadline) private var plotHeight: CGFloat = 114
    @ScaledMetric(relativeTo: .subheadline) private var labelSize: CGFloat = 14
    @State private var selected: String?
    @State private var hasGrown = false

    private let bars: [Bar]
    private let measure: String
    private let tint: Color
    private let glint: Color

    /// - Parameters:
    ///   - measure: what the bars measure, for VoiceOver: "Time at the office".
    ///   - tint: the bars' colour, usually the insight's category's.
    ///   - glint: the light along their top edge (`PlaceCategory.glint`).
    public init(_ bars: [Bar], measure: String, tint: Color, glint: Color) {
        self.bars = bars
        self.measure = measure
        self.tint = tint
        self.glint = glint
    }

    public var body: some View {
        let top = max(bars.compactMap(\.value).max() ?? 0, 3600)
        let picked = bars.first { $0.id == selected && $0.value != nil }
        let strong = picked?.id ?? bars.first(where: \.isFocus)?.id
        let grown = hasGrown || reduceMotion
        Chart {
            ForEach(bars) { bar in
                if let value = bar.value {
                    // A week with none of it keeps a sliver, so it still reads as a week, at zero.
                    let shown = value > 0 ? value : top * 0.03
                    BarMark(
                        x: .value("Week", bar.id),
                        y: .value(measure, grown ? shown : 0),
                        width: .ratio(0.77))
                        .cornerRadius(4)
                        .foregroundStyle(fill(height: shown / top * plotHeight, isStrong: bar.id == strong))
                        .accessibilityLabel(bar.name)
                        .accessibilityValue(DurationText.spoken(value))
                        .annotation(
                            position: .top,
                            alignment: .center,
                            spacing: 6,
                            overflowResolution: AnnotationOverflowResolution(x: .fit(to: .chart), y: .fit(to: .chart))
                        ) {
                            if bar.id == picked?.id {
                                callout(bar, value: value)
                            }
                        }
                }
            }
        }
        .chartXScale(domain: bars.map(\.id))
        .chartYScale(domain: 0 ... top)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(values: bars.map(\.id)) { value in
                AxisValueLabel {
                    if let id = value.as(String.self), let bar = bars.first(where: { $0.id == id }), let label = bar.label {
                        // A chart label takes a font, not a text role, so the role's -2%
                        // tracking is set here (Figma: SF Pro Rounded 14 regular, -2%).
                        Text(verbatim: label)
                            .font(TextRole.caption.font(size: labelSize))
                            .tracking(TextRole.tracking * labelSize)
                            .foregroundStyle(id == strong ? Palette.textSecondary : Palette.textSecondary.opacity(0.4))
                            .lineLimit(1)
                    }
                }
            }
        }
        .chartXSelection(value: $selected)
        .frame(height: plotHeight + labelSize * 2)
        .onAppear {
            guard !hasGrown else { return }
            if reduceMotion {
                hasGrown = true
            } else {
                withAnimation(Motion.reveal) { hasGrown = true }
            }
        }
    }

    /// The bar's colour with its glint fading in over the top 8 pt, whatever the bar's height.
    private func fill(height: CGFloat, isStrong: Bool) -> LinearGradient {
        let edge = min(0.5, 8 / max(height, 1))
        let base = tint.opacity(isStrong ? 1 : 0.4)
        return LinearGradient(
            stops: [
                Gradient.Stop(color: glint.opacity(isStrong ? 1 : 0.4), location: 0),
                Gradient.Stop(color: base, location: edge),
                Gradient.Stop(color: base, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom)
    }

    /// The picked week: "Oct 12 – 18 · 47h 51m", on a white pill over the bars.
    private func callout(_ bar: Bar, value: TimeInterval) -> some View {
        HStack(spacing: Space.xs) {
            Text(verbatim: bar.name)
                .textRole(.footnote, weight: .medium)
                .foregroundStyle(Palette.textSecondary)
            Text(verbatim: DurationText.short(value))
                .textRole(.footnote, weight: .medium, monospacedDigits: true)
                .foregroundStyle(Palette.textPrimary)
        }
        .lineLimit(1)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(Palette.surface)
                .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        }
        .overlay { Capsule().strokeBorder(Palette.cardStroke, lineWidth: 1) }
        .accessibilityHidden(true)
    }
}

/// The window over a chart (Insights design: "‹ Oct 2026 – Nov 2026 ›"): the window's months
/// (16 medium, ink) between two chevrons (12 semibold), 10 apart. Each chevron steps a window
/// back or on, and greys out at the end; each is tappable over 44 pt without moving the words.
public struct PeriodStepper: View {
    private let title: String
    private let backLabel: String
    private let forwardLabel: String
    private let canGoBack: Bool
    private let canGoForward: Bool
    private let back: () -> Void
    private let forward: () -> Void

    @ScaledMetric(relativeTo: .callout) private var chevronSize: CGFloat = 12

    /// - Parameters:
    ///   - backLabel: VoiceOver's name for the back chevron: "Earlier weeks".
    ///   - forwardLabel: and for the other: "Later weeks".
    public init(
        _ title: String,
        backLabel: String,
        forwardLabel: String,
        canGoBack: Bool,
        canGoForward: Bool,
        back: @escaping () -> Void,
        forward: @escaping () -> Void
    ) {
        self.title = title
        self.backLabel = backLabel
        self.forwardLabel = forwardLabel
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.back = back
        self.forward = forward
    }

    public var body: some View {
        HStack(spacing: 10) {
            chevron("chevron.left", label: backLabel, isEnabled: canGoBack, action: back)
            Text(verbatim: title)
                .textRole(.label)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            chevron("chevron.right", label: forwardLabel, isEnabled: canGoForward, action: forward)
        }
    }

    private func chevron(_ symbol: String, label: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: chevronSize, weight: .semibold))
                .flipsForRightToLeftLayoutDirection(true)
                .foregroundStyle(isEnabled ? Palette.textPrimary : Palette.textSecondary.opacity(0.4))
                // 44 to tap, without pushing the words away.
                .padding(16)
                .contentShape(.rect)
                .padding(-16)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }
}
