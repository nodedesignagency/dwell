import CoreLocation

/// Asks iOS for When-In-Use location from Start my day, and says how it went. Never Always here
/// (brief A.1): Always is asked a day or two later, in its own moment. The line iOS shows under
/// its question is the app's `NSLocationWhenInUseUsageDescription`: "Dwell records the places
/// you stop at and how long you stay. Never the route between them."
@MainActor
final class LocationAsk: NSObject, CLLocationManagerDelegate {
    enum Answer: Equatable {
        case allowed
        case declined
    }

    private let manager = CLLocationManager()
    private var waiting: CheckedContinuation<Answer, Never>?

    override init() {
        super.init()
        manager.delegate = self
    }

    /// Asks once. When the question has been answered before, iOS doesn't ask again: the
    /// answer given then comes back at once.
    func ask() async -> Answer {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return .allowed
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                waiting = continuation
                manager.requestWhenInUseAuthorization()
            }
        default:
            return .declined
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in self.answered(status) }
    }

    private func answered(_ status: CLAuthorizationStatus) {
        guard status != .notDetermined, let waiting else { return }
        self.waiting = nil
        waiting.resume(returning: status == .authorizedWhenInUse || status == .authorizedAlways ? .allowed : .declined)
    }
}
