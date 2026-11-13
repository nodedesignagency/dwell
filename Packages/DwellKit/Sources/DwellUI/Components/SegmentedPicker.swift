import SwiftUI

/// The design's segmented control (Time design: "Day · Week · Month · Year", and the small
/// "Weekday · Weekend" on Your rhythm): a capsule track in `segmentTrack` with the tab bar's
/// white pill behind the chosen option, sliding between them.
///
/// Measured from the screenshot (393 pt): the range control spans the content (353), 44 tall,
/// the pill 34 tall and 5 in from the track; labels 14 medium in ink, the chosen one and the
/// rest alike. The compact size hugs its labels (12 medium, 10 across), 30 tall.
///
/// The design's look over the system's behaviour: VoiceOver meets a system segmented `Picker`
/// (`accessibilityRepresentation`). The pill slides on `Motion.standard`; under Reduce Motion
/// it appears in place. No haptics: choosing a range isn't a physical event (brief §6.1).
public struct SegmentedPicker<Value: Hashable>: View {
    public enum Size: Sendable {
        /// Full width: Time's range control.
        case regular
        /// Hugs its labels: a card's toggle.
        case compact
    }

    @Binding private var selection: Value
    private let label: String
    private let options: [Value]
    private let size: Size
    private let title: (Value) -> String
    private let spokenTitle: (Value) -> String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var pill
    @ScaledMetric(relativeTo: .subheadline) private var regularPill: CGFloat = 34
    @ScaledMetric(relativeTo: .caption) private var compactPill: CGFloat = 24

    /// - Parameters:
    ///   - label: what's being chosen, for VoiceOver: "Range".
    ///   - title: each option's label.
    ///   - spokenTitle: what VoiceOver reads for an option, where its label is shorthand
    ///     ("4W" is "4 weeks"). Defaults to the label.
    public init(
        _ label: String,
        selection: Binding<Value>,
        options: [Value],
        size: Size = .regular,
        title: @escaping (Value) -> String,
        spokenTitle: ((Value) -> String)? = nil
    ) {
        self.label = label
        _selection = selection
        self.options = options
        self.size = size
        self.title = title
        self.spokenTitle = spokenTitle ?? title
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                segment(option)
            }
        }
        .padding(size == .regular ? 5 : 3)
        .background(Palette.segmentTrack, in: .capsule)
        .motion(value: selection)
        .accessibilityRepresentation {
            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(verbatim: spokenTitle(option)).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func segment(_ option: Value) -> some View {
        let isSelected = option == selection
        return Button {
            selection = option
        } label: {
            Text(verbatim: title(option))
                .textRole(size == .regular ? .caption : .footnote, weight: .medium)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, size == .regular ? Space.xs : 10)
                .frame(maxWidth: size == .regular ? .infinity : nil)
                .frame(minHeight: size == .regular ? regularPill : compactPill)
                .background {
                    if isSelected {
                        if reduceMotion {
                            SelectedPill()
                        } else {
                            SelectedPill().matchedGeometryEffect(id: "pill", in: pill)
                        }
                    }
                }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}

/// The white pill behind a chosen option: the tab bar's (Figma "tabPills"): white 80%, a 1-pt
/// #F6F6F6 border inside and four soft drop shadows (y 26.05, 14.37, 5.86, 1.2; blur 10.78,
/// 8.36, 5.86, 3.59; black 1, 2, 4, 4%), SwiftUI's radius half Figma's blur.
public struct SelectedPill: View {
    public init() {}

    public var body: some View {
        Capsule()
            .fill(Palette.tabPill)
            .overlay { Capsule().strokeBorder(Palette.tabPillStroke, lineWidth: 1) }
            .shadow(color: .black.opacity(0.01), radius: 5.39, y: 26.05)
            .shadow(color: .black.opacity(0.02), radius: 4.18, y: 14.37)
            .shadow(color: .black.opacity(0.04), radius: 2.93, y: 5.86)
            .shadow(color: .black.opacity(0.04), radius: 1.8, y: 1.2)
    }
}
