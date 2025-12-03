//
//  SettingsViewModel.swift
//  InkFiction
//
//  ViewModel for settings management
//

import Foundation
import SwiftUI
import Combine

@MainActor
@Observable
final class SettingsViewModel {

    // MARK: - Properties

    var notificationsEnabled: Bool = false
    var biometricAuthEnabled: Bool = false

    // Storage Statistics
    var storageStats: StorageStats = StorageStats()
    var isCalculatingStorage: Bool = false
    var isSyncing: Bool = false

    private var settingsRepository = SettingsRepository.shared

    // MARK: - Storage Stats

    struct StorageStats {
        var journalEntriesSize: Int64 = 0
        var imagesSize: Int64 = 0
        var appDataSize: Int64 = 0
        var totalSize: Int64 = 0

        var journalEntriesSizeFormatted: String {
            ByteCountFormatter.string(fromByteCount: journalEntriesSize, countStyle: .file)
        }

        var imagesSizeFormatted: String {
            ByteCountFormatter.string(fromByteCount: imagesSize, countStyle: .file)
        }

        var appDataSizeFormatted: String {
            ByteCountFormatter.string(fromByteCount: appDataSize, countStyle: .file)
        }

        var totalSizeFormatted: String {
            ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
        }
    }

    // MARK: - Initialization

    init() {
        loadSettings()
    }

    // MARK: - Public Methods

    func loadSettings() {
        notificationsEnabled = settingsRepository.currentSettings?.notificationsEnabled ?? false
        // Biometric auth enabled can be loaded from UserDefaults or BiometricService
        biometricAuthEnabled = BiometricService.shared.isEnabled
    }

    func getStorageUsage() -> String {
        return storageStats.totalSizeFormatted
    }

    func getAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    func getBuildNumber() -> String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    func calculateStorageUsage() async {
        isCalculatingStorage = true
        defer { isCalculatingStorage = false }

        do {
            // Calculate journal entries size
            let entriesSize = try calculateJournalEntriesSize()

            // Calculate images size from file system
            let imagesSize = try calculateImagesSize()

            // Calculate app data size (settings, cache, etc.)
            let appDataSize = try calculateAppDataSize()

            // Update storage stats
            storageStats = StorageStats(
                journalEntriesSize: entriesSize,
                imagesSize: imagesSize,
                appDataSize: appDataSize,
                totalSize: entriesSize + imagesSize + appDataSize
            )

            Log.debug("Storage calculation complete: \(storageStats.totalSizeFormatted)", category: .data)
        } catch {
            Log.error("Failed to calculate storage", error: error, category: .data)
        }
    }

    func clearAllData() async throws {
        Log.warning("Clearing all data", category: .data)

        // Clear journal entries
        let journalRepository = JournalRepository.shared
        for entry in journalRepository.entries {
            try await journalRepository.deleteEntry(entry)
        }

        // Clear persona data
        try await PersonaRepository.shared.clearAllData()

        // Reset settings
        try await settingsRepository.resetToDefaults()

        // Recalculate storage
        await calculateStorageUsage()

        Log.info("All data cleared successfully", category: .data)
    }

    // MARK: - Private Methods

    private func calculateJournalEntriesSize() throws -> Int64 {
        // Estimate size based on entry count and average content size
        let journalRepository = JournalRepository.shared
        var totalSize: Int64 = 0

        for entry in journalRepository.entries {
            // Estimate: title + content + tags + metadata
            let titleSize = entry.title.utf8.count
            let contentSize = entry.content.utf8.count
            let tagsSize = entry.tags.joined().utf8.count
            let metadataEstimate = 200 // UUID, dates, mood, etc.

            totalSize += Int64(titleSize + contentSize + tagsSize + metadataEstimate)
        }

        return totalSize
    }

    private func calculateImagesSize() throws -> Int64 {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagesURL = documentsURL.appendingPathComponent("Images")

        guard FileManager.default.fileExists(atPath: imagesURL.path) else {
            return 0
        }

        var totalSize: Int64 = 0
        let resourceKeys: [URLResourceKey] = [.totalFileSizeKey, .isRegularFileKey]

        guard let enumerator = FileManager.default.enumerator(
            at: imagesURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        while let fileURL = enumerator.nextObject() as? URL {
            let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            if resourceValues.isRegularFile == true {
                totalSize += Int64(resourceValues.totalFileSize ?? 0)
            }
        }

        return totalSize
    }

    private func calculateAppDataSize() throws -> Int64 {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        var totalSize: Int64 = 0

        let resourceKeys: [URLResourceKey] = [.totalFileSizeKey, .isRegularFileKey]

        guard let enumerator = FileManager.default.enumerator(
            at: documentsURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        while let fileURL = enumerator.nextObject() as? URL {
            // Skip images directory as it's calculated separately
            if fileURL.path.contains("Images") || fileURL.path.contains("JournalEntries") {
                continue
            }

            let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            if resourceValues.isRegularFile == true {
                totalSize += Int64(resourceValues.totalFileSize ?? 0)
            }
        }

        return totalSize
    }
}
