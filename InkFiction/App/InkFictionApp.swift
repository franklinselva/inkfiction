import SwiftUI
import SwiftData

@main
struct InkFictionApp: App {

    // MARK: - State

    @State private var appState = AppState()
    @State private var router = Router()

    // MARK: - SwiftData

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Models will be added here as we implement them
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.quantumtech.InkFiction")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(router)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    handleAppBackground()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    handleAppForeground()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - App Lifecycle

    private func handleAppBackground() {
        Log.info("App entering background", category: .app)
        appState.isActive = false
        appState.lock()
    }

    private func handleAppForeground() {
        Log.info("App entering foreground", category: .app)
        appState.isActive = true
    }
}
