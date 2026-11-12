import SwiftUI

/// Icons turning in one spot like a coin, a new one each half turn: the loading moment on
/// Today before the first stop (Today design, "Getting Started"; the design team's note: "a
/// bunch of icons rotating at full speed"). Each icon faces you for a moment, turns away on
/// its vertical axis, and the next turns in from the far edge: the swap happens edge-on, where
/// nothing shows. Decorative. Under Reduce Motion the first icon stays put.
public struct IconShuffle: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let icons: [Image]
    private let interval: TimeInterval

    /// - Parameters:
    ///   - icons: the first one is the one shown under Reduce Motion.
    ///   - interval: how often a new icon turns in, in seconds; the turn itself is
    ///     `Motion.flip`, and the icon rests facing you for the rest.
    public init(_ icons: [Image], interval: TimeInterval = 0.7) {
        self.icons = icons
        self.interval = interval
    }

    public var body: some View {
        Group {
            if reduceMotion || icons.count < 2 {
                if let first = icons.first {
                    first
                        .resizable()
                        .scaledToFit()
                }
            } else {
                TimelineView(.periodic(from: Date(timeIntervalSinceReferenceDate: 0), by: interval)) { context in
                    let turn = Int(context.date.timeIntervalSinceReferenceDate / interval)
                    IconFlip(turns: Double(turn), icons: icons)
                        .animation(Motion.flip, value: turn)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// The turning icon. `turns` counts half turns: at a whole number an icon faces you; on the
/// way to the next it turns to 90°, and past the halfway mark the next icon is drawn from
/// −90° back to facing you. SwiftUI animates `turns`, so the swap lands exactly edge-on.
private struct IconFlip: View, Animatable {
    var turns: Double
    let icons: [Image]

    nonisolated var animatableData: Double {
        get { turns }
        set { turns = newValue }
    }

    var body: some View {
        let nearest = turns.rounded()
        let count = icons.count
        let index = ((Int(nearest) % count) + count) % count
        icons[index]
            .resizable()
            .scaledToFit()
            .rotation3DEffect(.degrees((turns - nearest) * 180), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
    }
}
