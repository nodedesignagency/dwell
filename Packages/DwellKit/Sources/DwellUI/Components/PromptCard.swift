import DwellCore
import SwiftUI

/// A card that asks one thing with something to look at in the middle ("Set your tone", "Is
/// this home?"; screenshots, 14 Nov): the title, a grey line, the middle, a navy button and,
/// if given, a words-only button under it; the close button in the corner. On the page's grey
/// (`background`), corners 32. Present it with `.promptSheet(isPresented:)`, like
/// `PromptSheet` (the location sheet), whose title, line and close button it shares.
///
/// Measured at 393 × 852: the title (40) 32 from the top to its capitals, the line (20, grey,
/// at most 300 wide, lines 24 apart) 8 under it; the close button 44 on glass, 16 in.
public struct PromptCard<Middle: View, Backdrop: View>: View {
    private let title: Text
    private let titleLabel: String
    private let message: String
    private let actionTitle: String
    private let actionInset: CGFloat
    private let secondaryTitle: String?
    private let closeLabel: String
    private let onAction: () -> Void
    private let onSecondary: () -> Void
    private let onClose: () -> Void
    private let middle: Middle
    private let backdrop: Backdrop

    /// - Parameters:
    ///   - title: the title as set, voiced or not.
    ///   - titleLabel: what VoiceOver reads for it.
    ///   - actionInset: the navy button's distance from the card's sides (10.5 on "Set your
    ///     tone", 16 on "Is this home?").
    ///   - secondaryTitle: a words-only button under the navy one ("Pick another").
    ///   - middle: what sits between the line and the buttons, edge to edge.
    ///   - backdrop: drawn behind everything, from the card's top ("Set your tone"'s sky).
    public init(
        title: Text,
        titleLabel: String,
        message: String,
        actionTitle: String,
        actionInset: CGFloat = 10.5,
        secondaryTitle: String? = nil,
        closeLabel: String,
        onAction: @escaping () -> Void,
        onSecondary: @escaping () -> Void = {},
        onClose: @escaping () -> Void,
        @ViewBuilder middle: () -> Middle,
        @ViewBuilder backdrop: () -> Backdrop
    ) {
        self.title = title
        self.titleLabel = titleLabel
        self.message = message
        self.actionTitle = actionTitle
        self.actionInset = actionInset
        self.secondaryTitle = secondaryTitle
        self.closeLabel = closeLabel
        self.onAction = onAction
        self.onSecondary = onSecondary
        self.onClose = onClose
        self.middle = middle()
        self.backdrop = backdrop()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.xxl)
        VStack(spacing: 0) {
            title
                .textRole(.display)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: titleLabel))
                .accessibilityAddTraits(.isHeader)
                // The type's own space above the capitals makes up the rest of the design's 32;
                // clear of the close button.
                .padding(.top, 22)
                .padding(.horizontal, 60)

            Text(verbatim: message)
                .textRole(.title, weight: .regular)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 300)
                .padding(.top, 8)
                .padding(.horizontal, Space.l)

            middle

            Button(actionTitle, action: onAction)
                .buttonStyle(.primary)
                .padding(.horizontal, actionInset)
            if let secondaryTitle {
                Button(secondaryTitle, action: onSecondary)
                    .buttonStyle(.text(Palette.textSecondary))
                    .padding(.top, 4)
            }
        }
        .padding(.bottom, secondaryTitle == nil ? Space.l : 4.5)
        .frame(maxWidth: .infinity)
        .background {
            ZStack(alignment: .top) {
                Palette.background
                backdrop
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                CloseCross()
            }
            .buttonStyle(.glassCircle)
            .accessibilityLabel(Text(verbatim: closeLabel))
            .padding(Space.l)
        }
        .clipShape(shape)
    }
}

extension PromptCard where Backdrop == EmptyView {
    public init(
        title: Text,
        titleLabel: String,
        message: String,
        actionTitle: String,
        actionInset: CGFloat = 10.5,
        secondaryTitle: String? = nil,
        closeLabel: String,
        onAction: @escaping () -> Void,
        onSecondary: @escaping () -> Void = {},
        onClose: @escaping () -> Void,
        @ViewBuilder middle: () -> Middle
    ) {
        self.init(
            title: title, titleLabel: titleLabel, message: message, actionTitle: actionTitle,
            actionInset: actionInset, secondaryTitle: secondaryTitle, closeLabel: closeLabel,
            onAction: onAction, onSecondary: onSecondary, onClose: onClose,
            middle: middle, backdrop: { EmptyView() })
    }
}

/// "Set your tone"'s sky: the dial's blue (`dialSky`) across the card's top, even for 57 and
/// gone by 217, with faint white rays turning slowly behind it, meeting at the art (still under
/// Reduce Motion). Read from the screenshot (14 Nov): the blue's strength down the card at 0,
/// 57, 77, 97, 117, 137, 157, 177, 197 and 217 is 100, 100, 82, 70, 58, 39, 21, 11, 3 and 0%.
public struct ToneSky: View {
    /// Where the rays meet, below the card's top: the top of the dial's art.
    private let raysCentre: CGFloat

    public init(raysCentre: CGFloat = 156) {
        self.raysCentre = raysCentre
    }

    /// The blue's strength at each depth below the card's top, in points.
    private static let strength: [(depth: CGFloat, opacity: Double)] = [
        (0, 1), (57, 1), (77, 0.82), (97, 0.70), (117, 0.58),
        (137, 0.39), (157, 0.21), (177, 0.11), (197, 0.03), (217, 0),
    ]

    private static var stops: [Gradient.Stop] {
        strength.map { step in
            Gradient.Stop(color: Palette.dialSky.opacity(step.opacity), location: step.depth / 217)
        }
    }

    public var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(stops: Self.stops, startPoint: .top, endPoint: .bottom)
                .frame(height: 217)
            TurningRays(color: Palette.glowRays, size: 560, fadeRadius: 280)
                .opacity(0.25)
                .frame(width: 560, height: 560)
                .offset(y: raysCentre - 280)
                .mask {
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 217)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A notification as iOS shows one, drawn in the app: "Set your tone"'s preview of today's
/// insight in the dial's voice (screenshot, 14 Nov). A black capsule 86 tall, the Dwell mark
/// (44) 24 in, then "Dwell" (14, grey) over the sentence (14, white), 8 from the mark. The
/// sentence cross-fades as the dial moves into another stop (`VoiceText`). Light in every
/// scheme: it's black. Hides the status bar it sits over.
public struct NotificationPreview: View {
    @Environment(\.dial) private var dial
    private let line: VoicedLine
    @ScaledMetric(relativeTo: .subheadline) private var height: CGFloat = 86
    @ScaledMetric(relativeTo: .subheadline) private var icon: CGFloat = 44

    public init(_ line: VoicedLine) {
        self.line = line
    }

    public var body: some View {
        HStack(spacing: Space.s) {
            DwellMark()
                .frame(width: icon, height: icon)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: ToneSheetCopy.appName)
                    .textRole(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                VoiceText(line)
                    .textRole(.caption)
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 24)
        .padding(.trailing, Space.screen)
        .padding(.vertical, Space.m)
        .frame(minHeight: height)
        .background(.black, in: .capsule)
        .environment(\.colorScheme, .dark)
        .statusBarHidden()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: ToneSheetCopy.previewLabel))
        .accessibilityValue(Text(verbatim: line.text(for: dial)))
    }
}
