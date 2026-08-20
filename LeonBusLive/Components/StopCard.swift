import SwiftUI

struct NearbyStopCard: View {
    let nearby: NearbyStop
    let linesByID: [String: BusLine]
    var isHighlighted: Bool = false
    var now: Date = .now

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(nearby.stop.name)
                        .font(.headline)
                    Text(nearby.walkingDistanceLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isHighlighted {
                    Text("Más cercana")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .leonGlassInteractive()
                }
            }

            if nearby.arrivals.isEmpty {
                Text("Sin próximas llegadas")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(nearby.arrivals.prefix(3)) { arrival in
                        ArrivalRow(
                            arrival: arrival,
                            line: linesByID[arrival.lineID],
                            now: now
                        )
                        if arrival.id != nearby.arrivals.prefix(3).last?.id {
                            Divider().opacity(0.35)
                        }
                    }
                }
            }
        }
        .padding(16)
        .leonGlassSurface(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

struct StopCard: View {
    let stop: BusStop
    let lines: [BusLine]
    var distanceLabel: String?
    var nextArrivalLabel: String?

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "bus.fill")
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text(stop.name)
                    .font(.body.weight(.semibold))
                HStack(spacing: 6) {
                    ForEach(lines.prefix(5)) { line in
                        LineBadge(line: line, compact: true)
                    }
                    if lines.count > 5 {
                        Text("+\(lines.count - 5)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let nextArrivalLabel {
                    Text(nextArrivalLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            if let distanceLabel {
                Text(distanceLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [stop.name]
        if !lines.isEmpty {
            parts.append("Líneas " + lines.map(\.number).joined(separator: ", "))
        }
        if let distanceLabel { parts.append(distanceLabel) }
        if let nextArrivalLabel { parts.append(nextArrivalLabel) }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    let stop = LeonDemoCatalog.stops[0]
    NearbyStopCard(
        nearby: NearbyStop(stop: stop, distanceMeters: 120, arrivals: []),
        linesByID: Dictionary(uniqueKeysWithValues: LeonDemoCatalog.lines.map { ($0.id, $0) }),
        isHighlighted: true
    )
    .padding()
}
