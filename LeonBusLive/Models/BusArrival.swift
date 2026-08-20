import Foundation

/// Predicted or scheduled arrival at a stop.
struct BusArrival: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let stopID: String
    let lineID: String
    let vehicleID: String?
    let destination: String
    let scheduledArrival: Date
    let predictedArrival: Date?
    let isRealtime: Bool
    /// Delay in seconds; positive means late.
    let delaySeconds: Int?
    let isDemoData: Bool

    var effectiveArrival: Date {
        predictedArrival ?? scheduledArrival
    }

    func status(at referenceDate: Date = .now) -> ArrivalStatus {
        ArrivalStatus.resolved(
            effectiveArrival: effectiveArrival,
            isRealtime: isRealtime,
            delaySeconds: delaySeconds,
            at: referenceDate
        )
    }

    func minutesRemaining(at referenceDate: Date = .now) -> Int {
        let seconds = effectiveArrival.timeIntervalSince(referenceDate)
        return max(0, Int(ceil(seconds / 60.0)))
    }
}
