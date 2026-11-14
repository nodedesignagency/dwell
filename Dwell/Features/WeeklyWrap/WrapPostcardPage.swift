import DwellCore
import DwellUI
import MessageUI
import Photos
import SwiftUI
import UIKit

/// The wrap's last page (Weekly wrap design, "Weekly Wrap 7", 13 Nov): the week as a postcard
/// stamp, and the ways to share it.
///
/// The page's colour: a radial pink, #F6ABBE in the middle (55% down) to #FF567E at the edges,
/// all edge colour 46.5% of the way out, and the designer's swirl stripes over it at 10%,
/// flowing, drawn on the GPU (`SwirlStripesLive`). Both read from the screenshot [VALUES NEEDED].
///
/// Measured from the screenshot at 393 × 852: the title as on the weekend page (48 medium,
/// white, lines 48 apart, its box 29 below the progress bar, breaking after "from"); 16 below
/// it, the stamp (277 × 350, centred; `PostcardStamp`). At the foot, the share panel: the
/// page's grey (#F9F9FB) with 32 corners at the top, 20 down to five share buttons in equal
/// columns 10 in from the sides (`ShareTargetLabel`), 15 to a dashed line (20 in), 15 to "Only
/// categories are shared. Never places or home." (14, grey, centred), 27 above the bottom.
///
/// The five (the user's call, 13 Nov; the design's are all "IG Story"): IG Story and More open
/// the share sheet (Instagram's own story sharing needs a Meta app ID first), Messages opens a
/// message with the postcard (the share sheet where Messages can't send it), Save adds it to
/// Photos and Copy puts it on the clipboard, each saying so with a light tap. What's shared is
/// a 1080 × 1920 image: the stamp on the page's pink and stripes (`PostcardShareCard`), drawn
/// only when it's shared (`PostcardShareItem`), so opening the page never waits on it.
///
/// The stamp lands as the page opens (`Motion.landing`); under Reduce Motion it fades in. The
/// page's clock runs as on every page and, when it's done, the bar stays full and the page
/// stays (the user, 14 Nov); touching a share button stops it where it is (`onShare`). A tap
/// on the stamp side moves on as any page does, which closes the wrap; taps on the panel
/// stay in it. At large text sizes the title
/// stops at the largest standard size and the panel grows; what doesn't fit above it scrolls.
struct WrapPostcardPage: View {
    let state: Loadable<WrapPostcard>
    /// Where the header ends, down from the top of the screen.
    let headerBottom: CGFloat
    var onNext: () -> Void = {}
    var onRetry: () -> Void = {}
    /// A share button was touched: the page's clock stops.
    var onShare: () -> Void = {}

    @Environment(\.dial) private var dial
    @Environment(\.calendar) private var calendar
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var titleWidth: CGFloat = 300
    @State private var map: UIImage?
    @State private var landed = false
    /// The postcard drawn for Messages, while its message is open.
    @State private var messageImage: UIImage?
    @State private var notice: String?
    @State private var confirmations = 0

    /// From the progress bar to the title's box; from the title's box to the stamp.
    private static let top: CGFloat = 29
    private static let titleToStamp: CGFloat = 16

