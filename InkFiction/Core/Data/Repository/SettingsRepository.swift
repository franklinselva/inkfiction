//
//  SettingsRepository.swift
//  InkFiction
//
//  Repository for app settings persistence with iCloud sync
//

import CloudKit
import Foundation
import SwiftData

// MARK: - Settings Repository Errors

enum SettingsRepositoryError: LocalizedError {
    case modelContextNotAvailable
    case settingsNotFound
    case saveFailed(Error)
    case syncFailed(Error)

    var errorDescription: String? {
        switch self {
        case .modelContextNotAvailable:
            return "Database context is not available."
        case .settingsNotFound:
            return "Settings not found."
        case .saveFailed(let error):
            return "Failed to save settings: \(error.localizedDescription)"
        case .syncFailed(let error):
            return "Failed to sync settings: \(error.localizedDescription)"
        }
    }
}

// MARK: - Settings Repository

@Observable
@MainActor
final class SettingsRepository {

    // MARK: - Singleton

    static let shared = SettingsRepository()

    // MARK: - Published State

    /// Current app settings
    private(set) var currentSettings: AppSettingsModel?

    /// Loading state
    private(set) var isLoading: Bool = false

    // MARK: - Dependencies

    private var modelContext: ModelContext?
    private let cloudKitManager = CloudKitManager.shared
    private let syncMonitor = SyncMonitor.shared

    // MARK: - Computed Properties

    /// Whether onboarding is completed
    var hasCompletedOnboarding: Bool {
        currentSettings?.onboardingCompleted ?? UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
    }

