import DwellCore
import DwellUI
import SwiftUI

// Onboarding's pages and states. Onboarding keeps the design's colours in dark mode too (the
// pages are coloured pictures), so "Dark" checks nothing turns dark under it. Only My world's
// title follows the dial (Appendix B, "Onboarding, step 1"); a new user reads Plain.

#Preview("1 My world") {
    OnboardingScreen(startsAt: .myWorld) {}
        .samplePreview()
}

#Preview("1 My world · Peace") {
    OnboardingScreen(startsAt: .myWorld) {}
        .samplePreview(.peace)
}

#Preview("1 My world · Grind") {
    OnboardingScreen(startsAt: .myWorld) {}
        .samplePreview(.grind)
}

#Preview("1 My world · AX3") {
    OnboardingScreen(startsAt: .myWorld) {}
        .samplePreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("1 My world · Dark") {
    OnboardingScreen(startsAt: .myWorld) {}
        .samplePreview()
        .environment(\.colorScheme, .dark)
}

#Preview("2 Your places") {
    OnboardingScreen(startsAt: .yourPlaces) {}
        .samplePreview()
}

#Preview("2 Your places · places added") {
    PlacesPreview(setup: .preview)
        .samplePreview()
}

#Preview("2 Your places · picking on the map") {
    PlacesPreview(setup: PlaceSetup(), isPicking: true)
        .samplePreview()
}

#Preview("2 Your places · AX3") {
    PlacesPreview(setup: .preview)
        .samplePreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("2 Address search") {
    AddressSearchSheet(role: .home) { _ in }
        .samplePreview()
}

#Preview("3 See where it all goes") {
    OnboardingScreen(startsAt: .seeWhereItGoes) {}
        .samplePreview()
}

#Preview("3 See where it all goes · AX3") {
    OnboardingScreen(startsAt: .seeWhereItGoes) {}
        .samplePreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("4 Start my day") {
    OnboardingScreen(startsAt: .startMyDay) {}
        .samplePreview()
}

#Preview("4 Start my day · AX3") {
    OnboardingScreen(startsAt: .startMyDay) {}
        .samplePreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("4b Location declined") {
    GeometryReader { proxy in
        StartMyDayPage(
            isCurrent: true,
            insets: PageInsets(top: proxy.safeAreaInsets.top, bottom: proxy.safeAreaInsets.bottom),
            onAllow: {}, onNotNow: {})
            .ignoresSafeArea()
    }
    .promptSheet(isPresented: .constant(true)) {
        PromptSheet(
            titleLines: LocationSheetCopy.titleLines,
            message: LocationSheetCopy.message,
            art: Art.Illustration.place,
            actionTitle: LocationSheetCopy.action,
            closeLabel: LocationSheetCopy.close,
            onAction: {}, onClose: {})
    }
    .samplePreview()
}

// Account setup (screens, 14 Nov). Its words hold at every dial position (setup, consent and
// legal lines carry no voice), so one dial stop each; light in dark mode, as all of onboarding.

#Preview("5 Save your world") {
    SetupPreview(.saveYourWorld)
        .samplePreview()
}

#Preview("5 Save your world · signing in") {
    PagePreview { insets in
        SaveYourWorldPage(insets: insets, isSigningIn: true, didFail: false, onBack: {}, onApple: {}, onPhone: {}, onLegal: { _ in })
    }
    .samplePreview()
}

#Preview("5 Save your world · sign-in failed") {
    PagePreview { insets in
        SaveYourWorldPage(insets: insets, isSigningIn: false, didFail: true, onBack: {}, onApple: {}, onPhone: {}, onLegal: { _ in })
    }
    .samplePreview()
}

#Preview("5 Save your world · AX3") {
    SetupPreview(.saveYourWorld)
        .samplePreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("5 Save your world · Dark") {
    SetupPreview(.saveYourWorld)
        .samplePreview()
        .environment(\.colorScheme, .dark)
}

#Preview("5 Terms, waiting for the client's text") {
    LegalDocumentSheet(document: .terms)
        .samplePreview()
}

#Preview("6 Birthday · the design's date") {
    SetupPreview(.birthday, birthday: BirthDate(year: 1995, month: 3, day: 14))
        .samplePreview()
}

