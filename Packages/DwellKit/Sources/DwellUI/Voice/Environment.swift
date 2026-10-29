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
    }
}

extension View {
    /// The sample week, frozen at Monday 26 October, 2:47 PM, at the given dial stop.
    public func samplePreview(_ stop: Dial.Stop = .plain) -> some View {
        environment(\.dial, Dial(stop))
            .environment(\.fixedNow, SampleData.now)
            .environment(\.repository, SampleRepository())
            .environment(\.timeZone, SampleData.calendar.timeZone)
    }
}

extension PlaceCategory {
    /// Stand-in icons until the custom category icons arrive.
    public var placeholderSymbol: String {
        switch self {
        case .work: "briefcase.fill"
        case .home: "house.fill"
        case .foodAndDrink: "fork.knife"
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
