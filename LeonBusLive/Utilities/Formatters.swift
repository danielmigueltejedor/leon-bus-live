import CoreLocation
import Foundation

enum DistanceFormatter {
    static func walkingLabel(meters: Double, unit: DistanceUnitPreference = .meters) -> String {
        switch unit {
        case .meters:
            if meters < 1000 {
                return "\(Int(meters.rounded())) m"
            }
            return String(format: "%.1f km", meters / 1000)
        case .kilometers:
            if meters < 1000 {
                return String(format: "%.2f km", meters / 1000)
            }
            return String(format: "%.1f km", meters / 1000)
        }
    }

    static func approximateWalkingMinutes(meters: Double, walkingSpeedMps: Double = 1.4) -> Int {
        max(1, Int(ceil(meters / walkingSpeedMps / 60)))
    }
}

enum ArrivalSorter {
    static func sorted(_ arrivals: [BusArrival], at date: Date = .now) -> [BusArrival] {
        arrivals.sorted { lhs, rhs in
            let l = lhs.effectiveArrival
            let r = rhs.effectiveArrival
            if l != r { return l < r }
            return lhs.id < rhs.id
        }
    }

    static func next(from arrivals: [BusArrival], at date: Date = .now) -> BusArrival? {
        sorted(arrivals, at: date).first
    }
}

enum PolylineSampler {
    struct Sample: Sendable {
        var coordinate: Coordinates
        var heading: Double
    }

    static func densify(_ points: [Coordinates], segmentsPerLeg: Int) -> [Coordinates] {
        guard points.count >= 2, segmentsPerLeg > 0 else { return points }
        var result: [Coordinates] = []
        for index in 0..<(points.count - 1) {
            let start = points[index]
            let end = points[index + 1]
            for step in 0..<segmentsPerLeg {
                let t = Double(step) / Double(segmentsPerLeg)
                result.append(
                    Coordinates(
                        latitude: start.latitude + (end.latitude - start.latitude) * t,
                        longitude: start.longitude + (end.longitude - start.longitude) * t
                    )
                )
            }
        }
        if let last = points.last {
            result.append(last)
        }
        return result
    }

    static func point(on polyline: [Coordinates], progress: Double) -> Sample {
        guard polyline.count >= 2 else {
            let coordinate = polyline.first ?? .leonCityCenter
            return Sample(coordinate: coordinate, heading: 0)
        }

        let clamped = min(max(progress, 0), 0.999999)
        let total = Double(polyline.count - 1)
        let scaled = clamped * total
        let index = Int(scaled)
        let t = scaled - Double(index)
        let start = polyline[index]
        let end = polyline[min(index + 1, polyline.count - 1)]
        let coordinate = Coordinates(
            latitude: start.latitude + (end.latitude - start.latitude) * t,
            longitude: start.longitude + (end.longitude - start.longitude) * t
        )
        let heading = bearing(from: start, to: end)
        return Sample(coordinate: coordinate, heading: heading)
    }

    static func bearing(from start: Coordinates, to end: Coordinates) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let dLon = (end.longitude - start.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radians = atan2(y, x)
        return (radians * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }
}
