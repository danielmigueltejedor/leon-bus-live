import SwiftUI

@main
struct LeonBusLiveApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(appModel)
                .preferredColorScheme(appModel.settingsStore.appearance.colorScheme)
                .task {
                    await appModel.bootstrap()
                }
        }
    }
}
