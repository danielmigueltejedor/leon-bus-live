import SwiftUI

struct RootTabView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedTab: AppTab = .nearby
    @State private var showSettings = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Cerca de mí", systemImage: "location.fill", value: .nearby) {
                NavigationStack {
                    NearbyView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destination(for: route)
                        }
                }
            }

            Tab("Paradas", systemImage: "bus.fill", value: .stops) {
                NavigationStack {
                    StopsListView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destination(for: route)
                        }
                        .toolbar { settingsButton }
                }
            }

            Tab("Líneas", systemImage: "point.topleft.down.to.point.bottomright.curvepath.fill", value: .lines) {
                NavigationStack {
                    LinesListView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destination(for: route)
                        }
                        .toolbar { settingsButton }
                }
            }

            Tab("Favoritos", systemImage: "star.fill", value: .favorites) {
                NavigationStack {
                    FavoritesView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destination(for: route)
                        }
                        .toolbar { settingsButton }
                }
            }

            Tab(value: .search, role: .search) {
                NavigationStack {
                    SearchView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destination(for: route)
                        }
                }
            } label: {
                Label("Buscar", systemImage: "magnifyingglass")
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
            }
            .environment(appModel)
        }
        .overlay {
            if appModel.isBootstrapping {
                LoadingView(message: "Preparando León Bus Live…")
            }
        }
    }

    @ToolbarContentBuilder
    private var settingsButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Ajustes")
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .stop(let id):
            StopDetailView(stopID: id)
        case .line(let id):
            LineDetailView(lineID: id)
        case .stopMap(let id):
            StopMapView(stopID: id)
        }
    }
}

enum AppTab: Hashable {
    case nearby
    case stops
    case lines
    case favorites
    case search
}

#Preview("Root") {
    RootTabView()
        .environment(AppModel())
}
