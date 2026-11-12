import DwellCore
import DwellUI
import SwiftUI

// Every state of You on the sample week (Monday 26 October 2026, 2:47 PM). The dial in each
// preview can be dragged; the page follows it. Numbers never change with the dial: only which
// streak leads, and the empty state's words.

/// The page in a navigation stack, holding the dial and the switches so they work in the canvas.
private struct YouPreview: View {
    let state: Loadable<YouModel>
    @State private var dial: Double
    @State private var switches = Dictionary(
        uniqueKeysWithValues: NotificationKind.allCases.map { ($0, $0.isOnByDefault) })

    init(_ state: Loadable<YouModel>, at stop: Dial.Stop = .plain) {
        self.state = state
        _dial = State(initialValue: stop.position)
    }

    var body: some View {
        NavigationStack {
            YouContent(state: state, dial: $dial, isOn: { kind in
                Binding(get: { switches[kind] ?? false }, set: { switches[kind] = $0 })
            })
            .environment(\.dial, Dial(position: dial))
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private let sample = Loadable<YouModel>.loaded(.sample)

// MARK: Loaded, at the three anchor voices

#Preview("Plain (the design)") {
    YouPreview(sample).samplePreview()
}

#Preview("Peace") {
    YouPreview(sample, at: .peace).samplePreview(.peace)
}

#Preview("Grind · gym streak leads, every push on offer") {
    YouPreview(sample, at: .grind).samplePreview(.grind)
}

#Preview("Push") {
    YouPreview(sample, at: .push).samplePreview(.push)
}

#Preview("Plain · dark") {
    YouPreview(sample).samplePreview()
        .preferredColorScheme(.dark)
}

#Preview("Plain · AX3") {
    YouPreview(sample).samplePreview()
        .dynamicTypeSize(.accessibility3)
}

#Preview("Grind · AX3 · dark") {
    YouPreview(sample, at: .grind).samplePreview(.grind)
        .dynamicTypeSize(.accessibility3)
        .preferredColorScheme(.dark)
}

// MARK: Streak states

private func withStreaks(_ streaks: [Streak]) -> Loadable<YouModel> {
    var model = YouModel.sample
    model.streaks = streaks
    return .loaded(model)
}

#Preview("Streak broken, nothing going") {
    YouPreview(withStreaks([
        Streak(kind: .outByTarget, current: 0, best: 14, freezes: 0, state: .broken,
               recent: SampleData.streaks[0].recent.map { Streak.Mark(start: $0.start, state: $0.state == .frozen ? .missed : $0.state) },
               target: TimeOfDay(hour: 18, minute: 30)),
    ])).samplePreview()
}

#Preview("Weekly streak leads (explorer)") {
    YouPreview(withStreaks(SampleData.streaks.filter { $0.kind == .explorerWeek })).samplePreview()
}

// MARK: The install day: nothing yet (empty), then one place (still mapping)

#Preview("First day · Peace") {
    YouPreview(.loaded(.firstDay), at: .peace).samplePreview(.peace)
}

#Preview("First day · Plain") {
    YouPreview(.loaded(.firstDay)).samplePreview()
}

#Preview("First day · Grind · dark") {
    YouPreview(.loaded(.firstDay), at: .grind).samplePreview(.grind)
        .preferredColorScheme(.dark)
}

#Preview("First place, minutes in") {
    YouPreview(.loaded(.firstPlace)).samplePreview()
}

// MARK: Loading, stale, failed

#Preview("Loading") {
    YouPreview(.loading).samplePreview()
}

#Preview("Stale") {
    YouPreview(.loaded(.sample, staleSince: SampleData.now.addingTimeInterval(-37 * 60))).samplePreview()
}

#Preview("Failed · retry") {
    YouPreview(.failed(.unavailable)).samplePreview()
}

#Preview("Offline · retry sync · dark") {
    YouPreview(.failed(.offline)).samplePreview()
        .preferredColorScheme(.dark)
}
