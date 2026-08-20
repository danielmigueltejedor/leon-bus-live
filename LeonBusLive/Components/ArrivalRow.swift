import SwiftUI

struct ArrivalRow: View {
    let arrival: BusArrival
    let line: BusLine?
    var now: Date = .now

    private var status: ArrivalStatus {
        arrival.status(at: now)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            if let line {
                LineBadge(line: line)
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.quaternary)
                    .frame(width: 34, height: 34)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(arrival.destination)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                HStack(spacing: 8) {
                    RealtimeStatusBadge(quality: arrival.dataQuality)
                    Text(arrival.effectiveArrival, style: .time)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }

            Spacer(minLength: 8)

            Text(status.shortLabel)
                .font(.title3.weight(.semibold))
                .foregroundStyle(emphasisColor)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var emphasisColor: Color {
        switch status {
        case .atStop, .arriving, .lessThanOneMinute:
            return .primary
        case .delayed:
            return .orange
        default:
            return .primary
        }
    }

    private var accessibilityText: String {
        let lineText = line.map { "Línea \($0.number)" } ?? "Línea"
        return "\(lineText), destino \(arrival.destination), \(status.accessibilityLabel), \(arrival.dataQuality.title)"
    }
}

#Preview {
    let line = LeonDemoCatalog.lines[0]
    let arrival = BusArrival(
        id: "p1",
        stopID: "stop-sd",
        lineID: line.id,
        vehicleID: nil,
        destination: line.destination,
        scheduledArrival: .now.addingTimeInterval(120),
        predictedArrival: .now.addingTimeInterval(110),
        isRealtime: true,
        delaySeconds: 0,
        isDemoData: true
    )
    ArrivalRow(arrival: arrival, line: line)
        .padding()
}
