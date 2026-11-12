import DwellCore
import DwellUI
import SwiftUI

// Time's sections below the hour grid, each from the Time design. Section headers are the
// app's `SectionHeader` (20, the art 20, 4 to the title); cards are 16 in, with a dashed line
// 12 under the header.

// MARK: - All categories

/// "All categories" on the page, not in a card (Time design): the header, a dashed line, then a
/// row per category, largest first, home last, dashed lines between them indented past the
/// badge; a full line, then how long Dwell slept, in the dial's voice.
struct TimeCategories: View {
    let report: TimeReport
    /// "this week".
    let this: String
    @Binding var collapsed: Set<PlaceCategory>
    var onOpen: (PlaceCategory) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(TimeCopy.allCategories, icon: Art.thisWeek)
            DashedDivider()
                .padding(.top, 10)
            ForEach(Array(report.lines.enumerated()), id: \.element.id) { index, line in
                if index > 0 {
                    DashedDivider()
                        .padding(.leading, 32)
                }
                CategoryRow(
                    line,
                    isExpanded: Binding(
                        get: { !collapsed.contains(line.category) },
                        set: { open in
                            if open { collapsed.remove(line.category) } else { collapsed.insert(line.category) }
                        }),
                    onOpen: { onOpen(line.category) })
                    .padding(.vertical, Space.m)
            }
            if report.unmapped >= 60 {
                DashedDivider()
                VoiceText(TimeCopy.asleep(report.unmapped, this: this))
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
            }
        }
    }
}

// MARK: - Work and yours

/// "Work and yours" (Time design; brief §7.3): the two numbers side by side on the hero tiles,
/// label over number, then a pair of bars for each of the last four periods. Never a ratio.
/// Peace and Plain call the second number "Yours", Grind "Off".
struct WorkAndYoursCard: View {
    let overview: TimeOverview
    let now: Date

    @Environment(\.calendar) private var calendar
    @Environment(\.dial) private var dial
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let yours = TimeCopy.yours.text(for: dial)
        VStack(alignment: .leading, spacing: 0) {
            // [ICON NEEDED] the design's 3D scales.
            SectionHeader(TimeCopy.workAndYours.text(for: dial), icon: Image(systemName: "scalemass.fill"))
            DashedDivider()
                .padding(.top, Space.m)
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: Space.s))
                : AnyLayout(HStackLayout(spacing: Space.s))
            layout {
                StatTile(
                    value: DurationText.short(overview.report.work), label: TimeCopy.atWork,
                    spokenValue: DurationText.spoken(overview.report.work), tint: PlaceCategory.work.color,
                    labelFirst: true
                ) { art(Art.heroWork) }
                StatTile(
                    value: DurationText.short(overview.report.yours), label: yours,
                    spokenValue: DurationText.spoken(overview.report.yours), tint: Palette.yours,
                    labelFirst: true
                ) { art(Art.heroYours) }
            }
            .padding(.top, Space.m)
            if overview.trend.count > 1 {
                TrendBars(
                    overview.trend.map { point in
                        TrendBars.Period(
                            id: point.id,
                            label: TimeCopy.trendLabel(point.period, now: now, calendar: calendar),
                            work: point.work, yours: point.yours, isShown: point.isShown)
                    },
                    workName: TimeCopy.atWork,
                    yoursName: yours)
                    .padding(.top, Space.l)
            }
        }
        .padding(Space.l)
        .card()
    }

    private func art(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
    }
}

// MARK: - Calendar vs reality

