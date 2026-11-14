import DwellCore
import DwellUI
import SwiftUI

/// The Insights page's layout for any state, with no loading of its own: previews drive it
/// directly.
///
/// Read from the screenshot (iPhone, 393 pt), top to bottom on the page's grey: the back
/// button (40 on glass) 17 below the status bar and 16 from the edge, "Insights" (24) centred
/// level with it; 16 below, a dashed line 20 from the edges; 16 to the sentence (24, words at
/// 70%, the data in ink with its 3D art, as on Time); 14 to the chart card (16 in: the window
/// and 4W / 3M, 12 to a dashed line, 12 to the bars, 12 below); 14 to the tiles, one to a
/// row, 7 apart, at Today's hero-tile size (the user's call, 13 Nov: the design's three side
/// by side cut their numbers short). Share and Not useful sit 20 above the screen's bottom edge, 12 apart, 20 from the sides,
/// where the tab bar would be: an inside page has none. Content is 20 from the edges.
struct InsightContent: View {
    let insight: Insight
    let state: Loadable<InsightDetail>
    let now: Date
    var actions = InsightActions()

    @Environment(\.calendar) private var calendar
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var span: InsightSpan = .fourWeeks
    /// How many windows back the chart is: 0 is the window ending with the insight's week.
    @State private var page = 0
    /// The home indicator's strip; the buttons reach into it, as drawn.
    @State private var homeIndicator: CGFloat = 0
    /// "Share this insight" is up.
    @State private var isSharing: Bool

    /// Figma: the buttons stand 20 above the screen's bottom edge (measured).
    private static let buttonsAboveEdge: CGFloat = 20
    /// The tiles sit 7 apart, as Today's hero tiles do.
    private static let tileSpacing: CGFloat = 7

    /// - Parameters:
    ///   - span: the chart's range to start on (4W, as drawn); previews pick 3M.
    ///   - page: windows back to start on; previews show an earlier one.
    ///   - isSharing: whether "Share this insight" starts up; previews show it.
    init(
        insight: Insight,
        state: Loadable<InsightDetail>,
        now: Date,
        actions: InsightActions = InsightActions(),
        span: InsightSpan = .fourWeeks,
        page: Int = 0,
        isSharing: Bool = false
    ) {
        self.insight = insight
        self.state = state
        self.now = now
        self.actions = actions
        _span = State(initialValue: span)
        _page = State(initialValue: page)
        _isSharing = State(initialValue: isSharing)
    }

