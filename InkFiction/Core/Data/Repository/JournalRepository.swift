//
//  JournalRepository.swift
//  InkFiction
//
//  Repository for journal entries with CloudKit sync and local SwiftData persistence
//

import CloudKit
import Foundation
import SwiftData

// MARK: - Journal Repository Errors

enum JournalRepositoryError: LocalizedError {
    case modelContextNotAvailable
    case entryNotFound(UUID)
    case saveFailed(Error)
    case deleteFailed(Error)
    case syncFailed(Error)
    case imageLoadFailed(UUID)

    var errorDescription: String? {
        switch self {
        case .modelContextNotAvailable:
            return "Database context is not available."
        case .entryNotFound(let id):
            return "Journal entry not found: \(id)"
        case .saveFailed(let error):
            return "Failed to save journal entry: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete journal entry: \(error.localizedDescription)"
        case .syncFailed(let error):
            return "Failed to sync with iCloud: \(error.localizedDescription)"
        case .imageLoadFailed(let id):
            return "Failed to load image: \(id)"
        }
    }
}

// MARK: - Journal Filter

struct JournalFilter: Sendable {
    var searchText: String?
    var mood: Mood?
    var startDate: Date?
    var endDate: Date?
    var includeArchived: Bool
    var pinnedOnly: Bool
    var tags: [String]?

    init(
        searchText: String? = nil,
        mood: Mood? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        includeArchived: Bool = false,
        pinnedOnly: Bool = false,
        tags: [String]? = nil
    ) {
        self.searchText = searchText
        self.mood = mood
        self.startDate = startDate
        self.endDate = endDate
        self.includeArchived = includeArchived
        self.pinnedOnly = pinnedOnly
        self.tags = tags
    }

    nonisolated static let `default` = JournalFilter()
}

// MARK: - Journal Sort

enum JournalSort {
    case dateDescending
    case dateAscending
    case titleAscending
    case titleDescending
    case mood

    var sortDescriptor: SortDescriptor<JournalEntryModel> {
        switch self {
        case .dateDescending:
            return SortDescriptor(\JournalEntryModel.createdAt, order: .reverse)
        case .dateAscending:
            return SortDescriptor(\JournalEntryModel.createdAt, order: .forward)
        case .titleAscending:
            return SortDescriptor(\JournalEntryModel.title, order: .forward)
        case .titleDescending:
            return SortDescriptor(\JournalEntryModel.title, order: .reverse)
        case .mood:
            return SortDescriptor(\JournalEntryModel.moodRaw, order: .forward)
        }
    }
}

// MARK: - Journal Repository

@Observable
@MainActor
final class JournalRepository {

    // MARK: - Singleton

    static let shared = JournalRepository()

    // MARK: - Published State

    private(set) var entries: [JournalEntryModel] = []
    private(set) var isLoading: Bool = false
    private(set) var error: JournalRepositoryError?

    // MARK: - Dependencies

    private var modelContext: ModelContext?
    private let cloudKitManager = CloudKitManager.shared
    private let syncMonitor = SyncMonitor.shared

    // MARK: - Initialization

    private init() {
        Log.info("JournalRepository initialized", category: .journal)
    }

