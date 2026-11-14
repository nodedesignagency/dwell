import SwiftUI

/// A card from the bottom with its words at the top and a picture of its own filling the rest
/// ("Getting your world ready", Checking, 14 Nov): the close button in the corner, as on
/// `PromptSheet`, the title (`display` 40, lines 39 apart, as onboarding's titles) and its line
/// (20 regular, ink at 70%, lines 22 apart, broken where the design breaks it), then the content
/// edge to edge down to the card's foot. On the page's colour (`background`), corners 32.
/// Present it with `.promptSheet(isPresented:)`.
///
/// Measured from the screenshot at 393 × 852: the title's first line 31 from the card's top
/// (its box 22), the line 7 under the title; the close button 44 on glass, 16 in from the top
/// and side. The title keeps 60 from each side, clear of the close button.
public struct SheetCard<Content: View>: View {
    @ScaledMetric(relativeTo: .title3) private var lineGap: CGFloat = -1.7

    private let title: String
    private let titleWidth: CGFloat
    private let lines: [String]
    private let closeLabel: String
    private let onClose: () -> Void
    private let content: Content

    /// - Parameters:
    ///   - titleWidth: where the title breaks ("Getting your / world ready" at 250).
    ///   - lines: the line under the title, as the design breaks it.
    ///   - closeLabel: what VoiceOver calls the close button.
    public init(
        title: String,
        titleWidth: CGFloat,
        lines: [String],
        closeLabel: String,
        onClose: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.titleWidth = titleWidth
        self.lines = lines
        self.closeLabel = closeLabel
        self.onClose = onClose
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            LeadedText(title, role: .display, lineHeight: 39)
                .frame(maxWidth: titleWidth)
                .foregroundStyle(Palette.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 22)
                .padding(.horizontal, 60)
            VStack(spacing: lineGap) {
                ForEach(lines, id: \.self) { line in
                    Text(verbatim: line)
                }
            }
            .textRole(.title, weight: .regular)
            .foregroundStyle(Palette.textPrimary.opacity(0.7))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .padding(.top, 7)
            .padding(.horizontal, Space.l)
            content
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .background(Palette.background)
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                CloseCross()
            }
            .buttonStyle(.glassCircle)
            .accessibilityLabel(Text(verbatim: closeLabel))
            .padding(Space.l)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.xxl))
    }
}
