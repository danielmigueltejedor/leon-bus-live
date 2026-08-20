import MapKit
import SwiftUI

struct BusMarker: MapContent {
    let vehicle: BusVehicle
    let line: BusLine?

    var body: some MapContent {
        Annotation("", coordinate: vehicle.coordinate.clLocationCoordinate2D, anchor: .center) {
            ZStack {
                Circle()
                    .fill((line?.color ?? .accentColor).opacity(0.25))
                    .frame(width: 34, height: 34)
                Image(systemName: "bus.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(line?.color ?? .accentColor, in: Circle())
            }
            .rotationEffect(.degrees(vehicle.heading))
            .accessibilityLabel(line.map { "Autobús línea \($0.number)" } ?? "Autobús")
        }
    }
}

struct StopMapMarker: MapContent {
    let stop: BusStop
    var isSelected: Bool = false

    var body: some MapContent {
        Annotation(stop.name, coordinate: stop.coordinate.clLocationCoordinate2D, anchor: .bottom) {
            Image(systemName: isSelected ? "bus.doubledecker.fill" : "bus.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(10)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.9), in: Circle())
                .leonGlassInteractive(Circle())
                .accessibilityLabel("Parada \(stop.name)")
        }
    }
}
