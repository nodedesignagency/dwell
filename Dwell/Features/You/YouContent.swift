import DwellCore
import DwellUI
import SwiftUI

/// You's layout for any state, with no loading of its own: previews drive it directly.
///
/// Read from the screenshot (iPhone, 393 pt): "You" and the settings button 17 below the status
/// bar, 16 from the sides; the profile on its map 15 below them; 14 to the dial card; the
/// cards 16 apart and 20 from the sides; 18 to the privacy line. Everything scrolls together.
///
/// The dial card shows in every state: the dial is the phone's own setting, so it works even
/// when the profile, streaks and badges fail to load.
struct YouContent: View {
    let state: Loadable<YouModel>
    @Binding var dial: Double
    let isOn: (NotificationKind) -> Binding<Bool>
    var actions = YouActions()

    @Environment(\.calendar) private var calendar

    private var stop: Dial.Stop { Dial(position: dial).stop }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, Space.l)
                    .padding(.top, 17)
                    .zIndex(1)
                content
            }
            .padding(.bottom, Space.xxl)
        }
        .background(Palette.background)
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Text(verbatim: YouCopy.title)
                .textRole(.pageTitle)
                .foregroundStyle(Palette.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Space.s)
            Button {
                actions.open(.settings)
            } label: {
                // [ICON NEEDED] the design's settings gear (a line icon).
                Image(systemName: "gearshape")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    // Figma's black in light, as on the back button; white in dark, derived.
                    .foregroundStyle(Color.primary)
            }
            .buttonStyle(.glassSquare)
            .accessibilityLabel(YouCopy.settings)
        }
    }

    // MARK: States

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProfileSkeleton()
                .padding(.top, 15)
            cards {
                dialCard
                YouCardSkeleton(rows: 2)
                YouCardSkeleton(rows: 2)
            }
        case .loaded(let model, let staleSince):
            if let staleSince {
                NoticeBanner(
                    symbol: "arrow.clockwise",
                    message: TodayCopy.stale(since: staleSince, calendar: calendar),
                    actionTitle: TodayCopy.retrySync,
                    action: actions.retry)
                    .padding(.horizontal, Space.screen)
                    .padding(.top, Space.m)
            }
            ProfileHeader(
                profile: model.profile,
                placeCount: model.placeCount,
                coverage: model.coverage,
                cells: model.cells,
                openPlaces: { actions.open(.places) },
                openCoverage: { actions.open(.coverage) })
                .padding(.top, 15)
            cards {
                dialCard
                StreakCard(
                    streak: model.featuredStreak(at: stop),
                    viewAll: { actions.open(.streaks) },
                    editTarget: { actions.show(.outByTarget) })
                BadgesCard(
                    badges: model.badges,
                    earned: model.earnedBadges,
                    viewAll: { actions.open(.badges) },
                    open: { actions.show(.badge($0.kind)) })
            }
            privacy
        case .failed(let failure):
            cards {
                failed(failure)
                dialCard
            }
            privacy
        case .empty, .stillMapping:
            // You always has a profile, so the repository never sends these; the dial still works.
            cards {
                dialCard
            }
        }
    }

    /// The cards, 16 apart and 20 from the sides, 14 below what's above them.
    private func cards(@ViewBuilder _ content: () -> some View) -> some View {
        VStack(spacing: Space.l) {
            content()
        }
        .padding(.horizontal, Space.screen)
        .padding(.top, 14)
    }

    private var dialCard: some View {
        DialCard(dial: $dial, isOn: isOn)
    }

    private var privacy: some View {
        PrivacyBar(YouCopy.privacy)
            .padding(.horizontal, Space.screen)
            .padding(.top, 18)
    }

    private func failed(_ failure: LoadFailure) -> some View {
        ContentUnavailableView {
            switch failure {
            case .offline: Label(TodayCopy.offline, systemImage: "wifi.slash")
            case .unavailable: Label(YouCopy.couldNotLoad, systemImage: "exclamationmark.triangle")
            }
        } description: {
            Text(verbatim: failure == .offline ? YouCopy.offlineDetail : YouCopy.unavailableDetail)
        } actions: {
            Button(failure == .offline ? TodayCopy.retrySync : "Retry", action: actions.retry)
                .buttonStyle(.borderedProminent)
                .tint(Palette.textPrimary)
        }
        .padding(.vertical, Space.xl)
        .card()
    }
}

// MARK: - Skeletons

/// The profile's shape while it loads: the ring, a name and a line. Static, so there's nothing
/// to reduce under Reduce Motion.
private struct ProfileSkeleton: View {
    var body: some View {
        VStack(spacing: Space.s) {
            Circle()
                .fill(Palette.gap)
                .frame(width: 133, height: 133)
                .padding(.bottom, 14)
            SkeletonBar(width: 160)
                .frame(width: 160)
            SkeletonBar(width: 120)
                .frame(width: 120)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading your profile")
    }
}

/// A card's shape while it loads: a title, a dashed line and a few bars.
private struct YouCardSkeleton: View {
    let rows: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            SkeletonBar(width: 110)
            DashedDivider()
            ForEach(0..<rows, id: \.self) { _ in
                SkeletonBar(width: 220)
            }
        }
        .padding(Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .accessibilityHidden(true)
    }
}
