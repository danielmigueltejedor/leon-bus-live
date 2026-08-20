import SwiftUI

@MainActor
@Observable
final class SearchViewModel {
    var query = ""
    var results: SearchResults = .empty
    var isSearching = false
    var errorMessage: String?

    private var task: Task<Void, Never>?

    func updateQuery(_ value: String, appModel: AppModel) {
        query = value
        task?.cancel()
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = .empty
            isSearching = false
            return
        }
        isSearching = true
        task = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            do {
                let found = try await appModel.provider.search(query: trimmed)
                results = found
                errorMessage = nil
            } catch {
                errorMessage = (error as? TransitError)?.errorDescription ?? "No se pudo buscar."
            }
            isSearching = false
        }
    }
}

struct SearchView: View {
    @Environment(AppModel.self) private var appModel
    @State private var model = SearchViewModel()

    var body: some View {
        List {
            if let errorMessage = model.errorMessage {
                ErrorBanner(message: errorMessage)
                    .listRowBackground(Color.clear)
            }

            if model.query.isEmpty {
                Section {
                    Text("Prueba con “Santo Domingo”, “Universidad”, “Línea 4” o “Hospital”.")
                        .foregroundStyle(.secondary)
                }
            } else if model.isSearching {
                ProgressView("Buscando…")
            } else if model.results.isEmpty {
                EmptyStateView(title: "Sin resultados", systemImage: "magnifyingglass")
                    .listRowBackground(Color.clear)
            } else {
                if !model.results.lines.isEmpty {
                    Section("Líneas") {
                        ForEach(model.results.lines) { line in
                            NavigationLink(value: AppRoute.line(line.id)) {
                                HStack {
                                    LineBadge(line: line, compact: true)
                                    Text(line.displayTitle)
                                    Spacer()
                                    Text(line.name)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                if !model.results.stops.isEmpty {
                    Section("Paradas") {
                        ForEach(model.results.stops) { stop in
                            NavigationLink(value: AppRoute.stop(stop.id)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stop.name)
                                    Text(stop.address)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                if !model.results.destinations.isEmpty {
                    Section("Destinos") {
                        ForEach(model.results.destinations) { destination in
                            if let lineID = destination.lineID {
                                NavigationLink(value: AppRoute.line(lineID)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(destination.title)
                                        Text(destination.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            } else if let stopID = destination.stopID {
                                NavigationLink(value: AppRoute.stop(stopID)) {
                                    Text(destination.title)
                                }
                            } else {
                                Text(destination.title)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Buscar")
        .searchable(text: Binding(
            get: { model.query },
            set: { model.updateQuery($0, appModel: appModel) }
        ), prompt: "Líneas, paradas o destinos")
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
    .environment(AppModel())
}
