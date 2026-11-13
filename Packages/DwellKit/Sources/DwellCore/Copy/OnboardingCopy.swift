import Foundation

/// Onboarding's words (onboarding flow, 13 Nov). The design's are used as they are, in
/// sentence case; the rest are placeholders marked [COPY NEEDED] until the client's copy deck
/// arrives.
///
/// Onboarding runs before the user sets the dial, so a new user always reads Plain. Only the
/// first title is voiced: Appendix B writes it for all three positions ("Onboarding, step 1"),
/// and a returning user with a dial already set sees theirs. Page titles drop the full stop,
/// as the design sets them.
public enum OnboardingCopy {
    // MARK: My world

    /// Appendix B, "Onboarding, step 1".
    public static let myWorldTitle = VoicedLine(
        peace: "More of your day, quietly",
        plain: "See where your time goes",
        grind: "Know exactly where your hours went")
    public static let myWorldLine = "Dwell notices the places you stop and how long you stay. Your map fills in as you live."
    public static let startMyWorld = "Start my world"
    public static let haveAccount = "I already have an account"

    // MARK: Your places

    public static let placesTitle = "Your places"
    /// The brief's own line (A.1): "Saving a place does not record a visit."
    public static let placesLine = "Add the places that matter. Saving a place does not record a visit."
    public static let enterAddress = "Enter address"
    public static let selectOnMap = "Select on map"
    public static let saveAs = "Save as:"
    /// The design's "Add More", in sentence case (brief §8.6).
    public static let addMore = "Add more"
    public static let `continue` = "Continue"
    public static let skip = "Skip"
    /// "Remove Home": the button that takes an added place out of the list.
    public static func remove(_ draft: PlaceDraft) -> String {
        "Remove \(draft.name)"
    }

    /// The address search's title: "Home address". [COPY NEEDED]
    public static func searchTitle(_ role: SetupRole) -> String {
        switch role {
        case .home, .work: "\(role.name) address"
        case .other: "Address"
        }
    }

    /// Picking a spot on the map instead of typing an address.
    public static let pickOnMapHint = "Move the map until the pin is on your place" // [COPY NEEDED]
    public static let useThisPlace = "Use this place" // [COPY NEEDED]
    public static let cancel = "Cancel"
    /// The map's spot before its address has come back.
    public static let findingAddress = "Finding the address…" // [COPY NEEDED]
    /// A spot the map can't name: its coordinates are kept, with words instead of an address.
    public static let pinnedPlace = "Pinned on the map" // [COPY NEEDED]

    /// Address search found nothing for what was typed.
    public static let noMatches = "No matching addresses" // [COPY NEEDED]
    /// Address search couldn't reach the network.
    public static let searchFailed = "Can't search addresses right now. Select on map works offline." // [COPY NEEDED]

    // MARK: See where it all goes

    public static let seeTitle = "See where it all goes"
    public static let seeLine = "Every hour of your week, sorted. Work, yours and the gaps in between."
    /// The design's back card ("Breakdown" over the week's categories).
    public static let breakdown = "Breakdown"
    /// The example week, as its cards name it ("Dwell was asleep for 8h 46m this week."): the
    /// picture shows a week as if it were this one.
    public static let exampleThis = "this week"

    // MARK: Start my day

    public static let startTitle = "Start my day"
    /// The brief's fixed line (Appendix B), the same at every position.
    public static let startLine = "Dwell records places and times. Never the route between them."
    /// The design's "Allow tracking" / "No, don't track", reworded (the user, 13 Nov): the
    /// brief never says "track" (§8.6), and "Allow Tracking" is Apple's ad-tracking prompt.
    public static let allowLocation = "Allow location"
    public static let notNow = "Not now"

    // MARK: Example world

    /// What VoiceOver says for the example art. The brief asks for the example world to be
    /// captioned as made up (A.1); the design has no caption on screen.
    /// - Parameter duration: how VoiceOver says a time (`DurationText.spoken` in DwellUI).
    public static func exampleMap(duration: (TimeInterval) -> String = DurationText.short) -> String {
        "An example map of Brooklyn with made-up places: \(spoken(OnboardingExample.mapSpots, duration))." // [COPY NEEDED]
    }
    public static let exampleWeek = "An example week, every hour coloured by where it was spent, beside its breakdown by category." // [COPY NEEDED]
    public static func examplePhotos(duration: (TimeInterval) -> String = DurationText.short) -> String {
        "Photos of made-up places: \(spoken(OnboardingExample.daySpots, duration))." // [COPY NEEDED]
    }
    public static let exampleGlobe = "A city curled into a small planet." // [COPY NEEDED]

    /// "Mara's place, 4h 43m; and Brambleline Café, 33m"
    private static func spoken(_ spots: [OnboardingExample.Spot], _ duration: (TimeInterval) -> String) -> String {
        let parts = spots.map { "\($0.name), \(duration($0.time))" }
        guard let last = parts.last else { return "" }
        return parts.count == 1 ? last : parts.dropLast().joined(separator: "; ") + "; and " + last
    }

    /// "Page 2 of 4", for the page dots.
    public static func pageLabel(_ page: OnboardingPage) -> String {
        "Page \(page.rawValue + 1) of \(OnboardingPage.allCases.count)"
    }

    /// Every fixed line, for checks that must hold across onboarding.
    public static var allFixedLines: [String] {
        [
            myWorldLine, startMyWorld, haveAccount,
            placesTitle, placesLine, enterAddress, selectOnMap, saveAs, addMore, `continue`, skip,
            pickOnMapHint, useThisPlace, cancel, findingAddress, pinnedPlace, noMatches, searchFailed,
            seeTitle, seeLine, breakdown,
            startTitle, startLine, allowLocation, notNow,
            exampleMap(), exampleWeek, examplePhotos(), exampleGlobe,
        ] + SetupRole.allCases.map(\.name) + SetupRole.allCases.map(searchTitle)
    }
}
