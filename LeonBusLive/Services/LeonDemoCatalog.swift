import Foundation

/// Static demonstration catalog inspired by León place names.
/// All entries are fictional for UI development — not official ALESA data.
enum LeonDemoCatalog {
    static let isDemoData = true

    static let lines: [BusLine] = [
        BusLine(id: "line-1", number: "1", name: "Universidad", colorHex: "C62828", origin: "Universidad", destination: "Hospitales", stopIDs: ["stop-uni", "stop-filo", "stop-sd", "stop-guzman", "stop-inmaculada", "stop-hospital"], frequencyMinutes: 12, isInService: true, isDemoData: true),
        BusLine(id: "line-2", number: "2", name: "El Ejido", colorHex: "1565C0", origin: "El Ejido", destination: "La Chantría", stopIDs: ["stop-ejido", "stop-sd", "stop-guzman", "stop-junta", "stop-chantria"], frequencyMinutes: 15, isInService: true, isDemoData: true),
        BusLine(id: "line-3", number: "3", name: "Pinilla", colorHex: "2E7D32", origin: "Pinilla", destination: "Centro", stopIDs: ["stop-pinilla", "stop-inmaculada", "stop-sd", "stop-guzman"], frequencyMinutes: 14, isInService: true, isDemoData: true),
        BusLine(id: "line-4", number: "4", name: "Pinilla Express", colorHex: "6A1B9A", origin: "Pinilla", destination: "Universidad", stopIDs: ["stop-pinilla", "stop-hospital", "stop-sd", "stop-uni"], frequencyMinutes: 18, isInService: true, isDemoData: true),
        BusLine(id: "line-6", number: "6", name: "La Asunción", colorHex: "00838F", origin: "La Asunción", destination: "Estación", stopIDs: ["stop-asuncion", "stop-inmaculada", "stop-sd", "stop-estacion"], frequencyMinutes: 20, isInService: true, isDemoData: true),
        BusLine(id: "line-7", number: "7", name: "Hospitales", colorHex: "EF6C00", origin: "Hospital de León", destination: "Universidad", stopIDs: ["stop-hospital", "stop-junta", "stop-guzman", "stop-sd", "stop-uni"], frequencyMinutes: 12, isInService: true, isDemoData: true),
        BusLine(id: "line-10", number: "10", name: "Eras de Renueva", colorHex: "455A64", origin: "Eras", destination: "Centro", stopIDs: ["stop-eras", "stop-junta", "stop-sd", "stop-guzman"], frequencyMinutes: 16, isInService: true, isDemoData: true),
        BusLine(id: "line-12", number: "12", name: "Puente Castro", colorHex: "AD1457", origin: "Puente Castro", destination: "Universidad", stopIDs: ["stop-castro", "stop-estacion", "stop-sd", "stop-uni"], frequencyMinutes: 22, isInService: false, isDemoData: true)
    ]

