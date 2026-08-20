import Foundation

struct NearbyStop: Identifiable, Hashable, Sendable {
    var id: String { stop.id }
    let stop: BusStop
    let distanceMeters: Double
    let arrivals: [BusArrival]

    var walkingDistanceLabel: String {
        DistanceFormatter.walkingLabel(meters: distanceMeters)
    }
}

struct LineRoute: Identifiable, Hashable, Sendable {
    var id: String { line.id }
    let line: BusLine
    let stops: [BusStop]
    /// Ordered coordinates approximating the path (demo polyline).
    let polyline: [Coordinates]
    let vehicles: [BusVehicle]
    let isDemoData: Bool
}

struct SearchResults: Hashable, Sendable {
    var lines: [BusLine]
    var stops: [BusStop]
    var destinations: [SearchDestination]

    static let empty = SearchResults(lines: [], stops: [], destinations: [])

    var isEmpty: Bool {
        lines.isEmpty && stops.isEmpty && destinations.isEmpty
    }
}

struct SearchDestination: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let lineID: String?
    let stopID: String?
}

enum TransitError: Error, LocalizedError, Equatable, Sendable {
    case unavailable
    case offline
    case notFound
    case unauthorized
    case decodingFailed
    case lineOutOfService
    case realtimeUnavailable

    var errorDescription: String? {
        switch self {
        case .unavailable: return "No se pueden cargar los datos ahora mismo."
        case .offline: return "Sin conexión. Mostrando la última información disponible."
        case .notFound: return "No se ha encontrado lo que buscas."
        case .unauthorized: return "No hay permiso para acceder a estos datos."
        case .decodingFailed: return "Los datos recibidos no se pueden interpretar."
        case .lineOutOfService: return "Esta línea no está en servicio ahora."
        case .realtimeUnavailable: return "El tiempo real no está disponible. Se muestra el horario."
        }
    }
}
