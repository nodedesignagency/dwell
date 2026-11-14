import DwellCore
import DwellUI
import SwiftUI

/// Account setup over onboarding's pages (screens, 14 Nov; brief §7.6 step 2): Save your
/// world, then the birthday, then One last thing, or a stop (under 16, or outside the beta's
/// region). Each step slides in over the one before from the trailing edge and slides away on
/// Back (`Motion.standard`); under Reduce Motion they cross-fade. Back on Save your world
/// returns to Start my day. A stop has no Back.
///
/// The birthday is held here only while setup runs: Continue turns it into one answer, and the
/// date is never written anywhere or sent (brief A.1 #2). On a stop the repository forgets
/// everything entered (brief A.1 #2a: "Nothing you entered was saved").
struct AccountSetupFlow: View {
    @Binding var setup: AccountSetup
    let insets: PageInsets
    /// Back on Save your world: back to Start my day.
    let onLeave: () -> Void
    /// A step whose design hasn't arrived: phone number, the no-data preview.
    let onPending: (OnboardingScreen.Next) -> Void
    /// One last thing saved: onboarding is done, and Today asks for the tone.
    let onComplete: () -> Void

    @Environment(\.repository) private var repository
    @Environment(\.appleSignIn) private var appleSignIn
    @Environment(\.fixedNow) private var fixedNow
    @Environment(\.clockOffset) private var clockOffset
    @Environment(\.calendar) private var calendar
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSigningIn = false
    @State private var signInFailed = false
    /// The date on the wheel; `nil` until the birthday shows, so it starts on today.
    @State private var birthday: BirthDate?
    @State private var consent = Consent()
    @State private var isSaving = false
    @State private var saveFailed = false
    @State private var legal: LegalDocument?

    /// - Parameter birthday: a date already on the wheel, for previews.
    init(
        setup: Binding<AccountSetup>,
        insets: PageInsets,
        birthday: BirthDate? = nil,
        onLeave: @escaping () -> Void,
        onPending: @escaping (OnboardingScreen.Next) -> Void,
        onComplete: @escaping () -> Void
    ) {
        _setup = setup
        self.insets = insets
        _birthday = State(initialValue: birthday)
        self.onLeave = onLeave
        self.onPending = onPending
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            ForEach(Array(setup.path.enumerated()), id: \.element) { index, step in
                stepView(step)
                    .zIndex(Double(index))
                    .allowsHitTesting(step == setup.current)
                    .accessibilityHidden(step != setup.current)
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing))
            }
        }
        .sheet(item: $legal) { document in
            LegalDocumentSheet(document: document)
        }
    }

    @ViewBuilder
    private func stepView(_ step: AccountStep) -> some View {
        switch step {
        case .saveYourWorld:
            SaveYourWorldPage(
                insets: insets,
                isSigningIn: isSigningIn,
                didFail: signInFailed,
                onBack: back,
                onApple: signInWithApple,
                onPhone: { onPending(.phoneNumber) },
                onLegal: { legal = $0 })
        case .birthday:
            BirthdayPage(
                insets: insets,
                birthday: birthdayOnWheel,
                years: BirthDate.years(today: now, calendar: calendar),
                canContinue: birthdayOnWheel.wrappedValue.isAnswered(today: now, calendar: calendar),
                onBack: back,
                onContinue: answerBirthday)
        case .oneLastThing:
            OneLastThingPage(
                insets: insets,
                consent: $consent,
                isSaving: isSaving,
                didFail: saveFailed,
                onBack: back,
                onContinue: finish)
        case .stopped(let stop):
            SetupStoppedPage(stop: stop, insets: insets) {
                onPending(.noDataPreview)
            }
        }
    }

    // MARK: Actions

    private var now: Date {
        fixedNow ?? Date().addingTimeInterval(clockOffset)
    }

    private var motion: Animation {
        reduceMotion ? Motion.reduced : Motion.standard
    }

    private var birthdayOnWheel: Binding<BirthDate> {
        Binding(
            get: { birthday ?? BirthDate(today: now, calendar: calendar) },
            set: { birthday = $0 })
    }

    private func back() {
        guard setup.canGoBackWithin else {
            onLeave()
            return
        }
        withAnimation(motion) { setup.back() }
    }

    /// Apple's sheet (the sample account until the client's team is in), then the account's
    /// answer: the birthday, or Not in your region yet. Closing Apple's sheet says nothing.
    private func signInWithApple() {
        guard !isSigningIn else { return }
        isSigningIn = true
        signInFailed = false
        Task {
            defer { isSigningIn = false }
            do {
                let credential = try await appleSignIn.run()
                let check = try await repository.signIn(credential)
                withAnimation(motion) { setup.signedIn(check) }
                if check == .notInRegion {
                    await repository.stopSetup(.notInRegion)
                }
            } catch is AppleSignIn.Canceled {
                return
            } catch {
                signInFailed = true
            }
        }
    }

    /// 16 or older goes on to One last thing; younger stops here for good.
    private func answerBirthday() {
        let isOldEnough = birthdayOnWheel.wrappedValue.isOldEnough(today: now, calendar: calendar)
        withAnimation(motion) { setup.answeredAge(isOldEnough: isOldEnough) }
        if !isOldEnough {
            Task { await repository.stopSetup(.underSixteen) }
        }
    }

    /// The two answers saved, then Today, with Set your tone over it.
    private func finish() {
        guard consent.canContinue, !isSaving else { return }
        isSaving = true
        saveFailed = false
        Task {
            defer { isSaving = false }
            do {
                try await repository.completeSetup(consent)
                onComplete()
            } catch {
                saveFailed = true
            }
        }
    }
}