#Preview("6 Birthday · starting on today") {
    SetupPreview(.birthday)
        .samplePreview()
}

#Preview("6 Birthday · AX3") {
    SetupPreview(.birthday, birthday: BirthDate(year: 1995, month: 3, day: 14))
        .samplePreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("6 Birthday · Italian") {
    SetupPreview(.birthday, birthday: BirthDate(year: 1995, month: 3, day: 14))
        .samplePreview()
        .environment(\.locale, Locale(identifier: "it_IT"))
}

#Preview("7 One last thing") {
    SetupPreview(.oneLastThing)
        .samplePreview()
}

#Preview("7 One last thing · visits off") {
    PagePreview { insets in
        OneLastThingPage(
            insets: insets, consent: .constant(Consent(useVisits: false)), isSaving: false, didFail: false,
            onBack: {}, onContinue: {})
    }
    .samplePreview()
}

#Preview("7 One last thing · saving failed") {
    PagePreview { insets in
        OneLastThingPage(
            insets: insets, consent: .constant(Consent(improveModels: true)), isSaving: false, didFail: true,
            onBack: {}, onContinue: {})
    }
    .samplePreview()
}

#Preview("7 One last thing · AX3") {
    SetupPreview(.oneLastThing)
        .samplePreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Account setup stopped") {
    SetupPreview(.stopped(.underSixteen))
        .samplePreview()
}

#Preview("Account setup stopped · AX3") {
    SetupPreview(.stopped(.underSixteen))
        .samplePreview()
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Not in your region yet") {
    SetupPreview(.stopped(.notInRegion))
        .samplePreview()
}

#Preview("Not in your region yet · Dark") {
    SetupPreview(.stopped(.notInRegion))
        .samplePreview()
        .environment(\.colorScheme, .dark)
}

#Preview("Next step, waiting for its design") {
    NextStepPending(step: .phoneNumber, onBack: {}, onFinish: {})
        .samplePreview()
}

/// Your places on its own, with a setup to start from.
private struct PlacesPreview: View {
    @State var setup: PlaceSetup
    @State var isPicking = false

    var body: some View {
        GeometryReader { proxy in
            PlacesSetupPage(
                setup: $setup,
                isPickingOnMap: $isPicking,
                isCurrent: true,
                insets: PageInsets(top: proxy.safeAreaInsets.top, bottom: proxy.safeAreaInsets.bottom),
                onContinue: {}, onSkip: {})
                .ignoresSafeArea()
        }
        .preferredColorScheme(.light)
    }
}

extension PlaceSetup {
    /// Home added, work being entered: what the card looks like part way through.
    fileprivate static var preview: PlaceSetup {
        var setup = PlaceSetup()
        setup.current = PlaceDraft(
            address: "214 Kent Ave", area: "Brooklyn, NY",
            coordinate: Coordinate(latitude: 40.7146, longitude: -73.9654), role: .home)
        setup.addMore()
        setup.current.address = "88 Water St"
        setup.current.area = "Brooklyn, NY"
        setup.current.coordinate = Coordinate(latitude: 40.7033, longitude: -73.9881)
        return setup
    }
}

/// Account setup opened on a step, the steps before it behind it.
private struct SetupPreview: View {
    @State private var setup: AccountSetup
    private let birthday: BirthDate?

    init(_ step: AccountStep, birthday: BirthDate? = nil) {
        _setup = State(initialValue: .reaching(step))
        self.birthday = birthday
    }

    var body: some View {
        PagePreview { insets in
            AccountSetupFlow(setup: $setup, insets: insets, birthday: birthday, onLeave: {}, onPending: { _ in }, onComplete: {})
        }
    }
}

/// A page edge to edge, handed the screen's edges as the pager hands them.
private struct PagePreview<Content: View>: View {
    @ViewBuilder let content: (PageInsets) -> Content

    var body: some View {
        GeometryReader { proxy in
            content(PageInsets(top: proxy.safeAreaInsets.top, bottom: proxy.safeAreaInsets.bottom))
                .ignoresSafeArea()
        }
        .preferredColorScheme(.light)
    }
}
