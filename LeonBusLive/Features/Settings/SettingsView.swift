import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = appModel.settingsStore

        Form {
            Section("Ubicación") {
                LabeledContent("Estado") {
                    Text(locationStatusText)
                        .foregroundStyle(.secondary)
                }
                Button("Solicitar permiso de ubicación") {
                    appModel.locationService.requestWhenInUseIfNeeded()
                }
                Toggle("Reducir precisión pedida", isOn: $settings.reduceLocationPrecision)
                Toggle("Actualización en segundo plano", isOn: $settings.backgroundRefreshEnabled)
                Text("La actualización en segundo plano solo aplica si el sistema y el proveedor lo permiten.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Preferencias") {
                Picker("Apariencia", selection: $settings.appearance) {
                    ForEach(AppearancePreference.allCases) { preference in
                        Text(preference.title).tag(preference)
                    }
                }
                Picker("Unidades", selection: $settings.distanceUnit) {
                    ForEach(DistanceUnitPreference.allCases) { unit in
                        Text(unit.title).tag(unit)
                    }
                }
            }

            Section("Fuente de datos") {
                Picker("Proveedor", selection: $settings.providerKind) {
                    ForEach(DataProviderKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .onChange(of: settings.providerKind) { _, _ in
                    Task { await appModel.applyProviderChange() }
                }
                Text(settings.providerKind.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if appModel.provider.isDemoProvider {
                    DemoBanner()
                }
            }

            Section("Información sobre datos") {
                Text("León Bus Live está preparado para REST, GTFS y GTFS-Realtime. Mientras no haya API oficial confirmada, la app usa un proveedor mock claramente marcado como demostración.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Privacidad") {
                Text("La ubicación se usa solo en el dispositivo para calcular distancias y paradas cercanas. Los favoritos se guardan localmente con UserDefaults.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Acerca de") {
                LabeledContent("App", value: "León Bus Live")
                LabeledContent("Versión", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                LabeledContent("Proveedor activo", value: appModel.provider.providerName)
            }
        }
        .navigationTitle("Ajustes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Listo") { dismiss() }
            }
        }
    }

    private var locationStatusText: String {
        switch appModel.locationService.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return "Permitida"
        case .denied, .restricted: return "Denegada"
        case .notDetermined: return "Sin decidir"
        @unknown default: return "Desconocido"
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppModel())
}
