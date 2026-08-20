import MapKit
import SwiftUI

@MainActor
@Observable
final class LineDetailViewModel {
    let lineID: String
    var route: LineRoute?
    var errorMessage: String?
    var isLoading = false

    private var refreshTask: Task<Void, Never>?

    init(lineID: String) {
        self.lineID = lineID
    }

    func start(appModel: AppModel) {
        refreshTask?.cancel()
        refreshTask = Task {
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
        isLoading = route == nil
        do {
            let route = try await appModel.provider.route(for: lineID)
            withAnimation(.snappy) {
                self.route = route
                self.errorMessage = nil
            }
        } catch let error as TransitError where error == .lineOutOfService {
            // Still show static line info when out of service.
            if let line = appModel.line(for: lineID) {
                route = LineRoute(
                    line: line,
                    stops: line.stopIDs.compactMap { appModel.stop(for: $0) },
                    polyline: LeonDemoCatalog.polyline(for: line),
                    vehicles: [],
                    isDemoData: line.isDemoData
                )
            }
            errorMessage = error.errorDescription
        } catch {
            errorMessage = (error as? TransitError)?.errorDescription ?? "No se pudo cargar el recorrido."
        }
        isLoading = false
    }
}

struct LineDetailView: View {
    @Environment(AppModel.self) private var appModel
    @State private var model: LineDetailViewModel

    init(lineID: String) {
        _model = State(initialValue: LineDetailViewModel(lineID: lineID))
    }

    var body: some View {
        Group {
            if let route = model.route {
                content(route)
            } else if model.isLoading {
                ProgressView("Cargando línea…")
            } else if let errorMessage = model.errorMessage {
                EmptyStateView(title: "Línea no disponible", systemImage: "bus", message: errorMessage)
            }
        }
        .navigationTitle(model.route.map { "Línea \($0.line.number)" } ?? "Línea")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteButton(isFavorite: appModel.favoritesStore.isFavorite(lineID: model.lineID)) {
                    appModel.favoritesStore.toggleLine(model.lineID)
                }
            }
        }
        .onAppear { model.start(appModel: appModel) }
        .onDisappear { model.stop() }
    }

    @ViewBuilder
    private func content(_ route: LineRoute) -> some View {
        List {
            Section {
                HStack(spacing: 14) {
                    LineBadge(line: route.line)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(route.line.name)
                            .font(.headline)
                        Text(route.line.routeSummary)
                            .foregroundStyle(.secondary)
                        Text(route.line.isInService
                             ? "Frecuencia aprox. cada \(route.line.frequencyMinutes) min"
                             : "Fuera de servicio")
                            .font(.caption)
                            .foregroundStyle(route.line.isInService ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.orange))
                    }
                }
                if route.isDemoData {
                    DemoBanner()
                }
                if let errorMessage = model.errorMessage {
                    ErrorBanner(message: errorMessage)
                }
            }

            Section("Mapa del recorrido") {
                LineRouteMap(route: route)
                    .frame(height: 220)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }

            Section("Paradas") {
                ForEach(Array(route.stops.enumerated()), id: \.element.id) { index, stop in
                    VStack(alignment: .leading, spacing: 8) {
                        NavigationLink(value: AppRoute.stop(stop.id)) {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(spacing: 0) {
                                    Circle()
                                        .fill(route.line.color)
                                        .frame(width: 12, height: 12)
                                    if index < route.stops.count - 1 {
                                        Rectangle()
                                            .fill(route.line.color.opacity(0.35))
                                            .frame(width: 2, height: 28)
                                    }
                                }
                                .padding(.top, 4)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stop.name)
                                        .font(.body.weight(.medium))
                                    Text(stop.code)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        ForEach(vehiclesBetween(index: index, route: route)) { vehicle in
                            HStack(spacing: 8) {
                                Image(systemName: "bus.fill")
                                    .foregroundStyle(route.line.color)
                                Text("Bus en ruta · \(Int(vehicle.speedKmh)) km/h")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.leading, 24)
                            .accessibilityLabel("Autobús entre paradas, \(Int(vehicle.speedKmh)) kilómetros por hora")
                        }
                    }
                }
            }
        }
    }

    private func vehiclesBetween(index: Int, route: LineRoute) -> [BusVehicle] {
        guard route.stops.count > 1 else { return [] }
        let lower = Double(index) / Double(route.stops.count - 1)
        let upper = Double(index + 1) / Double(route.stops.count - 1)
        return route.vehicles.filter { $0.routeProgress >= lower && $0.routeProgress < upper }
    }
}

private struct LineRouteMap: View {
    let route: LineRoute

    var body: some View {
        Map {
            if route.polyline.count >= 2 {
                MapPolyline(coordinates: route.polyline.map(\.clLocationCoordinate2D))
                    .stroke(route.line.color, lineWidth: 4)
            }
            ForEach(route.stops) { stop in
                Annotation(stop.name, coordinate: stop.coordinate.clLocationCoordinate2D) {
                    Circle()
                        .fill(route.line.color)
                        .frame(width: 10, height: 10)
                        .accessibilityLabel(stop.name)
                }
            }
            ForEach(route.vehicles) { vehicle in
                BusMarker(vehicle: vehicle, line: route.line)
            }
        }
        .mapStyle(.standard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        LineDetailView(lineID: "line-1")
    }
    .environment(AppModel())
}
