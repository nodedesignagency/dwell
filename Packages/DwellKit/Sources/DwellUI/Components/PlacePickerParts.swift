import DwellCore
import SwiftUI

/// The close button on a sheet's grey (Share this insight, the place picker): the drawn cross
/// on `.raisedCircle`, 44 across. Solid, not glass: glass vanishes on the grey.
public struct RaisedCloseButton: View {
    private let label: String
    private let action: () -> Void

    public init(label: String, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            CloseCross()
        }
        .buttonStyle(.raisedCircle)
        .accessibilityLabel(label)
    }
}

/// A radio (Place picker, 14 Nov): 17 across. Chosen, a `choiceOn` disc with a white dot of 7;
/// not, white with a hairline and a soft shadow under it. Read from the screenshot.
public struct ChoiceRadio: View {
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 17
    private let isOn: Bool

    public init(isOn: Bool) {
        self.isOn = isOn
    }

    public var body: some View {
        ZStack {
            if isOn {
                Circle()
                    .fill(Palette.choiceOn)
                Circle()
                    .fill(Palette.ring)
                    .frame(width: size * 7 / 17, height: size * 7 / 17)
            } else {
                Circle()
                    .fill(Palette.surface)
                    .shadow(color: .black.opacity(0.12), radius: 1, y: 1)
                Circle()
                    .strokeBorder(Palette.outline, lineWidth: 1)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// One choice among places (Place picker, 14 Nov: "Lucali · Food & drink · 40 m"): the
/// category's glyph in a well, 8 to the name (16 medium) over its facts (14, grey) 4 apart,
/// the radio at the trailing edge. Chosen, it sits on `rowSelected`, corners 16. Measured from
/// the screenshot: 61 tall, 12 in, the radio 14 from the end.
public struct PlaceChoiceRow: View {
    private let name: String
    private let facts: String
    private let glyph: Image
    private let isSelected: Bool
    private let action: () -> Void

    public init(name: String, facts: String, glyph: Image, isSelected: Bool, action: @escaping () -> Void) {
        self.name = name
        self.facts = facts
        self.glyph = glyph
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Space.s) {
                IconWell {
                    glyph
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Palette.textPrimary)
                }
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text(verbatim: name)
                        .textRole(.body)
                        .foregroundStyle(Palette.textPrimary)
                    Text(verbatim: facts)
                        .textRole(.caption)
                        .foregroundStyle(Palette.textSecondary)
                }
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Space.s)
                ChoiceRadio(isOn: isSelected)
            }
            .padding(.leading, Space.m)
            .padding(.trailing, 14)
            .padding(.vertical, 9.5)
            .background {
                RoundedRectangle(cornerRadius: Radius.l)
                    .fill(isSelected ? Palette.rowSelected : .clear)
            }
            .contentShape(.rect(cornerRadius: Radius.l))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A way on to somewhere else, as a card (Place picker: "Somewhere else · Name it and pick
/// category"): white, corners 20, a hairline; its glyph in a well, 8 to the title (16 medium)
/// over its line (14, grey), the chevron (8 × 14, grey) 18 from the end; 16 inside.
public struct ChevronCard: View {
    private let title: String
    private let detail: String
    private let glyph: Image
    private let action: () -> Void

    public init(title: String, detail: String, glyph: Image, action: @escaping () -> Void) {
        self.title = title
        self.detail = detail
        self.glyph = glyph
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
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
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Space.s)
                Art.chevron
                    .resizable()
                    .scaledToFit()
                    .frame(width: 8, height: 14)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.trailing, 2)
            }
            .padding(Space.l)
            .background(Palette.surface, in: .rect(cornerRadius: Radius.xl))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.xl)
                    .strokeBorder(Palette.separator, lineWidth: 1)
            }
            .contentShape(.rect(cornerRadius: Radius.xl))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

private struct ChoicePreview: View {
    @State private var picked = 0

    var body: some View {
        VStack(spacing: Space.s) {
            ForEach(0..<3) { index in
                PlaceChoiceRow(
                    name: "Brambleline Café", facts: "Food & drink · 40 m", glyph: Art.glyph(.foodAndDrink),
                    isSelected: picked == index
                ) {
                    picked = index
                }
            }
            ChevronCard(title: "Somewhere else", detail: "Name it and pick a category", glyph: Image(systemName: "mappin.and.ellipse")) {}
        }
        .padding(Space.screen)
        .background(Palette.background)
    }
}

#Preview("Place choices") {
    ChoicePreview()
}

#Preview("Place choices · dark") {
    ChoicePreview()
        .preferredColorScheme(.dark)
}
