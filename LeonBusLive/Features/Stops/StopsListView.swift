import SwiftUI

@MainActor
@Observable
final class StopsListViewModel {
    var stops: [BusStop] = []
    var query = ""
    var sortByDistance = true
    var selectedLineID: String?
    var nextArrivalByStop: [String: String] = [:]
    var distances: [String: Double] = [:]
    var isLoading = false
    var errorMessage: String?

    func load(appModel: AppModel) async {
        isLoading = stops.isEmpty
        do {
            let all = try await appModel.provider.stops()
            let origin = appModel.locationService.effectiveCoordinate
            var distanceMap: [String: Double] = [:]
            var arrivalMap: [String: String] = [:]

            for stop in all {
                distanceMap[stop.id] = stop.coordinate.distanceMeters(to: origin)
            }

            // Prefetch next arrival for visible set (demo scale is small).
            for stop in all.prefix(20) {
                if let next = try? await appModel.provider.arrivals(for: stop.id).first,
                   let line = appModel.line(for: next.lineID) {
                    arrivalMap[stop.id] = "\(line.number) · \(next.status().shortLabel)"
                }
            }

            stops = all
            distances = distanceMap
            nextArrivalByStop = arrivalMap
            errorMessage = nil
        } catch {
            errorMessage = (error as? TransitError)?.errorDescription ?? "No se pudieron cargar las paradas."
        }
        isLoading = false
    }

    func filtered(linesByID: [String: BusLine]) -> [BusStop] {
        var result = stops
        if let selectedLineID {
            result = result.filter { $0.lineIDs.contains(selectedLineID) }
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let needle = trimmed.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            result = result.filter {
                [$0.name, $0.code, $0.address].joined(separator: " ")
                    .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                    .contains(needle)
            }
        }
        if sortByDistance {
            result.sort { (distances[$0.id] ?? .greatestFiniteMagnitude) < (distances[$1.id] ?? .greatestFiniteMagnitude) }
        } else {
            result.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        _ = linesByID
        return result
    }
}

struct StopsListView: View {
    @Environment(AppModel.self) private var appModel
    @State private var model = StopsListViewModel()

    var body: some View {
        List {
            if let errorMessage = model.errorMessage {
                Section {
                    ErrorBanner(message: errorMessage)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                Toggle("Ordenar por cercanía", isOn: $model.sortByDistance)
                Picker("Línea", selection: $model.selectedLineID) {
                    Text("Todas").tag(Optional<String>.none)
                    ForEach(appModel.linesByID.values.sorted { $0.number.localizedStandardCompare($1.number) == .orderedAscending }) { line in
                        Text("Línea \(line.number)").tag(Optional(line.id))
                    }
                }
            }

            Section {
                ForEach(model.filtered(linesByID: appModel.linesByID)) { stop in
                    NavigationLink(value: AppRoute.stop(stop.id)) {
                        StopCard(
                            stop: stop,
                            lines: stop.lineIDs.compactMap { appModel.line(for: $0) },
                            distanceLabel: model.distances[stop.id].map {
                                DistanceFormatter.walkingLabel(
                                    meters: $0,
                                    unit: appModel.settingsStore.distanceUnit
                                )
                            },
                            nextArrivalLabel: model.nextArrivalByStop[stop.id]
                        )
                    }
                }
            }
        }
        .navigationTitle("Paradas")
        .searchable(text: $model.query, prompt: "Buscar parada")
        .overlay {
            if model.isLoading {
                ProgressView()
            } else if model.filtered(linesByID: appModel.linesByID).isEmpty {
                EmptyStateView(title: "Sin resultados", systemImage: "magnifyingglass")
            }
        }
        .task {
            appModel.locationService.requestWhenInUseIfNeeded()
            await model.load(appModel: appModel)
        }
        .refreshable {
            await model.load(appModel: appModel)
        }
    }
}

#Preview {
    NavigationStack {
        StopsListView()
    }
    .environment(AppModel())
}
