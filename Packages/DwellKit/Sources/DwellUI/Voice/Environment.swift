import DwellCore
import SwiftUI

extension EnvironmentValues {
    /// The user's tone dial. Read it to choose a sentence, never to change a number.
    @Entry public var dial: Dial = Dial(.plain)

    /// Where screens read their data. The app injects the real repository once the tracking
    /// engine is connected; previews and the simulator use the sample week.
    @Entry public var repository: any DwellRepository = SampleRepository()

    /// Pins the clock for previews and screenshots. `nil` means live time.
    @Entry public var fixedNow: Date? = nil

    /// Shifts the live clock, so the simulator can run on the sample week and still tick.
    /// Screens read now as `fixedNow ?? Date() + clockOffset`.
    @Entry public var clockOffset: TimeInterval = 0

    /// What the user has granted. The app sets it from the system; previews set each banner.
    @Entry public var permissions: Permissions = .full
}

/// A sentence in the dial's voice. Re-renders the moment the dial moves.
public struct VoiceText: View {
    @Environment(\.dial) private var dial
    private let line: VoicedLine

    public init(_ line: VoicedLine) {
        self.line = line
    }

    public var body: some View {
        Text(verbatim: line.text(for: dial))
            .contentTransition(.opacity)
            .motion(value: dial.stop)
    }
}

extension View {
    /// The sample week as if it were happening now: the clock reads Monday 26 October,
    /// 2:47 PM in New York at `launch`, and ticks on from there. The simulator runs on this
    /// until the client's engine is connected.
    public func sampleWeek(launchedAt launch: Date) -> some View {
        environment(\.repository, SampleRepository())
            .environment(\.clockOffset, SampleData.now.timeIntervalSince(launch))
            .environment(\.calendar, SampleData.calendar)
            .environment(\.timeZone, SampleData.calendar.timeZone)
    }

    /// The sample week, frozen at Monday 26 October, 2:47 PM, at the given dial stop.
    public func samplePreview(_ stop: Dial.Stop = .plain) -> some View {
        environment(\.dial, Dial(stop))
            .environment(\.fixedNow, SampleData.now)
            .environment(\.repository, SampleRepository())
            .environment(\.calendar, SampleData.calendar)
            .environment(\.timeZone, SampleData.calendar.timeZone)
    }
}

extension PlaceCategory {
    /// Flat glyphs for rows. Stand-ins until the design's icon set (Solar, bold duotone)
    /// is exported; work, home and food & drink match its choices (Today design).
    public var placeholderSymbol: String {
        switch self {
        case .work: "building.2.fill"
        case .home: "house.fill"
        case .foodAndDrink: "cup.and.saucer.fill"
        case .shopping: "bag.fill"
        case .fitness: "figure.run"
        case .errands: "checklist"
        case .social: "person.2.fill"
        case .entertainment: "theatermasks.fill"
        case .outdoors: "tree.fill"
        case .education: "book.fill"
        case .transit: "tram.fill"
        case .travel: "airplane"
        case .personal: "heart.fill"
        case .other: "circle.grid.2x2.fill"
        }
    }
}
