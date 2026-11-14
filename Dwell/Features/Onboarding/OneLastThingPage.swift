import DwellCore
import DwellUI
import SwiftUI

/// Account setup, step 3: One last thing (screenshot, 14 Nov; brief A.1 #2, §8.2). The 3D
/// puzzle piece over lime turning green, the title and its line; the sheet: the two consents
/// as switches, Continue, and where to change them later.
///
/// "Use my visits to run Dwell" starts on and Continue waits (dimmed) while it's off: Dwell
/// can't work without it. "Help improve Dwell's models" starts off, as its own line says ("Optional,
/// off") and the brief asks: the design draws it on. Neither is bundled with the other, and
/// saying no to the models changes nothing.
///
/// Measured at 393 × 852: the sheet 244 tall; each consent 16 in (title 20 medium, 4 to its
/// line, 14 regular in ink at 70%) with the design's switch (41 × 19) 16 from the sheet's
/// edge, centred on the two lines; the first 16 below the sheet's top, a dashed line (2 on, 2
/// off, 9.6 in) 12 under it, the second 11 under that; Continue (navy, 9.6 in) 12.5 below;
/// the footnote (14, grey, centred) 17.5 below it and 24 above the sheet's foot.
struct OneLastThingPage: View {
    let insets: PageInsets
    @Binding var consent: Consent
    let isSaving: Bool
    let didFail: Bool
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        SetupPage(
            backdrop: .lime,
            insets: insets,
            title: AccountCopy.consentTitle,
            line: AccountCopy.consentLine,
            onBack: onBack
        ) {
            SetupArt(Art.Onboarding.puzzle)
        } sheet: {
            VStack(spacing: 0) {
                Toggle(isOn: $consent.useVisits) {
                    ConsentText(title: AccountCopy.useVisits, line: AccountCopy.useVisitsLine)
                }
                .toggleStyle(.row)
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
                .disabled(!consent.canContinue || isSaving)
                .opacity(consent.canContinue ? 1 : 0.4)
                .motion(value: consent.canContinue)
                .padding(.horizontal, 9.6)
                .padding(.top, 8.5)
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

/// A consent's two lines: its title (20 medium, ink) and 4 below it what it means (14
/// regular, ink at 70%).
private struct ConsentText: View {
    let title: String
    let line: String

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(verbatim: title)
                .textRole(.title)
                .foregroundStyle(Palette.textPrimary)
            Text(verbatim: line)
                .textRole(.caption)
                .foregroundStyle(Palette.textPrimary.opacity(0.7))
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}
