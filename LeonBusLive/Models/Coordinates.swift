import CoreLocation
import Foundation

/// Geographic point used across the app.
struct Coordinates: Hashable, Codable, Sendable {
    var latitude: Double
    var longitude: Double

    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    /// Approximate city center of León, Spain (fallback when location is unavailable).
    static let leonCityCenter = Coordinates(latitude: 42.5987, longitude: -5.5718)

    func distanceMeters(to other: Coordinates) -> CLLocationDistance {
        clLocation.distance(from: other.clLocation)
    }
}
