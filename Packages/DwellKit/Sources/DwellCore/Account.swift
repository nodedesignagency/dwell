import Foundation

// Onboarding's account steps (onboarding flow, 13 Nov; screens 14 Nov): after Start my day,
// Save your world (sign in), then the region and age checks, then One last thing (the two
// consents). Brief §7.6 step 2 and A.1 #2, #2a.

/// What the user signed in with on Save your world. The app gets it from Apple (or, once its
/// design arrives, a phone number and its code) and hands it to the repository, whose adapter
/// sends it to the client's server.
public enum SignInCredential: Hashable, Sendable {
    /// Sign in with Apple: Apple's stable ID for this user in this app, and the identity token
    /// the server checks with Apple.
    case apple(userID: String, identityToken: Data?)
}

/// What the account says once the user has signed in.
public enum AccountCheck: Hashable, Sendable {
    /// In the beta's region: on to the age check.
    case eligible
    /// Outside the beta's region, the United States (brief §2, §7.6): setup stops.
    case notInRegion
}

/// Why account setup stopped. Both screens are full screen, with no way back into setup
/// (brief A.1 #2a, A.1 account states).
public enum SetupStop: String, CaseIterable, Hashable, Sendable {
    /// Under 16 (brief A.1 #2a: "Account setup stopped.").
    case underSixteen
    /// Not in the beta's region ("Not in your region yet").
    case notInRegion
}

/// A step of account setup, each its own full screen over onboarding's pages.
public enum AccountStep: Hashable, Sendable {
    /// "Save your world": Continue with Apple or with a phone number.
    case saveYourWorld
    /// "When's your birthday?": the date of birth, only to check 16 or older, never stored.
    case birthday
    /// "One last thing": the two consents.
    case oneLastThing
    /// Setup stopped: under 16, or outside the beta's region.
    case stopped(SetupStop)

    /// A stop has no way back: no back button, no swipe.
    public var canGoBack: Bool {
        if case .stopped = self { return false }
        return true
    }
}

/// Where the user is in account setup: the steps shown so far, the last one showing. Back
/// goes to the one before; Back on the first leaves setup for Start my day.
///
/// The age check sits between sign-in and the consents. iOS's own age-range question (flow
/// overview, "Age range") would come first and skip the birthday when shared; it needs the
/// client's Apple team (QUESTIONS.md), so for now every new account answers the birthday.
public struct AccountSetup: Hashable, Sendable {
    public private(set) var path: [AccountStep]

    /// Setup from the start: Save your world.
    public init() {
        path = [.saveYourWorld]
    }

    /// Setup as it stands once `step` shows, the steps before it behind it, for opening a step
    /// to review it (`DWELL_OPEN=onboarding6`).
    public static func reaching(_ step: AccountStep) -> AccountSetup {
        var setup = AccountSetup()
        switch step {
        case .saveYourWorld:
            break
        case .birthday:
            setup.signedIn(.eligible)
        case .oneLastThing:
            setup.signedIn(.eligible)
            setup.answeredAge(isOldEnough: true)
        case .stopped(.notInRegion):
            setup.signedIn(.notInRegion)
        case .stopped(.underSixteen):
            setup.signedIn(.eligible)
            setup.answeredAge(isOldEnough: false)
        }
        return setup
    }

    /// The step showing.
    public var current: AccountStep { path.last ?? .saveYourWorld }

    /// Whether Back stays in setup (a step to go back to). On the first step Back leaves setup;
    /// on a stop there's no Back at all.
    public var canGoBackWithin: Bool {
        current.canGoBack && path.count > 1
    }

    /// Signed in: the age check, or a stop outside the region.
    public mutating func signedIn(_ check: AccountCheck) {
        guard current == .saveYourWorld else { return }
        switch check {
        case .eligible: path.append(.birthday)
        case .notInRegion: path.append(.stopped(.notInRegion))
        }
    }

    /// The birthday answered: the consents, or a stop under 16.
    public mutating func answeredAge(isOldEnough: Bool) {
        guard current == .birthday else { return }
        path.append(isOldEnough ? .oneLastThing : .stopped(.underSixteen))
    }

    /// Back to the step before. Nothing on the first step (the screen leaves setup) or a stop.
    public mutating func back() {
        guard canGoBackWithin else { return }
        path.removeLast()
    }
}