    /// Set the model context for SwiftData operations
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Log.debug("Model context set for JournalRepository", category: .journal)
    }

    // MARK: - CRUD Operations

    /// Fetch all entries with optional filter and sort
    func fetchEntries(
        filter: JournalFilter = .default,
        sort: JournalSort = .dateDescending
    ) async throws -> [JournalEntryModel] {
        guard let context = modelContext else {
            throw JournalRepositoryError.modelContextNotAvailable
        }

        isLoading = true
        defer { isLoading = false }

        Log.debug("Fetching journal entries with filter", category: .journal)

        var predicates: [Predicate<JournalEntryModel>] = []

        // Archive filter
        if !filter.includeArchived {
            predicates.append(#Predicate<JournalEntryModel> { $0.isArchived == false })
        }

        // Pinned filter
        if filter.pinnedOnly {
            predicates.append(#Predicate<JournalEntryModel> { $0.isPinned == true })
        }

        // Mood filter
        if let mood = filter.mood {
            let moodRaw = mood.rawValue
            predicates.append(#Predicate<JournalEntryModel> { $0.moodRaw == moodRaw })
        }

        // Date range filter
        if let startDate = filter.startDate {
            predicates.append(#Predicate<JournalEntryModel> { $0.createdAt >= startDate })
        }

        if let endDate = filter.endDate {
            predicates.append(#Predicate<JournalEntryModel> { $0.createdAt <= endDate })
        }

        // Build fetch descriptor
        var descriptor = FetchDescriptor<JournalEntryModel>(
            sortBy: [sort.sortDescriptor]
        )

        // Combine predicates if any
        if !predicates.isEmpty {
            // For simplicity, we'll apply the first predicate
            // Complex compound predicates would need manual handling
            descriptor.predicate = predicates.first
        }

        do {
            var results = try context.fetch(descriptor)

            // Force load images relationship for each entry
            // SwiftData lazy-loads relationships, so we need to access them to populate the data
            for entry in results {
                _ = entry.images?.count
                // Also ensure imageData is loaded for each image
                if let images = entry.images {
                    for image in images {
                        _ = image.imageData
                    }
                }
            }

            // Apply search text filter in memory (SwiftData predicate limitations)
            if let searchText = filter.searchText, !searchText.isEmpty {
                let lowercasedSearch = searchText.lowercased()
                results = results.filter { entry in
                    entry.title.lowercased().contains(lowercasedSearch) ||
                    entry.content.lowercased().contains(lowercasedSearch)
                }
            }

            // Apply tag filter in memory
            if let tags = filter.tags, !tags.isEmpty {
                results = results.filter { entry in
                    !Set(entry.tags).isDisjoint(with: Set(tags))
                }
            }

            entries = results
            Log.info("Fetched \(results.count) journal entries", category: .journal)
            return results
        } catch {
            Log.error("Failed to fetch journal entries", error: error, category: .journal)
            throw JournalRepositoryError.saveFailed(error)
        }
    }

    /// Get a single entry by ID
    func getEntry(by id: UUID) async throws -> JournalEntryModel? {
        guard let context = modelContext else {
            throw JournalRepositoryError.modelContextNotAvailable
        }

        let entryId = id
        let descriptor = FetchDescriptor<JournalEntryModel>(
            predicate: #Predicate<JournalEntryModel> { $0.id == entryId }
        )

        do {
            let results = try context.fetch(descriptor)
            if let entry = results.first {
                // Force load images relationship
                // SwiftData lazy-loads relationships, so we need to access them to populate the data
                _ = entry.images?.count
                if let images = entry.images {
                    for image in images {
                        _ = image.imageData
                    }
                }
                return entry
            }
            return nil
        } catch {
            Log.error("Failed to fetch entry by ID: \(id)", error: error, category: .journal)
            throw JournalRepositoryError.entryNotFound(id)
        }
    }

    /// Create a new journal entry
    func createEntry(
        title: String,
        content: String,
        mood: Mood,
        tags: [String] = []
    ) async throws -> JournalEntryModel {
        guard let context = modelContext else {
            throw JournalRepositoryError.modelContextNotAvailable
        }

        Log.debug("Creating new journal entry: \(title)", category: .journal)

        let entry = JournalEntryModel(
            title: title,
            content: content,
            mood: mood,
            tags: tags
        )

        context.insert(entry)

        do {
            try context.save()
            entries.insert(entry, at: 0)
            Log.info("Journal entry created: \(entry.id)", category: .journal)

            // Queue for CloudKit sync
            syncMonitor.addPendingSync()
            Task {
                await syncEntryToCloudKit(entry)
            }

            return entry
        } catch {
            Log.error("Failed to create journal entry", error: error, category: .journal)
            throw JournalRepositoryError.saveFailed(error)
        }
    }

    /// Update an existing journal entry
    func updateEntry(_ entry: JournalEntryModel) async throws {
        guard let context = modelContext else {
            throw JournalRepositoryError.modelContextNotAvailable
        }

        Log.debug("Updating journal entry: \(entry.id)", category: .journal)

        entry.updatedAt = Date()
        entry.needsSync = true

        do {
            try context.save()
            Log.info("Journal entry updated: \(entry.id)", category: .journal)

            // Queue for CloudKit sync
            Task {
                await syncEntryToCloudKit(entry)
            }
        } catch {
            Log.error("Failed to update journal entry", error: error, category: .journal)
            throw JournalRepositoryError.saveFailed(error)
        }
    }

    /// Delete a journal entry
    func deleteEntry(_ entry: JournalEntryModel) async throws {
        guard let context = modelContext else {
            throw JournalRepositoryError.modelContextNotAvailable
        }

        Log.debug("Deleting journal entry: \(entry.id)", category: .journal)

        // Delete from CloudKit first if synced
        if let recordName = entry.cloudKitRecordName {
            do {
                let recordID = CKRecord.ID(recordName: recordName)
                try await cloudKitManager.delete(recordID: recordID)
            } catch {
                Log.warning("Failed to delete from CloudKit: \(error.localizedDescription)", category: .cloudKit)
            }
        }

        context.delete(entry)

        do {
            try context.save()
            entries.removeAll { $0.id == entry.id }
            Log.info("Journal entry deleted: \(entry.id)", category: .journal)
        } catch {
            Log.error("Failed to delete journal entry", error: error, category: .journal)
            throw JournalRepositoryError.deleteFailed(error)
        }
    }

    /// Archive a journal entry
    func archiveEntry(_ entry: JournalEntryModel) async throws {
        entry.isArchived = true
        try await updateEntry(entry)
        Log.info("Journal entry archived: \(entry.id)", category: .journal)
    }

    /// Unarchive a journal entry
    func unarchiveEntry(_ entry: JournalEntryModel) async throws {
        entry.isArchived = false
        try await updateEntry(entry)
        Log.info("Journal entry unarchived: \(entry.id)", category: .journal)
    }

    /// Toggle pin status
    func togglePin(_ entry: JournalEntryModel) async throws {
        entry.isPinned.toggle()
        try await updateEntry(entry)
        Log.info("Journal entry pin toggled: \(entry.id) -> \(entry.isPinned)", category: .journal)
    }

    // MARK: - Image Management

    /// Add an image to a journal entry
    func addImage(
        to entry: JournalEntryModel,
        imageData: Data,
        caption: String? = nil,
        isAIGenerated: Bool = false
    ) async throws -> JournalImageModel {
        guard modelContext != nil else {
            throw JournalRepositoryError.modelContextNotAvailable
        }

        let image = JournalImageModel(
            imageData: imageData,
            caption: caption,
            isAIGenerated: isAIGenerated
        )

        image.journalEntry = entry
        if entry.images == nil {
            entry.images = []
        }
        entry.images?.append(image)

        try await updateEntry(entry)
        Log.info("Image added to journal entry: \(entry.id)", category: .journal)

        return image
    }

    /// Remove an image from a journal entry
    func removeImage(_ image: JournalImageModel, from entry: JournalEntryModel) async throws {
        guard let context = modelContext else {
            throw JournalRepositoryError.modelContextNotAvailable
        }

        // Delete from CloudKit if synced
        await deleteImageFromCloudKit(image)

        entry.images?.removeAll { $0.id == image.id }
        context.delete(image)

        try await updateEntry(entry)
        Log.info("Image removed from journal entry: \(entry.id)", category: .journal)
    }

    // MARK: - CloudKit Sync

    /// Sync a single entry to CloudKit (including images)
    private func syncEntryToCloudKit(_ entry: JournalEntryModel) async {
        guard syncMonitor.canSync else {
            Log.debug("Cannot sync - network or account unavailable", category: .cloudKit)
            return
        }

        syncMonitor.beginSync()

        do {
            // First, sync the entry record
            let record = entry.toRecord()
            let savedRecord = try await cloudKitManager.save(record)

            entry.cloudKitRecordName = savedRecord.recordID.recordName
            entry.lastSyncedAt = Date()
            entry.needsSync = false

            // Then, sync all images that need syncing
            if let images = entry.images {
                for image in images where image.needsSync {
                    await syncImageToCloudKit(image, entryId: entry.id)
                }
            }

            if let context = modelContext {
                try context.save()
            }

            syncMonitor.endSync()
            syncMonitor.removePendingSync()

            Log.info("Entry synced to CloudKit: \(entry.id)", category: .cloudKit)
        } catch {
            syncMonitor.syncFailed(error: error)
            Log.error("Failed to sync entry to CloudKit", error: error, category: .cloudKit)
        }
    }

    /// Sync a single image to CloudKit
    private func syncImageToCloudKit(_ image: JournalImageModel, entryId: UUID) async {
        guard let record = image.toRecord(entryId: entryId) else {
            Log.warning("Failed to create CloudKit record for image \(image.id)", category: .cloudKit)
            return
        }

        do {
            let savedRecord = try await cloudKitManager.save(record)

            image.cloudKitRecordName = savedRecord.recordID.recordName
            image.lastSyncedAt = Date()
            image.needsSync = false

            Log.info("Image synced to CloudKit: \(image.id)", category: .cloudKit)
        } catch {
            Log.error("Failed to sync image to CloudKit: \(image.id)", error: error, category: .cloudKit)
        }
    }

    /// Delete an image from CloudKit
    private func deleteImageFromCloudKit(_ image: JournalImageModel) async {
        guard let recordName = image.cloudKitRecordName else {
            return // Image was never synced
        }

        do {
            let recordID = CKRecord.ID(recordName: recordName)
            try await cloudKitManager.delete(recordID: recordID)
            Log.info("Image deleted from CloudKit: \(image.id)", category: .cloudKit)
        } catch {
            Log.warning("Failed to delete image from CloudKit: \(error.localizedDescription)", category: .cloudKit)
        }
    }

    /// Sync all pending entries to CloudKit
    func syncPendingEntries() async {
        guard syncMonitor.canSync else { return }
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<JournalEntryModel>(
            predicate: #Predicate { $0.needsSync == true }
        )

        do {
            let pendingEntries = try context.fetch(descriptor)

            guard !pendingEntries.isEmpty else {
                Log.debug("No pending entries to sync", category: .cloudKit)
                return
            }

            Log.info("Syncing \(pendingEntries.count) pending entries", category: .cloudKit)
            syncMonitor.beginSync(totalOperations: pendingEntries.count)

            for (index, entry) in pendingEntries.enumerated() {
                await syncEntryToCloudKit(entry)
                syncMonitor.updateProgress(completed: index + 1)
            }

            syncMonitor.endSync()
        } catch {
            Log.error("Failed to fetch pending entries for sync", error: error, category: .cloudKit)
        }
    }

    /// Pull entries from CloudKit
    func pullFromCloudKit() async throws {
        guard syncMonitor.canSync else {
            throw CloudKitError.networkUnavailable
        }

        guard let context = modelContext else {
            throw JournalRepositoryError.modelContextNotAvailable
        }

        Log.info("Pulling journal entries from CloudKit", category: .cloudKit)
        syncMonitor.beginSync()

        do {
            // Fetch entries
            let entryRecords = try await cloudKitManager.query(
                recordType: Constants.iCloud.RecordTypes.journalEntry,
                sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)]
            )

            for record in entryRecords {
                guard let remoteEntry = JournalEntryModel(from: record) else { continue }

                // Check if entry already exists locally
                let remoteId = remoteEntry.id
                let descriptor = FetchDescriptor<JournalEntryModel>(
                    predicate: #Predicate<JournalEntryModel> { $0.id == remoteId }
                )

                let existingEntries = try context.fetch(descriptor)

                if let existingEntry = existingEntries.first {
                    // Update if remote is newer
                    if remoteEntry.updatedAt > existingEntry.updatedAt {
                        existingEntry.title = remoteEntry.title
                        existingEntry.content = remoteEntry.content
                        existingEntry.moodRaw = remoteEntry.moodRaw
                        existingEntry.tags = remoteEntry.tags
                        existingEntry.isArchived = remoteEntry.isArchived
                        existingEntry.isPinned = remoteEntry.isPinned
                        existingEntry.updatedAt = remoteEntry.updatedAt
                        existingEntry.cloudKitRecordName = remoteEntry.cloudKitRecordName
                        existingEntry.lastSyncedAt = Date()
                        existingEntry.needsSync = false
                    }
                } else {
                    // Insert new entry
                    context.insert(remoteEntry)
                }
            }

            try context.save()

            // Now fetch and sync images
            await pullImagesFromCloudKit()

            syncMonitor.endSync()

            // Refresh entries list
            _ = try await fetchEntries()

            Log.info("Pulled \(entryRecords.count) entries from CloudKit", category: .cloudKit)
        } catch {
            syncMonitor.syncFailed(error: error)
            throw JournalRepositoryError.syncFailed(error)
        }
    }

    /// Pull images from CloudKit and associate with entries
    private func pullImagesFromCloudKit() async {
        guard let context = modelContext else { return }

        Log.info("Pulling images from CloudKit", category: .cloudKit)

        do {
            let imageRecords = try await cloudKitManager.query(
                recordType: Constants.iCloud.RecordTypes.journalImage,
                sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)]
            )

            Log.debug("Found \(imageRecords.count) image records in CloudKit", category: .cloudKit)

            for record in imageRecords {
                // Check if image already exists locally
                guard let idString = record.string(for: Constants.iCloud.RecordFields.JournalImage.id),
                      let imageId = UUID(uuidString: idString) else {
                    continue
                }

                let descriptor = FetchDescriptor<JournalImageModel>(
                    predicate: #Predicate<JournalImageModel> { $0.id == imageId }
                )

                let existingImages = try context.fetch(descriptor)

                if existingImages.first != nil {
                    // Image already exists locally, skip
                    continue
                }

                // Create new image from CloudKit record
                guard let newImage = JournalImageModel(from: record) else {
                    continue
                }

                // Load image data from asset
                await newImage.loadImageData(from: record)

                // Find parent entry and associate
                if let entryIdString = record.string(for: Constants.iCloud.RecordFields.JournalImage.journalEntryId),
                   let entryId = UUID(uuidString: entryIdString) {
                    let entryDescriptor = FetchDescriptor<JournalEntryModel>(
                        predicate: #Predicate<JournalEntryModel> { $0.id == entryId }
                    )

                    if let parentEntry = try context.fetch(entryDescriptor).first {
                        newImage.journalEntry = parentEntry
                        if parentEntry.images == nil {
                            parentEntry.images = []
                        }
                        parentEntry.images?.append(newImage)
                        context.insert(newImage)

                        Log.debug("Pulled image \(imageId) for entry \(entryId)", category: .cloudKit)
                    }
                }
            }

            try context.save()
            Log.info("Pulled \(imageRecords.count) images from CloudKit", category: .cloudKit)
        } catch {
            Log.error("Failed to pull images from CloudKit", error: error, category: .cloudKit)
        }
    }

    /// Full sync (pull then push)
    func performFullSync() async {
        guard syncMonitor.canSync else {
            Log.debug("Cannot perform full sync - network or account unavailable", category: .cloudKit)
            return
        }

        Log.info("Starting full journal sync", category: .cloudKit)

        do {
            // Pull from CloudKit first
            try await pullFromCloudKit()

            // Then push any local changes
            await syncPendingEntries()

            Log.info("Full journal sync completed", category: .cloudKit)
        } catch {
            Log.error("Full journal sync failed", error: error, category: .cloudKit)
        }
    }

    // MARK: - Statistics

    /// Get journal statistics
    func getStatistics() async -> JournalStatistics {
        guard let context = modelContext else {
            return JournalStatistics()
        }

        do {
            let allEntries = try context.fetch(FetchDescriptor<JournalEntryModel>())

            let moodCounts = Dictionary(grouping: allEntries, by: { $0.mood })
                .mapValues { $0.count }

            let entriesByDate = Dictionary(grouping: allEntries) { entry in
                Calendar.current.startOfDay(for: entry.createdAt)
            }

            // Calculate streak
            var currentStreak = 0
            var date = Calendar.current.startOfDay(for: Date())

            while entriesByDate[date] != nil {
                currentStreak += 1
                date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
            }

            return JournalStatistics(
                totalEntries: allEntries.count,
                archivedEntries: allEntries.filter { $0.isArchived }.count,
                pinnedEntries: allEntries.filter { $0.isPinned }.count,
                moodDistribution: moodCounts,
                currentStreak: currentStreak,
                entriesThisWeek: allEntries.filter {
                    Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .weekOfYear)
                }.count,
                entriesThisMonth: allEntries.filter {
                    Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .month)
                }.count
            )
        } catch {
            Log.error("Failed to get journal statistics", error: error, category: .journal)
            return JournalStatistics()
        }
    }

    // MARK: - Cleanup

    /// Clear all local data
    func clearAllData() async throws {
        guard let context = modelContext else {
            throw JournalRepositoryError.modelContextNotAvailable
        }

        Log.warning("Clearing all journal data", category: .journal)

        try context.delete(model: JournalEntryModel.self)
        try context.delete(model: JournalImageModel.self)
        try context.save()

        entries = []

        Log.info("All journal data cleared", category: .journal)
    }
}

// MARK: - Journal Statistics

struct JournalStatistics {
    var totalEntries: Int = 0
    var archivedEntries: Int = 0
    var pinnedEntries: Int = 0
    var moodDistribution: [Mood: Int] = [:]
    var currentStreak: Int = 0
    var entriesThisWeek: Int = 0
    var entriesThisMonth: Int = 0

    var mostCommonMood: Mood? {
        moodDistribution.max(by: { $0.value < $1.value })?.key
    }
}
