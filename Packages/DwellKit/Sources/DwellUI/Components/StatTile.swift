import SwiftUI

/// A hero stat: one number, its label, and an icon on a soft wash of colour (Today design:
/// "4h 29m · At work", "57m · Yours"). The label is a plain label, never voiced.
public struct StatTile<Icon: View>: View {
    @ScaledMetric(relativeTo: .callout) private var iconSize: CGFloat = 33
    private let value: String
    private let label: String
    private let spokenValue: String
    private let tint: Color
    private let icon: Icon

    /// - Parameter spokenValue: what VoiceOver reads for `value`, e.g. "4 hours, 40 minutes".
    public init(value: String, label: String, spokenValue: String? = nil, tint: Color, @ViewBuilder icon: () -> Icon) {
        self.value = value
        self.label = label
        self.spokenValue = spokenValue ?? value
        self.tint = tint
        self.icon = icon()
    }

    public var body: some View {
        HStack(spacing: Space.s) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(verbatim: value)
                    .textRole(.dataStat)
                    .foregroundStyle(Palette.textPrimary)
                Text(verbatim: label)
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer(minLength: Space.xs)
            icon
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)
        }
        .padding(13)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                LinearGradient(colors: [Palette.surface, tint.opacity(0.22)], startPoint: .leading, endPoint: .trailing)
                RadialGradient(colors: [tint.opacity(0.22), .clear], center: .trailing, startRadius: 0, endRadius: 90)
            }
            .clipShape(.rect(cornerRadius: Radius.l))
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.l)
                .strokeBorder(Palette.separator.opacity(0.7), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(spokenValue)
    }
}