    var body: some View {
        ZStack {
            WrapBackdrop(
                centre: Palette.wrapPostcardCentre,
                edge: Palette.wrapPostcardEdge,
                middle: UnitPoint(x: 0.5, y: 0.55),
                reach: 0.465,
                glows: false)
            SwirlStripesLive()
                .opacity(0.1)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ViewThatFits(in: .vertical) {
                    upper
                    ScrollView {
                        upper.padding(.bottom, Space.l)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollIndicators(.hidden)
                }
                .padding(.top, headerBottom + Self.top)
                .frame(maxHeight: .infinity, alignment: .top)

                if case .failed = state {
                    EmptyView()
                } else {
                    panel
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .task(id: state.value?.city) { await loadMap() }
        .onAppear { landed = true }
        .sheet(isPresented: Binding(get: { messageImage != nil }, set: { if !$0 { messageImage = nil } })) {
            if let messageImage {
                MessageComposer(image: messageImage, body: WrapCopy.shareTitle) { self.messageImage = nil }
                    .ignoresSafeArea()
            }
        }
        .haptic(.confirm, trigger: confirmations)
    }

    // MARK: Title and stamp

    @ViewBuilder
    private var upper: some View {
        switch state {
        case .failed:
            failed
        default:
            VStack(spacing: Self.titleToStamp) {
                LeadedText(WrapCopy.postcardTitle.text(for: dial), role: .storyHeadline, lineHeight: 48)
                    .foregroundStyle(.white)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .frame(maxWidth: titleWidth)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityAction(named: WrapCopy.nextPage, onNext)
                stamp
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var stamp: some View {
        let isLoaded = state.value != nil
        PostcardStamp(postcard: state.value ?? .placeholder, map: map, isPlaceholder: !isLoaded)
            .scaleEffect(landed || reduceMotion ? 1 : 1.08)
            .rotationEffect(.degrees(landed || reduceMotion ? 0 : -4))
            .opacity(landed ? 1 : 0)
            .animation((reduceMotion ? Motion.reduced : Motion.landing).delay(0.15), value: landed)
    }

    /// The opener's words and "Retry", should someone tap on past a week that didn't load.
    private var failed: some View {
        VStack(spacing: Space.m) {
            Text(verbatim: WrapCopy.failed)
                .textRole(.storyLine)
                .foregroundStyle(.white)
            Button(action: onRetry) {
                Text(verbatim: WrapCopy.retry)
                    .textRole(.action)
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, Space.screen)
                    .padding(.vertical, Space.s)
                    .background(.white, in: .capsule)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Space.screen)
        .frame(maxWidth: .infinity)
        .padding(.top, 200)
    }

    // MARK: Share panel

    private var panel: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 0) { targets }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .top), count: 3), spacing: Space.m) {
                    targets
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, Space.screen)
            .disabled(shareItem == nil)
            .opacity(shareItem == nil ? 0.4 : 1)
            DashedDivider()
                .padding(.horizontal, Space.screen)
                .padding(.top, 15)
            Text(verbatim: WrapCopy.sharePrivacy)
                .textRole(.caption)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Space.screen)
                .padding(.top, 15)
        }
        .padding(.bottom, 27)
        .frame(maxWidth: .infinity)
        .background(Palette.background, in: UnevenRoundedRectangle(topLeadingRadius: Radius.xxl, topTrailingRadius: Radius.xxl))
        .overlay(alignment: .top) {
            if let notice {
                Text(verbatim: notice)
                    .textRole(.caption, weight: .medium)
                    .foregroundStyle(Palette.inverseText)
                    .padding(.horizontal, Space.l)
                    .padding(.vertical, Space.s)
                    .background(Palette.inverseSurface, in: .capsule)
                    .offset(y: -Space.xxxl)
                    .transition(.opacity)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .motion(Motion.reduced, value: notice)
        // The panel keeps its taps: on the last page a stray one would close the wrap.
        .contentShape(.rect)
        .onTapGesture {}
    }

    /// What the share sheet hands on: the postcard, drawn when a target asks for it.
    private var shareItem: PostcardShareItem? {
        state.value.map { PostcardShareItem(postcard: $0, map: map, dial: dial, calendar: calendar) }
    }

    @ViewBuilder
    private var targets: some View {
        let preview = SharePreview(WrapCopy.shareTitle)
        let canMessage = MFMessageComposeViewController.canSendText() && MFMessageComposeViewController.canSendAttachments()
        if let shareItem {
            ShareLink(item: shareItem, preview: preview) {
                ShareTargetLabel(WrapCopy.shareInstagram, systemImage: "arrowshape.turn.up.right.fill")
            }
            .simultaneousGesture(TapGesture().onEnded(onShare))
            .accessibilityHint(WrapCopy.shareInstagramHint)
            if canMessage {
                Button(action: message) {
                    ShareTargetLabel(WrapCopy.shareMessages, systemImage: "message.fill")
                }
            } else {
                ShareLink(item: shareItem, preview: preview) {
                    ShareTargetLabel(WrapCopy.shareMessages, systemImage: "message.fill")
                }
                .simultaneousGesture(TapGesture().onEnded(onShare))
            }
            Button { Task { await save() } } label: {
                ShareTargetLabel(WrapCopy.shareSave, systemImage: "square.and.arrow.down.fill")
            }
            Button(action: copy) {
                ShareTargetLabel(WrapCopy.shareCopy, systemImage: "doc.on.doc.fill")
            }
            ShareLink(item: shareItem, preview: preview) {
                ShareTargetLabel(WrapCopy.shareMore, systemImage: "ellipsis")
            }
            .simultaneousGesture(TapGesture().onEnded(onShare))
        } else {
            // Loading: the five, waiting.
            ShareTargetLabel(WrapCopy.shareInstagram, systemImage: "arrowshape.turn.up.right.fill")
            ShareTargetLabel(WrapCopy.shareMessages, systemImage: "message.fill")
            ShareTargetLabel(WrapCopy.shareSave, systemImage: "square.and.arrow.down.fill")
            ShareTargetLabel(WrapCopy.shareCopy, systemImage: "doc.on.doc.fill")
            ShareTargetLabel(WrapCopy.shareMore, systemImage: "ellipsis")
        }
    }

    // MARK: Actions

    private func message() {
        onShare()
        messageImage = shareItem?.image()
    }

    private func save() async {
        onShare()
        guard let shareImage = shareItem?.image() else { return }
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            show(WrapCopy.saveFailed)
            return
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                _ = PHAssetChangeRequest.creationRequestForAsset(from: shareImage)
            }
            confirmations += 1
            show(WrapCopy.saved)
        } catch {
            show(WrapCopy.saveFailed)
        }
    }

    private func copy() {
        onShare()
        guard let shareImage = shareItem?.image() else { return }
        UIPasteboard.general.image = shareImage
        confirmations += 1
        show(WrapCopy.copied)
    }

    /// A word over the panel for 1.6 s; VoiceOver reads it.
    private func show(_ text: String) {
        notice = text
        AccessibilityNotification.Announcement(text).post()
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            if notice == text { notice = nil }
        }
    }

    // MARK: Map and image

    private func loadMap() async {
        guard let city = state.value?.city else { return }
        map = await PostcardMap.snapshot(of: city)
    }

}

