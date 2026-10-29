import DwellCore
import DwellUI
import SwiftUI

/// The ranked insights as a stack of cards (Today design, "This week"): the top one is the
/// hero, the next two peek out below. Arrows or a sideways swipe move through them.
/// Tap opens the insight; long-press offers Share and Not useful.
struct InsightDeck: View {
    let insights: [Insight]
    var onOpen: (Insight) -> Void = { _ in }
    var onShare: (Insight) -> Void = { _ in }
    var onNotUseful: (Insight) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0
    @State private var isForward = true

    var body: some View {
        let current = min(index, max(insights.count - 1, 0))
        VStack(spacing: Space.m) {
            // [ICON NEEDED] the design's 3D calendar.
            SectionHeader("This week", icon: Image(systemName: "calendar")) {
                HStack(spacing: 0) {
                    arrow("arrow.left", label: "Previous insight", isEnabled: current > 0) { step(-1, from: current) }
                    arrow("arrow.right", label: "Next insight", isEnabled: current < insights.count - 1) { step(1, from: current) }
                }
                .padding(.vertical, -Space.m)
                .padding(.trailing, -Space.m)
            }

            if insights.indices.contains(current) {
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

    private func arrow(_ symbol: String, label: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .textRole(.title)
                .foregroundStyle(isEnabled ? Palette.textPrimary : Palette.textSecondary.opacity(0.4))
                .frame(width: 44, height: 44)
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
