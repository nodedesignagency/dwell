import DwellCore
import SwiftUI

/// A place in a list (Your places design): its glyph in a well, the name over its facts
/// ("Work • 48 visits", "Since March"), and the time spent there with a chevron.
///
/// Read from the screenshot: the 32-pt well 8 from the text, the name (16 medium) 4 above
/// the facts (14, grey, 8 to each dot), centred on the well; the time sits on the name's
/// baseline at the trailing edge. Like a timeline row, the row has 4 below it. At
/// accessibility sizes the time moves under the facts so the name keeps its width.
public struct PlaceRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let name: String
    private let category: PlaceCategory
    private let details: [String]
    private let total: String
    private let spokenTotal: String

    /// - Parameters:
    ///   - details: "Work", "48 visits"; or "Since March" for home.
    ///   - total: "186h"; `spokenTotal`, how VoiceOver reads it, "186 hours".
    public init(name: String, category: PlaceCategory, details: [String], total: String, spokenTotal: String) {
        self.name = name
        self.category = category
        self.details = details
        self.total = total
        self.spokenTotal = spokenTotal
    }

    public var body: some View {
        let large = dynamicTypeSize.isAccessibilitySize
        HStack(spacing: Space.s) {
            IconWell {
                CategoryIcon(category, style: .glyph)
                    .foregroundStyle(Palette.textPrimary)
            }
            VStack(alignment: .leading, spacing: Space.xs) {
                HStack(alignment: .firstTextBaseline, spacing: Space.s) {
                    Text(verbatim: name)
                        .textRole(.body)
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(large ? nil : 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !large {
                        DurationTrail(total, showsChevron: true)
                    }
                }
                DotLine(details, spacing: Space.s)
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
                if large {
                    DurationTrail(total, showsChevron: true)
                }
            }
        }
        .padding(.bottom, Space.xs)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(([name] + details + [spokenTotal]).joined(separator: ", "))
    }
}

/// A list section's label, set in capitals as the design draws it ("FAVOURITES", 14, grey).
/// The words themselves stay in sentence case, so VoiceOver reads them as words.
public struct SectionLabel: View {
    private let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(verbatim: title)
            .textCase(.uppercase)
            .textRole(.caption)
            .foregroundStyle(Palette.textSecondary)
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isHeader)
    }
}
