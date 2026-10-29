import DwellCore
import DwellUI
import SwiftUI

/// Today's layout for any state, with no loading of its own: previews drive it directly.
///
/// The header (avatar, day pill, headline) sits on the sunrise; a sheet with rounded top
/// corners slides over it with the live card, the insight deck and the day. While a visit
/// needs a yes, the confirmation card floats above the tab bar.
struct TodayContent: View {
    let state: Loadable<TodayModel>
    let day: DwellDay
    let isToday: Bool
    let now: Date
    var actions = TodayActions()

    @Environment(\.calendar) private var calendar
    @Environment(\.permissions) private var permissions
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    TodayHeader(
                        headline: headline,
                        dayLabel: isToday ? "Today" : ClockText.dayName(day, calendar: calendar),
                        topInset: proxy.safeAreaInsets.top,
                        onProfile: actions.openProfile,
                        onPickDay: actions.pickDay)
                    sheet
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Palette.background)
            .refreshable { await actions.refresh() }
            .safeAreaInset(edge: .bottom, spacing: 0) { confirmation }
            .motion(value: confirmationID)
        }
    }

    // MARK: Header

    private var headline: TodayHeadline {
        switch state {
        case .loading: return .placeholder
        case .failed: return .none
        case .stillMapping: return .line(TodayCopy.stillMapping)
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
            case .stillMapping(let progress):
                stillMapping(progress)
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
        .background(Palette.background, in: .rect(topLeadingRadius: Radius.xxl, topTrailingRadius: Radius.xxl))
    }

    @ViewBuilder
    private func loaded(_ model: TodayModel, staleSince: Date?) -> some View {
        banners(staleSince: staleSince)
        LiveCard(
            status: model.liveStatus,
            snapshot: model.snapshot,
            now: now,
            isToday: isToday,
            onOpenPlace: actions.openPlace)
        if isToday, !model.insights.isEmpty {
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

    /// The install day: no visits yet, so say what Today is waiting for and how long.
    @ViewBuilder
    private func stillMapping(_ progress: MappingProgress) -> some View {
        let empty = TodayModel.empty(day, isToday: true, calendar: calendar)
        banners(staleSince: nil)
        LiveCard(status: .unknown, snapshot: empty.snapshot, now: now, isToday: true, showsStats: false)
        DashedDivider()
        VStack(alignment: .leading, spacing: Space.m) {
            SectionHeader("This week", icon: Image(systemName: "calendar"))
            Text(verbatim: TodayCopy.waitingForInsights(progress))
                .textRole(.caption)
                .foregroundStyle(Palette.textSecondary)
            ProgressView(value: progress.fraction)
                .tint(Palette.accent)
                .accessibilityLabel("Days mapped")
                .accessibilityValue("\(progress.daysCollected) of \(progress.daysNeeded)")
        }
        .padding(Space.l)
        .card()
        DashedDivider()
        DayTimelineCard(snapshot: empty.snapshot, now: now, isToday: true)
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
            ConfirmationCard(
                TodayCopy.confirmVisit(placeName: visit.placeName, duration: visit.interval(now: now).duration),
                onLooksRight: { actions.confirm(visit) },
                onPickAnother: { actions.pickAnother(visit) })
                .padding(.horizontal, Space.l)
                .padding(.bottom, Space.s)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Header

/// Avatar, the day pill and the headline, on the sunrise. The sunrise runs up under the
/// status bar and down under the sheet's rounded corners.
struct TodayHeader: View {
    let headline: TodayHeadline
    let dayLabel: String
    let topInset: CGFloat
    var onProfile: () -> Void = {}
    var onPickDay: () -> Void = {}

    @Environment(\.colorScheme) private var colorScheme
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
                            .textRole(.label)
                            .foregroundStyle(Palette.textPrimary)
                    }
                    .padding(10)
                    .background(Palette.glass, in: .rect(cornerRadius: Radius.m))
                }
                .buttonStyle(.plain)
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
        .background {
            Art.sunrise
                .resizable()
                .scaledToFill()
                .overlay {
                    // Derived: no night sunrise yet, so dark mode dims the day one.
                    if colorScheme == .dark {
                        Color.black.opacity(0.55)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Runs on under the sheet's rounded corners; the scroll view clips the sides.
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
