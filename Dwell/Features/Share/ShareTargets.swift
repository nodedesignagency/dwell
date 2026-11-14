import DwellCore
import DwellUI
import MessageUI
import Photos
import SwiftUI
import UIKit

/// The five ways to share, in equal columns (the design's five "IG Story" are placeholders;
/// the user's five, 13 Nov): IG Story and More open the share sheet (Instagram's own story
/// sharing needs a Meta app ID first), Messages opens a message with the image (the share
/// sheet where the phone can't send one), Save adds it to Photos and Copy puts it on the
/// clipboard, each saying so for a moment with a light tap. Three to a row when five don't
/// fit (large text).
///
/// The same buttons and behaviour as the weekly wrap's postcard (`WrapPostcardPage`), here for
/// any shared card: the share sheet hands on `item`, and Save, Copy and Messages draw `image`
/// when they're touched, so nothing is drawn until something is shared.
struct ShareTargets<Item: Transferable>: View {
    /// What the share sheet hands on. `nil` while there's nothing to share yet: the buttons wait.
    let item: Item?
    /// The shared image's title in the share sheet.
    let previewTitle: String
    /// What VoiceOver adds to IG Story.
    let instagramHint: String
    /// The image, drawn when Save, Copy or Messages asks for it.
    let image: () -> UIImage?
    /// A button was touched (the postcard's page stops its clock).
    var onShare: () -> Void = {}

    /// The image for Messages, while its message is open.
    @State private var messageImage: UIImage?
    @State private var notice: String?
    @State private var confirmations = 0

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 0) { targets }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .top), count: 3), spacing: Space.m) {
                targets
            }
        }
        .disabled(item == nil)
        .opacity(item == nil ? 0.4 : 1)
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
                    .allowsHitTesting(false)
            }
        }
        .motion(Motion.reduced, value: notice)
        .sheet(isPresented: Binding(get: { messageImage != nil }, set: { if !$0 { messageImage = nil } })) {
            if let messageImage {
                MessageComposer(image: messageImage, body: previewTitle) { self.messageImage = nil }
                    .ignoresSafeArea()
            }
        }
        .haptic(.confirm, trigger: confirmations)
    }

    @ViewBuilder
    private var targets: some View {
        if let item {
            let preview = SharePreview(previewTitle)
            let canMessage = MFMessageComposeViewController.canSendText() && MFMessageComposeViewController.canSendAttachments()
            ShareLink(item: item, preview: preview) {
                ShareTargetLabel(ShareCopy.instagram, systemImage: "arrowshape.turn.up.right.fill")
            }
            .simultaneousGesture(TapGesture().onEnded(onShare))
            .accessibilityHint(instagramHint)
            if canMessage {
                Button(action: message) {
                    ShareTargetLabel(ShareCopy.messages, systemImage: "message.fill")
                }
            } else {
                ShareLink(item: item, preview: preview) {
                    ShareTargetLabel(ShareCopy.messages, systemImage: "message.fill")
                }
                .simultaneousGesture(TapGesture().onEnded(onShare))
            }
            Button { Task { await save() } } label: {
                ShareTargetLabel(ShareCopy.save, systemImage: "square.and.arrow.down.fill")
            }
            Button(action: copy) {
                ShareTargetLabel(ShareCopy.copy, systemImage: "doc.on.doc.fill")
            }
            ShareLink(item: item, preview: preview) {
                ShareTargetLabel(ShareCopy.more, systemImage: "ellipsis")
            }
            .simultaneousGesture(TapGesture().onEnded(onShare))
        } else {
            // Nothing to share yet: the five, waiting.
            ShareTargetLabel(ShareCopy.instagram, systemImage: "arrowshape.turn.up.right.fill")
            ShareTargetLabel(ShareCopy.messages, systemImage: "message.fill")
            ShareTargetLabel(ShareCopy.save, systemImage: "square.and.arrow.down.fill")
            ShareTargetLabel(ShareCopy.copy, systemImage: "doc.on.doc.fill")
            ShareTargetLabel(ShareCopy.more, systemImage: "ellipsis")
        }
    }

    // MARK: Actions

    private func message() {
        onShare()
        messageImage = image()
    }

    private func save() async {
        onShare()
        guard let shared = image() else { return }
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            show(ShareCopy.saveFailed)
            return
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                _ = PHAssetChangeRequest.creationRequestForAsset(from: shared)
            }
            confirmations += 1
            show(ShareCopy.saved)
        } catch {
            show(ShareCopy.saveFailed)
        }
    }

    private func copy() {
        onShare()
        guard let shared = image() else { return }
        UIPasteboard.general.image = shared
        confirmations += 1
        show(ShareCopy.copied)
    }

    /// A word over the buttons for 1.6 s; VoiceOver reads it.
    private func show(_ text: String) {
        notice = text
        AccessibilityNotification.Announcement(text).post()
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            if notice == text { notice = nil }
        }
    }
}
