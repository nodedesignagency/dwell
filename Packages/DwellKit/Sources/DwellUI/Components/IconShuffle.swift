import SwiftUI

/// Icons swapping in one spot, fast, each popping in as the last one leaves: the loading
/// moment on Today before the first stop (Today design, "Getting Started"; the design team's
/// note: "a bunch of icons rotating at full speed"). Decorative. Under Reduce Motion the first
/// icon stays put.
public struct IconShuffle: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let icons: [Image]
    private let interval: TimeInterval

    /// - Parameters:
    ///   - icons: the first one is the one shown under Reduce Motion.
    ///   - interval: how long each icon stays, in seconds.
    public init(_ icons: [Image], interval: TimeInterval = 0.3) {
        self.icons = icons
        self.interval = interval
    }

    public var body: some View {
        Group {
            if reduceMotion || icons.count < 2 {
                icon(0)
            } else {
                TimelineView(.periodic(from: Date(timeIntervalSinceReferenceDate: 0), by: interval)) { context in
                    let index = Int(context.date.timeIntervalSinceReferenceDate / interval) % icons.count
                    ZStack {
                        icon(index)
                            .id(index)
                            .transition(Self.swap)
                    }
                    .animation(Motion.shuffle, value: index)
                }
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func icon(_ index: Int) -> some View {
        if icons.indices.contains(index) {
            icons[index]
                .resizable()
                .scaledToFit()
        }
    }

    private static let swap = AnyTransition.asymmetric(
        insertion: .scale(scale: 0.6).combined(with: .opacity),
        removal: .scale(scale: 1.2).combined(with: .opacity))
}
