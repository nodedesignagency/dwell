/// The tone dial (brief §6): one continuous control from Peace (0) to Grind (100)
/// with five named stops. It changes sentences, emphasis and which stats are chosen.
/// It never changes a number, a chart or a setting.
public struct Dial: Hashable, Sendable {
    public static let range: ClosedRange<Double> = 0...100

    /// Clamped to `range`.
    public let position: Double

    public init(position: Double) {
        self.position = min(max(position, Self.range.lowerBound), Self.range.upperBound)
    }

    public init(_ stop: Stop) {
        self.init(position: stop.position)
    }

    /// The named stop nearest to the current position.
    public var stop: Stop {
        Stop.allCases.min { abs($0.position - position) < abs($1.position - position) } ?? .plain
    }

    public enum Stop: String, CaseIterable, Codable, Sendable {
        case peace
        case calm
        case plain
        case push
        case grind

        public var position: Double {
            switch self {
            case .peace: 0
            case .calm: 25
            case .plain: 50
            case .push: 75
            case .grind: 100
            }
        }

        public var name: String {
            switch self {
            case .peace: "Peace"
            case .calm: "Calm"
            case .plain: "Plain"
            case .push: "Push"
            case .grind: "Grind"
            }
        }

        /// The anchor voice this stop speaks in when a line has no variant of its own.
        ///
        /// The brief writes every string in three anchors and asks in-between stops to
        /// "pick the nearer variant with softer intensifiers". Calm (25) and Push (75)
        /// sit exactly between two anchors, so we lean outward: Calm speaks Peace,
        /// Push speaks Grind. Open question, see docs/QUESTIONS.md.
        public var voice: Voice {
            switch self {
            case .peace, .calm: .peace
            case .plain: .plain
            case .push, .grind: .grind
            }
        }
    }
}

extension Dial: Codable {
    public init(from decoder: any Decoder) throws {
        self.init(position: try decoder.singleValueContainer().decode(Double.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(position)
    }
}

/// The three anchor voices every string is written in.
public enum Voice: String, CaseIterable, Codable, Sendable {
    case peace
    case plain
    case grind
}

/// One sentence written for every dial position.
///
/// Numbers must agree across variants: only the framing changes. Calm and Push are
/// optional; without them the stop falls back to its anchor (`Dial.Stop.voice`).
/// Character lives in headlines, insights, notifications, empty states, badges and the
/// weekly wrap. It never lives in numbers, axes, timeline rows or settings.
public struct VoicedLine: Hashable, Codable, Sendable {
    public var peace: String
    public var calm: String?
    public var plain: String
    public var push: String?
    public var grind: String

    public init(peace: String, calm: String? = nil, plain: String, push: String? = nil, grind: String) {
        self.peace = peace
        self.calm = calm
        self.plain = plain
        self.push = push
        self.grind = grind
    }

    /// A line that holds at every position, e.g. "Only you can see this."
    public init(fixed text: String) {
        self.init(peace: text, plain: text, grind: text)
    }

    public func text(for dial: Dial) -> String {
        text(at: dial.stop)
    }

    public func text(at stop: Dial.Stop) -> String {
        switch stop {
        case .calm: calm ?? text(in: stop.voice)
        case .push: push ?? text(in: stop.voice)
        case .peace, .plain, .grind: text(in: stop.voice)
        }
    }

    public func text(in voice: Voice) -> String {
        switch voice {
        case .peace: peace
        case .plain: plain
        case .grind: grind
        }
    }

    /// Every variant, for checks that must hold across the whole dial.
    public var allVariants: [String] {
        [peace, calm, plain, push, grind].compactMap(\.self)
    }
}
