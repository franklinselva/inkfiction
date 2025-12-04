import SwiftUI
import SwiftData

@main
struct InkFictionApp: App {

    // MARK: - State

    @State private var appState = AppState()
    @State private var router = Router()
    @State private var themeManager = ThemeManager()
    @State private var subscriptionService = SubscriptionService.shared

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
                .environment(subscriptionService)
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

        // Configure warm-up service
        let warmupService = AppWarmupService.shared
        warmupService.configure(modelContext: context, themeManager: themeManager)

        // Perform warm-up and track phases via AppState
        let result = await performWarmupWithTracking(warmupService)

        // Update app state based on warm-up result
        appState.hasCompletedOnboarding = result.hasCompletedOnboarding

        // Mark splash as finished
        withAnimation(.easeInOut(duration: 0.5)) {
            appState.finishSplash()
        }

        Log.info("App initialization complete", category: .app)
    }

    /// Perform warm-up while tracking phases in AppState
    @MainActor
    private func performWarmupWithTracking(_ warmupService: AppWarmupService) async -> WarmupResult {
        // Start a background task to track warm-up phases
        let trackingTask = Task { @MainActor in
            // Continuously update appState with warm-up phase
            while !warmupService.isComplete {
                appState.warmupPhase = warmupService.currentPhase
                try? await Task.sleep(for: .milliseconds(50))
            }
            appState.warmupPhase = warmupService.currentPhase
        }

        // Perform the warm-up
        let result = await warmupService.performWarmup()

        // Ensure tracking task completes
        trackingTask.cancel()

        return result
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
