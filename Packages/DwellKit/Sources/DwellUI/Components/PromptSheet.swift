import SwiftUI

/// A card that asks for one thing (Today design, "Turn Location"): a big two-line title, a
/// grey line under it, 3D art over a glow of turning light rays, and one navy button, with a
/// close button in the corner. White, corners 32. Present it with `.promptSheet(isPresented:)`.
///
/// Measured from the design at 373 × 519: the title (40, lines 44 apart) starts 32 from the
/// top, the message (20, grey, at most 300 wide) 10 under it, the art (200) 17 under that,
/// the button (44) 71 under the art, 10.5 in from the sides and 16 above the bottom. The
/// close button is 44, 16 in from the top and side.
public struct PromptSheet: View {
    @ScaledMetric(relativeTo: .largeTitle) private var titleLineGap: CGFloat = -3.8
    @ScaledMetric(relativeTo: .largeTitle) private var artSize: CGFloat = 200
    @ScaledMetric(relativeTo: .title3) private var closeSize: CGFloat = 44

    private let titleLines: [String]
    private let message: String
    private let art: Image
    private let actionTitle: String
    private let closeLabel: String
    private let onAction: () -> Void
    private let onClose: () -> Void

    /// - Parameters:
    ///   - titleLines: the title as designed, line by line ("Turn on", "your location").
    ///   - art: 3D art; the glow centres on its upper third (a pin's head).
    ///   - closeLabel: what VoiceOver calls the close button.
    public init(
        titleLines: [String],
        message: String,
        art: Image,
        actionTitle: String,
        closeLabel: String,
        onAction: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.titleLines = titleLines
        self.message = message
        self.art = art
        self.actionTitle = actionTitle
        self.closeLabel = closeLabel
        self.onAction = onAction
        self.onClose = onClose
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.xxl)
        VStack(spacing: 0) {
            VStack(spacing: titleLineGap) {
                ForEach(titleLines, id: \.self) { line in
                    Text(verbatim: line)
                }
            }
            .textRole(.display)
            .foregroundStyle(Palette.textPrimary)
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(titleLines.joined(separator: " "))
            .accessibilityAddTraits(.isHeader)
            // The type's own space above the capitals makes up the rest of the design's 32.
            .padding(.top, 22)
            .padding(.horizontal, Space.l)
            .zIndex(1)

            Text(verbatim: message)
                .textRole(.title, weight: .regular)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
                .padding(.top, 10)
                .padding(.horizontal, Space.l)
                .zIndex(1)

            art
                .resizable()
                .scaledToFit()
                .frame(width: artSize, height: artSize)
                .accessibilityHidden(true)
                // The glow sits behind the art, centred on the pin's head (36% down the art,
                // 14% above its middle); the words and button draw over it.
                .background {
                    SheetGlow()
                        .offset(y: -artSize * 0.14)
                }
                .padding(.top, 17)
                .zIndex(0)

            Button(actionTitle, action: onAction)
                .buttonStyle(.primary)
                .padding(.top, 71)
                .padding(.horizontal, 10.5)
                .zIndex(1)
        }
        .padding(.bottom, Space.l)
        .frame(maxWidth: .infinity)
        .background(Palette.surface)
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: closeSize * 0.36, weight: .medium))
                    .foregroundStyle(Palette.textPrimary)
                    .frame(width: closeSize, height: closeSize)
                    .background(Palette.surfaceRaised, in: .circle)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(closeLabel)
            .padding(Space.l)
        }
        .clipShape(shape)
    }
}

/// Behind the art (Figma "Frame 2147239465", as on the hero tiles, in light): a 726-pt disc
/// fading from clear at its centre to grey at its edge at 50%, under sixteen light rays at
/// 30%, radial from 50% to nothing over 1018 pt.
private struct SheetGlow: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Palette.glowShade.opacity(0), Palette.glowShade],
                    center: .center, startRadius: 0, endRadius: 363))
                .frame(width: 726, height: 726)
                .opacity(0.5)
            // Big enough to reach the corners of the card; the gradient keeps Figma's
            // 1018-pt fade.
            TurningRays(color: Palette.glowRays, size: 760, fadeRadius: 1018)
                .opacity(0.3)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Presenting

extension View {
    /// Presents a card from the bottom of the screen, as the design draws its sheets: floating
    /// 10 in from the sides and 21 up from the bottom edge, over everything (the tab bar too),
    /// the screen behind it blurred and dimmed. It slides up on a smooth spring; it leaves by
    /// its own buttons (set `isPresented` to false), a swipe down, or a tap outside. Under
    /// Reduce Motion it fades instead of sliding.
    public func promptSheet<Card: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder card: @escaping () -> Card
    ) -> some View {
        modifier(PromptSheetPresenter(isPresented: isPresented, card: card))
    }
}

/// Holds a clear full-screen cover, shown and hidden without the system's slide, so the card
/// and the dimming can move on their own.
private struct PromptSheetPresenter<Card: View>: ViewModifier {
    @Binding var isPresented: Bool
    let card: () -> Card
    @State private var isCovering = false

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented, initial: true) { _, show in
                // Closing is the stage's job: it animates out, then lets the cover go.
                guard show, !isCovering else { return }
                withoutAnimation { isCovering = true }
            }
            .fullScreenCover(isPresented: $isCovering) {
                PromptSheetStage(isPresented: $isPresented, card: card) {
                    withoutAnimation { isCovering = false }
                }
                .presentationBackground(.clear)
            }
    }

    private func withoutAnimation(_ change: () -> Void) {
        var still = Transaction()
        still.disablesAnimations = true
        withTransaction(still, change)
    }
}

private struct PromptSheetStage<Card: View>: View {
    @Binding var isPresented: Bool
    let card: () -> Card
    let onGone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var drag: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // The screen behind, blurred and dimmed; a tap here closes the card.
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay { Palette.scrim }
                .opacity(shown ? 1 : 0)
                .contentShape(.rect)
                .onTapGesture { close() }
                .ignoresSafeArea()
                .accessibilityHidden(true)

            if shown {
                // At the largest text sizes the card can outgrow the screen; then it scrolls.
                ViewThatFits(in: .vertical) {
                    card()
                    ScrollView {
                        card()
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
                .padding(.horizontal, 10)
                // Figma: 21 up from the screen's bottom edge, into the home indicator's strip.
                .padding(.bottom, 21)
                .ignoresSafeArea(.container, edges: .bottom)
                .offset(y: drag)
                .gesture(swipeDown)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom))
                .accessibilityAddTraits(.isModal)
                .accessibilityAction(.escape) { close() }
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? Motion.reduced : Motion.arrive) { shown = true }
        }
        .onChange(of: isPresented) { _, show in
            if !show { close() }
        }
    }

    /// Follows the finger down (and only a little up); far or fast enough closes the card.
    private var swipeDown: some Gesture {
        DragGesture()
            .onChanged { value in
                let y = value.translation.height
                drag = y > 0 ? y : y / 8
            }
            .onEnded { value in
                if value.translation.height > 120 || value.predictedEndTranslation.height > 260 {
                    close()
                } else {
                    withAnimation(Motion.arrive) { drag = 0 }
                }
            }
    }

    private func close() {
        guard shown else { return }
        if isPresented { isPresented = false }
        withAnimation(reduceMotion ? Motion.reduced : Motion.leave) {
            shown = false
        } completion: {
            drag = 0
            onGone()
        }
    }
}
