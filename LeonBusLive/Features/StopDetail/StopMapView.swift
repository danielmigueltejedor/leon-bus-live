import MapKit
import SwiftUI

struct StopMapView: View {
    @Environment(AppModel.self) private var appModel
    let stopID: String

    var body: some View {
        Group {
            if let stop = appModel.stop(for: stopID) ?? LeonDemoCatalog.stop(id: stopID) {
                Map(initialPosition: .region(
                    MKCoordinateRegion(
                        center: stop.coordinate.clLocationCoordinate2D,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )) {
                    Marker(stop.name, coordinate: stop.coordinate.clLocationCoordinate2D)
                        .tint(Color.accentColor)
                    if appModel.locationService.hasUserLocation,
                       let user = appModel.locationService.coordinate {
                        Marker("Tú", coordinate: user.clLocationCoordinate2D)
                            .tint(Color.blue)
                    }
                }
                .navigationTitle(stop.name)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                EmptyStateView(title: "Mapa no disponible", systemImage: "map")
            }
        }
    }
}

#Preview {
    NavigationStack {
        StopMapView(stopID: "stop-sd")
    }
    .environment(AppModel())
}
