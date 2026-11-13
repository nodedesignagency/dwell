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

#Preview("Next step, waiting for its design") {
    NextStepPending(step: .saveYourWorld, onBack: {}, onFinish: {})
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
