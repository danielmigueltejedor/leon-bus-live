import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class AppModel {
    let locationService: LocationService
    let favoritesStore: FavoritesStore
    let settingsStore: SettingsStore
    let realtimeEngine: MockRealtimeEngine

    private(set) var provider: any TransitDataProvider
    private(set) var linesByID: [String: BusLine] = [:]
    private(set) var stopsByID: [String: BusStop] = [:]
    private(set) var isBootstrapping = true
    private(set) var bootstrapError: String?

    init(
        locationService: LocationService = LocationService(),
        favoritesStore: FavoritesStore = FavoritesStore(),
        settingsStore: SettingsStore = SettingsStore(),
        realtimeEngine: MockRealtimeEngine = MockRealtimeEngine()
    ) {
        self.locationService = locationService
        self.favoritesStore = favoritesStore
        self.settingsStore = settingsStore
        self.realtimeEngine = realtimeEngine
        self.provider = TransitProviderFactory.make(
            kind: settingsStore.providerKind,
            realtimeEngine: realtimeEngine
        )
    }

    func bootstrap() async {
        isBootstrapping = true
        bootstrapError = nil
        recreateProvider()
        if let mock = provider as? MockTransitDataProvider {
            await mock.bootstrapIfNeeded()
        }
        do {
            let lines = try await provider.lines()
            let stops = try await provider.stops()
            linesByID = Dictionary(uniqueKeysWithValues: lines.map { ($0.id, $0) })
            stopsByID = Dictionary(uniqueKeysWithValues: stops.map { ($0.id, $0) })
        } catch {
            bootstrapError = (error as? TransitError)?.errorDescription
                ?? "No se pudieron cargar los datos de demostración."
        }
        isBootstrapping = false
    }

    func applyProviderChange() async {
        await bootstrap()
    }

    func line(for id: String) -> BusLine? {
        linesByID[id]
    }

    func stop(for id: String) -> BusStop? {
        stopsByID[id]
    }

    private func recreateProvider() {
        provider = TransitProviderFactory.make(
            kind: settingsStore.providerKind,
            realtimeEngine: realtimeEngine
        )
    }
}

enum AppRoute: Hashable {
    case stop(String)
    case line(String)
    case stopMap(String)
}

struct DemoBanner: View {
    var body: some View {
        Label("Datos de demostración — no oficiales", systemImage: "info.circle")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("Aviso: los datos mostrados son de demostración y no son oficiales")
    }
}
