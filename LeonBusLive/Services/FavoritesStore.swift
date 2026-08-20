import Foundation
import Observation

@MainActor
@Observable
final class FavoritesStore {
    private(set) var items: [FavoriteItem] = []

    private let defaults: UserDefaults
    private let storageKey = "leonbus.favorites.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    var stopFavorites: [FavoriteItem] {
        items.filter { $0.kind == .stop }.sorted { $0.sortIndex < $1.sortIndex }
    }

    var lineFavorites: [FavoriteItem] {
        items.filter { $0.kind == .line }.sorted { $0.sortIndex < $1.sortIndex }
    }

    func isFavorite(stopID: String) -> Bool {
        items.contains { $0.kind == .stop && $0.referenceID == stopID }
    }

    func isFavorite(lineID: String) -> Bool {
        items.contains { $0.kind == .line && $0.referenceID == lineID }
    }

    func alias(forStopID stopID: String) -> String? {
        items.first { $0.kind == .stop && $0.referenceID == stopID }?.alias
    }

    func toggleStop(_ stopID: String, alias: String? = nil) {
        if let index = items.firstIndex(where: { $0.kind == .stop && $0.referenceID == stopID }) {
            items.remove(at: index)
        } else {
            let nextIndex = (stopFavorites.map(\.sortIndex).max() ?? -1) + 1
            items.append(.stop(stopID, alias: alias, sortIndex: nextIndex))
        }
        persist()
    }

    func toggleLine(_ lineID: String) {
        if let index = items.firstIndex(where: { $0.kind == .line && $0.referenceID == lineID }) {
            items.remove(at: index)
        } else {
            let nextIndex = (lineFavorites.map(\.sortIndex).max() ?? -1) + 1
            items.append(.line(lineID, sortIndex: nextIndex))
        }
        persist()
    }

    func setAlias(forStopID stopID: String, alias: String?) {
        guard let index = items.firstIndex(where: { $0.kind == .stop && $0.referenceID == stopID }) else {
            toggleStop(stopID, alias: alias)
            return
        }
        let trimmed = alias?.trimmingCharacters(in: .whitespacesAndNewlines)
        items[index].alias = (trimmed?.isEmpty == false) ? trimmed : nil
        persist()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else {
            // Sensible demo defaults on first launch.
            items = [
                .stop("stop-uni", alias: "Universidad", sortIndex: 0),
                .stop("stop-sd", alias: "Centro", sortIndex: 1),
                .line("line-1", sortIndex: 0)
            ]
            persist()
            return
        }
        do {
            items = try JSONDecoder().decode([FavoriteItem].self, from: data)
        } catch {
            items = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(items)
            defaults.set(data, forKey: storageKey)
        } catch {
            // Persistence failure should not crash; favorites remain in memory.
        }
    }
}
