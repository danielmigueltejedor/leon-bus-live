import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class LocationService: NSObject {
    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var coordinate: Coordinates?
    private(set) var accuracy: CLLocationAccuracy?
    private(set) var lastErrorMessage: String?
    private(set) var isUpdating = false

    /// Used when the user denies location or GPS is unavailable.
    var fallbackCoordinate: Coordinates = .leonCityCenter

    var effectiveCoordinate: Coordinates {
        coordinate ?? fallbackCoordinate
    }

    var hasUserLocation: Bool { coordinate != nil }

    var permissionDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    private let manager: CLLocationManager

    override init() {
        manager = CLLocationManager()
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 25
    }

    func requestWhenInUseIfNeeded() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdating()
        case .denied, .restricted:
            lastErrorMessage = "Permiso de ubicación denegado. Se muestra el centro de León."
        @unknown default:
            break
        }
    }

    func startUpdating() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            return
        }
        isUpdating = true
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        isUpdating = false
        manager.stopUpdatingLocation()
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                lastErrorMessage = nil
                startUpdating()
            case .denied, .restricted:
                stopUpdating()
                coordinate = nil
                lastErrorMessage = "Permiso de ubicación denegado. Se muestra el centro de León."
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = Coordinates(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        let accuracy = location.horizontalAccuracy
        Task { @MainActor in
            self.coordinate = coordinate
            self.accuracy = accuracy
            lastErrorMessage = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            lastErrorMessage = "No se pudo obtener la ubicación. Se usa León como zona inicial."
        }
    }
}