/// "Calendar vs reality" (Time design; brief §7.3): a ring of the period's meetings with "6/8
/// meetings" in it and the count of each state beside it; under them, in a grey box, what's
/// worth noticing, in the dial's voice. Without a calendar it sells the feature.
struct CalendarCard: View {
    let section: TimeOverview.CalendarSection
    let this: String
    let recordingSince: Date?
    let now: Date
    var onConnect: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(TimeCopy.calendarTitle, icon: Art.thisWeek)
            DashedDivider()
                .padding(.top, Space.m)
            switch section {
            case .notConnected:
                notConnected
                    .padding(.top, Space.l)
            case .report(let report) where report.scheduled == 0:
                VoiceText(TimeCopy.noMeetings(this: this))
                    .textRole(.body)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.top, Space.l)
            case .report(let report):
                ring(report)
                    .padding(.top, Space.l)
                notes(report)
                    .padding(.top, Space.l)
            }
        }
        .padding(Space.l)
        .card()
    }

    private func ring(_ report: CalendarReport) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Space.l))
            : AnyLayout(HStackLayout(spacing: Space.xl))
        return layout {
            MeetingRing(meetings(report), attended: report.attended, caption: TimeCopy.meetings(report.scheduled))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(TimeCopy.attendedSummary(report, this: this))
            VStack(spacing: 6) {
                legendRow(Palette.meetingAttended, TimeCopy.attended, report.attended)
                legendRow(Palette.meetingPartial, TimeCopy.leftEarly, report.leftEarly)
                legendRow(Palette.meetingMissed, TimeCopy.elsewhere, report.elsewhere)
                if report.unknown > 0 {
                    legendRow(Palette.separator, TimeCopy.noMatch, report.unknown)
                }
            }
        }
    }

    /// One mark per meeting, grouped: attended, then left early, elsewhere, no match.
    private func meetings(_ report: CalendarReport) -> [MeetingRing.Meeting] {
        func rank(_ state: CalendarMatch.State) -> Int {
            switch state {
            case .attended: 0
            case .partial: 1
            case .missed: 2
            case .unknown: 3
            }
        }
        return report.matches
            .sorted { rank($0.state) < rank($1.state) }
            .map { match in
                switch match.state {
                case .attended: MeetingRing.Meeting(id: match.id, state: TimeCopy.attended, color: Palette.meetingAttended)
                case .partial: MeetingRing.Meeting(id: match.id, state: TimeCopy.leftEarly, color: Palette.meetingPartial)
                case .missed: MeetingRing.Meeting(id: match.id, state: TimeCopy.elsewhere, color: Palette.meetingMissed)
                case .unknown: MeetingRing.Meeting(id: match.id, state: TimeCopy.noMatch, color: Palette.separator)
                }
            }
    }

    private func legendRow(_ color: Color, _ label: String, _ count: Int) -> some View {
        HStack(spacing: Space.s) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(verbatim: label)
                .textRole(.body)
                .foregroundStyle(Palette.textPrimary)
            Spacer(minLength: Space.s)
            Text(verbatim: "\(count)")
                .textRole(.body, monospacedDigits: true)
                .foregroundStyle(Palette.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func notes(_ report: CalendarReport) -> some View {
        InsetBox {
            VStack(alignment: .leading, spacing: 10) {
                Text(verbatim: TimeCopy.worthNoticing)
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .accessibilityAddTraits(.isHeader)
                if report.notes.isEmpty {
                    VoiceText(patternsAreYoung ? TimeCopy.patternsWaiting : TimeCopy.nothingToNotice)
                        .textRole(.body)
                        .foregroundStyle(Palette.textPrimary)
                }
                ForEach(Array(report.notes.enumerated()), id: \.element.id) { index, note in
                    if index > 0 {
                        DashedDivider()
                    }
                    // The design's ⊗ beside each note. A fact, not a scolding: the words carry it.
                    HStack(alignment: .firstTextBaseline, spacing: Space.s) {
                        Image(systemName: "xmark.circle")
                            .textRole(.body)
                            .foregroundStyle(Palette.textPrimary)
                            .accessibilityHidden(true)
                        VoiceText(TimeCopy.note(note.kind))
                            .textRole(.body)
                            .foregroundStyle(Palette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    /// Fewer than two weeks of meetings: patterns can't show yet.
    private var patternsAreYoung: Bool {
        guard let recordingSince else { return true }
        return now.timeIntervalSince(recordingSince) < Double(CalendarReport.weeksForPatterns) * 7 * 86_400
    }

    private var notConnected: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            VoiceText(TimeCopy.connectTitle)
                .textRole(.voice)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(verbatim: TimeCopy.connectDetail)
                .textRole(.body, weight: .regular)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(TimeCopy.connectAction, action: onConnect)
                .buttonStyle(.soft)
                .padding(.top, Space.s)
        }
    }
}

// MARK: - Your rhythm

/// "Your rhythm" (Time design; brief §7.3): the Weekday / Weekend toggle in the header, then the
/// typical day as a strip with its moments under it. Locked until Dwell has two weeks.
struct RhythmCard: View {
    let section: TimeOverview.RhythmSection
    @Binding var kind: Rhythm.Kind
    let day: DwellDay

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // [ICON NEEDED] the design's 3D rhythm art.
            SectionHeader(TimeCopy.rhythmTitle, icon: Image(systemName: "metronome.fill")) {
                if case .ready = section {
                    SegmentedPicker("Days", selection: $kind, options: Rhythm.Kind.allCases, size: .compact) { $0.title }
                }
            }
            DashedDivider()
                .padding(.top, Space.m)
            Group {
                switch section {
                case .locked(let daysToGo):
                    VoiceText(TimeCopy.rhythmLocked(daysToGo: daysToGo))
                        .textRole(.body)
                        .foregroundStyle(Palette.textSecondary)
                case .ready(let weekday, let weekend):
                    if let rhythm = kind == .weekday ? weekday : weekend {
                        RhythmStrip(rhythm, on: day)
                            .id(kind)
                            .transition(.opacity)
                    } else {
                        Text(verbatim: TimeCopy.rhythmMissing(kind))
                            .textRole(.body)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
            }
            .padding(.top, Space.l)
            .motion(value: kind)
        }
        .padding(Space.l)
        .card()
    }
}

// MARK: - Places over time

/// "Places over time" on the page (Time design): the places growing, shrinking and paused over
/// the last four weeks, each opening its place page.
struct PlacesOverTime: View {
    let trends: [PlaceTrend]
    var onOpen: (PlaceID) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(TimeCopy.placesTitle, icon: Art.Illustration.place)
            DashedDivider()
                .padding(.top, 10)
            if trends.isEmpty {
                Text(verbatim: TimeCopy.placesWaiting)
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.top, Space.m)
            }
            ForEach(Array(trends.enumerated()), id: \.element.id) { index, trend in
                if index > 0 {
                    DashedDivider()
                        .padding(.leading, 32)
                }
                Button {
                    onOpen(trend.placeID)
                } label: {
                    PlaceTrendRow(trend)
                }
                .buttonStyle(.plain)
                .padding(.vertical, Space.m)
            }
        }
    }
}

// MARK: - Records

/// The records wall (Time design; brief §7.3): lifetime bests two to a row, 12 apart, the
/// locked ones saying what wins them; one to a row at accessibility sizes.
struct RecordsWall: View {
    let records: [PersonalRecord]
    var onOpen: (PersonalRecord) -> Void = { _ in }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            // [ICON NEEDED] the design's 3D trophy.
            SectionHeader(TimeCopy.recordsTitle, icon: Image(systemName: "trophy.fill"))
            if dynamicTypeSize.isAccessibilitySize {
                ForEach(records) { record in
                    tile(record)
                }
            } else {
                Grid(horizontalSpacing: Space.m, verticalSpacing: Space.m) {
                    ForEach(Array(stride(from: 0, to: records.count, by: 2)), id: \.self) { index in
                        GridRow {
                            tile(records[index])
                            if records.indices.contains(index + 1) {
                                tile(records[index + 1])
                            } else {
                                Color.clear
                            }
                        }
                    }
                }
            }
        }
    }

    private func tile(_ record: PersonalRecord) -> some View {
        Button {
            onOpen(record)
        } label: {
            RecordTile(record)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }
}
