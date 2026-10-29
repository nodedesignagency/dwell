import DwellCore
import DwellUI
import SwiftUI

/// The heartbeat (brief §7.1): where you are and for how long, today's day bar, and the two
/// hero stats the dial picks. On a past day the live status drops away.
struct LiveCard: View {
    let status: LiveStatus?
    let snapshot: DaySnapshot
    let now: Date
    let isToday: Bool
    var showsStats = true
    var onOpenPlace: (PlaceID) -> Void = { _ in }

    @Environment(\.dial) private var dial
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let recap = snapshot.recap(now: now)
        VStack(spacing: 0) {
            if let status {
                LiveStatusView(status: status, now: now, onOpenPlace: onOpenPlace)
                    .padding(.top, Space.screen)
                    .padding(.bottom, 19)
            }
            DayBarView(DayBar(snapshot: snapshot, now: now), title: isToday ? "Today so far" : "The day")
            if showsStats {
                let stats = HeroStat.pair(for: dial.stop)
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(spacing: 7))
                    : AnyLayout(HStackLayout(spacing: 7))
                layout {
                    tile(stats.0, recap)
                    tile(stats.1, recap)
                }
                .padding(.top, 6)
                .motion(value: dial.stop)
            }
        }
        .padding(.horizontal, Space.s)
        .padding(.top, Space.s)
        .padding(.bottom, 6)
        .card()
    }

    /// Labels are plain labels, never voiced. Icons are stand-ins until the design's 3D
    /// briefcase and sunrise are exported. [ICON NEEDED]
    @ViewBuilder
    private func tile(_ stat: HeroStat, _ recap: DayRecap) -> some View {
        switch stat {
        case .work:
            StatTile(
                value: DurationText.short(recap.work), label: "At work",
                spokenValue: DurationText.spoken(recap.work), tint: PlaceCategory.work.color
            ) { standIn("briefcase.fill") }
        case .yours:
            StatTile(
                value: DurationText.short(recap.yours), label: "Yours",
                spokenValue: DurationText.spoken(recap.yours), tint: Palette.yours
            ) { standIn("sun.horizon.fill") }
        case .sessions:
            StatTile(
                value: "\(recap.workSessions)", label: recap.workSessions == 1 ? "Session" : "Sessions",
                tint: PlaceCategory.work.color
            ) { standIn("repeat") }
        }
    }

    private func standIn(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Palette.textPrimary)
            .padding(5)
    }
}

/// The big timer and the caption under it. The timer ticks on the minute and is always an
/// estimate; a quiet phone freezes it to "last seen" rather than pretending it still runs.
struct LiveStatusView: View {
    let status: LiveStatus
    let now: Date
    var onOpenPlace: (PlaceID) -> Void = { _ in }

    @Environment(\.calendar) private var calendar
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Space.l) {
            if let big {
                Text(verbatim: big.text)
                    .textRole(.dataHero)
                    .foregroundStyle(big.isLive ? Palette.textPrimary : Palette.textSecondary)
                    .contentTransition(reduceMotion ? .opacity : .numericText(value: big.minutes))
                    .motion(value: big.text)
                    .accessibilityLabel(big.spoken)
            }
            HStack(alignment: .firstTextBaseline, spacing: Space.xs) {
                LiveDot(color: dotColor)
                VoiceText(TodayCopy.liveCaption(status, calendar: calendar))
                    .textRole(.body)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .onTapGesture {
            if let placeID { onOpenPlace(placeID) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(placeID == nil ? [] : .isButton)
    }

    private struct Big {
        var text: String
        var spoken: String
        var minutes: Double
        var isLive: Bool
    }

    private var big: Big? {
        switch status {
        case .atPlace(let visit):
            return running(now.timeIntervalSince(visit.arrival))
        case .inTransit(let since):
            return running(now.timeIntervalSince(since))
        case .lastKnown(_, let lastSeen):
            let time = ClockText.time(lastSeen, calendar: calendar)
            return Big(text: time, spoken: "Last seen \(time)", minutes: 0, isLive: false)
        case .unknown, .noPermission:
            return nil
        }
    }

    private func running(_ interval: TimeInterval) -> Big {
        Big(
            text: DurationText.short(interval),
            spoken: "\(DurationText.spoken(interval)), estimate",
            minutes: (interval / 60).rounded(.down),
            isLive: true)
    }

    private var placeID: PlaceID? {
        if case .atPlace(let visit) = status { visit.placeID } else { nil }
    }

    private var dotColor: Color {
        switch status {
        case .atPlace: Palette.live
        case .inTransit: PlaceCategory.transit.color
        case .lastKnown, .unknown, .noPermission: Palette.textSecondary
        }
    }
}

private struct LiveDot: View {
    @ScaledMetric(relativeTo: .callout) private var size: CGFloat = 8
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .padding(size * 0.375)
            .background(color.opacity(0.12), in: .circle)
            .accessibilityHidden(true)
    }
}