    static let stops: [BusStop] = [
        BusStop(id: "stop-sd", code: "SD01", name: "Plaza de Santo Domingo", address: "Plaza de Santo Domingo, León", coordinate: Coordinates(latitude: 42.5989, longitude: -5.5710), lineIDs: ["line-1", "line-2", "line-3", "line-4", "line-6", "line-7", "line-10", "line-12"], isDemoData: true),
        BusStop(id: "stop-guzman", code: "GZ02", name: "Guzmán", address: "Av. de Ordoño II / Guzmán, León", coordinate: Coordinates(latitude: 42.5972, longitude: -5.5702), lineIDs: ["line-1", "line-2", "line-3", "line-7", "line-10"], isDemoData: true),
        BusStop(id: "stop-uni", code: "UN10", name: "Universidad", address: "Campus de Vegazana, León", coordinate: Coordinates(latitude: 42.6120, longitude: -5.5625), lineIDs: ["line-1", "line-4", "line-7", "line-12"], isDemoData: true),
        BusStop(id: "stop-hospital", code: "HL20", name: "Hospital de León", address: "Altos de Nava, León", coordinate: Coordinates(latitude: 42.6165, longitude: -5.5820), lineIDs: ["line-1", "line-4", "line-7"], isDemoData: true),
        BusStop(id: "stop-inmaculada", code: "IN05", name: "Plaza de la Inmaculada", address: "Plaza de la Inmaculada, León", coordinate: Coordinates(latitude: 42.5998, longitude: -5.5688), lineIDs: ["line-1", "line-3", "line-6"], isDemoData: true),
        BusStop(id: "stop-junta", code: "JC30", name: "Junta de Castilla y León", address: "Av. Peregrinos, León", coordinate: Coordinates(latitude: 42.6035, longitude: -5.5755), lineIDs: ["line-2", "line-7", "line-10"], isDemoData: true),
        BusStop(id: "stop-filo", code: "FF11", name: "Facultad de Filosofía", address: "Campus de Vegazana, León", coordinate: Coordinates(latitude: 42.6095, longitude: -5.5648), lineIDs: ["line-1"], isDemoData: true),
        BusStop(id: "stop-pinilla", code: "PN40", name: "Pinilla", address: "Barrio de Pinilla, León", coordinate: Coordinates(latitude: 42.5895, longitude: -5.5580), lineIDs: ["line-3", "line-4"], isDemoData: true),
        BusStop(id: "stop-ejido", code: "EJ15", name: "El Ejido", address: "El Ejido, León", coordinate: Coordinates(latitude: 42.6058, longitude: -5.5650), lineIDs: ["line-2"], isDemoData: true),
        BusStop(id: "stop-chantria", code: "CH16", name: "La Chantría", address: "La Chantría, León", coordinate: Coordinates(latitude: 42.5910, longitude: -5.5805), lineIDs: ["line-2"], isDemoData: true),
        BusStop(id: "stop-asuncion", code: "AS22", name: "La Asunción", address: "La Asunción, León", coordinate: Coordinates(latitude: 42.5940, longitude: -5.5620), lineIDs: ["line-6"], isDemoData: true),
        BusStop(id: "stop-estacion", code: "ES01", name: "Estación de Autobuses", address: "Av. de Palencia, León", coordinate: Coordinates(latitude: 42.5890, longitude: -5.5748), lineIDs: ["line-6", "line-12"], isDemoData: true),
        BusStop(id: "stop-eras", code: "ER08", name: "Eras de Renueva", address: "Eras de Renueva, León", coordinate: Coordinates(latitude: 42.6088, longitude: -5.5788), lineIDs: ["line-10"], isDemoData: true),
        BusStop(id: "stop-castro", code: "PC12", name: "Puente Castro", address: "Puente Castro, León", coordinate: Coordinates(latitude: 42.5835, longitude: -5.5655), lineIDs: ["line-12"], isDemoData: true)
    ]

    static func stop(id: String) -> BusStop? {
        stops.first { $0.id == id }
    }

    static func line(id: String) -> BusLine? {
        lines.first { $0.id == id }
    }

    static func polyline(for line: BusLine) -> [Coordinates] {
        let stopCoords = line.stopIDs.compactMap { stop(id: $0)?.coordinate }
        guard stopCoords.count >= 2 else { return stopCoords }
        return PolylineSampler.densify(stopCoords, segmentsPerLeg: 6)
    }

    static func seedVehicles(now: Date = .now) -> [BusVehicle] {
        var result: [BusVehicle] = []
        for line in lines where line.isInService {
            for index in 0..<2 {
                let progress = (Double(index) * 0.42) + Double(abs(line.number.hashValue % 7)) * 0.03
                let polyline = Self.polyline(for: line)
                let sample = PolylineSampler.point(on: polyline, progress: progress.truncatingRemainder(dividingBy: 1))
                result.append(
                    BusVehicle(
                        id: "veh-\(line.number)-\(index + 1)",
                        lineID: line.id,
                        tripID: "trip-\(line.number)-\(index + 1)",
                        coordinate: sample.coordinate,
                        heading: sample.heading,
                        speedKmh: 20,
                        lastUpdate: now,
                        routeProgress: progress.truncatingRemainder(dividingBy: 1),
                        isDemoData: true
                    )
                )
            }
        }
        return result
    }

    static func routes(vehicles: [BusVehicle]) -> [LineRoute] {
        lines.map { line in
            let routeStops = line.stopIDs.compactMap(stop(id:))
            return LineRoute(
                line: line,
                stops: routeStops,
                polyline: polyline(for: line),
                vehicles: vehicles.filter { $0.lineID == line.id },
                isDemoData: true
            )
        }
    }
}
