import Foundation

/// Realtime (or simulated) vehicle position.
struct BusVehicle: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let lineID: String
    let tripID: String
    var coordinate: Coordinates
    var heading: Double
    var speedKmh: Double
    var lastUpdate: Date
    /// Progress along the mock route polyline, 0...1.
    var routeProgress: Double
    let isDemoData: Bool
}
