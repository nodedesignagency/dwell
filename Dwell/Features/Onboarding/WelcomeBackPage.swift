import DwellCore
import DwellUI
import SwiftUI

/// The returning user, step 1: Welcome back (screenshot, 14 Nov; onboarding flow, "Returning
/// user": "Apple or phone, nothing else"; brief A.1, "Sign in to resume"). Reached from My
/// world's "I already have an account". Save your world's page in its words: the Dwell sun over
/// the gold, "Welcome back" and its line; the sheet: Continue with Apple, Continue with phone
/// number, and "New here? Start my world", a link back to a new world.
///
/// Measured at 393 × 852: as Save your world (the sun 80, the buttons 9.6 in from the sheet's
/// sides and top, 8 apart, the line at most 290 wide so it breaks after "hours"); the link (18
/// medium, `link`, underlined) 20 below the second button and 20 above the sheet's foot, its
/// 44 to tap reaching 9 into each.
///
/// While sign-in runs, Continue with Apple shows a spinner and the sheet holds still. A failed
/// sign-in (not the user closing Apple's sheet), or no account for it, says so above the link.
/// No legal line: the account agreed to the terms when it was made, and Re-consent asks again
/// when they change.
struct WelcomeBackPage: View {
    /// What the sheet says above the link.
    nonisolated enum Notice: Equatable {
        /// Apple's sign-in didn't go through.
        case signInFailed
        /// Checking found no account for the sign-in.
        case noAccount

        var line: String {
            switch self {
            case .signInFailed: AccountCopy.signInFailed
            case .noAccount: AccountCopy.noAccount
            }
        }
    }

    let insets: PageInsets
    let isSigningIn: Bool
    let notice: Notice?
    let onBack: () -> Void
    let onApple: () -> Void
    let onPhone: () -> Void
    let onNewHere: () -> Void

    var body: some View {
        SetupPage(
            backdrop: .gold,
            insets: insets,
            title: AccountCopy.welcomeTitle,
            line: AccountCopy.welcomeLine,
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
                if let notice {
                    Text(verbatim: notice.line)
                        .textRole(.caption, weight: .medium)
                        .foregroundStyle(Palette.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Space.m)
                        .transition(.opacity)
                }
                Button(action: onNewHere) {
                    Text(verbatim: AccountCopy.newHere)
                        .underline()
                }
                .buttonStyle(.text(Palette.link))
                .padding(.top, 9)
            }
            .padding(.horizontal, 9.6)
            .padding(.top, 9.6)
            .padding(.bottom, 8.5)
            .disabled(isSigningIn)
            .motion(value: notice)
        }
    }
}
