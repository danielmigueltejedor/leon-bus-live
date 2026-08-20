import Foundation

/// Selects the active transit backend without views knowing concrete types.
enum DataProviderKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case mock
    case api

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mock: return "Datos de demostración"
        case .api: return "API remota"
        }
    }

    var detail: String {
        switch self {
        case .mock: return "Simulación local basada en León. No es información oficial."
        case .api: return "URLSession hacia un endpoint REST configurable."
        }
    }
}

enum TransitProviderFactory {
    static func make(
        kind: DataProviderKind,
        configuration: APITransitConfiguration = .default,
        realtimeEngine: MockRealtimeEngine
    ) -> any TransitDataProvider {
        switch kind {
        case .mock:
            return MockTransitDataProvider(realtimeEngine: realtimeEngine)
        case .api:
            return APITransitDataProvider(configuration: configuration)
        }
    }
}
