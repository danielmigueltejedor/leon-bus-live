import SwiftUI

@MainActor
@Observable
final class StopDetailViewModel {
    let stopID: String
    var stop: BusStop?
    var arrivals: [BusArrival] = []
    var distanceMeters: Double?
    var now: Date = .now
    var isLoading = false
    var errorMessage: String?
    var showAliasDialog = false
    var aliasDraft = ""

    private var refreshTask: Task<Void, Never>?

    init(stopID: String) {
        self.stopID = stopID
    }

    func start(appModel: AppModel) {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                await refresh(appModel: appModel)
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }

    func stopRefreshing() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refresh(appModel: AppModel) async {
        isLoading = stop == nil
        do {
            let stop = try await appModel.provider.stop(id: stopID)
            let arrivals = try await appModel.provider.arrivals(for: stopID)
            let distance = stop.coordinate.distanceMeters(to: appModel.locationService.effectiveCoordinate)
            withAnimation(.snappy) {
                self.stop = stop
                self.arrivals = arrivals
                self.distanceMeters = distance
                self.now = .now
                self.errorMessage = nil
            }
        } catch {
            errorMessage = (error as? TransitError)?.errorDescription ?? "No se pudo cargar la parada."
        }
        isLoading = false
    }
}

struct StopDetailView: View {
    @Environment(AppModel.self) private var appModel
    @State private var model: StopDetailViewModel

    init(stopID: String) {
        _model = State(initialValue: StopDetailViewModel(stopID: stopID))
    }

    var body: some View {
        Group {
            if let stop = model.stop {
                content(stop)
            } else if model.isLoading {
                ProgressView("Cargando parada…")
            } else if let errorMessage = model.errorMessage {
                EmptyStateView(title: "Parada no disponible", systemImage: "bus", message: errorMessage)
            }
        }
        .navigationTitle(model.stop?.name ?? "Parada")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteButton(isFavorite: appModel.favoritesStore.isFavorite(stopID: model.stopID)) {
                    if appModel.favoritesStore.isFavorite(stopID: model.stopID) {
                        appModel.favoritesStore.toggleStop(model.stopID)
                    } else {
                        model.aliasDraft = appModel.favoritesStore.alias(forStopID: model.stopID) ?? ""
                        model.showAliasDialog = true
                    }
                }
            }
        }
        .alert("Alias de la parada", isPresented: $model.showAliasDialog) {
            TextField("Casa, Trabajo…", text: $model.aliasDraft)
            Button("Guardar") {
                appModel.favoritesStore.toggleStop(
                    model.stopID,
                    alias: model.aliasDraft.isEmpty ? nil : model.aliasDraft
                )
            }
            Button("Sin alias") {
                appModel.favoritesStore.toggleStop(model.stopID)
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Puedes poner un nombre como Casa o Trabajo.")
        }
        .onAppear { model.start(appModel: appModel) }
        .onDisappear { model.stopRefreshing() }
    }

    @ViewBuilder
    private func content(_ stop: BusStop) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(stop.name)
                        .font(.title2.weight(.semibold))
                    LabeledContent("Código", value: stop.code)
                    Text(stop.address)
                        .foregroundStyle(.secondary)
                    if let distanceMeters = model.distanceMeters {
                        Text(DistanceFormatter.walkingLabel(
                            meters: distanceMeters,
                            unit: appModel.settingsStore.distanceUnit
                        ))
                        .foregroundStyle(.secondary)
                    }
                    if stop.isDemoData {
                        DemoBanner()
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Próximas llegadas") {
                if let errorMessage = model.errorMessage {
                    ErrorBanner(message: errorMessage)
                }
                if model.arrivals.isEmpty {
                    Text("No hay llegadas disponibles")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.arrivals) { arrival in
                        ArrivalRow(
                            arrival: arrival,
                            line: appModel.line(for: arrival.lineID),
                            now: model.now
                        )
                    }
                }
            }

            Section("Acciones") {
                NavigationLink(value: AppRoute.stopMap(stop.id)) {
                    Label("Ver en el mapa", systemImage: "map")
                }
                ForEach(stop.lineIDs.compactMap { appModel.line(for: $0) }) { line in
                    NavigationLink(value: AppRoute.line(line.id)) {
                        Label("Recorrido línea \(line.number)", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        StopDetailView(stopID: "stop-sd")
    }
    .environment(AppModel())
}
