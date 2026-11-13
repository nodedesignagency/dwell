import DwellCore
import DwellUI
import SwiftUI

/// Today's layout for any state, with no loading of its own: previews drive it directly.
///
/// The header (avatar, day pill, headline) sits on the sunrise and stays put; the sheet with
/// the live card, the insight deck and the day scrolls up over it and covers it. Pulling down
/// shows more sky (its last colour runs on below it) rather than a gap. While a visit needs a yes, the
/// confirmation card floats above the tab bar.
struct TodayContent: View {
    let state: Loadable<TodayModel>
    let day: DwellDay
    let isToday: Bool
    let now: Date
    var actions = TodayActions()

    @Environment(\.calendar) private var calendar
    @Environment(\.permissions) private var permissions
    @Environment(\.skyPhase) private var skyOverride
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.wrapZoom) private var wrapZoom

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    TodayHeader(
                        sky: skyOverride ?? SkyPhase(date: now, calendar: calendar),
                        headline: headline,
                        dayLabel: isToday ? "Today" : ClockText.dayName(day, calendar: calendar),
                        topInset: proxy.safeAreaInsets.top,
                        onProfile: actions.openProfile,
                        onPickDay: actions.pickDay)
                    // Pinned: cancel the scroll so the header stays where it is. The sheet comes
                    // later in the stack, so it draws on top and covers the header as it rises.
                    .visualEffect { content, geometry in
                        content.offset(y: -geometry.frame(in: .scrollView).minY)
                    }
                    sheet
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Palette.background)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Animate the card coming and going, and nothing else: on the whole screen this
                // also animated Today's first layout, which grew in from the middle at launch.
                ZStack { confirmation }
                    .motion(Motion.arrive, value: confirmationID)
            }
        }
    }

    // MARK: Header

    private var headline: TodayHeadline {
        switch state {
        case .loading: return .placeholder
        case .failed: return .none
        case .stillMapping: return .sentence(TodayCopy.firstStopHeadline)
        case .empty: return .line(isToday ? TodayCopy.emptyToday : TodayCopy.emptyPastDay)
        case .loaded(let model, _):
            let recap = model.snapshot.recap(now: now)
            let dayName = ClockText.dayName(day, calendar: calendar)
            if let sentence = TodayCopy.headline(recap, isToday: isToday, dayName: dayName) {
                return .sentence(sentence)
            }
            return .line(isToday ? TodayCopy.emptyToday : TodayCopy.emptyPastDay)
        }
    }

    // MARK: Sheet

    private var sheet: some View {
        VStack(spacing: Space.screen) {
            switch state {
            case .loading:
                banners(staleSince: nil)
                TodaySkeleton()
            case .empty:
                loaded(.empty(day, isToday: isToday, calendar: calendar), staleSince: nil)
            case .stillMapping:
                gettingStarted
            case .failed(let failure):
                banners(staleSince: nil)
                failed(failure)
            case .loaded(let model, let staleSince):
                loaded(model, staleSince: staleSince)
            }
        }
        .padding(.horizontal, Space.l)
        .padding(.top, Space.l)
        .padding(.bottom, Space.xxl)
        .frame(maxWidth: .infinity)
        .background {
            // Runs on well below the content, so overscrolling at the end shows the sheet,
            // never the sky's colour waiting underneath for a pull-down at the top.
            UnevenRoundedRectangle(topLeadingRadius: Radius.xxl, topTrailingRadius: Radius.xxl)
                .fill(Palette.background)
                .padding(.bottom, -1000)
        }
    }

    @ViewBuilder
    private func loaded(_ model: TodayModel, staleSince: Date?) -> some View {
        banners(staleSince: staleSince)
        if isToday, let wrap = model.wrapToOpen {
            // Today design, "Weekly Wrap": the invite leads the sheet. A dashed divider sets it
            // off from the live card, 20 above and below like every section (the user, 13 Nov).
            WeeklyWrapCard(
                label: ClockText.dayRange(wrap.firstDay, wrap.lastDay, calendar: calendar),
                title: TodayCopy.wrapInviteTitle,
                action: TodayCopy.wrapInviteAction,
                onOpen: { actions.openWeeklyWrap(wrap) })
                // The wrap grows out of the card (iOS 18 and later).
                .wrapZoomSource(id: wrap.id, in: wrapZoom)
            DashedDivider()
        }
        LiveCard(
            status: model.liveStatus,
            snapshot: model.snapshot,
            now: now,
            isToday: isToday,
            onOpenPlace: actions.openPlace)
        // In a new user's first week, an empty deck stays and says what it's waiting for
        // (Today design, "after a few minutes"); after that, the engine's fallback keeps it full.
        if isToday, !model.insights.isEmpty || model.snapshot.isLearning(now: now) {
            DashedDivider()
            InsightDeck(
                insights: model.insights,
                onOpen: actions.openInsight,
                onShare: actions.share,
                onNotUseful: actions.notUseful)
        }
        DashedDivider()
        DayTimelineCard(
            snapshot: model.snapshot,
            now: now,
            isToday: isToday,
            onOpenPlace: actions.openPlace,
            onReview: actions.pickAnother)
    }

    /// Day 0, before the first stop (Today design, "Getting Started"; brief §3.1): icons
    /// shuffling while Dwell waits, "Waiting for your first stop" over the live dot, then the
    /// Now / Next / Then checklist. No live card, day bar or timeline: nothing to show yet.
    @ViewBuilder
    private var gettingStarted: some View {
        banners(staleSince: nil)
        // Figma: the icon (80) 26 below the sheet's top, 16 to the title (22), 6 to the line.
        VStack(spacing: 0) {
            IconShuffle(Art.firstStopIcons)
                .frame(width: 80, height: 80)
            Text(verbatim: TodayCopy.waitingForFirstStop)
                .textRole(.voice)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, Space.l)
            LiveLabel(color: Palette.live, pulses: true) {
                Text(verbatim: TodayCopy.mappingRightNow)
                    .textRole(.body)
                    .foregroundStyle(Palette.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .padding(.top, 6)
        }
        .padding(.top, 10)
        .padding(.bottom, Space.xs)
        .frame(maxWidth: .infinity)

        DashedDivider()

        // Figma: the header 16 above the first step, steps 10 apart.
        VStack(alignment: .leading, spacing: Space.l) {
            SectionHeader(TodayCopy.gettingStarted, icon: Art.gettingStarted)
            VStack(spacing: 10) {
                ForEach(Array(TodayCopy.gettingStartedSteps.enumerated()), id: \.offset) { offset, step in
                    StepRow(number: offset + 1, tag: step.tag, title: step.title, detail: step.detail)
                }
            }
        }
    }

    private func failed(_ failure: LoadFailure) -> some View {
        ContentUnavailableView {
            switch failure {
            case .offline: Label(TodayCopy.offline, systemImage: "wifi.slash")
            case .unavailable: Label(TodayCopy.couldNotLoad, systemImage: "exclamationmark.triangle")
            }
        } description: {
            // [COPY NEEDED]
            switch failure {
            case .offline: Text(verbatim: "Today loads once you're back online.")
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

    /// One permission banner at a time (brief §8.3), then the stale line if Today is old.
    @ViewBuilder
    private func banners(staleSince: Date?) -> some View {
        if let banner = permissions.banner {
            NoticeBanner(symbol: banner.symbol, message: banner.message, actionTitle: banner.actionTitle) {
                actions.fixPermission(banner)
            }
        }
        if let staleSince {
            NoticeBanner(
                symbol: "arrow.clockwise",
                message: TodayCopy.stale(since: staleSince, calendar: calendar),
                actionTitle: TodayCopy.retrySync,
                action: actions.retry)
        }
    }

    // MARK: Confirmation

    private var visitToConfirm: Visit? {
        isToday ? state.value?.visitToConfirm : nil
    }

    private var confirmationID: VisitID? { visitToConfirm?.id }

    @ViewBuilder
    private var confirmation: some View {
        if let visit = visitToConfirm {
            let duration = visit.interval(now: now).duration
            ConfirmationCard(
                question: TodayCopy.confirmQuestion,
                value: DurationText.short(duration),
                detail: TodayCopy.confirmDetail(placeName: visit.placeName),
                sentence: TodayCopy.confirmVisit(placeName: visit.placeName, duration: duration),
                onLooksRight: { actions.confirm(visit) },
                onPickAnother: { actions.pickAnother(visit) }
            ) {
                CategoryIcon(visit.category, style: .illustration)
            }
            .padding(.horizontal, Space.l)
            .padding(.bottom, Space.s)
            .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Header

/// Avatar, the day pill and the headline, on the sky for this time of day. The sky runs up
/// under the status bar and down under the sheet's rounded corners. Text follows the sky,
/// not light or dark mode: dark ink by day, light ink at sunset and night.
struct TodayHeader: View {
    let sky: SkyPhase
    let headline: TodayHeadline
    let dayLabel: String
    let topInset: CGFloat
    var onProfile: () -> Void = {}
    var onPickDay: () -> Void = {}

    @ScaledMetric(relativeTo: .callout) private var pillIcon: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            HStack {
                Button(action: onProfile) {
                    Avatar(Art.sampleAvatar)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Profile")

                Spacer()

                Button(action: onPickDay) {
                    HStack(spacing: Space.xs) {
                        Art.calendar
                            .resizable()
                            .scaledToFit()
                            .frame(width: pillIcon, height: pillIcon)
                            .accessibilityHidden(true)
                        Text(verbatim: dayLabel)
                            .textRole(.label, tracking: 0)
                            .foregroundStyle(Palette.textPrimary)
                    }
                    .padding(10)
                    .background(Palette.glass, in: .rect(cornerRadius: Radius.m))
                }
                .buttonStyle(.plain)
                // White glass in every sky, as designed; its calendar art is drawn for light.
                .environment(\.colorScheme, .light)
                .accessibilityLabel("Choose a day")
                .accessibilityValue(dayLabel)
            }

            switch headline {
            case .sentence(let sentence):
                VoicedSentenceView(sentence, role: .voiceHero, ink: Palette.textOnHero)
            case .line(let line):
                VoiceText(line)
                    .textRole(.voiceHero)
                    .foregroundStyle(Palette.textOnHero)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            case .placeholder:
                VStack(alignment: .leading, spacing: Space.m) {
                    SkeletonBar(width: 300)
                    SkeletonBar(width: 260)
                    SkeletonBar(width: 180)
                }
                .accessibilityHidden(true)
            case .none:
                EmptyView()
            }
        }
        .padding(.horizontal, Space.screen)
        .padding(.top, topInset + Space.m - 2)
        .padding(.bottom, Space.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .environment(\.colorScheme, sky.isDark ? .dark : .light)
        .background {
            SkyView(sky)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Runs on under the sheet's rounded corners (and, in its last colour, further
                // down, for when the sheet is pulled down).
                .padding(.bottom, -Space.xxl)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Skeleton

/// Today's shape while it loads (brief: a skeleton within 600 ms of cold launch). Static, so
/// there's nothing to reduce under Reduce Motion.
struct TodaySkeleton: View {
    var body: some View {
        VStack(spacing: Space.screen) {
            block(height: 262)
            DashedDivider()
            block(height: 210)
            DashedDivider()
            block(height: 290)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading Today")
    }

    private func block(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: Space.m) {
            SkeletonBar(width: 120)
            SkeletonBar(width: 220)
            SkeletonBar(width: 160)
            Spacer(minLength: 0)
        }
        .padding(Space.l)
        .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
        .card()
    }
}

struct SkeletonBar: View {
    let width: CGFloat

    var body: some View {
        Capsule()
            .fill(Palette.gap)
            .frame(maxWidth: width, minHeight: 14, maxHeight: 14)
    }
}
