import SwiftUI

/// A persistent, non-modal notice above a screen's content: the permission banner (one at a
/// time, brief §8.3) and the stale-data line. Never blocks what's under it.
///
/// Derived from the Today design's card language; no banner has been designed yet.
public struct NoticeBanner: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let symbol: String
    private let message: String
    private let actionTitle: String
    private let action: () -> Void

    public init(symbol: String, message: String, actionTitle: String, action: @escaping () -> Void) {
        self.symbol = symbol
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.s))
            : AnyLayout(HStackLayout(spacing: Space.m))
        layout {
            HStack(alignment: .firstTextBaseline, spacing: Space.s) {
                Image(systemName: symbol)
                    .foregroundStyle(Palette.textSecondary)
                    .accessibilityHidden(true)
                Text(verbatim: message)
                    .foregroundStyle(Palette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .textRole(.caption)
            Button(action: action) {
                Text(verbatim: actionTitle)
                    .textRole(.label)
                    .foregroundStyle(Palette.accent)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Space.m)
        .padding(.vertical, Space.xs)
        .background(Palette.surface, in: .rect(cornerRadius: Radius.l))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.l)
                .strokeBorder(Palette.separator, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A round profile picture, or a person glyph when there is none.
public struct Avatar: View {
    private let image: Image?
    private let size: CGFloat

    public init(_ image: Image?, size: CGFloat = 40) {
        self.image = image
        self.size = size
    }

    public var body: some View {
        Group {
            if let image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
    }
}
