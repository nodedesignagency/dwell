import Foundation

/// A voiced sentence with data slotted into it, like Today's headline:
/// "Today, you've spent {0}, {1} and {2}."
///
/// The words follow the dial; the runs are data (a duration and where it went) and read the
/// same at every position. Each variant of `line` must use every slot, `{0}`, `{1}`…, exactly
/// once, so the numbers can never differ between Peace and Grind.
public struct VoicedSentence: Hashable, Sendable {
    /// One piece of data in the sentence: "4h 40m at work", shown with its category's icon.
    public struct Run: Hashable, Sendable {
        public var category: PlaceCategory?
        public var text: String

        public init(category: PlaceCategory? = nil, text: String) {
            self.category = category
            self.text = text
        }
    }

    /// A template split for layout: words wrap one by one; a run keeps the punctuation
    /// that touches it ("{0}," stays together), so a comma never starts a line.
    public enum Token: Hashable, Sendable {
        case word(String)
        case run(prefix: String, index: Int, suffix: String)
    }

    public var line: VoicedLine
    public var runs: [Run]

    public init(line: VoicedLine, runs: [Run]) {
        self.line = line
        self.runs = runs
    }

    /// The sentence with every slot filled, as VoiceOver reads it.
    public func text(for dial: Dial) -> String {
        fill(line.text(for: dial))
    }

    public func text(at stop: Dial.Stop) -> String {
        fill(line.text(at: stop))
    }

    public func fill(_ template: String) -> String {
        runs.enumerated().reduce(template) { text, run in
            text.replacingOccurrences(of: "{\(run.offset)}", with: run.element.text)
        }
    }

    public static func tokens(_ template: String) -> [Token] {
        template.split(separator: " ").map { word in
            guard
                let open = word.firstIndex(of: "{"),
                let close = word[open...].firstIndex(of: "}"),
                let index = Int(word[word.index(after: open)..<close])
            else { return .word(String(word)) }
            return .run(
                prefix: String(word[..<open]),
                index: index,
                suffix: String(word[word.index(after: close)...]))
        }
    }
}
