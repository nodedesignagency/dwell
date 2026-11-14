import SwiftUI

/// The design's switch (You design): smaller than the system's, 41 × 19, green when on and grey
/// when off, with a white pill for a knob (25 × 17, 1 in from the edge). The system `Toggle`
/// stays underneath for its state and accessibility; only the look is the design's. Read from
/// the screenshot.
///
/// It moves like the user's reference video (14 Nov), frame by frame at 60 fps: the knob lifts
/// into glass, 1.4 times its size in 0.12 s, so it stands proud of the track (see-through,
/// tinted with the colour it's switching to, a white rim, a light along its top, a deeper
/// shadow); a beat later it travels across on a spring with a little overshoot, stretching a
/// tenth wider on the way, while the track's colour changes under it; then it shrinks back to a
/// solid white knob, 0.62 s in all. Under Reduce Motion it slides a short way with no lift.
/// No haptic: a switch isn't one of the brief's physical moments (§6.1).
public struct PillSwitch: View {
    private let isOn: Bool
    @ScaledMetric(relativeTo: .callout) private var scale: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(isOn: Bool) {
        self.isOn = isOn
    }

    public var body: some View {
        let track = isOn ? Palette.toggleOn : Palette.toggleOff
        Capsule()
            .fill(track)
            .frame(width: 41 * scale, height: 19 * scale)
            .overlay(alignment: isOn ? .trailing : .leading) {
                knob(tint: track)
                    .frame(width: 25 * scale, height: 17 * scale)
                    .padding(scale)
            }
            .animation(reduceMotion ? Motion.reduced : Motion.switchTravel, value: isOn)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func knob(tint: Color) -> some View {
        // Read here, not inside the animator's closure, which may run off the main actor.
        let white = Palette.ring
        let inset = 1.5 * scale
        if reduceMotion {
            Capsule()
                .fill(white)
                .shadow(color: .black.opacity(0.08), radius: 1, y: 0.5)
        } else {
            Capsule()
                .fill(white)
                .keyframeAnimator(initialValue: KnobLift(), trigger: isOn) { knob, lift in
                    knob
                        // The white thins to glass, showing the track and the tint through it.
                        .opacity(1 - 0.7 * lift.glass)
                        .background {
                            Capsule().fill(tint.opacity(0.45 * lift.glass))
                        }
                        .overlay {
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [white.opacity(0.75 * lift.glass), white.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .center))
                                .padding(inset)
                        }
                        .overlay {
                            Capsule().strokeBorder(white.opacity(0.9 * lift.glass), lineWidth: 1)
                        }
                        .shadow(
                            color: .black.opacity(0.08 + 0.12 * lift.glass),
                            radius: 1 + 3 * lift.glass,
                            y: 0.5 + 1.5 * lift.glass)
                        .scaleEffect(x: lift.scale * lift.stretch, y: lift.scale)
                } keyframes: { _ in
                    // Lifts in 0.12 s, holds while it travels, settles back by 0.62 s.
                    KeyframeTrack(\.scale) {
                        CubicKeyframe(1.4, duration: 0.12)
                        LinearKeyframe(1.4, duration: 0.26)
                        SpringKeyframe(1, duration: 0.24, spring: .snappy)
                    }
                    // A tenth wider in the middle of the travel.
                    KeyframeTrack(\.stretch) {
                        LinearKeyframe(1, duration: 0.1)
                        CubicKeyframe(1.1, duration: 0.14)
                        CubicKeyframe(1, duration: 0.18)
                    }
                    // Glass while it's up, white again as it lands.
                    KeyframeTrack(\.glass) {
                        CubicKeyframe(1, duration: 0.12)
                        LinearKeyframe(1, duration: 0.24)
                        CubicKeyframe(0, duration: 0.26)
                    }
                }
        }
    }
}

/// Where the knob is in its lift: its size (1 at rest), how much wider it's stretched, and how
/// much glass it is (0 solid white, 1 see-through). Nonisolated: the animator works on it.
private nonisolated struct KnobLift {
    var scale: CGFloat = 1
    var stretch: CGFloat = 1
    var glass: Double = 0
}

/// A setting that turns on and off (You design: "Morning recap · A short summary of your day"):
/// its glyph in a well, 8 to the title (16 medium) over a line (14, grey) 4 apart, and the
/// design's switch at the trailing edge. The whole row toggles, so it's easy to hit. Like a
/// place row, it has 4 below it. When the row can't be changed (the dial doesn't send that
/// push), it shows off and doesn't respond; the rest looks the same, as drawn.
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
