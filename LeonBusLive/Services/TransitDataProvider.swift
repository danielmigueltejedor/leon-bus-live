import CoreLocation
import Foundation

/// Abstraction over transit feeds (mock, REST, GTFS, GTFS-RT).
protocol TransitDataProvider: Sendable {
    var providerName: String { get }
    var isDemoProvider: Bool { get }

    func lines() async throws -> [BusLine]
    func line(id: String) async throws -> BusLine
    func stops() async throws -> [BusStop]
    func stop(id: String) async throws -> BusStop
    func nearbyStops(
        around coordinate: Coordinates,
        radiusMeters: CLLocationDistance,
        limit: Int
    ) async throws -> [NearbyStop]
    func arrivals(for stopID: String) async throws -> [BusArrival]
    func route(for lineID: String) async throws -> LineRoute
    func vehicles(for lineID: String?) async throws -> [BusVehicle]
    func search(query: String) async throws -> SearchResults
}
