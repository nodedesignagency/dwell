import DwellCore
import SwiftUI

/// A category and its time on a white capsule (Weekly wrap 3, "What you did instead"): the
/// category's swatch (12 × 6, the legends' own), 4 to its name (14 medium, ink), 6 to a
/// hairline 12 tall (ink 10%), 6 to the time (14, grey, monospaced digits). 30 tall, 10 in at
/// the sides, lifted off the page by You's pill shadow (#1B1C1D 5%, y 5.42, blur 10.85) until
/// this design's own values are in [VALUES NEEDED]. Measured from the screenshot.
/// White in every scheme, like the wrap it sits on. Grows with the text and stays on one line,
/// its words shrinking rather than running off the screen.
/// VoiceOver reads "Home, 19 hours 11 minutes".
public struct CategoryPill: View {
    @ScaledMetric(relativeTo: .subheadline) private var height: CGFloat = 30
    @ScaledMetric(relativeTo: .subheadline) private var swatchWidth: CGFloat = 12
    @ScaledMetric(relativeTo: .subheadline) private var hairline: CGFloat = 12
    private let bucket: ChartBucket
    private let duration: TimeInterval

    public init(_ bucket: ChartBucket, duration: TimeInterval) {
        self.bucket = bucket
        self.duration = duration
    }

    public var body: some View {
        HStack(spacing: 0) {
            GridSegment(kind: .bucket(bucket), radius: swatchWidth / 4)
                .frame(width: swatchWidth, height: swatchWidth / 2)
            Text(verbatim: bucket.name)
                .textRole(.caption, weight: .medium)
                .foregroundStyle(Palette.textPrimary)
                .padding(.leading, Space.xs)
            Rectangle()
                .fill(Palette.separator)
                .frame(width: 1, height: hairline)
                .padding(.horizontal, 6)
            Text(verbatim: DurationText.short(duration))
                .textRole(.data)
                .foregroundStyle(Palette.textSecondary)
        }
        .lineLimit(1)
        // At the largest text sizes a pill can outgrow the screen: its words shrink to fit.
        .minimumScaleFactor(0.6)
        .padding(.horizontal, 10)
        .frame(minHeight: height)
        .background {
            Capsule()
                .fill(Palette.surface)
                .shadow(color: Palette.glassShadow, radius: 10.85 / 2, y: 5.42)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(bucket.name), \(DurationText.spoken(duration))"))
    }
}
