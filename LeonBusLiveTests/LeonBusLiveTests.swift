import Foundation
import Testing
@testable import LeonBusLive

struct ArrivalStatusTests {
    @Test func atStopWhenVeryClose() {
        let arrival = Date().addingTimeInterval(5)
        let status = ArrivalStatus.resolved(
            effectiveArrival: arrival,
            isRealtime: true,
            delaySeconds: 0,
            at: .now
        )
        #expect(status == .atStop)
    }

    @Test func arrivingUnderFortyFiveSeconds() {
        let arrival = Date().addingTimeInterval(30)
        let status = ArrivalStatus.resolved(
            effectiveArrival: arrival,
            isRealtime: true,
            delaySeconds: 0,
            at: .now
        )
        #expect(status == .arriving)
    }

    @Test func lessThanOneMinute() {
        let arrival = Date().addingTimeInterval(50)
        let status = ArrivalStatus.resolved(
            effectiveArrival: arrival,
            isRealtime: true,
            delaySeconds: 0,
            at: .now
        )
        #expect(status == .lessThanOneMinute)
    }

    @Test func minutesRounding() {
        let arrival = Date().addingTimeInterval(125)
        let status = ArrivalStatus.resolved(
            effectiveArrival: arrival,
            isRealtime: true,
            delaySeconds: 0,
            at: .now
        )
        #expect(status == .minutes(3))
    }

    @Test func delayedWhenLateEnough() {
        let arrival = Date().addingTimeInterval(180)
        let status = ArrivalStatus.resolved(
            effectiveArrival: arrival,
            isRealtime: true,
            delaySeconds: 180,
            at: .now
        )
        #expect(status == .delayed(minutes: 3))
    }
}

struct ArrivalSorterTests {
    @Test func sortsByEffectiveArrival() {
        let now = Date()
        let later = BusArrival(
            id: "b",
            stopID: "s",
            lineID: "l",
            vehicleID: nil,
            destination: "A",
            scheduledArrival: now.addingTimeInterval(300),
            predictedArrival: now.addingTimeInterval(300),
            isRealtime: true,
            delaySeconds: 0,
            isDemoData: true
        )
        let sooner = BusArrival(
            id: "a",
            stopID: "s",
            lineID: "l",
            vehicleID: nil,
            destination: "B",
            scheduledArrival: now.addingTimeInterval(600),
            predictedArrival: now.addingTimeInterval(120),
            isRealtime: true,
            delaySeconds: 0,
            isDemoData: true
        )
        let sorted = ArrivalSorter.sorted([later, sooner], at: now)
        #expect(sorted.first?.id == "a")
        #expect(ArrivalSorter.next(from: [later, sooner], at: now)?.id == "a")
    }

    @Test func minutesRemainingCeil() {
        let arrival = BusArrival(
            id: "a",
            stopID: "s",
            lineID: "l",
            vehicleID: nil,
            destination: "X",
            scheduledArrival: Date().addingTimeInterval(61),
            predictedArrival: Date().addingTimeInterval(61),
            isRealtime: true,
            delaySeconds: 0,
            isDemoData: true
        )
        #expect(arrival.minutesRemaining() == 2)
    }
}

@MainActor
struct FavoritesStoreTests {
    @Test func toggleStopAndAlias() {
        let suite = "leonbus.tests.favorites.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        defaults.set(Data("[]".utf8), forKey: "leonbus.favorites.v1")
        let store = FavoritesStore(defaults: defaults)

        #expect(store.isFavorite(stopID: "stop-sd") == false)
        store.toggleStop("stop-sd", alias: "Casa")
        #expect(store.isFavorite(stopID: "stop-sd"))
        #expect(store.alias(forStopID: "stop-sd") == "Casa")
        store.setAlias(forStopID: "stop-sd", alias: "Trabajo")
        #expect(store.alias(forStopID: "stop-sd") == "Trabajo")
        store.toggleStop("stop-sd")
        #expect(store.isFavorite(stopID: "stop-sd") == false)
    }

    @Test func toggleLine() {
        let suite = "leonbus.tests.lines.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("[]".utf8), forKey: "leonbus.favorites.v1")
        let store = FavoritesStore(defaults: defaults)
        store.toggleLine("line-1")
        #expect(store.isFavorite(lineID: "line-1"))
        store.toggleLine("line-1")
        #expect(store.isFavorite(lineID: "line-1") == false)
    }
}

struct APIDTOParsingTests {
    @Test func decodesLineDTO() throws {
        let json = """
        {
          "id": "line-1",
          "number": "1",
          "name": "Universidad",
          "color_hex": "C62828",
          "origin": "Universidad",
          "destination": "Hospitales",
          "stop_ids": ["stop-uni", "stop-sd"],
          "frequency_minutes": 12,
          "is_in_service": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dto = try decoder.decode(APILineDTO.self, from: json)
        let line = dto.toDomain()
        #expect(line.number == "1")
        #expect(line.stopIDs.count == 2)
        #expect(line.isDemoData == false)
    }

    @Test func decodesArrivalDTOISO8601() throws {
        let json = """
        {
          "id": "arr-1",
          "stop_id": "stop-sd",
          "line_id": "line-1",
          "vehicle_id": "veh-1",
          "destination": "Universidad",
          "scheduled_arrival": "2026-08-20T17:00:00Z",
          "predicted_arrival": "2026-08-20T17:02:00Z",
          "realtime": true,
          "delay_seconds": 120
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let arrival = try decoder.decode(APIArrivalDTO.self, from: json).toDomain()
        #expect(arrival.isRealtime)
        #expect(arrival.delaySeconds == 120)
        #expect(arrival.vehicleID == "veh-1")
    }
}

struct DistanceFormatterTests {
    @Test func metersUnderOneKilometer() {
        #expect(DistanceFormatter.walkingLabel(meters: 120) == "120 m")
    }

    @Test func kilometersFormatting() {
        #expect(DistanceFormatter.walkingLabel(meters: 1500) == "1.5 km")
    }
}
