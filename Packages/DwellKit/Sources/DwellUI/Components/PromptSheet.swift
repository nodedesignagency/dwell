import SwiftUI

/// A card that asks for one thing (Today design, "Turn Location"): a big two-line title, a
/// grey line under it, 3D art over a glow of turning light rays, and one navy button, with a
/// close button in the corner. White, corners 32. Present it with `.promptSheet(isPresented:)`.
///
/// Measured from the design's screenshots at 373 × 519 (glyph positions, not Figma's boxes):
/// the title (40, lines 44 apart) starts 32 from the top, the message (20, grey, at most 300
/// wide) 8 under it, the art (200) 10 under that, the button (44) 78 under the art, 10.5 in
/// from the sides and 16 above the bottom. The close button is 44 on glass, 16 in from the
/// top and side.
public struct PromptSheet: View {
    @ScaledMetric(relativeTo: .largeTitle) private var titleLineGap: CGFloat = -3.8
    @ScaledMetric(relativeTo: .largeTitle) private var artSize: CGFloat = 200

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
                .padding(.top, 8)
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
                .padding(.top, 10)
                .zIndex(0)

            Button(actionTitle, action: onAction)
                .buttonStyle(.primary)
                .padding(.top, 78)
                .padding(.horizontal, 10.5)
                .zIndex(1)
        }
        .padding(.bottom, Space.l)
        .frame(maxWidth: .infinity)
        .background(Palette.surface)
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                CloseCross()
            }
            .buttonStyle(.glassCircle)
            .accessibilityLabel(closeLabel)
            .padding(Space.l)
        }
        .clipShape(shape)
    }
}

/// Behind the art (Figma "Frame 2147239465", as on the hero tiles, in light): grey over the
/// whole card, a little deeper at the pin, under sixteen light rays at 30%, radial from 50%
/// to nothing over 1018 pt. The grey's falloff is read from the design's screenshot, then
/// lightened at the pin on the user's call (12 Nov): about #E0 at the pin to #E6 at the
/// corners over white. Figma's own numbers for its disc don't render the same outside Figma.
private struct SheetGlow: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    stops: [
                        .init(color: Palette.glowShade.opacity(0.36), location: 0),
                        .init(color: Palette.glowShade.opacity(0.35), location: 0.25),
                        .init(color: Palette.glowShade.opacity(0.32), location: 0.5),
                        .init(color: Palette.glowShade.opacity(0.28), location: 0.7),
                        .init(color: Palette.glowShade.opacity(0.25), location: 1),
                    ],
                    center: .center, startRadius: 0, endRadius: 600))
                .frame(width: 1200, height: 1200)
            // Big enough to reach the corners of the card; the gradient keeps Figma's
            // 1018-pt fade.
            TurningRays(color: Palette.glowRays, size: 760, fadeRadius: 1018)
                .opacity(0.3)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The close button's cross (Figma): 14 across in a 24 box, a 1.5 stroke with round ends, ink.
struct CloseCross: View {
    @ScaledMetric(relativeTo: .title3) private var box: CGFloat = 24

    var body: some View {
        Cross()
            .stroke(Palette.textPrimary, style: StrokeStyle(lineWidth: box / 16, lineCap: .round))
            .frame(width: box * 14 / 24, height: box * 14 / 24)
            .frame(width: box, height: box)
    }
}

nonisolated private struct Cross: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
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
        modifier(PromptSheetPresenter(isPresented: isPresented, card: card, top: { EmptyView() }))
    }

    /// A card from the bottom with something of its own at the top of the screen, over the
    /// status bar ("Set your tone": the notification-style preview of today's insight). The top
    /// piece drops in from above as the card slides up, and leaves the same way; it takes no
    /// touches.
    public func promptSheet<Card: View, Top: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder card: @escaping () -> Card,
        @ViewBuilder top: @escaping () -> Top
    ) -> some View {
        modifier(PromptSheetPresenter(isPresented: isPresented, card: card, top: top))
    }
}

/// Holds a clear full-screen cover, shown and hidden without the system's slide, so the card
/// and the dimming can move on their own.
private struct PromptSheetPresenter<Card: View, Top: View>: ViewModifier {
    @Binding var isPresented: Bool
    let card: () -> Card
    let top: () -> Top
    @State private var isCovering = false

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented, initial: true) { _, show in
                // Closing is the stage's job: it animates out, then lets the cover go.
                guard show, !isCovering else { return }
                withoutAnimation { isCovering = true }
            }
            .fullScreenCover(isPresented: $isCovering) {
                PromptSheetStage(isPresented: $isPresented, card: card, top: top) {
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

private struct PromptSheetStage<Card: View, Top: View>: View {
    @Binding var isPresented: Bool
    let card: () -> Card
    let top: () -> Top
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
                top()
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .ignoresSafeArea(.container, edges: .top)
                    .allowsHitTesting(false)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }

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
