import Foundation

/// Account setup's words (screens, 14 Nov): Save your world, the birthday, One last thing and
/// the two stops. The design's are used as they are, in sentence case and with its slips
/// mended (QUESTIONS.md); the rest are placeholders marked [COPY NEEDED] until the client's
/// copy deck arrives. One line each: a new user hasn't set the dial yet (Plain), and setup,
/// consent and legal words hold at every position.
public enum AccountCopy {
    // MARK: Save your world

    public static let saveTitle = "Save your world"
    public static let saveLine = "Sign in so your places and hours stay with you, even on a new phone."
    /// One of the three titles Apple allows on its button ("Sign in", "Sign up", "Continue").
    public static let continueWithApple = "Continue with Apple"
    /// The design's "Continue with Phone Number", in sentence case (brief §8.6).
    public static let continueWithPhone = "Continue with phone number"
    /// The legal line, with its two links: "By continuing you agree to the Terms and Privacy
    /// Policy, and let Dwell use your visits to run the app."
    public static let legalLead = "By continuing you agree to the"
    public static let terms = "Terms"
    public static let legalJoin = "and"
    public static let privacyPolicy = "Privacy Policy"
    public static let legalTail = ", and let Dwell use your visits to run the app."
    public static var legalLine: String {
        "\(legalLead) \(terms) \(legalJoin) \(privacyPolicy)\(legalTail)"
    }
    /// Sign-in didn't go through (not when the user closed Apple's sheet). [COPY NEEDED]
    public static let signInFailed = "Couldn't sign in. Check your connection and try again."
    /// What VoiceOver says while sign-in runs. [COPY NEEDED]
    public static let signingIn = "Signing in"

    // MARK: Birthday

    public static let birthdayTitle = "When's your birthday?"
    public static let birthdayLine = "Only used to check you're 16 or older. Never stored."
    public static let birthdayLabel = "Select your birth date"
    /// The wheel's columns, for VoiceOver. [COPY NEEDED]
    public static let month = "Month"
    public static let day = "Day"
    public static let year = "Year"
    public static let `continue` = "Continue"

    // MARK: One last thing

    public static let consentTitle = "One last thing"
    public static let consentLine = "Everything else is set. This one is up to you."
    /// The brief's own words (A.1 #2).
    public static let useVisits = "Use my visits to run Dwell"
    /// The design's "Needed fo the app to work", mended.
    public static let useVisitsLine = "Needed for the app to work"
    /// The brief's own words (A.1 #2).
    public static let improveModels = "Help improve Dwell's models"
    public static let improveModelsLine = "Optional, off. Saying no changes nothing."
    /// The design's "Change it anytime in You tab.", with its "the".
    public static let consentFootnote = "Change it anytime in the You tab."
    /// Continue couldn't save the answers. [COPY NEEDED]
    public static let saveFailed = "Couldn't save that. Check your connection and try again."

    // MARK: Stops

    /// The brief's "Account setup stopped." (A.1 #2a), without its full stop, as titles are set.
    public static let stoppedTitle = "Account setup stopped"
    public static let stoppedLine = "Dwell is for people 16 and older. Nothing you entered was saved. You can still look around with example data."
    public static let regionTitle = "Not in your region yet"
    /// The design's line, with its full stop.
    public static let regionLine = "The beta is open in the United States. You can try the fictional demo while we get there."
    /// Both stops' button (brief A.1 #2a).
    public static let noDataPreview = "View a no-data preview"

    public static func title(_ stop: SetupStop) -> String {
        switch stop {
        case .underSixteen: stoppedTitle
        case .notInRegion: regionTitle
        }
    }

    public static func line(_ stop: SetupStop) -> String {
        switch stop {
        case .underSixteen: stoppedLine
        case .notInRegion: regionLine
        }
    }

    /// Every fixed line, for checks that must hold across account setup.
    public static var allFixedLines: [String] {
        [
            saveTitle, saveLine, continueWithApple, continueWithPhone, legalLine, signInFailed, signingIn,
            birthdayTitle, birthdayLine, birthdayLabel, month, day, year, `continue`,
            consentTitle, consentLine, useVisits, useVisitsLine, improveModels, improveModelsLine, consentFootnote, saveFailed,
            stoppedTitle, stoppedLine, regionTitle, regionLine, noDataPreview,
        ]
    }
}
