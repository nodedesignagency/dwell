import DwellCore
import DwellUI
import SwiftUI

/// What Time's controls do. Screens wire these; previews leave them empty.
struct TimeActions {
    var pickPeriod: () -> Void = {}
    var share: () -> Void = {}
    var retry: () -> Void = {}
    var openCategory: (PlaceCategory) -> Void = { _ in }
    var openPlace: (PlaceID) -> Void = { _ in }
    var openRecord: (PersonalRecord) -> Void = { _ in }
    var openYear: () -> Void = {}
    var connectCalendar: () -> Void = {}
    var fixPermission: (PermissionBanner) -> Void = { _ in }
}

/// Time's layout for any state, with no loading of its own: previews drive it directly.
///
/// Read from the screenshot (iPhone, 393 pt), top to bottom, everything scrolling together on
/// the page's grey: "Time" (24), the date pill centred on the screen and the share button on
/// glass, 17 below the status bar and 16 from the edges; 18 to the range control; 16 to the
/// headline (24, lines 32 apart, data in navy, words in grey); 14 to the "Every hour" card;
/// then, 20 apart, "All categories" on the page, the Work and yours, Calendar vs reality and
/// Your rhythm cards, "Places over time" and "Records" on the page, and the year in places.
/// Content is 20 from the edges.
struct TimeContent: View {
    let state: Loadable<TimeOverview>
    let period: TimePeriod
    @Binding var range: TimeRange
    let now: Date
    var actions = TimeActions()

