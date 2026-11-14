import DwellCore
import DwellUI
import SwiftUI

/// The returning user (onboarding flow, "Returning user", 13 Nov; screens, 14 Nov): My world's
/// "I already have an account" slides Welcome back in over the pages. Continue with Apple signs
/// in (Apple's sheet; the sample account until the client's Apple team is in), then Checking
/// rises over Welcome back while the account is found. Found: Today, their data back; or, when
/// the terms changed while they were away, Re-consent first, sliding in over Welcome back with
/// a Back that returns there. Not found: Welcome back says so, and "New here? Start my world"
/// starts a new one. Full screen, no tabs, light in every scheme.
///
/// Checking stays up at least 1.4 s, however quick the answer, so it reads as a moment rather
/// than a flash. Closing it stops the check; Back on Welcome back returns to My world.
struct ReturningUserFlow: View {
    let insets: PageInsets
    /// The whole screen's height, for Checking's map.
    let screenHeight: CGFloat
    /// Signs in straight away, for reviewing Checking (`DWELL_OPEN=checking`).
    var startsChecking = false
    /// Back on Welcome back: My world.
    let onBack: () -> Void
    /// "New here? Start my world": Your places.
    let onNewHere: () -> Void
    /// A step whose design hasn't arrived: phone number.
    let onPending: (OnboardingScreen.Next) -> Void
    /// Signed in, the terms agreed: Today.
    let onFinish: () -> Void

    @Environment(\.repository) private var repository
    @Environment(\.appleSignIn) private var appleSignIn
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSigningIn = false
    @State private var notice: WelcomeBackPage.Notice?
    @State private var credential: SignInCredential?
    @State private var isChecking = false
    @State private var checkFailed = false
    @State private var check: Task<Void, Never>?
    /// The user's answers, when the terms changed while they were away: Re-consent shows.
    @State private var review: Consent?

    /// How long Checking stays up at least.
    private static let leastChecking: Duration = .milliseconds(1400)

    var body: some View {
        ZStack {
            WelcomeBackPage(
                insets: insets,
                isSigningIn: isSigningIn,
                notice: notice,
                onBack: onBack,
                onApple: signInWithApple,
                onPhone: { onPending(.phoneNumber) },
                onNewHere: onNewHere)
                .allowsHitTesting(review == nil)
                .accessibilityHidden(review != nil)
            if let review {
                ReconsentScreen(consent: review, insets: insets, onBack: leaveReview, onDone: onFinish)
                    .zIndex(1)
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing))
            }
        }
        .promptSheet(isPresented: $isChecking) {
            CheckingCard(
                screenHeight: screenHeight,
                didFail: checkFailed,
                onTryAgain: runCheck,
                onClose: { isChecking = false })
        }
        // Closed by its button, a swipe or a tap outside: the check stops.
        .onChange(of: isChecking) { _, showing in
            if !showing { stopChecking() }
        }
        .task {
            if startsChecking { signInWithApple() }
        }
    }

    private var motion: Animation {
        reduceMotion ? Motion.reduced : Motion.standard
    }

    // MARK: Actions

    /// Apple's sheet, then Checking. Closing Apple's sheet says nothing.
    private func signInWithApple() {
        guard !isSigningIn, !isChecking else { return }
        isSigningIn = true
        withAnimation(motion) { notice = nil }
        Task {
            defer { isSigningIn = false }
            do {
                credential = try await appleSignIn.run()
                checkFailed = false
                isChecking = true
                runCheck()
            } catch is AppleSignIn.Canceled {
                return
            } catch {
                withAnimation(motion) { notice = .signInFailed }
            }
        }
    }

    /// Finds the account (and whether the terms changed), at least `leastChecking` long. Try
    /// again runs it afresh.
    private func runCheck() {
        guard let credential else { return }
        check?.cancel()
        withAnimation(motion) { checkFailed = false }
        let started = ContinuousClock.now
        check = Task {
            do {
                let found = try await repository.resumeAccount(credential)
                var terms: Consent?
                if found == .found {
                    terms = try await repository.termsToReview()
                }
                let shown = ContinuousClock.now - started
                if shown < Self.leastChecking {
                    try await Task.sleep(for: Self.leastChecking - shown)
                }
                try Task.checkCancellation()
                check = nil
                finish(found, terms: terms)
            } catch {
                // Stopped by the user: nothing to say.
                guard !Task.isCancelled else { return }
                check = nil
                withAnimation(motion) { checkFailed = true }
            }
        }
    }

    private func stopChecking() {
        check?.cancel()
        check = nil
    }

    /// Checking's answer: Today, Re-consent first, or no account.
    private func finish(_ found: ResumeCheck, terms: Consent?) {
        isChecking = false
        switch found {
        case .notFound:
            credential = nil
            withAnimation(motion) { notice = .noAccount }
        case .found:
            if let terms {
                withAnimation(motion) { review = terms }
            } else {
                // Today once the card has gone (`Motion.leave`, 0.25 s).
                Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    onFinish()
                }
            }
        }
    }

    /// Back on Re-consent: Welcome back, signed out; the terms weren't agreed.
    private func leaveReview() {
        credential = nil
        withAnimation(motion) { review = nil }
    }
}
