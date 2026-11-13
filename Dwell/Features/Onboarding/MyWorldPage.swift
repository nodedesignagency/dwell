import DwellCore
import DwellUI
import SwiftUI

/// Onboarding, page 1: My world (screenshot, 13 Nov; brief A.1 #1). A city curled into a small
/// planet under a bright sky, the promise, Start my world, and I already have an account. No
/// permissions here.
///
/// Measured at 393 × 852: the dots 545.5 down; the title (white) in two lines, breaking after
/// "your"; the line in white at 70%; Start my world on white, I already have an account on
/// clear glass, its bottom 32.5 above the screen's edge. The brief's "Preview a fictional demo"
/// isn't on the design (the user's call, 13 Nov: build as designed; QUESTIONS.md).
struct MyWorldPage: View {
    let insets: PageInsets
    let onStart: () -> Void
    let onHaveAccount: () -> Void

    @Environment(\.dial) private var dial

    var body: some View {
        ColorPage(.sky, insets: insets, footInset: 32.5) { room in
            MyWorldSky(room: room)
        } foot: {
            PageWords(
                page: .myWorld,
                title: OnboardingCopy.myWorldTitle.text(for: dial),
                titleWidth: 300,
                line: OnboardingCopy.myWorldLine,
                ink: .white,
                dots: .onColor
            ) {
                Button(OnboardingCopy.startMyWorld, action: onStart)
                    .buttonStyle(.secondary)
                Button(OnboardingCopy.haveAccount, action: onHaveAccount)
                    .buttonStyle(.clearGlass)
            }
        }
    }
}

/// My world's sky, sun and globe: one picture, the top 565 of the design's 393 × 852 screen
/// [ASSET NEEDED: a stand-in cut from the screenshot until the designer's file arrives].
///
/// It keeps the design's distance between the globe's foot and the dots (28.5): on a taller
/// screen it grows with the width and the sky above it runs on; on a short one (an iPhone SE,
/// or large text) it shrinks to fit, and the same picture, blurred and stretched, carries its
/// colours out to the sides. Its foot fades into onboarding's blue under the words.
private struct MyWorldSky: View {
    let room: CGSize

    /// The picture's size on the design's screen.
    private static let size = CGSize(width: 393, height: 565)
    /// Where the dots start on the design's screen: the room above the words.
    private static let designRoom: CGFloat = 545.5

    var body: some View {
        let scale = min(room.width / Self.size.width, room.height / Self.designRoom)
        let width = Self.size.width * scale
        let height = Self.size.height * scale
        let top = room.height - Self.designRoom * scale
        ZStack(alignment: .top) {
            Art.Onboarding.myWorld
                .resizable()
                .scaledToFill()
                .frame(width: room.width, height: room.height)
                .blur(radius: 30, opaque: true)
                .clipped()
                .mask(fade)
            Art.Onboarding.myWorld
                .resizable()
                .frame(width: width, height: height)
                .mask(fade)
                .padding(.top, top)
        }
        .frame(width: room.width, height: room.height, alignment: .top)
        .accessibilityHidden(true)
    }

    /// Full strength down to 92% of the way, gone at the foot.
    private var fade: some View {
        LinearGradient(
            stops: [.init(color: .black, location: 0.92), .init(color: .clear, location: 1)],
            startPoint: .top, endPoint: .bottom)
    }
}
