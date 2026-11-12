import SwiftUI

/// A pushed page's title (Your places design): its 3D art (40), 10 to the title (24 medium)
/// over its facts (16, grey, 12 to each dot), 2 apart, the text centred on the art. Plain
/// words, never voiced: the page's name and its counts.
public struct PageHeader: View {
    @ScaledMetric(relativeTo: .title2) private var artSize: CGFloat = 40
    private let title: String
    private let details: [String]
    private let art: Image

    public init(_ title: String, details: [String], art: Image) {
        self.title = title
        self.details = details
        self.art = art
    }

    public var body: some View {
        HStack(spacing: 10) {
            art
                .resizable()
                .scaledToFit()
                .frame(width: artSize, height: artSize)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Space.xxs) {
                Text(verbatim: title)
                    .textRole(.pageTitle)
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if !details.isEmpty {
                    DotLine(details, spacing: Space.m)
                        .textRole(.body, weight: .regular)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
