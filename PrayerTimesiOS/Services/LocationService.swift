import Foundation
import CoreLocation
import Observation
import OSLog

enum LocationError: LocalizedError {
    case denied
    case noResult
    case busy
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .denied: return "Location access was denied. Enable it in Settings → Privacy & Security → Location Services."
        case .noResult: return "No location was returned."
        case .busy: return "A location request is already in progress."
        case .failed(let message): return message
        }
    }
}

/// One-shot location + reverse geocoding for the optional auto-detect feature.
/// Adapted from macOS: uses `requestWhenInUseAuthorization()` for iOS and
/// includes `.authorizedWhenInUse` in the authorization check.
@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let log = Logger(subsystem: "co.hasib.prayertimes.ios", category: "location")

    private(set) var authorization: CLAuthorizationStatus
    @ObservationIgnored private var continuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Fetch the current location once, prompting for authorization if needed.
    func fetchCurrent() async throws -> CLLocation {
        guard continuation == nil else { throw LocationError.busy }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                resume(.failure(LocationError.denied))
            @unknown default:
                resume(.failure(LocationError.denied))
            }
        }
    }

    /// Reverse-geocoded facts about a location.
    struct PlaceInfo: Sendable {
        var countryCode: String?
        var timeZone: TimeZone?
    }

    /// Reverse-geocode a location into its country code and timezone.
    func place(for location: CLLocation) async -> PlaceInfo {
        let placemark = try? await geocoder.reverseGeocodeLocation(location).first
        return PlaceInfo(countryCode: placemark?.isoCountryCode, timeZone: placemark?.timeZone)
    }

    // MARK: Continuation plumbing

    private func resume(_ result: Result<CLLocation, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(with: result)
    }

    // MARK: CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated {
            authorization = status
            guard continuation != nil else { return }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.manager.requestLocation()
            case .denied, .restricted:
                resume(.failure(LocationError.denied))
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let first = locations.first
        MainActor.assumeIsolated {
            if let first {
                resume(.success(first))
            } else {
                resume(.failure(LocationError.noResult))
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let message = error.localizedDescription
        MainActor.assumeIsolated {
            resume(.failure(LocationError.failed(message)))
        }
    }
}
