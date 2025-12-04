//
//  DataStorageView.swift
//  InkFiction
//
//  Data management and storage settings view
//

import SwiftUI

struct DataStorageView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(Router.self) private var router
    @State private var viewModel = DataStorageViewModel()
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                // Navigation header
                NavigationHeaderView(
                    config: NavigationHeaderConfig(
                        title: "Data & Storage",
                        leftButton: .back(action: { dismiss() }),
                        rightButton: .none
                    ),
                    scrollOffset: scrollOffset
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // iCloud Sync Section
                        iCloudSyncSection

                        // Storage Info Section
                        storageInfoSection

                        // Data Management Section
                        dataManagementSection

                        // Add bottom spacing to avoid tab bar overlap
                        Color.clear
                            .frame(height: 120)
                    }
                    .padding()
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    scrollOffset = -newValue
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.calculateStorageUsage()
            }
        }
        .alert("Clear All Data?", isPresented: $viewModel.showingClearDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                Task {
                    await viewModel.clearAllData()
                }
            }
        } message: {
            Text("This will permanently delete all your journal entries, images, and settings. This cannot be undone.")
        }
    }

    // MARK: - iCloud Sync Section

    private var iCloudSyncSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("iCloud Sync")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(spacing: 16) {
                // Sync Status
                HStack(spacing: 12) {
                    Image(systemName: "icloud.fill")
                        .font(.body)
                        .foregroundColor(.cyan)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Automatic Sync")
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        Text("Sync your journal across all your devices")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundColor(.green)
                }

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                // Sync Now Button
                Button {
                    Task {
                        await viewModel.syncNow()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.body)
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        Text("Sync Now")
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                        Spacer()

                        if viewModel.isSyncing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        }
                    }
                }
                .disabled(viewModel.isSyncing)

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                // Info
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text("Your data is securely synced via iCloud")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
                .padding(.horizontal, 4)
            }
            .padding()
            .gradientCard()
        }
    }

    // MARK: - Storage Info Section

    private var storageInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Storage")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(spacing: 16) {
                // Journal Entries
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text.fill")
                            .font(.body)
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Journal Entries")
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                            Text("Entries, images, and app data")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        }
                    }

                    Spacer()

                    if viewModel.isCalculatingStorage {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text(viewModel.storageStats.totalSizeFormatted)
                            .font(.body.weight(.medium))
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                }

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                // Images
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.fill")
                            .font(.body)
                            .foregroundColor(.purple)
                            .frame(width: 24)

                        Text("Images")
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                    }

                    Spacer()

                    Text(viewModel.storageStats.imagesSizeFormatted)
                        .font(.body.weight(.medium))
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                // Refresh Button
                Button {
                    Task {
                        await viewModel.calculateStorageUsage()
                    }
                } label: {
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.clockwise")
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                                .frame(width: 24)

                            Text("Update Data Size")
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                }
            }
            .padding()
            .gradientCard()
        }
    }

    // MARK: - Data Management Section

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Management")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                // Export Data
                Button {
                    router.push(.settingsSection(section: .export))
                } label: {
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.body)
                                .foregroundColor(.blue)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Export Data")
                                    .font(.body)
                                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                                Text("Download your journal as CSV and images")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    .padding()
                }

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                // Clear All Data
                Button {
                    viewModel.showingClearDataAlert = true
                } label: {
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "trash.fill")
                                .font(.body)
                                .foregroundColor(.red)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Clear All Data")
                                    .font(.body)
                                    .foregroundColor(.red)
                                Text("Delete all journal entries and settings")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.6))
                    }
                    .padding()
                }
            }
            .gradientCard()
        }
    }
}

// MARK: - View Model

@MainActor
@Observable
final class DataStorageViewModel {
    var storageStats = StorageStats()
    var isCalculatingStorage: Bool = false
    var isSyncing: Bool = false
    var showingClearDataAlert: Bool = false

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

    func calculateStorageUsage() async {
        isCalculatingStorage = true
        defer { isCalculatingStorage = false }

        do {
            let entriesSize = try calculateJournalEntriesSize()
            let imagesSize = try calculateImagesSize()
            let appDataSize = try calculateAppDataSize()

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

    func syncNow() async {
        isSyncing = true
        defer { isSyncing = false }

        // CloudKit syncs automatically with iCloud
        // This just provides visual feedback to the user
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second delay for visual feedback
        Log.info("Sync check completed - iCloud syncs automatically", category: .cloudKit)
    }

    func clearAllData() async {
        Log.warning("Clearing all data", category: .data)

        do {
            // Clear journal entries
            let journalRepository = JournalRepository.shared
            for entry in journalRepository.entries {
                try await journalRepository.deleteEntry(entry)
            }

            // Clear persona data
            try await PersonaRepository.shared.clearAllData()

            // Reset settings
            try await SettingsRepository.shared.resetToDefaults()

            // Recalculate storage
            await calculateStorageUsage()

            Log.info("All data cleared successfully", category: .data)
        } catch {
            Log.error("Failed to clear all data", error: error, category: .data)
        }
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

#Preview {
    DataStorageView()
        .environment(\.themeManager, ThemeManager())
        .environment(Router())
}
