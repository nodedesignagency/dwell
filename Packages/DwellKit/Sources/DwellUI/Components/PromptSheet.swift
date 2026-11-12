import SwiftUI

/// A sheet that asks for one thing (Today design, "Turn Location"): a big two-line title, a
/// grey line under it, 3D art over a glow of turning light rays, and one navy button, with a
/// close button in the corner. White, corners 32, sized to its content.
///
/// Measured from the design at 373 × 519: the title (40, lines 44 apart) starts 32 from the
/// top, the message (20, grey, at most 300 wide) 10 under it, the art (200) 17 under that,
/// the button (44) 71 under the art, 10.5 in from the sides and 16 above the bottom. The
/// close button is 44, 16 in from the top and side.
public struct PromptSheet: View {
    @ScaledMetric(relativeTo: .largeTitle) private var titleLineGap: CGFloat = -3.8
    @ScaledMetric(relativeTo: .largeTitle) private var artSize: CGFloat = 200
    @ScaledMetric(relativeTo: .title3) private var closeSize: CGFloat = 44
    @State private var height: CGFloat = 519
    @State private var artCentre: CGPoint = .zero

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

            Text(verbatim: message)
                .textRole(.title, weight: .regular)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
                .padding(.top, 10)
                .padding(.horizontal, Space.l)

            art
                .resizable()
                .scaledToFit()
                .frame(width: artSize, height: artSize)
                .accessibilityHidden(true)
                .onGeometryChange(for: CGPoint.self) { proxy in
                    let frame = proxy.frame(in: .named(Self.space))
                    return CGPoint(x: frame.midX, y: frame.minY + frame.height * 0.36)
                } action: { artCentre = $0 }
                .padding(.top, 17)

            Button(actionTitle, action: onAction)
                .buttonStyle(.primary)
                .padding(.top, 71)
                .padding(.horizontal, 10.5)
        }
        .padding(.bottom, Space.l)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .background {
            SheetGlow()
                .position(artCentre)
        }
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
        .coordinateSpace(.named(Self.space))
        .clipped()
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        .presentationDetents([.height(height)])
        .presentationCornerRadius(Radius.xxl)
        .presentationDragIndicator(.hidden)
        .presentationBackground(Palette.surface)
    }

    private static let space = "PromptSheet"
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
            // Big enough to reach the corners of any sheet this size; the gradient keeps
            // Figma's 1018-pt fade.
            TurningRays(color: Palette.glowRays, size: 760, fadeRadius: 1018)
                .opacity(0.3)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
