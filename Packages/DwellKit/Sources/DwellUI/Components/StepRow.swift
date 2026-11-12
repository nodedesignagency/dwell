import SwiftUI

/// One step of a numbered checklist (Today design, "Getting Started"): a 32-pt blue number, 12
/// to a white card with the step's tag (12 medium, blue, in capitals), title (16) and detail
/// (14, grey), lines 6 apart, padding 16 across and 12 down. A dashed line runs behind the row
/// at the number's centre, joining it to its card.
public struct StepRow: View {
    @ScaledMetric(relativeTo: .subheadline) private var numberSize: CGFloat = 32
    private let number: Int
    private let tag: String
    private let title: String
    private let detail: String

    public init(number: Int, tag: String, title: String, detail: String) {
        self.number = number
        self.tag = tag
        self.title = title
        self.detail = detail
    }

    public var body: some View {
        HStack(spacing: Space.m) {
            StepNumber(number: number, size: numberSize)
            VStack(alignment: .leading, spacing: 6) {
                // The words are sentence case ("Now"); the design sets the tag in capitals.
                Text(verbatim: tag)
                    .textCase(.uppercase)
                    .textRole(.footnote, weight: .medium)
                    .foregroundStyle(Palette.step)
                Text(verbatim: title)
                    .textRole(.body)
                    .foregroundStyle(Palette.textPrimary)
                Text(verbatim: detail)
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Space.l)
            .padding(.vertical, Space.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
        .background { DashedDivider() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(number), \(tag). \(title). \(detail)")
    }
}

/// "01" in white on a blue disc, lit a little along its bottom and top edges (Today design).
private struct StepNumber: View {
    let number: Int
    let size: CGFloat

    var body: some View {
        Text(number.formatted(.number.precision(.integerLength(2))))
            .textRole(.caption)
            .monospacedDigit()
            .foregroundStyle(Palette.inverseText)
            .frame(width: size, height: size)
            .background {
                Circle()
                    .fill(
                        Palette.step
                            .shadow(.inner(color: .white.opacity(0.4), radius: 2, y: -2))
                            .shadow(.inner(color: .white.opacity(0.25), radius: 1.5, y: 1.5)))
            }
    }
}
