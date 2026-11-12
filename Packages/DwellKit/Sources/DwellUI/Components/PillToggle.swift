import SwiftUI

/// The design's switch (You design): smaller than the system's, 41 × 19, green when on and grey
/// when off, with a white pill for a knob (25 × 17, 1 in from the edge). The system `Toggle`
/// stays underneath for its state and accessibility; only the look is the design's. Read from
/// the screenshot.
public struct PillSwitch: View {
    private let isOn: Bool
    @ScaledMetric(relativeTo: .callout) private var scale: CGFloat = 1

    public init(isOn: Bool) {
        self.isOn = isOn
    }

    public var body: some View {
        Capsule()
            .fill(isOn ? Palette.toggleOn : Palette.toggleOff)
            .frame(width: 41 * scale, height: 19 * scale)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(Palette.ring)
                    .shadow(color: .black.opacity(0.08), radius: 1, y: 0.5)
                    .frame(width: 25 * scale, height: 17 * scale)
                    .padding(scale)
            }
            .motion(value: isOn)
            .accessibilityHidden(true)
    }
}

/// A setting that turns on and off (You design: "Morning recap · A short summary of your day"):
/// its glyph in a well, 8 to the title (16 medium) over a line (14, grey) 4 apart, and the
/// design's switch at the trailing edge. The whole row toggles, so it's easy to hit. Like a
/// place row, it has 4 below it. When the row can't be changed (the dial doesn't send that
/// push), it shows off and doesn't respond, and its glyph greys.
public struct ToggleRowStyle: ToggleStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        ToggleRow(configuration: configuration)
    }
}

private struct ToggleRow: View {
    let configuration: ToggleStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let isOn = configuration.isOn && isEnabled
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: Space.s) {
                configuration.label
                    .frame(maxWidth: .infinity, alignment: .leading)
                PillSwitch(isOn: isOn)
            }
            .padding(.bottom, Space.xs)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

extension ToggleStyle where Self == ToggleRowStyle {
    public static var row: ToggleRowStyle { ToggleRowStyle() }
}

/// The label of a `.row` toggle: a glyph in a well over the title and its line.
public struct ToggleRowLabel: View {
    @Environment(\.isEnabled) private var isEnabled
    private let title: String
    private let detail: String
    private let glyph: Image

    public init(_ title: String, detail: String, glyph: Image) {
        self.title = title
        self.detail = detail
        self.glyph = glyph
    }

    public var body: some View {
        HStack(spacing: Space.s) {
            IconWell {
                glyph
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isEnabled ? Palette.textPrimary : Palette.textSecondary)
            }
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(verbatim: title)
                    .textRole(.body)
                    .foregroundStyle(Palette.textPrimary)
                Text(verbatim: detail)
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
