import DwellCore
import DwellUI
import SwiftUI

/// The day as a list, newest first (Today design, "Your day"). Shows the last three visits
/// with what came between them; "View more" opens the whole day. Transit and gaps are slim
/// rows, and a gap always reads as a gap ("Dwell was asleep · 22m").
struct DayTimelineCard: View {
    let snapshot: DaySnapshot
    let now: Date
    let isToday: Bool
    var onOpenPlace: (PlaceID) -> Void = { _ in }
    var onReview: (Visit) -> Void = { _ in }

    static let collapsedVisits = 3

    @Environment(\.calendar) private var calendar
    @State private var isExpanded = false

    var body: some View {
        let all = Array(snapshot.entries.reversed())
        let shown = isExpanded ? all : Self.collapsed(all)
        VStack(alignment: .leading, spacing: Space.m) {
            // [ICON NEEDED] the design's 3D sun and clock.
            SectionHeader("Your day", icon: Image(systemName: "sun.max.fill"))
            DashedDivider()

            if all.isEmpty {
                Text(verbatim: TodayCopy.timelineEmpty)
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
            }

            ForEach(Array(shown.enumerated()), id: \.element.id) { offset, entry in
                if offset > 0, entry.visit != nil, shown[offset - 1].visit != nil {
                    DashedDivider()
                }
                row(entry)
            }

            if shown.count < all.count || isExpanded {
                Button(isExpanded ? "View less" : "View more") {
                    isExpanded.toggle()
                }
                .buttonStyle(.soft)
            }
        }
        .padding(Space.l)
        .card()
        .motion(value: isExpanded)
    }

    @ViewBuilder
    private func row(_ entry: TimelineEntry) -> some View {
        switch entry {
        case .visit(let visit):
            VisitRow(
                visit: visit,
                span: ClockText.span(from: visit.arrival, to: visit.departure, calendar: calendar),
                duration: visit.interval(now: now).duration,
                showsChevron: visit.placeID != nil,
                onReview: isToday && visit.needsReview ? { onReview(visit) } : nil)
                .contentShape(.rect)
                .onTapGesture {
                    if let id = visit.placeID { onOpenPlace(id) }
                }
                .accessibilityAddTraits(visit.placeID == nil ? [] : .isButton)
                .accessibilityAction {
                    if let id = visit.placeID { onOpenPlace(id) }
                }
        case .transit(let interval):
            TimelineNote(TodayCopy.transitRow(interval.duration), symbol: "tram.fill", isGap: false)
        case .gap(let interval):
            TimelineNote(TodayCopy.gapRow(interval.duration), symbol: "moon.zzz", isGap: true)
        }
    }

    /// Newest first, up to the third visit, with whatever came between them.
    static func collapsed(_ entries: [TimelineEntry]) -> [TimelineEntry] {
        var shown: [TimelineEntry] = []
        var visits = 0
        for entry in entries {
            if entry.visit != nil {
                guard visits < collapsedVisits else { break }
                visits += 1
            }
            shown.append(entry)
        }
        while let last = shown.last, last.visit == nil, shown.count < entries.count {
            shown.removeLast()
        }
        return shown
    }
}
