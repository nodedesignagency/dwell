import SwiftUI

/// The design's switch (You design): smaller than the system's, 41 × 19, green when on and grey
/// when off, with a white pill for a knob (25 × 17, 1 in from the edge). Read from the
/// screenshot.
///
/// On iOS 26 and later the row uses the system's own switch instead (`SystemSwitch`), so it
/// moves exactly as Settings' does (the user, 14 Nov). This one is for earlier iOS, whose
/// Settings switch slides plainly too: the knob slides and the track's colour changes,
/// `Motion.standard`; under Reduce Motion, `Motion.reduced`.
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

/// The system's switch, as Settings has it on iOS 26: Liquid Glass, so as it flips the knob
/// lifts into a lens over the track, travels and settles, all Apple's own motion (the user
/// wanted Settings' exact animation, 14 Nov; a drawn copy can't refract). Tinted the design's
/// green and shrunk to the design's height (19), measured from the switch itself rather than
/// assumed; its off grey is the system's. It takes its own touches, as in Settings.
@available(iOS 26.0, macOS 26.0, *)
struct SystemSwitch: View {
    @Binding var isOn: Bool
    /// Shows off whatever `isOn` says: the row can't be changed (the dial doesn't send that push).
    var showsOff = false
    @ScaledMetric(relativeTo: .callout) private var height: CGFloat = 19
    /// The switch's own size, before it's shrunk.
    @State private var natural = CGSize(width: 63, height: 28)

    var body: some View {
        let ratio = height / max(natural.height, 1)
        // Built from Sendable pieces only: the binding and a flag.
        let binding = $isOn
        let off = showsOff
        let shown = Binding(get: { off ? false : binding.wrappedValue }, set: { binding.wrappedValue = $0 })
        Toggle(isOn: shown) { EmptyView() }
            .labelsHidden()
            .toggleStyle(.switch)
            .tint(Palette.toggleOn)
            .fixedSize()
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { size in
                natural = size
            }
            .scaleEffect(ratio)
            .frame(width: natural.width * ratio, height: natural.height * ratio)
    }
}

/// A setting that turns on and off (You design: "Morning recap · A short summary of your day"):
/// its glyph in a well, 8 to the title (16 medium) over a line (14, grey) 4 apart, and the
/// design's switch at the trailing edge (the system's own on iOS 26, `SystemSwitch`). The whole
/// row toggles, so it's easy to hit. Like a place row, it has 4 below it. When the row can't be
/// changed (the dial doesn't send that push), it shows off and doesn't respond (on iOS 26 the
/// system dims its switch).
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
        HStack(spacing: Space.s) {
            // The words toggle it too, so the row is easy to hit.
            Button(action: flip) {
                configuration.label
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isToggle)
            .accessibilityValue(isOn ? "On" : "Off")

            // The switch takes its own touches, as in Settings; VoiceOver uses the row.
            Group {
                if #available(iOS 26.0, macOS 26.0, *) {
                    SystemSwitch(isOn: configuration.$isOn, showsOff: !isEnabled)
                } else {
                    Button(action: flip) {
                        PillSwitch(isOn: isOn)
                    }
                    .buttonStyle(.plain)
                }
            }
            .accessibilityHidden(true)
        }
        .padding(.bottom, Space.xs)
    }

    private func flip() {
        withAnimation(Motion.standard) {
            configuration.isOn.toggle()
        }
    }
}

extension ToggleStyle where Self == ToggleRowStyle {
    public static var row: ToggleRowStyle { ToggleRowStyle() }
}

/// The label of a `.row` toggle: a glyph in a well over the title and its line.
public struct ToggleRowLabel: View {
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
                    .foregroundStyle(Palette.textPrimary)
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

/// The switch to try in the canvas: tap the row.
private struct SwitchPreview: View {
    @State private var isOn = true

    var body: some View {
        Toggle(isOn: $isOn) {
            ToggleRowLabel("Morning recap", detail: "A short summary of your day", glyph: Art.Glyph.sun)
        }
        .toggleStyle(.row)
        .padding(Space.l)
        .background(Palette.surface)
    }
}

#Preview("Switch · tap to flip") {
    SwitchPreview()
}

#Preview("Switch · dark") {
    SwitchPreview()
        .preferredColorScheme(.dark)
}
