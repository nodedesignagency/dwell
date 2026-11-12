import DwellCore
import SwiftUI

/// One day of a streak (You design): the design's orange flame for a day kept, its grey one for
/// a day a freeze covered, and its dashed outline for one missed or still to come. 20 × 24,
/// the flame itself 19.25 × 23.5.
public struct FlameMark: View {
    @ScaledMetric(relativeTo: .caption) private var height: CGFloat = 24
    private let state: Streak.Mark.State

    public init(_ state: Streak.Mark.State) {
        self.state = state
    }

    public var body: some View {
        image
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .accessibilityHidden(true)
    }

    private var image: Image {
        switch state {
        case .kept: Art.Flame.kept
        case .frozen: Art.Flame.frozen
        case .missed, .open: Art.Flame.open
        }
    }
}

/// A figure with its label above it (You design, under the streak: "Current · 12 days"): the
/// label 14 grey, 4 to the value 16 medium.
public struct StatColumn: View {
    private let label: String
    private let value: String
    private let spokenValue: String

    public init(_ label: String, value: String, spokenValue: String? = nil) {
        self.label = label
        self.value = value
        self.spokenValue = spokenValue ?? value
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(verbatim: label)
                .textRole(.caption)
                .foregroundStyle(Palette.textSecondary)
            Text(verbatim: value)
                .textRole(.dataStat)
                .foregroundStyle(Palette.textPrimary)
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(spokenValue)
    }
}

/// The dashed hairline standing between figures (You design, between Current, Best and
/// Freezes): `DashedDivider` turned upright.
public struct VerticalDashedDivider: View {
    public init() {}

    public var body: some View {
        VerticalLine()
            .stroke(Palette.separator, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            .frame(width: 1)
            .accessibilityHidden(true)
    }
}

nonisolated private struct VerticalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

/// The way into more, at the trailing end of a section header (You design: "View all ›",
/// "6 of 13 ›"): 14 grey, 6 to the row's chevron (8 × 14). A label for a link or a button.
public struct HeaderLink: View {
    @ScaledMetric(relativeTo: .subheadline) private var chevronHeight: CGFloat = 14
    private let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        HStack(spacing: 6) {
            Text(verbatim: title)
                .textRole(.caption)
            Art.chevron
                .resizable()
                .scaledToFit()
                .frame(width: chevronHeight * 8 / 14, height: chevronHeight)
                .flipsForRightToLeftLayoutDirection(true)
                .accessibilityHidden(true)
        }
        .foregroundStyle(Palette.textSecondary)
        // 44 to tap without making the header taller.
        .contentShape(Rectangle().inset(by: -12))
    }
}

/// A badge in a grid (You design: the medal, "Explorer", "Gold • 41 places"): the medal 25
/// (the art 24 inside), 8 to the name (16 medium), 2 to its facts (12, grey, 8 to each dot),
/// all centred. Locked badges keep their place with their medal in grey. Badges whose art
/// hasn't arrived show an SF Symbol medal in their tier's colour. [ICON NEEDED]
public struct BadgeTile: View {
    @ScaledMetric(relativeTo: .callout) private var medalSize: CGFloat = 25
    private let name: String
    private let details: [String]
    private let tier: Badge.Tier?
    private let art: Image?

    /// - Parameter art: the medal at this tier (`Art.badge`), or `nil` for a stand-in.
    public init(name: String, details: [String], tier: Badge.Tier?, art: Image? = nil) {
        self.name = name
        self.details = details
        self.tier = tier
        self.art = art
    }

    public var body: some View {
        VStack(spacing: 0) {
            Group {
                if let art {
                    art
                        .resizable()
                        .scaledToFit()
                        .grayscale(tier == nil ? 1 : 0)
                        .opacity(tier == nil ? 0.45 : 1)
                } else {
                    Image(systemName: tier == nil ? "medal" : "medal.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(medalColor)
                        .padding(2)
                }
            }
            .frame(width: medalSize, height: medalSize)
            .accessibilityHidden(true)
            Text(verbatim: name)
                .textRole(.body)
                .foregroundStyle(tier == nil ? Palette.textSecondary : Palette.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, Space.s)
            DotLine(details, spacing: Space.s, alignment: .center)
                .textRole(.footnote)
                .foregroundStyle(Palette.textSecondary)
                .padding(.top, Space.xxs)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(([name] + details).joined(separator: ", "))
    }

    private var medalColor: Color {
        switch tier {
        case .bronze: Palette.bronze
        case .silver: Palette.silver
        case .gold: Palette.gold
        case nil: Palette.flameFrozen
        }
    }
}
