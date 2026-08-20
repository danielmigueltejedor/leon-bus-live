import Foundation
import Observation

/// Simulates vehicle motion and evolving arrival predictions for the mock provider.
@MainActor
@Observable
final class MockRealtimeEngine {
    private(set) var tick: Int = 0
    private(set) var lastTickDate: Date = .now
    private(set) var isRunning = false

    private var vehicles: [String: BusVehicle] = [:]
    private var routePolylines: [String: [Coordinates]] = [:]
    private var task: Task<Void, Never>?
    private let intervalNanoseconds: UInt64

    init(intervalSeconds: Double = 7) {
        self.intervalNanoseconds = UInt64(intervalSeconds * 1_000_000_000)
    }

    func configure(routes: [LineRoute], seedVehicles: [BusVehicle]) {
        routePolylines = Dictionary(uniqueKeysWithValues: routes.map { ($0.line.id, $0.polyline) })
        vehicles = Dictionary(uniqueKeysWithValues: seedVehicles.map { ($0.id, $0) })
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        task = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: self.intervalNanoseconds)
                guard !Task.isCancelled else { break }
                await self.advance()
            }
        }
    }

    func stop() {
        isRunning = false
        task?.cancel()
        task = nil
    }

    func snapshotVehicles(lineID: String? = nil) -> [BusVehicle] {
        let all = Array(vehicles.values)
        guard let lineID else { return all.sorted { $0.id < $1.id } }
        return all.filter { $0.lineID == lineID }.sorted { $0.id < $1.id }
    }

    func predictedArrival(
        for vehicleID: String?,
        stopCoordinate: Coordinates,
        scheduled: Date,
        now: Date = .now
    ) -> (date: Date, delaySeconds: Int?, realtime: Bool) {
        guard let vehicleID, let vehicle = vehicles[vehicleID] else {
            return (scheduled, nil, false)
        }

        let distance = vehicle.coordinate.distanceMeters(to: stopCoordinate)
        let speedMps = max(2.5, vehicle.speedKmh / 3.6)
        let travelSeconds = distance / speedMps
        let predicted = now.addingTimeInterval(travelSeconds)
        let delay = Int(predicted.timeIntervalSince(scheduled))
        return (predicted, delay, true)
    }

    private func advance() {
        tick += 1
        lastTickDate = .now

        for (id, var vehicle) in vehicles {
            let delta = 0.012 + Double((id.hashValue % 5)) * 0.002
            vehicle.routeProgress = (vehicle.routeProgress + delta).truncatingRemainder(dividingBy: 1.0)
            if let polyline = routePolylines[vehicle.lineID], polyline.count >= 2 {
                let sample = PolylineSampler.point(on: polyline, progress: vehicle.routeProgress)
                vehicle.coordinate = sample.coordinate
                vehicle.heading = sample.heading
            }
            vehicle.speedKmh = 18 + Double(abs(id.hashValue % 12))
            vehicle.lastUpdate = lastTickDate
            vehicles[id] = vehicle
        }
    }
}
