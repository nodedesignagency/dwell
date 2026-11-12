import DwellCore
import DwellUI
import SwiftUI

/// The ranked insights as a stack of cards (Today design, "This week"): the top one is the
/// hero, the next two peek out below. Arrows or a sideways swipe move through them.
/// Tap opens the insight; long-press offers Share and Not useful.
///
/// With nothing to show yet (a new user's first week), it says what it's waiting for
/// instead: "Waiting for your insights", with no arrows.
struct InsightDeck: View {
    let insights: [Insight]
    var onOpen: (Insight) -> Void = { _ in }
    var onShare: (Insight) -> Void = { _ in }
    var onNotUseful: (Insight) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title3) private var arrowSize: CGFloat = 22
    @State private var index = 0
    @State private var isForward = true

    var body: some View {
        let current = min(index, max(insights.count - 1, 0))
        VStack(spacing: Space.m) {
            SectionHeader("This week", icon: Art.thisWeek) {
                if !insights.isEmpty {
                    // Figma: the two 22-pt arrows 8 apart. Their 44-pt tap areas overlap to keep it.
                    HStack(spacing: Space.s - arrowInset * 2) {
                        arrow(back: true, label: "Previous insight", isEnabled: current > 0) { step(-1, from: current) }
                        arrow(back: false, label: "Next insight", isEnabled: current < insights.count - 1) { step(1, from: current) }
                    }
                    .padding(.vertical, -arrowInset)
                    .padding(.trailing, -arrowInset)
                }
            }

            if insights.isEmpty {
                WaitingCard(title: TodayCopy.insightsWaitingTitle, detail: TodayCopy.insightsWaitingDetail) {
                    Art.Illustration.chart
                        .resizable()
                        .scaledToFit()
                }
            } else if insights.indices.contains(current) {
                let insight = insights[current]
                let behind = min(insights.count - current - 1, 2)
                ZStack {
                    InsightCard(insight, onShare: { onShare(insight) })
                        .contentShape(.rect)
                        .onTapGesture { onOpen(insight) }
                        .contextMenu {
                            Button("Share", systemImage: "square.and.arrow.up") { onShare(insight) }
                            Button("Not useful", systemImage: "hand.thumbsdown") { onNotUseful(insight) }
                        }
                        .accessibilityAction(named: "Not useful") { onNotUseful(insight) }
                        .id(insight.id)
                        .transition(transition)
                }
                .background(alignment: .bottom) { layers(behind) }
                .padding(.bottom, behind == 2 ? 31 : behind == 1 ? 16 : 0)
                .simultaneousGesture(swipe(from: current))
            }
        }
    }

    // MARK: Paging

    private func step(_ delta: Int, from current: Int) {
        let next = current + delta
        guard insights.indices.contains(next) else { return }
        isForward = delta > 0
        withAnimation(reduceMotion ? Motion.reduced : Motion.standard) {
            index = next
        }
    }

    private func swipe(from current: Int) -> some Gesture {
        DragGesture(minimumDistance: 24).onEnded { value in
            let dx = value.translation.width
            guard abs(dx) > 60, abs(dx) > abs(value.translation.height) * 1.5 else { return }
            step(dx < 0 ? 1 : -1, from: current)
        }
    }

    /// Cards slide in the direction of travel; under Reduce Motion they cross-fade.
    private var transition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .move(edge: isForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: isForward ? .leading : .trailing).combined(with: .opacity))
    }

    /// The design's arrow (22), mirrored to point back.
    /// The space between an arrow and the edge of its tap area.
    private var arrowInset: CGFloat { (max(44, arrowSize) - arrowSize) / 2 }

    private func arrow(back: Bool, label: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Art.arrow
                .resizable()
                .scaledToFit()
                .frame(width: arrowSize, height: arrowSize)
                .scaleEffect(x: back ? -1 : 1)
                .foregroundStyle(isEnabled ? Palette.textPrimary : Palette.textSecondary.opacity(0.4))
                .frame(width: max(44, arrowSize), height: max(44, arrowSize))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }

    // MARK: The stack behind

    private func layers(_ count: Int) -> some View {
        ZStack(alignment: .bottom) {
            if count >= 2 {
                layer.padding(.horizontal, 33).offset(y: 31)
            }
            if count >= 1 {
                layer.padding(.horizontal, Space.l).offset(y: Space.l)
            }
        }
        .accessibilityHidden(true)
    }

    private var layer: some View {
        RoundedRectangle(cornerRadius: Radius.xl)
            .fill(Palette.surface)
            .overlay {
                RoundedRectangle(cornerRadius: Radius.xl)
                    .strokeBorder(Palette.cardStroke, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}
