import DwellCore
import DwellUI
import SwiftUI

/// Re-consent: "We updated how Dwell works" (screenshot, 14 Nov; onboarding flow, "After the
/// first day": "Only if the terms change"; brief A.1, §7.6). One last thing's page and sheet,
/// asked again when the terms change: the 3D map, clock and sync badge over lime turning green,
/// the title on two lines, "Please review before you continue. Your map and hours are
/// untouched."; the sheet: the two consents, Continue, Read what changed, and where to change
/// them later.
///
/// "Use my visits to run Dwell" is locked on (brief A.1: "core locked on"): drawn as the design
/// draws it, it takes no touches, and VoiceOver says it stays on. "Help improve Dwell's
/// models" shows the user's answer as they left it and can change (brief: "training editable").
/// Back shows only after Welcome back, where it returns there; when Re-consent shows on its own
/// it has none, and blocks (the user's call, 14 Nov).
///
/// Measured at 393 × 852: One last thing's sheet (each consent 16 in, the dashed line between,
/// Continue 9.6 in and 12.5 below the second), with Read what changed (grey, 44) 4 under
/// Continue and the footnote 17.5 under that, 24 above the sheet's foot; the sheet 294 tall.
/// The title (37, lines 39 apart) breaks after "how"; the line, at most 300 wide, after "map".
struct ReconsentPage: View {
    let insets: PageInsets
    @Binding var consent: Consent
    let isSaving: Bool
    let didFail: Bool
    /// `nil` when Re-consent blocks.
    let onBack: (() -> Void)?
    let onContinue: () -> Void
    let onReadChanges: () -> Void

    var body: some View {
        SetupPage(
            backdrop: .lime,
            insets: insets,
            title: AccountCopy.reconsentTitle,
            line: AccountCopy.reconsentLine,
            lineWidth: 300,
            titleWidth: 300,
            onBack: onBack
        ) {
            SetupArt(Art.Onboarding.termsUpdated)
        } sheet: {
            VStack(spacing: 0) {
                // Locked on: a constant switch that takes no touches, so the system's switch
                // (iOS 26) doesn't start to flip and snap back.
                Toggle(isOn: .constant(true)) {
                    ConsentText(title: AccountCopy.useVisits, line: AccountCopy.useVisitsLine)
                }
                .toggleStyle(.row)
                .allowsHitTesting(false)
                .accessibilityHint(Text(verbatim: AccountCopy.visitsLocked))
                .padding(.horizontal, Space.l)
                DashedDivider(dash: [2, 2])
                    .padding(.horizontal, 9.6)
                    .padding(.top, 8.5)
                Toggle(isOn: $consent.improveModels) {
                    ConsentText(title: AccountCopy.improveModels, line: AccountCopy.improveModelsLine)
                }
                .toggleStyle(.row)
                .padding(.horizontal, Space.l)
                .padding(.top, 11)
                if didFail {
                    Text(verbatim: AccountCopy.saveFailed)
                        .textRole(.caption, weight: .medium)
                        .foregroundStyle(Palette.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Space.l)
                        .padding(.top, Space.s)
                        .transition(.opacity)
                }
                Button(action: onContinue) {
                    if isSaving {
                        ProgressView()
                            .tint(Palette.inverseText)
                    } else {
                        Text(verbatim: AccountCopy.continue)
                    }
                }
                .buttonStyle(.primary(role: .action))
                .accessibilityLabel(Text(verbatim: AccountCopy.continue))
                .disabled(isSaving)
                .padding(.horizontal, 9.6)
                .padding(.top, 8.5)
                Button(AccountCopy.readWhatChanged, action: onReadChanges)
                    .buttonStyle(.muted)
                    .padding(.horizontal, 9.6)
                    .padding(.top, Space.xs)
                Text(verbatim: AccountCopy.consentFootnote)
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Space.l)
                    .padding(.top, 17.5)
            }
            .padding(.top, 16.3)
            .padding(.bottom, Space.xl)
            .motion(value: didFail)
        }
    }
}

/// Re-consent as it runs: the user's answers held while it shows, Continue saves them
/// (`agreeToTerms`), then on to Today. Read what changed opens the changes (a stand-in until the
/// client's text). Saving failed says so and Continue tries again.
struct ReconsentScreen: View {
    let insets: PageInsets
    /// Back to Welcome back, after sign-in; `nil` when Re-consent blocks.
    let onBack: (() -> Void)?
    let onDone: () -> Void

    @Environment(\.repository) private var repository
    @State private var consent: Consent
    @State private var isSaving = false
    @State private var saveFailed = false
    @State private var document: LegalDocument?

    /// - Parameter consent: the user's answers as they stand.
    init(consent: Consent, insets: PageInsets, onBack: (() -> Void)?, onDone: @escaping () -> Void) {
        _consent = State(initialValue: consent)
        self.insets = insets
        self.onBack = onBack
        self.onDone = onDone
    }

    var body: some View {
        ReconsentPage(
            insets: insets,
            consent: $consent,
            isSaving: isSaving,
            didFail: saveFailed,
            onBack: onBack,
            onContinue: agree,
            onReadChanges: { document = .changes })
            .sheet(item: $document) { document in
                LegalDocumentSheet(document: document)
            }
    }

    private func agree() {
        guard !isSaving else { return }
        isSaving = true
        saveFailed = false
        // The core consent can't be turned off here, whatever the answers held.
        var answers = consent
        answers.useVisits = true
        Task {
            defer { isSaving = false }
            do {
                try await repository.agreeToTerms(answers)
                onDone()
            } catch {
                saveFailed = true
            }
        }
    }
}

extension View {
    /// Re-consent over the app when the terms changed since the user agreed (brief A.1:
    /// blocking; the flow: "Only if the terms change"), asked of the repository once at launch.
    /// It covers everything, tab bar included, with no Back; Today waits underneath, hidden from
    /// VoiceOver, and shows as Re-consent fades once Continue has saved. `opens` forces it, for
    /// reviewing it (`DWELL_OPEN=reconsent`).
    func reconsentGate(checks: Bool, opens: Bool = false) -> some View {
        modifier(ReconsentGate(checks: checks, opens: opens))
    }
}

private struct ReconsentGate: ViewModifier {
    let checks: Bool
    let opens: Bool

    @Environment(\.repository) private var repository
    @State private var review: Consent?

    func body(content: Content) -> some View {
        content
            .accessibilityHidden(review != nil)
            .overlay {
                if let review {
                    GeometryReader { proxy in
                        ReconsentScreen(
                            consent: review,
                            insets: PageInsets(top: proxy.safeAreaInsets.top, bottom: proxy.safeAreaInsets.bottom),
                            onBack: nil
                        ) {
                            withAnimation(Motion.standard) { self.review = nil }
                        }
                        .ignoresSafeArea()
                    }
                    // Light, as all of onboarding: the status bar too.
                    .preferredColorScheme(.light)
                    .transition(.opacity)
                }
            }
            .task {
                if opens {
                    review = Consent()
                } else if checks {
                    review = try? await repository.termsToReview()
                }
            }
    }
}