    /// Current theme ID
    var themeId: String {
        currentSettings?.themeId ?? UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.selectedThemeId) ?? "paper"
    }

    /// Whether notifications are enabled
    var notificationsEnabled: Bool {
        currentSettings?.notificationsEnabled ?? UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.notificationsEnabled)
    }

    /// Whether AI auto-enhance is enabled
    var aiAutoEnhanceEnabled: Bool {
        currentSettings?.aiAutoEnhance ?? UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.aiAutoEnhanceEnabled)
    }

    /// Whether AI auto-title is enabled
    var aiAutoTitleEnabled: Bool {
        currentSettings?.aiAutoTitle ?? UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.aiAutoTitleEnabled)
    }

    // MARK: - Initialization

    private init() {
        Log.info("SettingsRepository initialized", category: .settings)
    }

    /// Set the model context for SwiftData operations
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Log.debug("Model context set for SettingsRepository", category: .settings)
    }

    // MARK: - CRUD Operations

    /// Load settings from storage
    func loadSettings() async throws {
        guard let context = modelContext else {
            throw SettingsRepositoryError.modelContextNotAvailable
        }

        isLoading = true
        defer { isLoading = false }

        Log.debug("Loading settings", category: .settings)

        let descriptor = FetchDescriptor<AppSettingsModel>()

        do {
            let settings = try context.fetch(descriptor)

            if let existingSettings = settings.first {
                currentSettings = existingSettings
                Log.info("Settings loaded from SwiftData", category: .settings)
            } else {
                // Create default settings if none exist
                let defaultSettings = AppSettingsModel.default
                context.insert(defaultSettings)
                try context.save()
                currentSettings = defaultSettings
                Log.info("Default settings created", category: .settings)
            }

            // Sync to UserDefaults for quick access
            syncToUserDefaults()

        } catch {
            Log.error("Failed to load settings", error: error, category: .settings)
            throw SettingsRepositoryError.saveFailed(error)
        }
    }

    /// Save current settings
    func saveSettings() async throws {
        guard let context = modelContext else {
            throw SettingsRepositoryError.modelContextNotAvailable
        }

        guard let settings = currentSettings else {
            throw SettingsRepositoryError.settingsNotFound
        }

        Log.debug("Saving settings", category: .settings)

        settings.updatedAt = Date()
        settings.needsSync = true

        do {
            try context.save()
            syncToUserDefaults()
            Log.info("Settings saved", category: .settings)

            // Sync to CloudKit
            Task {
                await syncSettingsToCloudKit(settings)
            }
        } catch {
            Log.error("Failed to save settings", error: error, category: .settings)
            throw SettingsRepositoryError.saveFailed(error)
        }
    }

    // MARK: - Settings Updates

    /// Update theme
    func setTheme(_ themeId: String) async throws {
        guard currentSettings != nil else {
            throw SettingsRepositoryError.settingsNotFound
        }

        Log.debug("Setting theme: \(themeId)", category: .settings)
        currentSettings?.themeId = themeId
        try await saveSettings()
    }

    /// Toggle notifications
    func toggleNotifications() async throws {
        guard let settings = currentSettings else {
            throw SettingsRepositoryError.settingsNotFound
        }

        Log.debug("Toggling notifications: \(!settings.notificationsEnabled)", category: .settings)
        currentSettings?.notificationsEnabled.toggle()
        try await saveSettings()
    }

    /// Set daily reminder time
    func setDailyReminderTime(_ time: Date?) async throws {
        guard currentSettings != nil else {
            throw SettingsRepositoryError.settingsNotFound
        }

        Log.debug("Setting daily reminder time", category: .settings)
        currentSettings?.dailyReminderTime = time
        try await saveSettings()
    }

    /// Toggle AI auto-enhance
    func toggleAIAutoEnhance() async throws {
        guard let settings = currentSettings else {
            throw SettingsRepositoryError.settingsNotFound
        }

        Log.debug("Toggling AI auto-enhance: \(!settings.aiAutoEnhance)", category: .settings)
        currentSettings?.aiAutoEnhance.toggle()
        try await saveSettings()
    }

    /// Toggle AI auto-title
    func toggleAIAutoTitle() async throws {
        guard let settings = currentSettings else {
            throw SettingsRepositoryError.settingsNotFound
        }

        Log.debug("Toggling AI auto-title: \(!settings.aiAutoTitle)", category: .settings)
        currentSettings?.aiAutoTitle.toggle()
        try await saveSettings()
    }

    /// Mark onboarding as completed
    func completeOnboarding() async throws {
        guard currentSettings != nil else {
            throw SettingsRepositoryError.settingsNotFound
        }

        Log.info("Marking onboarding as completed", category: .settings)
        currentSettings?.onboardingCompleted = true
        try await saveSettings()
    }

    /// Reset to default settings
    func resetToDefaults() async throws {
        guard let context = modelContext else {
            throw SettingsRepositoryError.modelContextNotAvailable
        }

        guard let settings = currentSettings else {
            throw SettingsRepositoryError.settingsNotFound
        }

        Log.info("Resetting settings to defaults", category: .settings)

        settings.themeId = "paper"
        settings.notificationsEnabled = true
        settings.dailyReminderTime = nil
        settings.aiAutoEnhance = true
        settings.aiAutoTitle = true
        settings.updatedAt = Date()
        settings.needsSync = true

        do {
            try context.save()
            syncToUserDefaults()
            Log.info("Settings reset to defaults", category: .settings)

            Task {
                await syncSettingsToCloudKit(settings)
            }
        } catch {
            Log.error("Failed to reset settings", error: error, category: .settings)
            throw SettingsRepositoryError.saveFailed(error)
        }
    }

    // MARK: - UserDefaults Sync

    /// Sync settings to UserDefaults for quick access
    private func syncToUserDefaults() {
        guard let settings = currentSettings else { return }

        let defaults = UserDefaults.standard
        defaults.set(settings.onboardingCompleted, forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
        defaults.set(settings.themeId, forKey: Constants.UserDefaultsKeys.selectedThemeId)
        defaults.set(settings.notificationsEnabled, forKey: Constants.UserDefaultsKeys.notificationsEnabled)
        defaults.set(settings.aiAutoEnhance, forKey: Constants.UserDefaultsKeys.aiAutoEnhanceEnabled)
        defaults.set(settings.aiAutoTitle, forKey: Constants.UserDefaultsKeys.aiAutoTitleEnabled)

        if let reminderTime = settings.dailyReminderTime {
            defaults.set(reminderTime, forKey: Constants.UserDefaultsKeys.dailyReminderTime)
        } else {
            defaults.removeObject(forKey: Constants.UserDefaultsKeys.dailyReminderTime)
        }

        Log.debug("Settings synced to UserDefaults", category: .settings)
    }

    // MARK: - CloudKit Sync

    /// Sync settings to CloudKit
    private func syncSettingsToCloudKit(_ settings: AppSettingsModel) async {
        guard syncMonitor.canSync else {
            Log.debug("Cannot sync - network or account unavailable", category: .cloudKit)
            return
        }

        syncMonitor.beginSync()

        do {
            let record = settings.toRecord()
            let savedRecord = try await cloudKitManager.save(record)

            settings.cloudKitRecordName = savedRecord.recordID.recordName
            settings.lastSyncedAt = Date()
            settings.needsSync = false

            if let context = modelContext {
                try context.save()
            }

            syncMonitor.endSync()

            Log.info("Settings synced to CloudKit", category: .cloudKit)
        } catch {
            syncMonitor.syncFailed(error: error)
            Log.error("Failed to sync settings to CloudKit", error: error, category: .cloudKit)
        }
    }

    /// Pull settings from CloudKit
    func pullFromCloudKit() async throws {
        guard syncMonitor.canSync else {
            throw CloudKitError.networkUnavailable
        }

        guard let context = modelContext else {
            throw SettingsRepositoryError.modelContextNotAvailable
        }

        Log.info("Pulling settings from CloudKit", category: .cloudKit)
        syncMonitor.beginSync()

        do {
            let records = try await cloudKitManager.query(
                recordType: Constants.iCloud.RecordTypes.appSettings,
                sortDescriptors: [NSSortDescriptor(key: "updatedAt", ascending: false)],
                resultsLimit: 1
            )

            if let record = records.first,
               let remoteSettings = AppSettingsModel(from: record) {

                // Check if settings exist locally
                let remoteId = remoteSettings.id
                let descriptor = FetchDescriptor<AppSettingsModel>(
                    predicate: #Predicate<AppSettingsModel> { $0.id == remoteId }
                )

                let existingSettings = try context.fetch(descriptor)

                if let localSettings = existingSettings.first {
                    // Use remote if newer (last-write-wins)
                    if remoteSettings.updatedAt > localSettings.updatedAt {
                        localSettings.themeId = remoteSettings.themeId
                        localSettings.notificationsEnabled = remoteSettings.notificationsEnabled
                        localSettings.dailyReminderTime = remoteSettings.dailyReminderTime
                        localSettings.aiAutoEnhance = remoteSettings.aiAutoEnhance
                        localSettings.aiAutoTitle = remoteSettings.aiAutoTitle
                        localSettings.onboardingCompleted = remoteSettings.onboardingCompleted
                        localSettings.updatedAt = remoteSettings.updatedAt
                        localSettings.cloudKitRecordName = remoteSettings.cloudKitRecordName
                        localSettings.lastSyncedAt = Date()
                        localSettings.needsSync = false
                    }
                    currentSettings = localSettings
                } else if currentSettings == nil {
                    // No local settings, use remote
                    context.insert(remoteSettings)
                    currentSettings = remoteSettings
                }

                try context.save()
                syncToUserDefaults()
            }

            syncMonitor.endSync()
            Log.info("Settings pulled from CloudKit", category: .cloudKit)

        } catch {
            syncMonitor.syncFailed(error: error)
            throw SettingsRepositoryError.syncFailed(error)
        }
    }

    /// Full sync (pull then push)
    func performFullSync() async {
        guard syncMonitor.canSync else {
            Log.debug("Cannot perform full sync - network or account unavailable", category: .cloudKit)
            return
        }

        Log.info("Starting full settings sync", category: .cloudKit)

        do {
            // Pull from CloudKit first
            try await pullFromCloudKit()

            // Then push any local changes
            if let settings = currentSettings, settings.needsSync {
                await syncSettingsToCloudKit(settings)
            }

            Log.info("Full settings sync completed", category: .cloudKit)
        } catch {
            Log.error("Full settings sync failed", error: error, category: .cloudKit)
        }
    }

    // MARK: - Warmup

    /// Warmup settings on app launch
    func warmup() async {
        Log.info("Starting settings warmup", category: .settings)

        do {
            try await loadSettings()

            // Try to pull from CloudKit if available
            if syncMonitor.canSync {
                try? await pullFromCloudKit()
            }

            Log.info("Settings warmup completed", category: .settings)
        } catch {
            Log.error("Settings warmup failed", error: error, category: .settings)
        }
    }

    // MARK: - Cleanup

    /// Clear all settings data
    func clearAllData() async throws {
        guard let context = modelContext else {
            throw SettingsRepositoryError.modelContextNotAvailable
        }

        Log.warning("Clearing all settings data", category: .settings)

        try context.delete(model: AppSettingsModel.self)
        try context.save()

        currentSettings = nil

        // Clear UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.selectedThemeId)
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.notificationsEnabled)
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.dailyReminderTime)
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.aiAutoEnhanceEnabled)
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.aiAutoTitleEnabled)

        Log.info("All settings data cleared", category: .settings)
    }
}