/// A date of birth as the birthday wheel holds it: a calendar date, no time, no time zone.
/// Used once, to answer the age check (`isOldEnough`), and never stored or sent (brief A.1 #2:
/// "date of birth (once, never stored)").
public struct BirthDate: Hashable, Sendable {
    public private(set) var year: Int
    /// 1 to 12.
    public private(set) var month: Int
    /// 1 to the month's last day.
    public private(set) var day: Int

    /// How old Dwell asks people to be (brief §7.6).
    public static let minimumAge = 16
    /// How far back the year wheel goes.
    public static let oldestAge = 120

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = min(max(month, 1), 12)
        self.day = 1
        setDay(day)
    }

    /// The wheel's starting point: today's month and day in this year, so nobody starts on an
    /// answer that passes and the wheel gives no hint of where the line is. Continue waits for a
    /// year before this one (`isAnswered`).
    public init(today: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.year, .month, .day], from: today)
        self.init(year: parts.year ?? 2000, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    public mutating func setYear(_ year: Int) {
        self.year = year
        setDay(day)
    }

    /// A new month keeps the day where it can: 31 March to February is the 28th (or 29th).
    public mutating func setMonth(_ month: Int) {
        self.month = min(max(month, 1), 12)
        setDay(day)
    }

    public mutating func setDay(_ day: Int) {
        self.day = min(max(day, 1), Self.days(inMonth: month, year: year))
    }

    /// The days in a month of the Gregorian calendar.
    public static func days(inMonth month: Int, year: Int) -> Int {
        switch month {
        case 2: isLeap(year) ? 29 : 28
        case 4, 6, 9, 11: 30
        default: 31
        }
    }

    static func isLeap(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    /// The years the wheel offers, oldest first, up to this one.
    public static func years(today: Date, calendar: Calendar) -> ClosedRange<Int> {
        let now = calendar.component(.year, from: today)
        return (now - oldestAge)...now
    }

    /// A birthday someone could sign up with: a year before this one. Until then Continue waits,
    /// so an untouched wheel never answers for anyone.
    public func isAnswered(today: Date, calendar: Calendar) -> Bool {
        year < calendar.component(.year, from: today)
    }

    /// Whole years old on `today`'s calendar date. A 29 February birthday comes round on
    /// 1 March in other years.
    public func age(on today: Date, calendar: Calendar) -> Int {
        let parts = calendar.dateComponents([.year, .month, .day], from: today)
        let (year, month, day) = (parts.year ?? 0, parts.month ?? 1, parts.day ?? 1)
        let hadBirthday = (month, day) >= (self.month, self.day)
        return year - self.year - (hadBirthday ? 0 : 1)
    }

    /// 16 or older today.
    public func isOldEnough(today: Date, calendar: Calendar) -> Bool {
        age(on: today, calendar: calendar) >= Self.minimumAge
    }
}

/// One last thing's two answers (brief A.1 #2, §8.2). "Use my visits to run Dwell" is needed
/// for the app to work: on to start, and Continue waits while it's off. "Help improve Dwell's
/// models" is optional, off to start, never bundled with anything, and saying no degrades
/// nothing.
public struct Consent: Hashable, Sendable {
    /// "Use my visits to run Dwell". Required.
    public var useVisits: Bool
    /// "Help improve Dwell's models". Optional.
    public var improveModels: Bool

    public init(useVisits: Bool = true, improveModels: Bool = false) {
        self.useVisits = useVisits
        self.improveModels = improveModels
    }

    /// Continue needs the visits consent; the models one is the user's either way.
    public var canContinue: Bool { useVisits }
}

// MARK: - Returning user

// The returning user (onboarding flow, "Returning user"; screens, 14 Nov): My world's "I already
// have an account", then Welcome back (Apple or phone, nothing else), then Checking ("Finding
// the account"), then Today with their data back. Re-consent comes between when the terms
// changed while they were away. Brief A.1: "Sign in to resume", "Re-consent", account states.

/// What Checking finds for the sign-in on Welcome back.
public enum ResumeCheck: Hashable, Sendable {
    /// Their account: their places and hours come back.
    case found
    /// No Dwell account for this sign-in. Nothing is made: a new world starts on My world.
    case notFound
}
