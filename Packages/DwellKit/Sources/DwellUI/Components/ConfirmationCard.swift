import DwellCore
import SwiftUI

/// "You spent 57m at Brambleline Café. Looks right?" The one piece of work Dwell asks for
/// (brief §7.1). A dark card that floats above the tab bar while a visit needs a yes.
///
/// From the Today Figma frame (where it sits hidden), with the brief's buttons: "Looks right"
/// and "Pick another", never "Yes" and "Wrong place". The design puts everything on one line;
/// the brief's longer sentence and buttons need a second line, so the buttons sit below.
public struct ConfirmationCard: View {
    @ScaledMetric(relativeTo: .subheadline) private var artSize: CGFloat = 40
    private let line: VoicedLine
    private let onLooksRight: () -> Void
    private let onPickAnother: () -> Void

    public init(_ line: VoicedLine, onLooksRight: @escaping () -> Void, onPickAnother: @escaping () -> Void) {
        self.line = line
        self.onLooksRight = onLooksRight
        self.onPickAnother = onPickAnother
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            HStack(spacing: Space.m) {
                Art.confirmVisit
                    .resizable()
                    .scaledToFit()
                    .frame(width: artSize, height: artSize)
                    .accessibilityHidden(true)
                VoiceText(line)
                    .textRole(.caption, weight: .medium)
                    .foregroundStyle(Palette.inverseText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            FlowLayout(alignment: .trailing, spacing: Space.s, lineSpacing: Space.xs) {
                Button(action: onLooksRight) {
                    Text(verbatim: TodayCopy.looksRight)
                        .foregroundStyle(Palette.textPrimary)
                        .padding(.horizontal, Space.l)
                        .padding(.vertical, Space.s)
                        .background(.white, in: .capsule)
                        .frame(minHeight: 44)
                        .contentShape(.rect)
                }
                Button(action: onPickAnother) {
                    Text(verbatim: TodayCopy.pickAnother)
                        .underline()
                        .foregroundStyle(Palette.inverseText)
                        .padding(.horizontal, Space.xs)
                        .frame(minHeight: 44)
                        .contentShape(.rect)
                }
            }
            .buttonStyle(.plain)
            .textRole(.footnote, weight: .semibold)
        }
        .padding(.horizontal, Space.l)
        .padding(.top, Space.l)
        .padding(.bottom, Space.xs)
        .background(Palette.inverseSurface, in: .rect(cornerRadius: Radius.xl))
        .overlay {
            Sheen()
                .clipShape(.rect(cornerRadius: Radius.xl))
        }
        .shadow(color: Color(red: 0.4, green: 0.8, blue: 1).opacity(0.18), radius: 20, y: 9)
        .accessibilityElement(children: .contain)
    }
}