    private var isLarge: Bool { dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                DashedDivider()
                    .padding(.horizontal, Space.screen)
                    .padding(.top, Space.l)
                content
                    .padding(.horizontal, Space.screen)
            }
            .padding(.bottom, Space.l)
        }
        .background(Palette.background)
        .safeAreaInset(edge: .bottom, spacing: 0) { actionBar }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: { inset in
            var still = Transaction()
            still.disablesAnimations = true
            withTransaction(still) { homeIndicator = inset }
        }
        .promptSheet(isPresented: $isSharing) {
            // The weeks on screen go with it; before the page has loaded, the deck's insight.
            InsightShareSheet(
                detail: state.value ?? InsightDetail(insight: insight),
                span: span,
                page: page,
                now: now,
                onClose: { isSharing = false })
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            HStack {
                BackButton()
                Spacer(minLength: 0)
            }
            Text(verbatim: InsightCopy.title)
                .textRole(.pageTitle)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                // Clear of the back button on both sides, so it stays centred on the screen.
                .padding(.horizontal, 56)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, Space.l)
        .padding(.top, 17)
    }

    // MARK: States

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            InsightSkeleton()
                .padding(.top, Space.l)
        case .failed(let failure):
            failed(failure)
                .padding(.top, Space.xl)
        case .empty, .stillMapping:
            // Nothing more to show than the deck had: its sentence and number.
            loaded(InsightDetail(insight: insight))
        case .loaded(let detail, let staleSince):
            if let staleSince {
                NoticeBanner(
                    symbol: "arrow.clockwise",
                    message: TodayCopy.stale(since: staleSince, calendar: calendar),
                    actionTitle: TodayCopy.retrySync,
                    action: actions.retry)
                    .padding(.top, Space.l)
            }
            loaded(detail)
        }
    }

    @ViewBuilder
    private func loaded(_ detail: InsightDetail) -> some View {
        InsightHeadline(headline: detail.headline)
            .padding(.top, Space.l)
        if let trend = detail.trend {
            trendCard(trend)
                .padding(.top, 14)
        } else if !detail.days.isEmpty {
            // No weeks to compare: the days Today's card charts, in a card of the same shape.
            WeekBarsChart(detail.days)
                .padding(Space.l)
                .card()
                .padding(.top, 14)
        }
        if !detail.stats.isEmpty {
            tiles(detail.stats)
                .padding(.top, 14)
        }
    }

    // MARK: The chart

    private func trendCard(_ trend: InsightTrend) -> some View {
        let page = min(self.page, trend.lastPage(span))
        let weeks = trend.window(span, page: page, calendar: calendar)
        return VStack(alignment: .leading, spacing: 0) {
            chartControls(trend, weeks: weeks, page: page)
            DashedDivider()
                .padding(.top, Space.m)
            InsightTrendChart(
                trend.bars(span: span, page: page, now: now, calendar: calendar),
                measure: trend.measure,
                tint: trend.category?.color ?? Palette.accent,
                glint: trend.category?.glint ?? Palette.accent)
                // Under Reduce Motion a new window cross-fades in rather than its bars moving.
                .id(reduceMotion ? "\(span.rawValue)-\(page)" : "bars")
                .transition(.opacity)
                .padding(.top, Space.m)
        }
        .padding(.horizontal, Space.l)
        .padding(.top, Space.l)
        .padding(.bottom, Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .motion(value: "\(span.rawValue)-\(page)")
    }

    /// "‹ Sep 2026 – Oct 2026 ›" and 4W / 3M on one row; stacked at accessibility sizes.
    @ViewBuilder
    private func chartControls(_ trend: InsightTrend, weeks: [InsightTrend.Week], page: Int) -> some View {
        let stepper = PeriodStepper(
            InsightCopy.window(weeks, calendar: calendar),
            backLabel: InsightCopy.earlierWeeks,
            forwardLabel: InsightCopy.laterWeeks,
            canGoBack: page < trend.lastPage(span),
            canGoForward: page > 0,
            back: { self.page = page + 1 },
            forward: { self.page = page - 1 })
        let picker = SegmentedPicker(
            InsightCopy.span,
            selection: Binding(get: { span }, set: { newSpan in
                span = newSpan
                self.page = 0
            }),
            options: InsightSpan.allCases,
            size: .compact,
            title: { $0.title },
            spokenTitle: { $0.spokenTitle })
        if isLarge {
            VStack(alignment: .leading, spacing: Space.m) {
                stepper
                picker
            }
        } else {
            HStack(spacing: Space.s) {
                stepper
                Spacer(minLength: 0)
                picker
            }
        }
    }

    // MARK: The numbers

    /// One tile to a row, full width, Today's hero tile as it is: the number over its label,
    /// the art (33) over its glow on the right.
    private func tiles(_ stats: [InsightStat]) -> some View {
        VStack(spacing: Self.tileSpacing) {
            ForEach(stats) { tile($0) }
        }
    }

    private func tile(_ stat: InsightStat) -> some View {
        StatTile(
            value: Self.text(stat.value),
            label: stat.label,
            spokenValue: Self.spoken(stat.value),
            tint: stat.tint.color
        ) {
            Art.insightStat(stat.icon)
                .resizable()
                .scaledToFit()
        }
        // On the page, not in a card as on Today: lifted like one (the design's tiles cast a
        // soft shadow).
        .card(radius: Radius.l)
    }

    private static func text(_ value: InsightStat.Value) -> String {
        switch value {
        case .duration(let duration): DurationText.short(duration)
        case .text(let text): text
        }
    }

    private static func spoken(_ value: InsightStat.Value) -> String {
        switch value {
        case .duration(let duration): DurationText.spoken(duration)
        case .text(let text): text
        }
    }

    // MARK: Share and Not useful

    /// The design's two buttons, equal halves 12 apart; stacked at accessibility sizes. They
    /// reach into the home indicator's strip as drawn (20 above the screen's edge), and the
    /// page's grey fades in behind them so the content scrolls away under them.
    private var actionBar: some View {
        Group {
            if isLarge {
                VStack(spacing: Space.m) { buttons }
            } else {
                HStack(spacing: Space.m) { buttons }
            }
        }
        .padding(.horizontal, Space.screen)
        .padding(.top, Space.m)
        .padding(.bottom, Self.buttonsAboveEdge - homeIndicator)
        .background {
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Palette.background.opacity(0), location: 0),
                    Gradient.Stop(color: Palette.background, location: 0.3),
                ],
                startPoint: .top,
                endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    @ViewBuilder
    private var buttons: some View {
        if insight.isShareable {
            Button(InsightCopy.share) { isSharing = true }
                .buttonStyle(.primary(role: .action))
        }
        Button(InsightCopy.notUseful, action: actions.notUseful)
            .buttonStyle(.secondary)
            .accessibilityHint("Takes this insight off Today") // [COPY NEEDED]
    }

    // MARK: Failed

    private func failed(_ failure: LoadFailure) -> some View {
        ContentUnavailableView {
            switch failure {
            case .offline: Label(TodayCopy.offline, systemImage: "wifi.slash")
            case .unavailable: Label(InsightCopy.couldNotLoad, systemImage: "exclamationmark.triangle")
            }
        } description: {
            switch failure {
            case .offline: Text(verbatim: InsightCopy.offlineDetail)
            case .unavailable: Text(verbatim: InsightCopy.tryAgain)
            }
        } actions: {
            Button(failure == .offline ? TodayCopy.retrySync : InsightCopy.retry, action: actions.retry)
                .buttonStyle(.borderedProminent)
                .tint(Palette.textPrimary)
        }
        .padding(.vertical, Space.xl)
        .card()
    }
}

// MARK: - Skeleton

/// The page's shape while it loads: the sentence's two lines, the chart card and the tiles,
/// one to a row.
/// Static, so there's nothing to reduce under Reduce Motion.
struct InsightSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: Space.m) {
                SkeletonBar(width: 320)
                SkeletonBar(width: 200)
            }
            VStack(alignment: .leading, spacing: Space.m) {
                SkeletonBar(width: 160)
                Spacer(minLength: 0)
            }
            .padding(Space.l)
            .frame(maxWidth: .infinity, minHeight: 224, alignment: .topLeading)
            .card()
            VStack(spacing: 7) {
                ForEach(0 ..< 3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: Radius.l)
                        .fill(Palette.surface)
                        .frame(height: 66)
                        .card(radius: Radius.l)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading this insight") // [COPY NEEDED]
    }
}
