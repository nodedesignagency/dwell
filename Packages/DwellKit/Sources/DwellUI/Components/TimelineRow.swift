import DwellCore
import SwiftUI

/// A visit in the day's timeline (Today design, "Your day"): icon, span, place, duration.
/// Badges say what the row can't show by itself: approximate, private, work from home.
/// Rows never carry character: no voiced text here (brief §6).
///
/// Figma: a 32-pt round well, 8 to the span over the place, the two lines spanning the well
/// (the row is 32-33 tall), then the clock, the duration and a chevron. At accessibility
/// sizes the duration moves under the place so names keep their width.
public struct VisitRow: View {
    @ScaledMetric(relativeTo: .callout) private var wellSize: CGFloat = 32

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
        VStack(alignment: .leading, spacing: Space.s) {
            TimelineLine(span: span, title: visit.placeName, duration: duration, showsChevron: showsChevron) {
                IconWell {
                    CategoryIcon(visit.placeID == nil ? nil : visit.category, style: .glyph)
                        .foregroundStyle(Palette.textPrimary)
                }
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
                .padding(.leading, wellSize + Space.s)
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

/// What comes between visits, shaped like a visit so the day reads as one list: transit
/// ("In transit", a tram in the well), or a gap, shown as a gap ("Dwell was asleep", a moon in
/// a dashed well, the words in grey). Never a chevron: neither opens anything.
public struct TimelineNote: View {
    private let title: String
    private let span: String
    private let duration: TimeInterval
    private let symbol: String
    private let isGap: Bool

    /// - Parameters:
    ///   - title: "In transit" or "Dwell was asleep".
    ///   - span: "12:38 PM – 12:46 PM".
    public init(_ title: String, span: String, duration: TimeInterval, symbol: String, isGap: Bool) {
        self.title = title
        self.span = span
        self.duration = duration
        self.symbol = symbol
        self.isGap = isGap
    }

    public var body: some View {
        TimelineLine(
            span: span,
            title: title,
            titleColor: isGap ? Palette.textSecondary : Palette.textPrimary,
            duration: duration,
            showsChevron: false
        ) {
            IconWell(isDashed: isGap) {
                Image(systemName: symbol)
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isGap ? Palette.textSecondary : Palette.textPrimary)
                    // SF Symbols fill their frame; the design's glyphs sit 16 inside 18.
                    .padding(1)
            }
        }
        .padding(.bottom, Space.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(span), \(DurationText.spoken(duration))")
    }
}

/// The row's line: the well, then the span (14, grey) over the title (16 medium) 4 apart, then
/// the duration. The space above the span's capitals and below the title's baseline is trimmed,
/// so the two lines span the 32-pt well as in Figma and the row stays 32-33 tall.
private struct TimelineLine<Well: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var capTrim: CGFloat = 3.4
    @ScaledMetric(relativeTo: .callout) private var baselineTrim: CGFloat = 3.9

    let span: String
    let title: String
    var titleColor: Color = Palette.textPrimary
    let duration: TimeInterval
    let showsChevron: Bool
    @ViewBuilder let well: Well

    var body: some View {
        let large = dynamicTypeSize.isAccessibilitySize
        HStack(spacing: Space.s) {
            well
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(verbatim: span)
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
                Text(verbatim: title)
                    .textRole(.body)
                    .foregroundStyle(titleColor)
                    .lineLimit(large ? nil : 2)
                if large {
                    DurationTrail(DurationText.short(duration), showsChevron: showsChevron)
                }
            }
            .padding(.top, -capTrim)
            .padding(.bottom, large ? 0 : -baselineTrim)
            .frame(maxWidth: .infinity, alignment: .leading)
            if !large {
                DurationTrail(DurationText.short(duration), showsChevron: showsChevron)
            }
        }
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
