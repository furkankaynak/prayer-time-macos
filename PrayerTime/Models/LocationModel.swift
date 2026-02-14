import Foundation
import CoreLocation
import Adhan

// MARK: - Saved Location

struct SavedLocation: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let city: String
    let country: String
    let timeZoneIdentifier: String

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    var coordinates: Coordinates {
        Coordinates(latitude: latitude, longitude: longitude)
    }

    var displayName: String {
        "\(city), \(country)"
    }
}

// MARK: - Location Search Result

struct LocationSearchResult: Identifiable {
    let id: UUID
    let city: String
    let country: String
    let administrativeArea: String?
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String

    init(
        id: UUID = UUID(),
        city: String,
        country: String,
        administrativeArea: String? = nil,
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String
    ) {
        self.id = id
        self.city = city
        self.country = country
        self.administrativeArea = administrativeArea
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    init(from placemark: CLPlacemark) {
        self.id = UUID()
        self.city = placemark.locality ?? "Unknown"
        self.country = placemark.country ?? "Unknown"
        self.administrativeArea = placemark.administrativeArea
        self.latitude = placemark.location?.coordinate.latitude ?? 0
        self.longitude = placemark.location?.coordinate.longitude ?? 0
        self.timeZoneIdentifier = placemark.timeZone?.identifier ?? TimeZone.current.identifier
    }

    func toSavedLocation() -> SavedLocation {
        SavedLocation(
            latitude: latitude,
            longitude: longitude,
            city: city,
            country: country,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }

    var displayName: String {
        if let area = administrativeArea {
            return "\(city), \(area), \(country)"
        }
        return "\(city), \(country)"
    }
}
