import CoreLocation
import DwellCore
import DwellUI
import MapKit
import Observation
import SwiftUI

/// An address picked for a place, ready to go on the map.
struct PickedAddress: Equatable, Sendable {
    var address: String
    var area: String?
    var coordinate: Coordinate
}

/// Finding an address for onboarding's Your places: a system sheet with a search field ready to
/// type into, and MapKit's suggestions as you type, addresses and named places alike ("Kestriva
/// Labs" finds work as well as its street does). Picking one places it and closes the sheet.
///
/// Not in the design, which shows the field at rest: a sheet, rather than typing on the page,
/// leaves room for the suggestions above the keyboard. What's typed goes to Apple's map search,
/// as in Maps (QUESTIONS.md).
struct AddressSearchSheet: View {
    let role: SetupRole
    let onPick: (PickedAddress) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var search = AddressSearch()
    @State private var lookup = AddressLookup()
    @State private var query = ""
    @State private var isSearchActive = true
    @State private var placing: MKLocalSearchCompletion?
    @State private var couldNotPlace = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(search.results, id: \.self) { completion in
                    Button {
                        place(completion)
                    } label: {
                        HStack(spacing: Space.s) {
                            VStack(alignment: .leading, spacing: Space.xxs) {
                                Text(verbatim: completion.title)
                                    .textRole(.body)
                                    .foregroundStyle(Palette.textPrimary)
                                if !completion.subtitle.isEmpty {
                                    Text(verbatim: completion.subtitle)
                                        .textRole(.caption)
                                        .foregroundStyle(Palette.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            if placing == completion {
                                ProgressView()
                            }
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(placing != nil)
                }
            }
            .listStyle(.plain)
            .overlay {
                if search.hasFailed || couldNotPlace {
                    ContentUnavailableView(
                        OnboardingCopy.searchFailed, systemImage: "wifi.slash")
                } else if !query.isEmpty, search.results.isEmpty, !search.isSearching {
                    ContentUnavailableView(OnboardingCopy.noMatches, systemImage: "magnifyingglass")
                }
            }
            .searchable(
                text: $query, isPresented: $isSearchActive,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text(verbatim: OnboardingCopy.enterAddress))
            .autocorrectionDisabled()
            .onChange(of: query) { _, query in
                couldNotPlace = false
                search.update(query)
            }
            .navigationTitle(OnboardingCopy.searchTitle(role))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(OnboardingCopy.cancel) { dismiss() }
                }
            }
        }
    }

    private func place(_ completion: MKLocalSearchCompletion) {
        placing = completion
        Task {
            let picked = await lookup.place(for: completion)
            placing = nil
            guard let picked else {
                couldNotPlace = true
                return
            }
            onPick(picked)
            dismiss()
        }
    }
}

/// MapKit's address suggestions as the user types. The completer calls back on its own; each
/// answer is carried to the main actor before it's kept.
@MainActor @Observable
final class AddressSearch: NSObject, MKLocalSearchCompleterDelegate {
    private(set) var results: [MKLocalSearchCompletion] = []
    private(set) var isSearching = false
    private(set) var hasFailed = false

    @ObservationIgnored private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func update(_ query: String) {
        let words = query.trimmingCharacters(in: .whitespacesAndNewlines)
        hasFailed = false
        guard !words.isEmpty else {
            completer.cancel()
            results = []
            isSearching = false
            return
        }
        isSearching = true
        completer.queryFragment = words
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in self.keepResults() }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        Task { @MainActor in self.fail() }
    }

    private func keepResults() {
        results = completer.results
        isSearching = false
    }

    private func fail() {
        results = []
        isSearching = false
        hasFailed = true
    }
}

/// Turns a suggestion into a place on the map, and a spot on the map into words. Holds its
/// search and geocoder while they work.
@MainActor
final class AddressLookup {
    private let geocoder = CLGeocoder()
    private var search: MKLocalSearch?

    /// Where a picked suggestion is, or `nil` when MapKit can't say (offline, or gone).
    func place(for completion: MKLocalSearchCompletion) async -> PickedAddress? {
        let search = MKLocalSearch(request: MKLocalSearch.Request(completion: completion))
        self.search = search
        let address = completion.title
        let area = completion.subtitle.isEmpty ? nil : completion.subtitle
        return await withCheckedContinuation { continuation in
            search.start { response, _ in
                guard let point = response?.mapItems.first?.placemark.coordinate else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: PickedAddress(
                    address: address, area: area,
                    coordinate: Coordinate(latitude: point.latitude, longitude: point.longitude)))
            }
        }
    }

    /// The street and town at a spot picked on the map: "214 Kent Ave", "Brooklyn, NY". `nil`
    /// when there's no answer (offline); the spot is kept all the same.
    func name(of coordinate: Coordinate) async -> (address: String, area: String?)? {
        geocoder.cancelGeocode()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return await withCheckedContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, _ in
                guard let mark = placemarks?.first else {
                    continuation.resume(returning: nil)
                    return
                }
                let street = [mark.subThoroughfare, mark.thoroughfare].compactMap(\.self).joined(separator: " ")
                let address = street.isEmpty ? (mark.name ?? "") : street
                let area = [mark.locality, mark.administrativeArea].compactMap(\.self).joined(separator: ", ")
                guard !address.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: (address: address, area: area.isEmpty ? nil : area))
            }
        }
    }
}
