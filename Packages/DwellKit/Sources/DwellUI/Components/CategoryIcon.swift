import DwellCore
import SwiftUI

/// A category's icon. Decorative: whatever shows it also shows the category's or place's name,
/// so colour and icon are never the only carriers of meaning.
public struct CategoryIcon: View {
    public enum Style: Sendable {
        /// The 3D illustration (Today's headline). Falls back to the glyph for categories
        /// whose art hasn't been designed yet.
        case illustration
        /// The flat glyph (timeline rows).
        case glyph
    }

    private let category: PlaceCategory?
    private let style: Style

    /// `nil` draws a generic place pin, for visits waiting for "Review this place".
    public init(_ category: PlaceCategory?, style: Style) {
        self.category = category
        self.style = style
    }

    public var body: some View {
        Group {
            if style == .illustration, let name = category?.illustrationName {
                Image(name, bundle: .module)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: category?.placeholderSymbol ?? "mappin")
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .accessibilityHidden(true)
    }
}
