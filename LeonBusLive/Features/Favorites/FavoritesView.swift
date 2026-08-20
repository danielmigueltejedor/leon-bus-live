import SwiftUI

@MainActor
@Observable
final class FavoritesViewModel {
    struct StopSection: Identifiable {
        var id: String { favorite.id }
        let favorite: FavoriteItem
        let stop: BusStop
        var arrivals: [BusArrival]
    }

    var stopSections: [StopSection] = []
    var favoriteLines: [BusLine] = []
    var now: Date = .now
    var errorMessage: String?

    private var refreshTask: Task<Void, Never>?

    func start(appModel: AppModel) {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                await refresh(appModel: appModel)
                try? await Task.sleep(nanoseconds: 6_000_000_000)
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refresh(appModel: AppModel) async {
        var sections: [StopSection] = []
        for favorite in appModel.favoritesStore.stopFavorites {
            let resolvedStop: BusStop?
            if let cached = appModel.stop(for: favorite.referenceID) {
                resolvedStop = cached
            } else {
                resolvedStop = try? await appModel.provider.stop(id: favorite.referenceID)
            }
            guard let stop = resolvedStop else { continue }
            let arrivals = (try? await appModel.provider.arrivals(for: stop.id)) ?? []
            sections.append(StopSection(favorite: favorite, stop: stop, arrivals: Array(arrivals.prefix(3))))
        }

        let lines = appModel.favoritesStore.lineFavorites.compactMap { favorite in
            appModel.line(for: favorite.referenceID)
        }

        withAnimation(.snappy) {
            stopSections = sections
            favoriteLines = lines
            now = .now
        }
    }
}

struct FavoritesView: View {
    @Environment(AppModel.self) private var appModel
    @State private var model = FavoritesViewModel()

    var body: some View {
        List {
            if model.stopSections.isEmpty && model.favoriteLines.isEmpty {
                EmptyStateView(
                    title: "Sin favoritos",
                    systemImage: "star",
                    message: "Guarda paradas o líneas desde su ficha de detalle."
                )
                .listRowBackground(Color.clear)
            }

            if !model.stopSections.isEmpty {
                Section("Paradas") {
                    ForEach(model.stopSections) { section in
                        NavigationLink(value: AppRoute.stop(section.stop.id)) {
                            VStack(alignment: .leading, spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    if let alias = section.favorite.alias {
                                        Text(alias.uppercased())
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(section.stop.name)
                                        .font(.headline)
                                }

                                ForEach(section.arrivals) { arrival in
                                    ArrivalRow(
                                        arrival: arrival,
                                        line: appModel.line(for: arrival.lineID),
                                        now: model.now
                                    )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

            if !model.favoriteLines.isEmpty {
                Section("Líneas") {
                    ForEach(model.favoriteLines) { line in
                        NavigationLink(value: AppRoute.line(line.id)) {
                            HStack(spacing: 12) {
                                LineBadge(line: line)
                                VStack(alignment: .leading) {
                                    Text(line.displayTitle)
                                    Text(line.routeSummary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Favoritos")
        .onAppear { model.start(appModel: appModel) }
        .onDisappear { model.stop() }
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
    }
    .environment(AppModel())
}
