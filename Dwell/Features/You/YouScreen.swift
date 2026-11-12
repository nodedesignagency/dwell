import DwellCore
import DwellUI
import SwiftUI

/// You (brief §7.4, A.6): the profile on the map, the dial with the pushes it allows, the
/// leading streak and the badges.
///
/// The dial and the three notification switches are the phone's own settings, kept in
/// `UserDefaults`, so they work even when the rest fails to load. While the dial is dragged
/// the page follows it at once; the app's dial (every other screen) follows a moment after
/// it's let go, so the whole app isn't redrawn on every point of the drag.
struct YouScreen: View {
    @State private var path: [YouPage]
    @State private var state: Loadable<YouModel> = .loading
    @State private var reloads = 0
    @State private var sheet: YouSheet?

    /// The app's dial, which every screen reads (`DwellApp`).
    @AppStorage("dial.position") private var storedDial = Dial.Stop.plain.position
    /// The dial as this page shows it: follows the drag point by point.
    @State private var dial = UserDefaults.standard.object(forKey: "dial.position") as? Double ?? Dial.Stop.plain.position
    @AppStorage("notify.morningRecap") private var morningRecap = NotificationKind.morningRecap.isOnByDefault
    @AppStorage("notify.streakAtRisk") private var streakAtRisk = NotificationKind.streakAtRisk.isOnByDefault
    @AppStorage("notify.records") private var records = NotificationKind.records.isOnByDefault

    @Environment(\.repository) private var repository

    /// - Parameter path: pages already open, for `DWELL_OPEN=places ./scripts/run.sh`.
    init(path: [YouPage] = []) {
        _path = State(initialValue: path)
    }

    var body: some View {
        NavigationStack(path: $path) {
            YouContent(
                state: state,
                dial: $dial,
                isOn: isOn,
                actions: YouActions(
                    retry: { reloads += 1 },
                    open: { path.append($0) },
                    show: { sheet = $0 }))
                .environment(\.dial, Dial(position: dial))
                .task(id: reloads) { await load() }
                .task(id: dial) {
                    // Saved once the drag rests, not on every point of it.
                    guard (try? await Task.sleep(for: .milliseconds(250))) != nil else { return }
                    storedDial = dial
                }
                .onChange(of: storedDial) { _, stored in
                    // Set somewhere else (onboarding's Set your dial).
                    if stored != dial { dial = stored }
                }
                .toolbar(.hidden, for: .navigationBar)
                .clearsTabBar()
                .navigationDestination(for: YouPage.self) { page in
                    destination(page)
                }
                .sheet(item: $sheet) { sheet in
                    PendingView(title: sheet.title, systemImage: sheet.systemImage)
                        .presentationDetents([.medium])
                }
        }
    }

    private func isOn(_ kind: NotificationKind) -> Binding<Bool> {
        switch kind {
        case .morningRecap: $morningRecap
        case .streakAtRisk: $streakAtRisk
        case .records: $records
        }
    }

    @ViewBuilder
    private func destination(_ page: YouPage) -> some View {
        switch page {
        case .places:
            YourPlacesScreen(openPlace: { path.append(.place($0)) })
        default:
            // Not designed yet: each says so instead of guessing.
            PendingView(title: page.title, systemImage: page.systemImage)
                .clearsTabBar()
        }
    }

    private func load() async {
        if case .failed = state { state = .loading }
        let repository = repository
        do {
            async let profile = repository.profile()
            async let places = repository.places()
            async let coverage = repository.coverage()
            async let streaks = repository.streaks()
            async let badges = repository.badges()
            // The cells only colour the map behind the profile: You loads without them.
            let cells = (try? await repository.scratchCells()) ?? []
            state = .loaded(YouModel(
                profile: try await profile,
                placeCount: try await places.count,
                coverage: try await coverage.city,
                cells: cells,
                streaks: try await streaks,
                badges: try await badges))
        } catch is CancellationError {
            return
        } catch let error as LoadError {
            state = .failed(error.failure)
        } catch {
            state = .failed((error as? URLError)?.code == .notConnectedToInternet ? .offline : .unavailable)
        }
    }
}

/// The pages You pushes.
enum YouPage: Hashable {
    case places
    case place(PlaceID)
    case settings
    case streaks
    case badges
    /// The scratch map's coverage at each level (M-08), from "3.2% mapped".
    case coverage

    var title: String {
        switch self {
        case .places: PlacesCopy.title
        case .place: "Place page"
        case .settings: YouCopy.settings
        case .streaks: YouCopy.streaks
        case .badges: YouCopy.badges
        case .coverage: "Scratch map"
        }
    }

    var systemImage: String {
        switch self {
        case .places, .place: "mappin.and.ellipse"
        case .settings: "gearshape"
        case .streaks: "flame"
        case .badges: "medal"
        case .coverage: "map"
        }
    }
}

/// Sheets whose designs haven't arrived.
enum YouSheet: Identifiable {
    /// Work rules (Y-08), from the pencil by the out-by time.
    case outByTarget
    /// Badge detail (S-05).
    case badge(Badge.Kind)

    var id: String {
        switch self {
        case .outByTarget: "out-by"
        case .badge(let kind): "badge-\(kind.rawValue)"
        }
    }

    var title: String {
        switch self {
        case .outByTarget: "Work rules"
        case .badge: "Badge detail"
        }
    }

    var systemImage: String {
        switch self {
        case .outByTarget: "clock"
        case .badge: "medal"
        }
    }
}

/// What You's controls do. The screen wires these; previews leave them empty.
struct YouActions {
    var retry: () -> Void = {}
    var open: (YouPage) -> Void = { _ in }
    var show: (YouSheet) -> Void = { _ in }
}

#Preview("Screen · sample repository") {
    YouScreen()
        .samplePreview()
}
