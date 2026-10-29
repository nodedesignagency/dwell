import DwellCore
import SwiftUI

/// A visit in the day's timeline (Today design, "Your day"): icon, span, place, duration.
/// Badges say what the row can't show by itself: approximate, private, work from home.
/// Rows never carry character: no voiced text here (brief §6).
///
/// At accessibility sizes the duration moves under the place so names keep their width.
public struct VisitRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .callout) private var wellSize: CGFloat = 32
    @ScaledMetric(relativeTo: .callout) private var glyphSize: CGFloat = 16

    private let visit: Visit
    private let span: String
    private let duration: TimeInterval
    private let showsChevron: Bool
    private let onReview: (() -> Void)?

    /// - Parameters:
    ///   - span: "8:02 AM – 8:59 AM", or "1:31 PM → now" while the visit is going.
    ///   - onReview: shows "Review this place" when the visit needs a yes.
    public init(visit: Visit, span: String, duration: TimeInterval, showsChevron: Bool, onReview: (() -> Void)? = nil) {
        self.visit = visit
        self.span = span
        self.duration = duration
        self.showsChevron = showsChevron
        self.onReview = onReview
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Space.s) {
            CategoryIcon(visit.placeID == nil ? nil : visit.category, style: .glyph)
                .foregroundStyle(Palette.textPrimary)
                .frame(width: glyphSize, height: glyphSize)
                .frame(width: wellSize, height: wellSize)
                .background(Palette.background, in: .circle)
                .overlay { Circle().strokeBorder(Palette.separator, lineWidth: 1) }

            VStack(alignment: .leading, spacing: Space.xs) {
                Text(verbatim: span)
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
                Text(verbatim: visit.placeName)
                    .textRole(.body)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                if dynamicTypeSize.isAccessibilitySize {
                    trailing
                }
                if !badges.isEmpty || (visit.needsReview && onReview != nil) {
                    FlowLayout(spacing: Space.xs, lineSpacing: Space.xs) {
                        ForEach(badges, id: \.self) { badge in
                            BadgeChip(badge: badge)
                        }
                        if visit.needsReview, let onReview {
                            Button("Review this place", action: onReview)
                                .buttonStyle(ReviewChipStyle())
                        }
                    }
                    .padding(.top, Space.xxs)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !dynamicTypeSize.isAccessibilitySize {
                trailing
            }
        }
        .padding(.bottom, Space.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityActions {
            if visit.needsReview, let onReview {
                Button("Review this place", action: onReview)
            }
        }
    }

    private var trailing: some View {
        HStack(spacing: Space.xs) {
            Image(systemName: "clock")
                .accessibilityHidden(true)
            Text(verbatim: DurationText.short(duration))
                .monospacedDigit()
            if showsChevron {
                Image(systemName: "chevron.right")
                    .imageScale(.small)
                    .accessibilityHidden(true)
            }
        }
        .textRole(.data)
        .foregroundStyle(Palette.textSecondary)
    }

    private var badges: [Badge] {
        var badges: [Badge] = []
        if visit.precision == .approximate { badges.append(Badge(title: "Approximate", symbol: "circle.dashed")) }
        if visit.isPrivate { badges.append(Badge(title: "Private", symbol: "lock.fill")) }
        if visit.isWorkFromHome { badges.append(Badge(title: "WFH", symbol: "laptopcomputer")) }
        return badges
    }

    private var accessibilityText: String {
        let parts = [visit.placeName, span, DurationText.spoken(duration)] + badges.map(\.title)
        return parts.joined(separator: ", ")
    }
}

/// A slim row between visits: transit, or a gap shown as a gap ("Dwell was asleep · 22m").
public struct TimelineNote: View {
    @ScaledMetric(relativeTo: .callout) private var wellSize: CGFloat = 32
    private let text: String
    private let symbol: String
    private let isGap: Bool

    public init(_ text: String, symbol: String, isGap: Bool) {
        self.text = text
        self.symbol = symbol
        self.isGap = isGap
    }

    public var body: some View {
        HStack(spacing: Space.s) {
            Image(systemName: symbol)
                .imageScale(.small)
                .frame(width: wellSize)
                .accessibilityHidden(true)
            Text(verbatim: text)
                .monospacedDigit()
                .textRole(.caption)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Palette.textSecondary)
        .padding(.vertical, Space.xxs)
        .padding(.horizontal, isGap ? Space.xs : 0)
        .background {
            if isGap {
                RoundedRectangle(cornerRadius: Radius.s)
                    .strokeBorder(Palette.gap, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct Badge: Hashable {
    let title: String
    let symbol: String
}

private struct BadgeChip: View {
    let badge: Badge

    var body: some View {
        Label(badge.title, systemImage: badge.symbol)
            .labelStyle(.titleAndIcon)
            .textRole(.footnote)
            .foregroundStyle(Palette.textSecondary)
            .padding(.horizontal, Space.s)
            .padding(.vertical, Space.xxs)
            .background(Palette.background, in: .capsule)
            .overlay { Capsule().strokeBorder(Palette.separator, lineWidth: 1) }
    }
}

private struct ReviewChipStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textRole(.footnote)
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, Space.s)
            .padding(.vertical, Space.xxs)
            .background(Palette.accent.opacity(0.1), in: .capsule)
            .frame(minHeight: 32)
            .contentShape(.rect)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}
