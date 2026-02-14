import Foundation
import CoreLocation

@MainActor
final class LocationService: NSObject, ObservableObject {

    @Published var currentLocation: LocationSearchResult?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocating = false
    @Published var locationError: String?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = locationManager.authorizationStatus
    }

    func requestLocation() {
        isLocating = true
        locationError = nil

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorized:
            locationManager.requestLocation()
        case .denied, .restricted:
            isLocating = false
            locationError = "Location access denied. Use manual search instead."
        @unknown default:
            isLocating = false
            locationError = "Unknown location authorization status."
        }
    }

    func searchLocations(query: String) async -> [LocationSearchResult] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        do {
            let placemarks = try await geocoder.geocodeAddressString(query)
            return placemarks.map { LocationSearchResult(from: $0) }
        } catch {
            return []
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        Task {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    self.currentLocation = LocationSearchResult(from: placemark)
                }
            } catch {
                self.locationError = "Could not determine your city."
            }
            self.isLocating = false
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            reverseGeocode(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isLocating = false
            locationError = "Could not detect your location."
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus

            if isLocating {
                switch manager.authorizationStatus {
                case .authorizedAlways, .authorized:
                    manager.requestLocation()
                case .denied, .restricted:
                    isLocating = false
                    locationError = "Location access denied. Use manual search instead."
                default:
                    break
                }
            }
        }
    }
}
