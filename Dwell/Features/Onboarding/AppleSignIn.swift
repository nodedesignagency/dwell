import AuthenticationServices
import DwellCore
import SwiftUI
import UIKit

/// Sign in with Apple as Save your world runs it: Apple's own sheet, then the credential for
/// the repository to send on.
///
/// The app runs on the sample week until the client's engine arrives, and signs the sample
/// account in without Apple's sheet (`.sample`): the sheet needs the client's Apple team and
/// the Sign in with Apple capability, which the project doesn't have yet (QUESTIONS.md, for
/// the client 3). `.system` is the real one, ready for when it does. Nonisolated, so the
/// environment can hold it; each run is on the main actor.
nonisolated struct AppleSignIn: Sendable {
    /// Signs in, or throws `AppleSignIn.Canceled` when the user closes Apple's sheet.
    let run: @MainActor @Sendable () async throws -> SignInCredential

    /// The user closed Apple's sheet: not a failure, nothing to say.
    struct Canceled: Error {}

    /// Apple's sheet, asking for no name and no email: Dwell needs neither.
    static let system = AppleSignIn {
        try await AppleIDRequest().perform()
    }

    /// The sample account, after a beat, as if Apple's sheet had answered.
    static let sample = AppleSignIn {
        try await Task.sleep(for: .milliseconds(600))
        return .apple(userID: "sample", identityToken: nil)
    }
}

extension EnvironmentValues {
    /// How Continue with Apple signs in. The sample until the client's engine and Apple team
    /// arrive.
    @Entry var appleSignIn: AppleSignIn = .sample
}

/// One Sign in with Apple request: Apple's sheet over the app's window, its answer as a
/// credential. Kept alive by `perform()` until Apple answers.
private final class AppleIDRequest: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<SignInCredential, any Error>?
    private var controller: ASAuthorizationController?

    func perform() async throws -> SignInCredential {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = []
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        self.controller = controller
        defer { self.controller = nil }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // Read Apple's answer here; only the Sendable credential goes on to the main actor.
        let result: Result<SignInCredential, any Error>
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            result = .success(.apple(userID: credential.user, identityToken: credential.identityToken))
        } else {
            result = .failure(ASAuthorizationError(.unknown))
        }
        MainActor.assumeIsolated {
            finish(result)
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        let canceled = (error as? ASAuthorizationError)?.code == .canceled
        let failure: any Error = canceled ? AppleSignIn.Canceled() : error
        MainActor.assumeIsolated {
            finish(.failure(failure))
        }
    }

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let windows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
            return windows.first(where: \.isKeyWindow) ?? windows.first ?? ASPresentationAnchor()
        }
    }

    private func finish(_ result: Result<SignInCredential, any Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}