    @Environment(\.calendar) private var calendar
    @Environment(\.dial) private var dial
    @Environment(\.permissions) private var permissions
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var collapsed: Set<PlaceCategory> = []
    @State private var rhythmKind: Rhythm.Kind = .weekday

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                SegmentedPicker("Range", selection: $range, options: TimeRange.allCases) { $0.title }
                    .padding(.horizontal, Space.screen)
                    .padding(.top, 18)
                content
                    .padding(.horizontal, Space.screen)
            }
            .padding(.bottom, Space.xxl)
        }
        .background(Palette.background)
    }

    // MARK: Header

    private var header: some View {
        let large = dynamicTypeSize.isAccessibilitySize
        return VStack(alignment: .leading, spacing: Space.s) {
            ZStack {
                HStack {
                    Text(verbatim: TimeCopy.title)
                        .textRole(.pageTitle)
                        .foregroundStyle(Palette.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: Space.s)
                    Button(action: actions.share) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.primary)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.glassSquare)
                    .accessibilityLabel("Share")
                }
                if !large {
                    periodPill
                }
            }
            if large {
                periodPill
            }
        }
        .padding(.horizontal, Space.l)
        .padding(.top, 17)
    }

    /// The design's date pill: the 3D calendar, the period, a chevron; opens the picker.
    private var periodPill: some View {
        let label = TimeCopy.label(period, calendar: calendar)
        return Button(action: actions.pickPeriod) {
            HStack(spacing: 6) {
                Art.calendar
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .accessibilityHidden(true)
                Text(verbatim: label)
                    .textRole(.caption, weight: .medium, tracking: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.leading, 2)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Palette.textPrimary)
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Choose a \(period.range.noun)") // [COPY NEEDED]
        .accessibilityValue(label)
    }

    // MARK: States

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            banners(staleSince: nil)
            TimeSkeleton()
                .padding(.top, Space.l)
        case .empty, .stillMapping:
            banners(staleSince: nil)
            // Nothing mapped yet: what Time is waiting for, not empty charts.
            WaitingCard(title: TimeCopy.waitingTitle, detail: TimeCopy.waitingDetail) {
                Art.Illustration.chart
                    .resizable()
                    .scaledToFit()
            }
            .padding(.top, Space.xl)
        case .failed(let failure):
            banners(staleSince: nil)
            failed(failure)
                .padding(.top, Space.xl)
        case .loaded(let overview, let staleSince):
            banners(staleSince: staleSince)
            loaded(overview)
        }
    }

    @ViewBuilder
    private func loaded(_ overview: TimeOverview) -> some View {
        let this = TimeCopy.this(period, now: now, calendar: calendar)
        headline(overview)
            .padding(.top, Space.l)
        if overview.report.isEmpty {
            EmptyView()
        } else {
            if let daysToGo = overview.learningDaysToGo {
                VoiceText(TimeCopy.stillLearning(period.range, daysToGo: daysToGo))
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.top, Space.s)
            }
            everyHour(overview, this: this)
                .padding(.top, 14)
            TimeCategories(
                report: overview.report,
                this: this,
                collapsed: $collapsed,
                onOpen: actions.openCategory)
                .padding(.top, Space.screen)
            WorkAndYoursCard(overview: overview, now: now)
                .padding(.top, Space.screen)
            CalendarCard(section: overview.calendarSection, this: this, recordingSince: overview.recordingSince, now: now, onConnect: actions.connectCalendar)
                .padding(.top, Space.screen)
            RhythmCard(section: overview.rhythm, kind: $rhythmKind, day: DwellDay(containing: now, calendar: calendar))
                .padding(.top, Space.screen)
        }
        PlacesOverTime(trends: overview.placeTrends, onOpen: actions.openPlace)
            .padding(.top, Space.xl)
        RecordsWall(records: overview.records, onOpen: actions.openRecord)
            .padding(.top, Space.xl)
        if let year = overview.year {
            YearCard(
                caption: TimeCopy.yearCaption(year.year, isCurrent: year.isCurrent),
                title: TimeCopy.yearTitle(places: year.places, coverage: year.coverage, records: year.records),
                action: TimeCopy.openYear,
                onOpen: actions.openYear)
                .padding(.top, Space.xl)
        }
    }

    @ViewBuilder
    private func headline(_ overview: TimeOverview) -> some View {
        let lead = TimeCopy.lead(period, now: now, calendar: calendar)
        let this = TimeCopy.this(period, now: now, calendar: calendar)
        if overview.report.isEmpty {
            headlineLine(TimeCopy.beforeRecording(this: this))
        } else if overview.report.totals.values.reduce(0, +) < 60 {
            headlineLine(TimeCopy.nothingMapped(this: this))
        } else if let sentence = TimeCopy.headline(overview.report, lead: lead) {
            VoicedSentenceView(sentence, role: .voiceHero, ink: Palette.textOnHero, dataInk: Palette.textPrimary)
        } else {
            headlineLine(TimeCopy.quietHeadline(lead: lead))
        }
    }

    private func headlineLine(_ line: VoicedLine) -> some View {
        VoiceText(line)
            .textRole(.voiceHero)
            .foregroundStyle(Palette.textOnHero.opacity(0.7))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    /// "Your days, 4AM to 4AM · Every hour of the week" (Time design): caption (16, grey), 4
    /// to the title (28), 4 to the dashed line, 12 to the grid; 12 down and 16 across inside.
    private func everyHour(_ overview: TimeOverview, this: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: TimeCopy.gridCaption(period.range, calendar: calendar))
                .textRole(.body, weight: .regular)
                .foregroundStyle(Palette.textSecondary)
            Text(verbatim: TimeCopy.gridTitle(period.range))
                .textRole(.cardTitle)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, Space.xs)
            DashedDivider()
                .padding(.top, Space.xs)
            HourGridView(overview.grid, this: this)
                .padding(.top, Space.m)
        }
        .padding(.horizontal, Space.l)
        .padding(.top, Space.m)
        .padding(.bottom, Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func failed(_ failure: LoadFailure) -> some View {
        ContentUnavailableView {
            switch failure {
            case .offline: Label(TodayCopy.offline, systemImage: "wifi.slash")
            case .unavailable: Label(TimeCopy.couldNotLoad, systemImage: "exclamationmark.triangle")
            }
        } description: {
            // [COPY NEEDED]
            switch failure {
            case .offline: Text(verbatim: "Time loads once you're back online.")
            case .unavailable: Text(verbatim: "Try again in a moment.")
            }
        } actions: {
            Button(failure == .offline ? TodayCopy.retrySync : "Retry", action: actions.retry)
                .buttonStyle(.borderedProminent)
                .tint(Palette.textPrimary)
        }
        .padding(.vertical, Space.xl)
        .card()
    }

    /// One permission banner at a time (brief §8.3), then the stale line, over usable content.
    @ViewBuilder
    private func banners(staleSince: Date?) -> some View {
        if let banner = permissions.banner {
            NoticeBanner(symbol: banner.symbol, message: banner.message, actionTitle: banner.actionTitle) {
                actions.fixPermission(banner)
            }
            .padding(.top, Space.l)
        }
        if let staleSince {
            NoticeBanner(
                symbol: "arrow.clockwise",
                message: TodayCopy.stale(since: staleSince, calendar: calendar),
                actionTitle: TodayCopy.retrySync,
                action: actions.retry)
                .padding(.top, Space.l)
        }
    }
}

// MARK: - Skeleton

/// Time's shape while it loads: the headline's lines and the card. Static, so there's nothing
/// to reduce under Reduce Motion.
struct TimeSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            SkeletonBar(width: 300)
            SkeletonBar(width: 260)
            SkeletonBar(width: 120)
            VStack(alignment: .leading, spacing: Space.m) {
                SkeletonBar(width: 140)
                SkeletonBar(width: 240)
                Spacer(minLength: 0)
            }
            .padding(Space.l)
            .frame(maxWidth: .infinity, minHeight: 340, alignment: .topLeading)
            .card()
            .padding(.top, Space.s)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading Time")
    }
}
