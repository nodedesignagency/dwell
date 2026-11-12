import DwellCore
import SwiftUI

/// Your rhythm's strip (Time design, "Your Rhythm"): a typical day from arrival to home as one
/// bar in four stretches (to lunch, lunch, the afternoon, the way home), each in its colour with
/// light diagonal stripes, 3 apart, rounded at the ends; under it the moments in columns, the
/// label 14 grey over the time 16 in ink.
///
/// The stretches keep their real lengths (the design draws them about even), never thinner
/// than 10 pt, so lunch stays visible.
public struct RhythmStrip: View {
    @Environment(\.calendar) private var calendar
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 20
    private let rhythm: Rhythm
    private let day: DwellDay

    /// - Parameter day: any day, to turn minutes after 4 AM into clock times.
    public init(_ rhythm: Rhythm, on day: DwellDay) {
        self.rhythm = rhythm
        self.day = day
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GeometryReader { proxy in
                strip(width: proxy.size.width)
            }
            .frame(height: height)
            .accessibilityHidden(true)

            HStack(alignment: .top, spacing: Space.s) {
                ForEach(rhythm.moments, id: \.mark) { moment in
                    VStack(alignment: .leading, spacing: Space.xs) {
                        Text(verbatim: moment.mark.title)
                            .textRole(.caption)
                            .foregroundStyle(Palette.textSecondary)
                        Text(verbatim: time(moment))
                            .textRole(.body, monospacedDigits: true)
                            .foregroundStyle(Palette.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rhythm.moments.map { "\($0.mark.title) \(time($0))" }.joined(separator: ", "))
    }

    private func time(_ moment: Rhythm.Moment) -> String {
        ClockText.time(rhythm.date(of: moment, on: day, calendar: calendar), calendar: calendar)
    }

    private func strip(width: CGFloat) -> some View {
        let stretches = rhythm.stretches
        let gap: CGFloat = 3
        let first = stretches.first?.start ?? 0
        let last = stretches.last?.end ?? 1
        let room = max(0, width - gap * CGFloat(max(0, stretches.count - 1)))
        let minimum: CGFloat = 10
        let raw = stretches.map { CGFloat(($0.end - $0.start) / max(1, last - first)) * room }
        let short = raw.filter { $0 < minimum }.count
        let longTotal = raw.filter { $0 >= minimum }.reduce(0, +)
        let spare = room - CGFloat(short) * minimum
        let widths = raw.map { $0 < minimum ? minimum : $0 / max(1, longTotal) * spare }
        return HStack(spacing: gap) {
            ForEach(Array(stretches.enumerated()), id: \.offset) { index, stretch in
                let shape = UnevenRoundedRectangle(
                    topLeadingRadius: index == 0 ? height / 2 : 4,
                    bottomLeadingRadius: index == 0 ? height / 2 : 4,
                    bottomTrailingRadius: index == stretches.count - 1 ? height / 2 : 4,
                    topTrailingRadius: index == stretches.count - 1 ? height / 2 : 4)
                shape
                    .fill(color(stretch.phase))
                    .overlay {
                        DiagonalStripes(spacing: 7)
                            .stroke(.white.opacity(0.22), lineWidth: 2.5)
                            .scaleEffect(x: -1)
                            .clipShape(shape)
                    }
                    .frame(width: widths[index])
            }
        }
    }

    private func color(_ phase: Rhythm.Phase) -> Color {
        switch phase {
        case .morning: Palette.rhythmMorning
        case .lunch: Palette.rhythmLunch
        case .afternoon: Palette.rhythmAfternoon
        case .wayHome: Palette.rhythmWayHome
        }
    }
}

/// A record on the records wall (Time design, "Records"). Won: a band in the record's colour
/// with its name in capitals, holding a white card with the value (18 medium), the day it was
/// set (14 grey) and its 3D art. Still to win: a dashed outline, the name, and a grey box saying
/// what wins it. Measured from the screenshot: 20-pt corners, the card 4 in, its corners 16.
public struct RecordTile: View {
    @Environment(\.calendar) private var calendar
    @ScaledMetric(relativeTo: .title3) private var iconSize: CGFloat = 34
    private let record: PersonalRecord

    public init(_ record: PersonalRecord) {
        self.record = record
    }

    public var body: some View {
        Group {
            if record.isLocked {
                locked
            } else {
                won
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private var title: some View {
        Text(verbatim: record.title)
            .textCase(.uppercase)
            .textRole(.footnote, weight: .medium, tracking: 0)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, Space.s)
            .padding(.vertical, 5)
    }

    private var won: some View {
        VStack(spacing: 0) {
            title
                .foregroundStyle(.black.opacity(0.7))
            HStack(spacing: Space.s) {
                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text(verbatim: record.value ?? "")
                        .textRole(.rowTitle, monospacedDigits: true)
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if let date = TimeCopy.recordDate(record, calendar: calendar) {
                        Text(verbatim: date)
                            .textRole(.caption)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
                Spacer(minLength: 0)
                RecordArt(record.icon)
                    .frame(width: iconSize, height: iconSize)
            }
            .padding(.horizontal, Space.m)
            .padding(.vertical, 10)
            .frame(maxHeight: .infinity)
            .background(Palette.surface, in: .rect(cornerRadius: Radius.l))
            .padding([.horizontal, .bottom], Space.xs)
        }
        .card(fill: tint)
    }

    private var locked: some View {
        VStack(spacing: 0) {
            title
                .foregroundStyle(Palette.textPrimary)
            HStack(spacing: Space.s) {
                Text(verbatim: record.unlockHint ?? "")
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                RecordArt(record.icon)
                    .frame(width: iconSize, height: iconSize)
                    .opacity(0.7)
            }
            .padding(.horizontal, Space.m)
            .padding(.vertical, 10)
            .frame(maxHeight: .infinity)
            .background(Palette.recordLocked, in: .rect(cornerRadius: Radius.l))
            .padding([.horizontal, .bottom], Space.xs)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.xl)
                .strokeBorder(Palette.separator, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
    }

    private var tint: Color {
        switch record.kind {
        case .duration: Palette.recordDuration
        case .timeOfDay: Palette.recordTime
        case .streak: Palette.recordStreak
        case .count: Palette.recordCount
        }
    }

    private var spoken: String {
        if record.isLocked {
            return "\(record.title), not set yet. \(record.unlockHint ?? "")" // [COPY NEEDED]
        }
        let date = TimeCopy.recordDate(record, calendar: calendar).map { ", \($0)" } ?? ""
        return "\(record.title), \(record.value ?? "")\(date)"
    }
}

/// A record's art: the design's 3D hourglass, alarm clock, flame, globe, sunset and compass.
/// [ICON NEEDED] SF Symbols stand in, in the 3D art's greys, until the art arrives.
public struct RecordArt: View {
    private let icon: PersonalRecord.Icon

    public init(_ icon: PersonalRecord.Icon) {
        self.icon = icon
    }

    public var body: some View {
        Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Palette.textPrimary.opacity(0.8))
            .padding(3)
            .accessibilityHidden(true)
    }

    private var symbol: String {
        switch icon {
        case .hourglass: "hourglass"
        case .alarmClock: "alarm.fill"
        case .flame: "flame.fill"
        case .globe: "globe.americas.fill"
        case .sunset: "sunset.fill"
        case .compass: "safari.fill"
        }
    }
}

/// The way into the year (Time design, "2026 in places, so far"): a purple card with the weekly
/// wrap invite's turning white rays, the year in a sentence (28, white) and "Open your year" on
/// a white capsule. Left-aligned, 20 in. Always the light scheme, so it looks the same in dark
/// mode, like the wrap invite.
public struct YearCard: View {
    private let caption: String
    private let title: String
    private let action: String
    private let onOpen: () -> Void

    public init(caption: String, title: String, action: String, onOpen: @escaping () -> Void) {
        self.caption = caption
        self.title = title
        self.action = action
        self.onOpen = onOpen
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(verbatim: caption)
                    .textRole(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                Text(verbatim: title)
                    .textRole(.cardTitle)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Button(action: onOpen) {
                Text(verbatim: action)
                    .textRole(.label)
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, Space.l)
                    .padding(.vertical, Space.s)
                    .background(.white, in: .capsule)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
        .padding(.horizontal, Space.screen)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            WrapGlow()
                .clipShape(.rect(cornerRadius: Radius.xl))
        }
        .card(fill: EllipticalGradient(
            colors: [Palette.yearCentre, Palette.yearEdge],
            center: UnitPoint(x: 0.45, y: 0.6),
            startRadiusFraction: 0,
            endRadiusFraction: 0.6))
        .environment(\.colorScheme, .light)
    }
}

/// A box set into a card (Time design, Calendar vs reality's "Worth noticing"): `insetSurface`,
/// 16-pt corners, 16 across and 12 down.
public struct InsetBox<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(.horizontal, Space.l)
            .padding(.vertical, Space.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.insetSurface, in: .rect(cornerRadius: Radius.l))
    }
}
