import Foundation

/// User-facing arrival state. Distinct from raw delay math.
enum ArrivalStatus: Hashable, Sendable {
    case atStop
    case arriving
    case lessThanOneMinute
    case minutes(Int)
    case delayed(minutes: Int)
    case noRealtime
    case scheduledOnly

    var accessibilityLabel: String {
        switch self {
        case .atStop: return "En parada"
        case .arriving: return "Llegando"
        case .lessThanOneMinute: return "Menos de un minuto"
        case .minutes(let value): return "\(value) minutos"
        case .delayed(let minutes): return "Retrasado \(minutes) minutos"
        case .noRealtime: return "Sin datos en tiempo real"
        case .scheduledOnly: return "Según horario"
        }
    }

    var shortLabel: String {
        switch self {
        case .atStop: return "En parada"
        case .arriving: return "Llegando"
        case .lessThanOneMinute: return "< 1 min"
        case .minutes(let value): return "\(value) min"
        case .delayed(let minutes): return "+\(minutes) min"
        case .noRealtime: return "Sin datos"
        case .scheduledOnly: return "Horario"
        }
    }

    /// Resolves display status from timing metadata.
    static func resolved(
        effectiveArrival: Date,
        isRealtime: Bool,
        delaySeconds: Int?,
        at referenceDate: Date
    ) -> ArrivalStatus {
        let remaining = effectiveArrival.timeIntervalSince(referenceDate)

        if !isRealtime {
            if remaining <= 0 {
                return .scheduledOnly
            }
            let minutes = max(1, Int(ceil(remaining / 60.0)))
            return minutes <= 1 ? .scheduledOnly : .minutes(minutes)
        }

        if let delay = delaySeconds, delay >= 120 {
            let delayMinutes = Int(ceil(Double(delay) / 60.0))
            if remaining > 45 {
                return .delayed(minutes: delayMinutes)
            }
        }

        if remaining <= 8 {
            return .atStop
        }
        if remaining <= 45 {
            return .arriving
        }
        if remaining < 60 {
            return .lessThanOneMinute
        }

        let minutes = Int(ceil(remaining / 60.0))
        return .minutes(minutes)
    }
}

enum ArrivalDataQuality: Hashable, Sendable {
    case realtime
    case estimated
    case scheduled

    var title: String {
        switch self {
        case .realtime: return "Tiempo real"
        case .estimated: return "Estimación"
        case .scheduled: return "Horario programado"
        }
    }
}

extension BusArrival {
    var dataQuality: ArrivalDataQuality {
        if isRealtime { return .realtime }
        if predictedArrival != nil { return .estimated }
        return .scheduled
    }
}
