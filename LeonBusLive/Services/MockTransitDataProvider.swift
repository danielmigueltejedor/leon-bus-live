import CoreLocation
import Foundation

/// Local demonstration provider. Swap via `DataProviderKind` without touching views.
actor MockTransitDataProvider: TransitDataProvider {
    nonisolated let providerName = "Mock León (demostración)"
    nonisolated let isDemoProvider = true

    private let realtimeEngine: MockRealtimeEngine

    init(realtimeEngine: MockRealtimeEngine) {
        self.realtimeEngine = realtimeEngine
    }

    func bootstrapIfNeeded() async {
        let vehicles = LeonDemoCatalog.seedVehicles()
        let routes = LeonDemoCatalog.routes(vehicles: vehicles)
        await MainActor.run {
            realtimeEngine.configure(routes: routes, seedVehicles: vehicles)
            realtimeEngine.start()
        }
    }

    func lines() async throws -> [BusLine] {
        LeonDemoCatalog.lines
    }

    func line(id: String) async throws -> BusLine {
        guard let line = LeonDemoCatalog.line(id: id) else { throw TransitError.notFound }
        return line
    }

    func stops() async throws -> [BusStop] {
        LeonDemoCatalog.stops
    }

    func stop(id: String) async throws -> BusStop {
        guard let stop = LeonDemoCatalog.stop(id: id) else { throw TransitError.notFound }
        return stop
    }

    func nearbyStops(
        around coordinate: Coordinates,
        radiusMeters: CLLocationDistance,
        limit: Int
    ) async throws -> [NearbyStop] {
        let ranked = LeonDemoCatalog.stops
            .map { stop -> (BusStop, Double) in
                (stop, stop.coordinate.distanceMeters(to: coordinate))
            }
            .filter { $0.1 <= radiusMeters }
            .sorted { $0.1 < $1.1 }
            .prefix(limit)

        var result: [NearbyStop] = []
        for (stop, distance) in ranked {
            let arrivals = try await arrivals(for: stop.id)
            result.append(NearbyStop(stop: stop, distanceMeters: distance, arrivals: Array(arrivals.prefix(3))))
        }
        return result
    }

    func arrivals(for stopID: String) async throws -> [BusArrival] {
        guard let stop = LeonDemoCatalog.stop(id: stopID) else { throw TransitError.notFound }
        let now = Date.now
        var items: [BusArrival] = []

        let vehicles = await MainActor.run { realtimeEngine.snapshotVehicles() }

        for lineID in stop.lineIDs {
            guard let line = LeonDemoCatalog.line(id: lineID), line.isInService else { continue }

            let matchingVehicles = vehicles.filter { $0.lineID == lineID }
            let slots = max(2, matchingVehicles.count)

            for slot in 0..<slots {
                let vehicle = matchingVehicles[safe: slot]
                let scheduledOffset = Double(slot) * Double(line.frequencyMinutes) * 60.0
                    + Double(abs(stop.code.hashValue % 180))
                let scheduled = now.addingTimeInterval(120 + scheduledOffset)

                let prediction: (date: Date, delaySeconds: Int?, realtime: Bool)
                if let vehicle {
                    prediction = await MainActor.run {
                        realtimeEngine.predictedArrival(
                            for: vehicle.id,
                            stopCoordinate: stop.coordinate,
                            scheduled: scheduled,
                            now: now
                        )
                    }
                } else {
                    prediction = (scheduled, nil, false)
                }

                // Mix one scheduled-only arrival for realism.
                let forceScheduled = slot == slots - 1 && matchingVehicles.isEmpty == false && slot > 0 && slot % 3 == 2

                items.append(
                    BusArrival(
                        id: "arr-\(stopID)-\(lineID)-\(slot)",
                        stopID: stopID,
                        lineID: lineID,
                        vehicleID: forceScheduled ? nil : vehicle?.id,
                        destination: slot % 2 == 0 ? line.destination : line.origin,
                        scheduledArrival: scheduled,
                        predictedArrival: forceScheduled ? nil : prediction.date,
                        isRealtime: forceScheduled ? false : prediction.realtime,
                        delaySeconds: forceScheduled ? nil : prediction.delaySeconds,
                        isDemoData: true
                    )
                )
            }
        }

        return ArrivalSorter.sorted(items, at: now)
    }

    func route(for lineID: String) async throws -> LineRoute {
        let line = try await line(id: lineID)
        if !line.isInService {
            throw TransitError.lineOutOfService
        }
        let stops = line.stopIDs.compactMap(LeonDemoCatalog.stop(id:))
        let vehicles = await MainActor.run { realtimeEngine.snapshotVehicles(lineID: lineID) }
        return LineRoute(
            line: line,
            stops: stops,
            polyline: LeonDemoCatalog.polyline(for: line),
            vehicles: vehicles,
            isDemoData: true
        )
    }

    func vehicles(for lineID: String?) async throws -> [BusVehicle] {
        await MainActor.run { realtimeEngine.snapshotVehicles(lineID: lineID) }
    }

    func search(query: String) async throws -> SearchResults {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }
        let needle = trimmed.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

        let matchedLines = LeonDemoCatalog.lines.filter { line in
            [line.number, line.name, line.origin, line.destination, "línea \(line.number)", "linea \(line.number)"]
                .joined(separator: " ")
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .contains(needle)
        }

        let matchedStops = LeonDemoCatalog.stops.filter { stop in
            [stop.name, stop.code, stop.address]
                .joined(separator: " ")
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .contains(needle)
        }

        var destinations: [SearchDestination] = []
        for line in LeonDemoCatalog.lines {
            for title in [line.origin, line.destination, line.name] {
                if title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).contains(needle) {
                    destinations.append(
                        SearchDestination(
                            id: "dest-\(line.id)-\(title)",
                            title: title,
                            subtitle: line.displayTitle,
                            lineID: line.id,
                            stopID: nil
                        )
                    )
                }
            }
        }

        // Deduplicate destination titles
        var seen = Set<String>()
        destinations = destinations.filter { seen.insert($0.title.lowercased()).inserted }

        return SearchResults(lines: matchedLines, stops: matchedStops, destinations: destinations)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
