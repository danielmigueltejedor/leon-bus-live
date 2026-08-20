import Foundation
import Observation
import SwiftUI

enum AppearancePreference: String, CaseIterable, Identifiable, Codable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Sistema"
        case .light: return "Claro"
        case .dark: return "Oscuro"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum DistanceUnitPreference: String, CaseIterable, Identifiable, Codable, Sendable {
    case meters
    case kilometers

    var id: String { rawValue }

    var title: String {
        switch self {
        case .meters: return "Metros"
        case .kilometers: return "Kilómetros"
        }
    }
}

@MainActor
@Observable
final class SettingsStore {
    var appearance: AppearancePreference {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    var distanceUnit: DistanceUnitPreference {
        didSet { defaults.set(distanceUnit.rawValue, forKey: Keys.distanceUnit) }
    }

    var providerKind: DataProviderKind {
        didSet { defaults.set(providerKind.rawValue, forKey: Keys.provider) }
    }

    var backgroundRefreshEnabled: Bool {
        didSet { defaults.set(backgroundRefreshEnabled, forKey: Keys.background) }
    }

    var reduceLocationPrecision: Bool {
        didSet { defaults.set(reduceLocationPrecision, forKey: Keys.reducePrecision) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let appearance = "leonbus.settings.appearance"
        static let distanceUnit = "leonbus.settings.distanceUnit"
        static let provider = "leonbus.settings.provider"
        static let background = "leonbus.settings.background"
        static let reducePrecision = "leonbus.settings.reducePrecision"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        appearance = AppearancePreference(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        distanceUnit = DistanceUnitPreference(rawValue: defaults.string(forKey: Keys.distanceUnit) ?? "") ?? .meters
        providerKind = DataProviderKind(rawValue: defaults.string(forKey: Keys.provider) ?? "") ?? .mock
        backgroundRefreshEnabled = defaults.object(forKey: Keys.background) as? Bool ?? false
        reduceLocationPrecision = defaults.object(forKey: Keys.reducePrecision) as? Bool ?? false
    }
}
