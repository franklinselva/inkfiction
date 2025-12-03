import SwiftUI

// MARK: - App State

/// Global application state
@Observable
final class AppState {

    // MARK: - Authentication State

    /// Whether the user has passed biometric authentication
    var isUnlocked: Bool = false

    /// Whether biometric authentication is in progress
    var isAuthenticating: Bool = false

    // MARK: - Onboarding State

    /// Whether the user has completed onboarding
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding) }
    }

    // MARK: - Persona State

    /// Whether the user has created a persona
    var hasPersona: Bool = false

    // MARK: - Sync State

    /// Current sync status
    var syncStatus: SyncStatus = .idle

    // MARK: - App Lifecycle

    /// Whether the app is in the foreground
    var isActive: Bool = true

    // MARK: - Initialization

    init() {
        Log.info("AppState initialized", category: .app)
    }

    // MARK: - Methods

    /// Lock the app (require biometric auth)
    func lock() {
        Log.info("App locked", category: .app)
        isUnlocked = false
    }

    /// Unlock the app after successful biometric auth
    func unlock() {
        Log.info("App unlocked", category: .app)
        isUnlocked = true
    }

    /// Mark onboarding as complete
    func completeOnboarding() {
        Log.info("Onboarding completed", category: .app)
        hasCompletedOnboarding = true
    }

    /// Reset app state (for testing/debugging)
    func reset() {
        Log.warning("Resetting app state", category: .app)
        isUnlocked = false
        hasCompletedOnboarding = false
        hasPersona = false
        syncStatus = .idle
    }
}

// MARK: - Sync Status

enum SyncStatus: Equatable {
    case idle
    case syncing
    case synced(Date)
    case error(String)
    case offline

    var displayText: String {
        switch self {
        case .idle: "Ready"
        case .syncing: "Syncing..."
        case .synced(let date): "Synced \(date.formatted(.relative(presentation: .named)))"
        case .error(let message): "Error: \(message)"
        case .offline: "Offline"
        }
    }

    var icon: String {
        switch self {
        case .idle: "checkmark.circle"
        case .syncing: "arrow.triangle.2.circlepath"
        case .synced: "checkmark.icloud"
        case .error: "exclamationmark.icloud"
        case .offline: "icloud.slash"
        }
    }
}

// MARK: - Environment

private struct AppStateKey: EnvironmentKey {
    static let defaultValue = AppState()
}

extension EnvironmentValues {
    var appState: AppState {
        get { self[AppStateKey.self] }
        set { self[AppStateKey.self] = newValue }
    }
}