/// The postcard as the share sheet hands it on: a PNG of `PostcardShareCard`, drawn only when
/// a target asks for it (drawing it as the page opened froze the page for a moment, the
/// user's recording, 14 Nov). Save, Copy and Messages draw it when they're touched.
nonisolated struct PostcardShareItem: Transferable {
    let postcard: WrapPostcard
    let map: UIImage?
    let dial: Dial
    let calendar: Calendar

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            guard let data = await MainActor.run(body: { item.image()?.pngData() }) else {
                throw CocoaError(.fileWriteUnknown)
            }
            return data
        }
        .suggestedFileName("Postcard.png")
    }

    /// The 1080 × 1920 image.
    @MainActor
    func image() -> UIImage? {
        let card = PostcardShareCard(postcard: postcard, map: map)
            .environment(\.dial, dial)
            .environment(\.calendar, calendar)
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: card)
        renderer.proposedSize = ProposedViewSize(PostcardShareCard.size)
        renderer.scale = 1080 / PostcardShareCard.size.width
        return renderer.uiImage
    }
}

/// The shared image (1080 × 1920, brief §10's story size): the stamp, a fifth larger, on the
/// page's pink and its stripes, held still. Nothing on it names a place or home.
struct PostcardShareCard: View {
    let postcard: WrapPostcard
    let map: UIImage?

    static let size = CGSize(width: 393, height: 393 * 1920 / 1080)

    var body: some View {
        ZStack {
            WrapBackdrop(
                centre: Palette.wrapPostcardCentre,
                edge: Palette.wrapPostcardEdge,
                middle: UnitPoint(x: 0.5, y: 0.5),
                reach: 0.465,
                glows: false)
            SwirlStripes(isMoving: false)
                .opacity(0.1)
            PostcardStamp(postcard: postcard, map: map)
                .scaleEffect(1.2)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipped()
    }
}

extension WrapPostcard {
    /// The stamp's shape while the week loads: its numbers are redacted.
    static let placeholder = WrapPostcard(
        work: 45 * 3600, yours: 23 * 3600, earliestExit: nil, weekendWork: 0, newPlaces: 2, city: nil)
}

/// A new message with the postcard attached (MessageUI), for the Messages button.
struct MessageComposer: UIViewControllerRepresentable {
    let image: UIImage
    let body: String
    var onFinish: () -> Void

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let composer = MFMessageComposeViewController()
        composer.messageComposeDelegate = context.coordinator
        composer.body = body
        if let data = image.pngData() {
            composer.addAttachmentData(data, typeIdentifier: "public.png", filename: "Postcard.png")
        }
        return composer
    }

    func updateUIViewController(_ controller: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            onFinish()
        }
    }
}
