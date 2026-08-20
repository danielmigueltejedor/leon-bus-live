import CoreLocation
import Foundation

struct APITransitConfiguration: Sendable, Hashable {
    var baseURL: URL
    var apiKey: String?
    var timeout: TimeInterval

    static let `default` = APITransitConfiguration(
        baseURL: URL(string: "https://api.example.com/v1")!,
        apiKey: nil,
        timeout: 20
    )
}

/// REST-oriented provider scaffold. Ready to map real León / GTFS endpoints later.
actor APITransitDataProvider: TransitDataProvider {
    nonisolated let providerName = "API Transit"
    nonisolated let isDemoProvider = false

    private let configuration: APITransitConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder

    init(configuration: APITransitConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func lines() async throws -> [BusLine] {
        try await get("lines", as: [APILineDTO].self).map { $0.toDomain() }
    }

    func line(id: String) async throws -> BusLine {
        try await get("lines/\(id)", as: APILineDTO.self).toDomain()
    }

    func stops() async throws -> [BusStop] {
        try await get("stops", as: [APIStopDTO].self).map { $0.toDomain() }
    }

    func stop(id: String) async throws -> BusStop {
        try await get("stops/\(id)", as: APIStopDTO.self).toDomain()
    }

    func nearbyStops(
        around coordinate: Coordinates,
        radiusMeters: CLLocationDistance,
        limit: Int
    ) async throws -> [NearbyStop] {
        let path = "stops/nearby?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&radius=\(Int(radiusMeters))&limit=\(limit)"
        return try await get(path, as: [APINearbyStopDTO].self).map { $0.toDomain() }
    }

    func arrivals(for stopID: String) async throws -> [BusArrival] {
        try await get("stops/\(stopID)/arrivals", as: [APIArrivalDTO].self).map { $0.toDomain() }
    }

    func route(for lineID: String) async throws -> LineRoute {
        try await get("lines/\(lineID)/route", as: APILineRouteDTO.self).toDomain()
    }

    func vehicles(for lineID: String?) async throws -> [BusVehicle] {
        let path = lineID.map { "vehicles?lineId=\($0)" } ?? "vehicles"
        return try await get(path, as: [APIVehicleDTO].self).map { $0.toDomain() }
    }

    func search(query: String) async throws -> SearchResults {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return try await get("search?q=\(encoded)", as: APISearchDTO.self).toDomain()
    }

    private func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        guard let url = URL(string: path, relativeTo: configuration.baseURL)?.absoluteURL else {
            throw TransitError.unavailable
        }

        var request = URLRequest(url: url, timeoutInterval: configuration.timeout)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let apiKey = configuration.apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw TransitError.unavailable }
            switch http.statusCode {
            case 200..<300:
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw TransitError.decodingFailed
                }
            case 404:
                throw TransitError.notFound
            default:
                throw TransitError.unavailable
            }
        } catch let error as TransitError {
            throw error
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw TransitError.offline
        } catch {
            throw TransitError.unavailable
        }
    }
}
