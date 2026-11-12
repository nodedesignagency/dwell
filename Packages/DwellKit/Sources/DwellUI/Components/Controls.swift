import SwiftUI

/// The design's back button (Your places, Figma): the design's arrow (20, black; the "This week"
/// arrow turned round) on a 40-pt square of glass with 13-pt corners (`.glassSquare`).
/// Tappable over 44. It pops the page; the app keeps the edge swipe working alongside it.
public struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    private let action: (() -> Void)?

    /// - Parameter action: what Back does. Leave it out to pop the page.
    public init(action: (() -> Void)? = nil) {
        self.action = action
    }

    public var body: some View {
        Button {
            if let action { action() } else { dismiss() }
        } label: {
            Art.arrow
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .scaleEffect(x: -1)
                .flipsForRightToLeftLayoutDirection(true)
                // Figma's #000000 in light; white in dark, derived.
                .foregroundStyle(Color.primary)
        }
        .buttonStyle(.glassSquare)
        .accessibilityLabel("Back")
    }
}

/// A chip that sorts or filters a list (Your places design: "Most time", "All categories",
/// "Favourites"): 32 tall, white, 13-pt corners (the back button's, from Figma; the chips
/// measure the same), the filter glyph (12) 6 from the label (14
/// medium), 10 across. On (a filter is applied) it turns navy with white words, derived from
/// the confirmation card: the design draws only the resting chip.
///
/// A label, not a control: put it in a `Menu` or a `Button`.
public struct FilterChip: View {
    @ScaledMetric(relativeTo: .subheadline) private var height: CGFloat = 32
    @ScaledMetric(relativeTo: .subheadline) private var glyphSize: CGFloat = 12
    private let title: String
    private let isOn: Bool

    public init(_ title: String, isOn: Bool = false) {
        self.title = title
        self.isOn = isOn
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "line.3.horizontal.decrease")
                .resizable()
                .scaledToFit()
                .fontWeight(.medium)
                .frame(width: glyphSize, height: glyphSize)
                .accessibilityHidden(true)
            Text(verbatim: title)
                .textRole(.caption, weight: .medium)
                .lineLimit(1)
        }
        .foregroundStyle(isOn ? Palette.inverseText : Palette.textPrimary)
        .padding(.horizontal, 10)
        .frame(minHeight: height)
        .background(isOn ? Palette.inverseSurface : Palette.surface, in: .rect(cornerRadius: Radius.m))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.m)
                .strokeBorder(Palette.cardStroke, lineWidth: 1)
        }
        .contentShape(.rect(cornerRadius: Radius.m))
    }
}

/// The design's search field (Your places): a 44-pt capsule raised off the page by a soft
/// shadow and lit along its top edge, the magnifier (14) 8 from the words (14). Placeholder
/// grey, magnifier and fill read from the screenshot; the shadow is our estimate until the
/// Figma values come in. A clear button while there's text. A system `TextField` underneath.
public struct SearchField: View {
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .subheadline) private var height: CGFloat = 44
    @ScaledMetric(relativeTo: .subheadline) private var iconSize: CGFloat = 14
    @Binding private var text: String
    private let prompt: String

    public init(_ prompt: String, text: Binding<String>) {
        self.prompt = prompt
        self._text = text
    }

    public var body: some View {
        HStack(spacing: Space.s) {
            Image(systemName: "magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(Palette.fieldIcon)
                .accessibilityHidden(true)
            TextField(text: $text, prompt: Text(verbatim: prompt).foregroundStyle(Palette.placeholder)) {
                Text(verbatim: prompt)
            }
            .textRole(.caption)
            .foregroundStyle(Palette.textPrimary)
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
            .autocorrectionDisabled()
            .submitLabel(.search)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Palette.textSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .padding(.trailing, -Space.m)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.leading, Space.l - 2)
        .padding(.trailing, Space.l)
        .frame(minHeight: height)
        .background {
            Capsule()
                .fill(Palette.field)
                // A contact shadow under the edge and a long soft one below it.
                .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 2, y: 2)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 12, y: 8)
        }
        .overlay {
            // Lit along the top edge, as in the screenshot; the card edge in dark mode.
            Capsule()
                .strokeBorder(
                    colorScheme == .dark
                        ? AnyShapeStyle(Palette.cardStroke)
                        : AnyShapeStyle(LinearGradient(colors: [.white, .white.opacity(0)], startPoint: .top, endPoint: .center)),
                    lineWidth: 1)
                .allowsHitTesting(false)
        }
    }
}
