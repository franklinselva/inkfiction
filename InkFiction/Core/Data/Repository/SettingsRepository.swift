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

    /// Current journaling style
    var journalingStyle: JournalingStyle {
        if let raw = currentSettings?.journalingStyleRaw {
            return JournalingStyle(rawValue: raw) ?? .quickNotes
        }
        if let raw = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.journalingStyle) {
            return JournalingStyle(rawValue: raw) ?? .quickNotes
        }
        return .quickNotes
    }

    /// Current emotional expression preference
    var emotionalExpression: EmotionalExpression {
        if let raw = currentSettings?.emotionalExpressionRaw {
            return EmotionalExpression(rawValue: raw) ?? .writingFreely
        }
        if let raw = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.emotionalExpression) {
            return EmotionalExpression(rawValue: raw) ?? .writingFreely
        }
        return .writingFreely
    }

    /// Current visual preference
    var visualPreference: VisualPreference {
        if let raw = currentSettings?.visualPreferenceRaw {
            return VisualPreference(rawValue: raw) ?? .abstractDreamy
        }
        if let raw = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.visualPreference) {
            return VisualPreference(rawValue: raw) ?? .abstractDreamy
        }
        return .abstractDreamy
    }

    /// Selected AI companion ID
    var selectedCompanionId: String {
        currentSettings?.selectedCompanionId ?? UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.selectedCompanionId) ?? "realist"
    }

    /// Selected AI companion
    var selectedCompanion: AICompanion {
        AICompanion.all.first { $0.id == selectedCompanionId } ?? .realist
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

    /// Load settings from local storage only (does not create defaults)
    /// Returns true if settings were found locally
    func loadSettingsFromLocal() async throws -> Bool {
        guard let context = modelContext else {
            throw SettingsRepositoryError.modelContextNotAvailable
        }

        isLoading = true
        defer { isLoading = false }

        Log.debug("Loading settings from local storage", category: .settings)

        let descriptor = FetchDescriptor<AppSettingsModel>()

        do {
            let settings = try context.fetch(descriptor)

            if let existingSettings = settings.first {
                currentSettings = existingSettings
                syncToUserDefaults()
                Log.info("Settings loaded from SwiftData", category: .settings)
                return true
            } else {
                Log.debug("No local settings found", category: .settings)
                return false
            }
        } catch {
            Log.error("Failed to load settings from local", error: error, category: .settings)
            throw SettingsRepositoryError.saveFailed(error)
        }
    }

    /// Create default settings (only call if no local or iCloud settings exist)
    func createDefaultSettings() async throws {
        guard let context = modelContext else {
            throw SettingsRepositoryError.modelContextNotAvailable
        }

        Log.info("Creating default settings", category: .settings)

        let defaultSettings = AppSettingsModel.default
        context.insert(defaultSettings)
        try context.save()
        currentSettings = defaultSettings
        syncToUserDefaults()

        Log.info("Default settings created", category: .settings)
    }

    /// Load settings from storage (legacy method, creates defaults if none exist)
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

    /// Set journaling style
    func setJournalingStyle(_ style: JournalingStyle) async throws {
        guard currentSettings != nil else {
            throw SettingsRepositoryError.settingsNotFound
        }

        Log.debug("Setting journaling style: \(style.rawValue)", category: .settings)
        currentSettings?.journalingStyleRaw = style.rawValue
        try await saveSettings()
    }

    /// Set emotional expression
    func setEmotionalExpression(_ expression: EmotionalExpression) async throws {
        guard currentSettings != nil else {
            throw SettingsRepositoryError.settingsNotFound
        }

        Log.debug("Setting emotional expression: \(expression.rawValue)", category: .settings)
        currentSettings?.emotionalExpressionRaw = expression.rawValue
        try await saveSettings()
    }

    /// Set visual preference
    func setVisualPreference(_ preference: VisualPreference) async throws {
        guard currentSettings != nil else {
            throw SettingsRepositoryError.settingsNotFound
        }

        Log.debug("Setting visual preference: \(preference.rawValue)", category: .settings)
        currentSettings?.visualPreferenceRaw = preference.rawValue
        try await saveSettings()
    }

    /// Set selected companion
    func setSelectedCompanion(_ companion: AICompanion) async throws {
        guard currentSettings != nil else {
            throw SettingsRepositoryError.settingsNotFound
        }

        Log.debug("Setting selected companion: \(companion.id)", category: .settings)
        currentSettings?.selectedCompanionId = companion.id
        try await saveSettings()
    }

    /// Update all journal preferences at once
    func updateJournalPreferences(
        journalingStyle: JournalingStyle,
        emotionalExpression: EmotionalExpression,
        visualPreference: VisualPreference,
        companion: AICompanion
    ) async throws {
        guard currentSettings != nil else {
            throw SettingsRepositoryError.settingsNotFound
        }

        Log.debug("Updating all journal preferences", category: .settings)
        currentSettings?.journalingStyleRaw = journalingStyle.rawValue
        currentSettings?.emotionalExpressionRaw = emotionalExpression.rawValue
        currentSettings?.visualPreferenceRaw = visualPreference.rawValue
        currentSettings?.selectedCompanionId = companion.id
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
        // Journal Preferences
        defaults.set(settings.journalingStyleRaw, forKey: Constants.UserDefaultsKeys.journalingStyle)
        defaults.set(settings.emotionalExpressionRaw, forKey: Constants.UserDefaultsKeys.emotionalExpression)
        defaults.set(settings.visualPreferenceRaw, forKey: Constants.UserDefaultsKeys.visualPreference)
        defaults.set(settings.selectedCompanionId, forKey: Constants.UserDefaultsKeys.selectedCompanionId)

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

                // First check if we have ANY local settings
                let allSettingsDescriptor = FetchDescriptor<AppSettingsModel>()
                let allLocalSettings = try context.fetch(allSettingsDescriptor)

                if let existingLocalSettings = allLocalSettings.first {
                    // We have local settings - check if remote is newer
                    if remoteSettings.updatedAt > existingLocalSettings.updatedAt {
                        existingLocalSettings.themeId = remoteSettings.themeId
                        existingLocalSettings.notificationsEnabled = remoteSettings.notificationsEnabled
                        existingLocalSettings.dailyReminderTime = remoteSettings.dailyReminderTime
                        existingLocalSettings.aiAutoEnhance = remoteSettings.aiAutoEnhance
                        existingLocalSettings.aiAutoTitle = remoteSettings.aiAutoTitle
                        existingLocalSettings.onboardingCompleted = remoteSettings.onboardingCompleted
                        // Journal Preferences
                        existingLocalSettings.journalingStyleRaw = remoteSettings.journalingStyleRaw
                        existingLocalSettings.emotionalExpressionRaw = remoteSettings.emotionalExpressionRaw
                        existingLocalSettings.visualPreferenceRaw = remoteSettings.visualPreferenceRaw
                        existingLocalSettings.selectedCompanionId = remoteSettings.selectedCompanionId
                        existingLocalSettings.updatedAt = remoteSettings.updatedAt
                        existingLocalSettings.cloudKitRecordName = remoteSettings.cloudKitRecordName
                        existingLocalSettings.lastSyncedAt = Date()
                        existingLocalSettings.needsSync = false
                        Log.info("Updated local settings from iCloud (remote was newer)", category: .cloudKit)
                    }
                    currentSettings = existingLocalSettings
                } else {
                    // No local settings at all - insert remote settings
                    Log.info("No local settings found, restoring from iCloud", category: .cloudKit)
                    remoteSettings.lastSyncedAt = Date()
                    remoteSettings.needsSync = false
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
    /// Flow: Local → iCloud → Defaults
    func warmup() async {
        Log.info("Starting settings warmup", category: .settings)

        do {
            // Step 1: Try to load from local storage
            let hasLocalSettings = try await loadSettingsFromLocal()

            if hasLocalSettings {
                Log.info("Settings found locally", category: .settings)

                // If we have local settings, still try to sync with iCloud for updates
                if syncMonitor.canSync {
                    try? await pullFromCloudKit()
                }
            } else {
                // Step 2: No local settings, try to fetch from iCloud
                Log.info("No local settings, checking iCloud...", category: .settings)

                var foundInCloud = false

                if syncMonitor.canSync {
                    do {
                        try await pullFromCloudKit()
                        // Check if we got settings from iCloud
                        if currentSettings != nil {
                            foundInCloud = true
                            Log.info("Settings restored from iCloud", category: .settings)
                        }
                    } catch {
                        Log.warning("Failed to fetch settings from iCloud: \(error.localizedDescription)", category: .cloudKit)
                    }
                }

                // Step 3: If still no settings, create defaults
                if !foundInCloud {
                    Log.info("No settings in iCloud, creating defaults", category: .settings)
                    try await createDefaultSettings()
                }
            }

            Log.info("Settings warmup completed - onboardingCompleted: \(hasCompletedOnboarding)", category: .settings)
        } catch {
            Log.error("Settings warmup failed", error: error, category: .settings)

            // Fallback: try to create defaults if warmup failed
            do {
                try await createDefaultSettings()
            } catch {
                Log.error("Failed to create default settings", error: error, category: .settings)
            }
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
        // Journal Preferences
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.journalingStyle)
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.emotionalExpression)
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.visualPreference)
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.selectedCompanionId)
        // Legacy onboarding data
        defaults.removeObject(forKey: "onboardingData")

        Log.info("All settings data cleared", category: .settings)
    }
}
