import Foundation

// MARK: - API DTOs (future REST / GTFS-derived payloads)

struct APILineDTO: Codable, Sendable {
    let id: String
    let number: String
    let name: String
    let colorHex: String
    let origin: String
    let destination: String
    let stopIds: [String]
    let frequencyMinutes: Int
    let isInService: Bool

    func toDomain() -> BusLine {
        BusLine(
            id: id,
            number: number,
            name: name,
            colorHex: colorHex,
            origin: origin,
            destination: destination,
            stopIDs: stopIds,
            frequencyMinutes: frequencyMinutes,
            isInService: isInService,
            isDemoData: false
        )
    }
}

struct APIStopDTO: Codable, Sendable {
    let id: String
    let code: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let lineIds: [String]

    func toDomain() -> BusStop {
        BusStop(
            id: id,
            code: code,
            name: name,
            address: address,
            coordinate: Coordinates(latitude: latitude, longitude: longitude),
            lineIDs: lineIds,
            isDemoData: false
        )
    }
}

struct APIArrivalDTO: Codable, Sendable {
    let id: String
    let stopId: String
    let lineId: String
    let vehicleId: String?
    let destination: String
    let scheduledArrival: Date
    let predictedArrival: Date?
    let realtime: Bool
    let delaySeconds: Int?

    func toDomain() -> BusArrival {
        BusArrival(
            id: id,
            stopID: stopId,
            lineID: lineId,
            vehicleID: vehicleId,
            destination: destination,
            scheduledArrival: scheduledArrival,
            predictedArrival: predictedArrival,
            isRealtime: realtime,
            delaySeconds: delaySeconds,
            isDemoData: false
        )
    }
}

struct APIVehicleDTO: Codable, Sendable {
    let id: String
    let lineId: String
    let tripId: String
    let latitude: Double
    let longitude: Double
    let heading: Double
    let speedKmh: Double
    let lastUpdate: Date
    let routeProgress: Double?

    func toDomain() -> BusVehicle {
        BusVehicle(
            id: id,
            lineID: lineId,
            tripID: tripId,
            coordinate: Coordinates(latitude: latitude, longitude: longitude),
            heading: heading,
            speedKmh: speedKmh,
            lastUpdate: lastUpdate,
            routeProgress: routeProgress ?? 0,
            isDemoData: false
        )
    }
}

struct APINearbyStopDTO: Codable, Sendable {
    let stop: APIStopDTO
    let distanceMeters: Double
    let arrivals: [APIArrivalDTO]

    func toDomain() -> NearbyStop {
        NearbyStop(
            stop: stop.toDomain(),
            distanceMeters: distanceMeters,
            arrivals: arrivals.map { $0.toDomain() }
        )
    }
}

struct APILineRouteDTO: Codable, Sendable {
    let line: APILineDTO
    let stops: [APIStopDTO]
    let polyline: [APICoordinateDTO]
    let vehicles: [APIVehicleDTO]

    func toDomain() -> LineRoute {
        LineRoute(
            line: line.toDomain(),
            stops: stops.map { $0.toDomain() },
            polyline: polyline.map { $0.toDomain() },
            vehicles: vehicles.map { $0.toDomain() },
            isDemoData: false
        )
    }
}

struct APICoordinateDTO: Codable, Sendable {
    let latitude: Double
    let longitude: Double

    func toDomain() -> Coordinates {
        Coordinates(latitude: latitude, longitude: longitude)
    }
}

struct APISearchDTO: Codable, Sendable {
    let lines: [APILineDTO]
    let stops: [APIStopDTO]
    let destinations: [APISearchDestinationDTO]

    func toDomain() -> SearchResults {
        SearchResults(
            lines: lines.map { $0.toDomain() },
            stops: stops.map { $0.toDomain() },
            destinations: destinations.map { $0.toDomain() }
        )
    }
}

struct APISearchDestinationDTO: Codable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let lineId: String?
    let stopId: String?

    func toDomain() -> SearchDestination {
        SearchDestination(
            id: id,
            title: title,
            subtitle: subtitle,
            lineID: lineId,
            stopID: stopId
        )
    }
}
