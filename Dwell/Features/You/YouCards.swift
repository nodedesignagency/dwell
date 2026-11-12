import DwellCore
import DwellUI
import SwiftUI

// MARK: - The dial

/// "Your dial" (You design): the dial's art, the stop's name and what it does, the arc to drag,
/// then the three pushes the dial decides on.
///
/// Read from the screenshot: the label on glass 18 from the top and 16 from the side; the art
/// standing 50 down (its pills bottom at 130); 24 to the name (24 medium); 2 to its line (14,
/// grey); 24 to the arc; 12 to the rows. Each row a dashed line, 12, the row, 4, 12, as in Your
/// places. The blue glow fades out above the arc.
///
/// The name, its line and the art follow the thumb while it's dragged (brief §6: "previewed
/// live"). A push the dial doesn't send shows off and can't be turned on; its line says which
/// stops send it.
struct DialCard: View {
    @Binding var dial: Double
    let isOn: (NotificationKind) -> Binding<Bool>

    var body: some View {
        let stop = Dial(position: dial).stop
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                DialArt(position: dial)
                // The words cross-fade as the dial passes from one stop's half to the next;
                // the thumb and the art follow the finger with no animation of their own.
                Text(verbatim: stop.name)
                    .textRole(.pageTitle)
                    .foregroundStyle(Palette.textPrimary)
                    .contentTransition(.opacity)
                    .motion(value: stop)
                    .padding(.top, Space.xl)
                Text(verbatim: YouCopy.dialDescription(stop))
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
                    .motion(value: stop)
                    .padding(.top, Space.xxs)
                DialControl(position: $dial, label: YouCopy.yourDial)
                    .padding(.top, Space.xl)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 50)
            .overlay(alignment: .topLeading) {
                LabelPill(YouCopy.yourDial)
                    .padding(.top, 18)
            }
            .padding(.bottom, Space.m)

            VStack(alignment: .leading, spacing: Space.m) {
                ForEach(NotificationKind.allCases, id: \.self) { kind in
                    DashedDivider()
                    Toggle(isOn: isOn(kind)) {
                        ToggleRowLabel(YouCopy.title(of: kind), detail: YouCopy.detail(of: kind), glyph: glyph(kind))
                    }
                    .toggleStyle(.row)
                    .disabled(!kind.isAvailable(at: stop))
                }
            }
        }
        .padding(.horizontal, Space.l)
        .padding(.bottom, Space.m)
        .background {
            DialGlow()
                .clipShape(.rect(cornerRadius: Radius.xl))
        }
        .card()
    }

    /// The design's sun, alarm clock and trophy (Solar, duotone).
    private func glyph(_ kind: NotificationKind) -> Image {
        switch kind {
        case .morningRecap: Art.Glyph.sun
        case .streakAtRisk: Art.Glyph.alarm
        case .records: Art.Glyph.trophy
        }
    }
}

// MARK: - Streaks

/// "Streaks" (You design): the streak the dial leads with, as its run ("12 evenings"), what it
/// asks for ("Home by 6:30 PM", the pencil to change the time), and its last seven days as
/// flames; then Current, Best and Freezes.
///
/// Read from the screenshot: header 14 from the top, 9 to the dashed line, 14 to the orange box
/// (#FFF7F1, corners 14, 16 across and 12 down inside): the run (32 medium, orange), 4 to the
/// rule (16, grey), 16 to the flames, 8 to their days (12, grey), the seven spread evenly; 14
/// to the figures, 12 further in than the box, spread out with dashed lines between; 10 to
/// the bottom.
struct StreakCard: View {
    let streak: Streak?
    var viewAll: () -> Void = {}
    var editTarget: () -> Void = {}

