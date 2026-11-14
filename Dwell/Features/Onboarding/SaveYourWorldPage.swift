import DwellCore
import DwellUI
import SwiftUI

/// Account setup, step 1: Save your world (screenshot, 14 Nov; brief A.1 #2). The Dwell sun
/// over the gold, "Save your world" and its line; the sheet: Continue with Apple, Continue
/// with phone number, and the legal line with its two links.
///
/// Measured at 393 × 852: the sun mark 80 across; the sheet 185 tall, its buttons 9.6 in from
/// its sides and top, 8 apart; the legal line (14, grey, links in ink and underlined, lines 20
/// apart, at most 320 wide so it breaks after "Policy,") 16.5 below the second button, 24 above
/// the sheet's foot.
///
/// While sign-in runs, Continue with Apple shows a spinner and the sheet holds still. If it
/// fails (not when the user closes Apple's sheet), a line says so above the legal line and the
/// buttons try again. The sun mark is drawn in code until the designer's arrives (`DwellMark`).
struct SaveYourWorldPage: View {
    let insets: PageInsets
    let isSigningIn: Bool
    let didFail: Bool
    let onBack: () -> Void
    let onApple: () -> Void
    let onPhone: () -> Void
    let onLegal: (LegalDocument) -> Void

    var body: some View {
        SetupPage(
            backdrop: .gold,
            insets: insets,
            title: AccountCopy.saveTitle,
            line: AccountCopy.saveLine,
            lineWidth: 290,
            onBack: onBack
        ) {
            DwellMark()
        } sheet: {
            VStack(spacing: 0) {
                Button(action: onApple) {
                    if isSigningIn {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(verbatim: AccountCopy.continueWithApple)
                    }
                }
                .buttonStyle(.apple)
                .accessibilityLabel(Text(verbatim: isSigningIn ? AccountCopy.signingIn : AccountCopy.continueWithApple))
                Button(AccountCopy.continueWithPhone, action: onPhone)
                    .buttonStyle(.muted)
                    .padding(.top, Space.s)
                if didFail {
                    Text(verbatim: AccountCopy.signInFailed)
                        .textRole(.caption, weight: .medium)
                        .foregroundStyle(Palette.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Space.m)
                        .transition(.opacity)
                }
                LinkedLine(legalParts) { url in
                    if let document = LegalDocument(url: url) { onLegal(document) }
                }
                .frame(maxWidth: 320)
                .padding(.top, 16.5)
            }
            .padding(.horizontal, 9.6)
            .padding(.top, 9.6)
            .padding(.bottom, 24)
            .disabled(isSigningIn)
            .motion(value: didFail)
        }
    }

    private var legalParts: [LinkedLine.Part] {
        [
            .text(AccountCopy.legalLead + " "),
            .link(AccountCopy.terms, LegalDocument.terms.url),
            .text(" " + AccountCopy.legalJoin + " "),
            .link(AccountCopy.privacyPolicy, LegalDocument.privacy.url),
            .text(AccountCopy.legalTail),
        ]
    }
}

/// The two documents the legal line links to. Their text and addresses are the client's
/// [LINK NEEDED]; until then each opens a stand-in sheet. Their links stay inside the app.
enum LegalDocument: String, Identifiable, CaseIterable {
    case terms
    case privacy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .terms: AccountCopy.terms
        case .privacy: AccountCopy.privacyPolicy
        }
    }

    /// The link inside the line, read back by `init(url:)`.
    var url: URL {
        URL(string: "dwell-legal:\(rawValue)") ?? URL(fileURLWithPath: "/")
    }

    init?(url: URL) {
        guard url.scheme == "dwell-legal" else { return nil }
        self.init(rawValue: url.absoluteString.replacingOccurrences(of: "dwell-legal:", with: ""))
    }
}

/// A legal document's place until the client's text arrives.
struct LegalDocumentSheet: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                document.title, systemImage: "doc.text",
                description: Text(verbatim: "Waiting for the client's text.")) // [COPY NEEDED]
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
