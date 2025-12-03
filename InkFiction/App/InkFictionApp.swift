import SwiftUI
import SwiftData

@main
struct InkFictionApp: App {

    // MARK: - State

    @State private var appState = AppState()
    @State private var router = Router()
    @State private var themeManager = ThemeManager()

    // MARK: - SwiftData

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            JournalEntryModel.self,
            JournalImageModel.self,
            PersonaProfileModel.self,
            PersonaAvatarModel.self,
            AppSettingsModel.self
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
                .environment(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .task {
                    await initializeApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    handleAppBackground()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    handleAppForeground()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - App Initialization

    @MainActor
    private func initializeApp() async {
        Log.info("Initializing app...", category: .app)

        // Get the model context from the container
        let context = sharedModelContainer.mainContext

        // Initialize repositories with model context
        JournalRepository.shared.setModelContext(context)
        PersonaRepository.shared.setModelContext(context)
        SettingsRepository.shared.setModelContext(context)

        // Check iCloud account status
        await CloudKitManager.shared.checkAccountStatus()

        // Load sync monitor's last sync date
        SyncMonitor.shared.loadLastSyncDate()

        // Warmup settings
        await SettingsRepository.shared.warmup()

        // Load theme from settings
        await themeManager.loadThemeFromRepository()

        // Load persona if exists
        do {
            try await PersonaRepository.shared.loadPersona()
            appState.hasPersona = PersonaRepository.shared.hasPersona
        } catch {
            Log.error("Failed to load persona", error: error, category: .persona)
        }

        // Update onboarding status
        appState.hasCompletedOnboarding = SettingsRepository.shared.hasCompletedOnboarding

        Log.info("App initialization complete", category: .app)
    }

    // MARK: - App Lifecycle

    private func handleAppBackground() {
        Log.info("App entering background", category: .app)
        appState.isActive = false
        // NOTE: Temporarily disabled auto-lock during development
        // appState.lock()
    }

    private func handleAppForeground() {
        Log.info("App entering foreground", category: .app)
        appState.isActive = true
    }
}