    @Environment(\.calendar) private var calendar
    /// The design's pencil, 14, growing with the rule's text.
    @ScaledMetric(relativeTo: .callout) private var pencilSize: CGFloat = 14

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(YouCopy.streaks, icon: Art.streaks) {
                Button(action: viewAll) {
                    HeaderLink(YouCopy.viewAll)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View all streaks")
            }
            DashedDivider()
                .padding(.top, 9)
            if let streak {
                run(streak)
                    .padding(.top, 14)
                figures(streak)
                    .padding(.horizontal, Space.m)
                    .padding(.top, 14)
            } else {
                empty
                    .padding(.top, 14)
            }
        }
        .padding(.horizontal, Space.l)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .card()
    }

    private func run(_ streak: Streak) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: YouCopy.run(streak))
                .textRole(.dataDisplay)
                .foregroundStyle(Palette.streak)
            HStack(spacing: Space.s) {
                Text(verbatim: YouCopy.rule(streak, calendar: calendar))
                    .textRole(.body, weight: .regular)
                    .foregroundStyle(Palette.textSecondary)
                if streak.kind == .outByTarget {
                    Button(action: editTarget) {
                        Art.Glyph.pencil
                            .resizable()
                            .scaledToFit()
                            .frame(width: pencilSize, height: pencilSize)
                            .foregroundStyle(Palette.textPrimary)
                            .contentShape(Rectangle().inset(by: -15))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Change your out-by time")
                }
            }
            .padding(.top, Space.xs)
            if !streak.recent.isEmpty {
                flames(streak)
                    .padding(.top, Space.l)
            }
        }
        .padding(.horizontal, Space.l)
        .padding(.vertical, Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.streakWash, in: .rect(cornerRadius: Radius.box))
    }

    private func flames(_ streak: Streak) -> some View {
        HStack(spacing: 0) {
            ForEach(streak.recent, id: \.start) { mark in
                VStack(spacing: Space.s) {
                    FlameMark(mark.state)
                    Text(verbatim: label(mark, period: streak.kind.period))
                        .textRole(.footnote)
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(streak.kind.period == .day ? "Last seven days" : "Last seven weeks")
        .accessibilityValue(streak.recent.map { mark in
            "\(spokenLabel(mark, period: streak.kind.period)), \(YouCopy.spokenMark(mark.state))"
        }.joined(separator: "; "))
    }

    private func label(_ mark: Streak.Mark, period: Streak.Period) -> String {
        switch period {
        case .day: ClockText.weekday(mark.start, calendar: calendar)
        case .week: ClockText.monthDay(mark.start, calendar: calendar)
        }
    }

    private func spokenLabel(_ mark: Streak.Mark, period: Streak.Period) -> String {
        switch period {
        case .day: ClockText.dayName(mark.start, calendar: calendar)
        case .week: "Week of \(ClockText.monthDay(mark.start, calendar: calendar))"
        }
    }

    /// Current, Best and Freezes spread across, dashed lines between; stacked when they don't
    /// fit side by side (large text sizes).
    private func figures(_ streak: Streak) -> some View {
        let period = streak.kind.period
        let current = StatColumn(YouCopy.current, value: YouCopy.length(streak.current, period: period))
        let best = StatColumn(YouCopy.best, value: YouCopy.length(streak.best, period: period))
        let freezes = StatColumn(
            YouCopy.freezes, value: YouCopy.freezes(streak.freezes), spokenValue: YouCopy.spokenFreezes(streak.freezes))
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                current
                Spacer(minLength: Space.s)
                VerticalDashedDivider()
                Spacer(minLength: Space.s)
                best
                Spacer(minLength: Space.s)
                VerticalDashedDivider()
                Spacer(minLength: Space.s)
                freezes
            }
            .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: Space.m) {
                current
                DashedDivider()
                best
                DashedDivider()
                freezes
            }
        }
    }

    /// No streaks at all yet: say what starts one. An empty state, so it follows the dial.
    private var empty: some View {
        VStack(spacing: Space.xs) {
            FlameMark(.open)
                .padding(.bottom, Space.xs)
            VoiceText(YouCopy.noStreaks)
                .textRole(.title)
                .foregroundStyle(Palette.textPrimary)
            VoiceText(YouCopy.noStreaksDetail)
                .textRole(.caption)
                .foregroundStyle(Palette.textSecondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, Space.l)
        .padding(.vertical, Space.l)
        .frame(maxWidth: .infinity)
        .background(Palette.streakWash, in: .rect(cornerRadius: Radius.box))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Badges

/// "Badges" (You design): how many are earned of thirteen, then six in a grid: earned first,
/// best tier first, then those closest to unlocking.
///
/// Read from the screenshot: header 14 from the top, 9 to the dashed line, 20 to the first
/// medals; three columns across the card's whole width (each about 118); rows 18 apart; 16 to
/// the bottom. At accessibility sizes, two columns.
struct BadgesCard: View {
    let badges: [Badge]
    let earned: Int
    var viewAll: () -> Void = {}
    var open: (Badge) -> Void = { _ in }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 0, alignment: .top),
            count: dynamicTypeSize.isAccessibilitySize ? 2 : 3)
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(YouCopy.badges, icon: Art.badges) {
                Button(action: viewAll) {
                    HeaderLink(YouCopy.earned(earned))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(YouCopy.spokenEarned(earned))
                .accessibilityHint("Shows every badge")
            }
            DashedDivider()
                .padding(.top, 9)
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(Badge.showcase(badges)) { badge in
                    Button {
                        open(badge)
                    } label: {
                        BadgeTile(
                            name: YouCopy.name(of: badge.kind),
                            details: YouCopy.details(for: badge),
                            tier: badge.tier,
                            art: Art.badge(badge.kind, tier: badge.tier))
                    }
                    .buttonStyle(.plain)
                }
            }
            // The grid runs the card's whole width, as drawn, so long facts have room.
            .padding(.horizontal, -Space.l)
            .padding(.top, 20)
        }
        .padding(.horizontal, Space.l)
        .padding(.top, 14)
        .padding(.bottom, Space.l)
        .card()
    }
}
