import MapKit
import SwiftUI

@MainActor
@Observable
final class NearbyViewModel {
    var nearbyStops: [NearbyStop] = []
    var vehicles: [BusVehicle] = []
    var selectedStopID: String?
    var isLoading = false
    var errorMessage: String?
    var now: Date = .now

    private var refreshTask: Task<Void, Never>?

    func start(appModel: AppModel) {
        refreshTask?.cancel()
        refreshTask = Task {
            appModel.locationService.requestWhenInUseIfNeeded()
            while !Task.isCancelled {
                await refresh(appModel: appModel)
                try? await Task.sleep(nanoseconds: 7_000_000_000)
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refresh(appModel: AppModel) async {
        let coordinate = appModel.locationService.effectiveCoordinate
        isLoading = nearbyStops.isEmpty
        do {
            async let nearby = appModel.provider.nearbyStops(around: coordinate, radiusMeters: 1500, limit: 8)
            async let fleet = appModel.provider.vehicles(for: nil)
            let (stops, buses) = try await (nearby, fleet)
            withAnimation(.snappy) {
                nearbyStops = stops
                vehicles = buses
                now = .now
                errorMessage = appModel.locationService.permissionDenied
                    ? "Ubicación no disponible. Mostrando el centro de León."
                    : nil
            }
        } catch {
            errorMessage = (error as? TransitError)?.errorDescription ?? "No se pudieron cargar las paradas cercanas."
        }
        isLoading = false
    }
}

struct NearbyView: View {
    @Environment(AppModel.self) private var appModel
    @State private var model = NearbyViewModel()
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: Coordinates.leonCityCenter.clLocationCoordinate2D,
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        )
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                mapSection
                if let errorMessage = model.errorMessage {
                    ErrorBanner(message: errorMessage)
                }
                nearbyList
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .navigationTitle("León Bus")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Ajustes")
            }
        }
        .onAppear { model.start(appModel: appModel) }
        .onDisappear { model.stop() }
        .onChange(of: appModel.locationService.coordinate?.latitude) { _, _ in
            updateCamera()
        }
        .sheet(item: Binding(
            get: { model.selectedStopID.map { StopSheetItem(id: $0) } },
            set: { model.selectedStopID = $0?.id }
        )) { item in
            NavigationStack {
                StopDetailView(stopID: item.id)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cerrar") { model.selectedStopID = nil }
                        }
                    }
            }
            .environment(appModel)
            .presentationDetents([.medium, .large])
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(locationCaption)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            if appModel.provider.isDemoProvider {
                DemoBanner()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private var mapSection: some View {
        Map(position: $position) {
            if appModel.locationService.hasUserLocation {
                UserAnnotation()
            }
            ForEach(model.nearbyStops) { nearby in
                Annotation(nearby.stop.name, coordinate: nearby.stop.coordinate.clLocationCoordinate2D) {
                    Button {
                        model.selectedStopID = nearby.stop.id
                    } label: {
                        Image(systemName: "bus.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.accentColor, in: Circle())
                    }
                    .accessibilityLabel("Parada \(nearby.stop.name)")
                }
            }
            ForEach(model.vehicles) { vehicle in
                BusMarker(vehicle: vehicle, line: appModel.line(for: vehicle.lineID))
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        }
        .accessibilityLabel("Mapa de paradas cercanas")
    }

    private var nearbyList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Paradas cercanas")
                .font(.title2.weight(.semibold))

            if model.isLoading && model.nearbyStops.isEmpty {
                ProgressView("Buscando paradas…")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if model.nearbyStops.isEmpty {
                EmptyStateView(
                    title: "Sin paradas cercanas",
                    systemImage: "mappin.slash",
                    message: "Prueba a ampliar la zona o revisa el permiso de ubicación."
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                ForEach(Array(model.nearbyStops.enumerated()), id: \.element.id) { index, nearby in
                    NavigationLink(value: AppRoute.stop(nearby.stop.id)) {
                        NearbyStopCard(
                            nearby: nearby,
                            linesByID: appModel.linesByID,
                            isHighlighted: index == 0,
                            now: model.now
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 6..<13: return "Buenos días"
        case 13..<21: return "Buenas tardes"
        default: return "Buenas noches"
        }
    }

    private var locationCaption: String {
        if appModel.locationService.hasUserLocation {
            return "Tu ubicación actual"
        }
        return "Zona inicial: León"
    }

    private func updateCamera() {
        let coordinate = appModel.locationService.effectiveCoordinate.clLocationCoordinate2D
        withAnimation(.smooth) {
            position = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
                )
            )
        }
    }
}

private struct StopSheetItem: Identifiable {
    let id: String
}

#Preview {
    NavigationStack {
        NearbyView()
    }
    .environment(AppModel())
}
