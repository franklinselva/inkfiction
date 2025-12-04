//
//  JournalListViewModel.swift
//  InkFiction
//
//  ViewModel for journal list view - manages entries, filtering, and selection
//

import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class JournalListViewModel {

    // MARK: - Published State

    private(set) var entries: [JournalEntry] = []
    private(set) var filteredEntries: [JournalEntry] = []
    var selectedEntryId: UUID?
    var filterState = JournalFilterState()
    var sortOrder: JournalSortOrder = .dateDescending
    var isSelectionMode: Bool = false
    var selectedEntries: Set<UUID> = []
    private(set) var isLoading: Bool = false
    private(set) var error: Error?

    // MARK: - Dependencies

    private var modelContext: ModelContext?
    private let repository = JournalRepository.shared

    // MARK: - Incremental Filter State

    private var previousFilterState: JournalFilterState?
    private var previousSearchText: String = ""
    private var previousSortOrder: JournalSortOrder?
    private var didReceiveEntriesUpdate: Bool = false

    // MARK: - Initialization

    init() {
        Log.debug("JournalListViewModel initialized", category: .journal)
    }

    /// Set the model context for SwiftData operations
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        repository.setModelContext(context)
        Log.debug("Model context set for JournalListViewModel", category: .journal)
    }

    // MARK: - Computed Properties

    /// Currently selected entry
    var selectedEntry: JournalEntry? {
        guard let id = selectedEntryId else { return nil }
        return entries.first(where: { $0.id == id })
    }

    /// Count of archived entries
    var archivedEntriesCount: Int {
        entries.filter(\.isArchived).count
    }

    /// Legacy property for compatibility
    var searchText: String {
        get { filterState.searchText }
        set { filterState.searchText = newValue }
    }

    // MARK: - Entry Loading

    func loadEntries() {
        Task {
            await loadEntriesAsync()
        }
    }

    func loadEntriesAsync() async {
        guard modelContext != nil else {
            Log.warning("Cannot load entries - model context not set", category: .journal)
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Include archived entries so they can be displayed when user toggles archive view
            let filter = JournalFilter(includeArchived: true)
            let models = try await repository.fetchEntries(
                filter: filter,
                sort: .dateDescending
            )

            entries = models.map { JournalEntry(from: $0) }
            didReceiveEntriesUpdate = true
            updateFilteredEntries()

            Log.info("Loaded \(entries.count) journal entries", category: .journal)
        } catch {
            self.error = error
            Log.error("Failed to load entries", error: error, category: .journal)
        }
    }

    // MARK: - Filtering

    func updateFilteredEntries() {
        // Check if we can use incremental search
        let canUseIncrementalSearch = !didReceiveEntriesUpdate && canApplyIncrementalSearch()

        if canUseIncrementalSearch {
            Log.debug("Using incremental search filter", category: .journal)
            let incrementallyFiltered = applyIncrementalSearch(
                on: filteredEntries,
                searchText: filterState.searchText
            )
            filteredEntries = incrementallyFiltered
            cacheFilterState()
            return
        }

        // Full filter
        var filtered = entries

        // Filter archived entries
        if !filterState.showArchived {
            filtered = filtered.filter { !$0.isArchived }
        } else {
            filtered = filtered.filter(\.isArchived)
        }

        // Apply date range filter
        let dateRange = filterState.dateRange.getDateRange(
            customStart: filterState.customStartDate,
            customEnd: filterState.customEndDate
        )

        if let startDate = dateRange.start {
            filtered = filtered.filter { $0.createdAt >= startDate }
        }

        if let endDate = dateRange.end {
            filtered = filtered.filter { $0.createdAt <= endDate }
        }

        // Apply search filter
        if !filterState.searchText.isEmpty {
            filtered = filtered.filter { entry in
                entry.title.localizedCaseInsensitiveContains(filterState.searchText) ||
                entry.content.localizedCaseInsensitiveContains(filterState.searchText) ||
                entry.tags.contains { $0.localizedCaseInsensitiveContains(filterState.searchText) }
            }
        }

        // Apply sorting
        filtered = applySorting(to: filtered)

        filteredEntries = filtered
        cacheFilterState()
    }

    private func canApplyIncrementalSearch() -> Bool {
        guard let previous = previousFilterState else { return false }

        let filtersCriteriaSame = (
            filterState.showArchived == previous.showArchived &&
            filterState.dateRange == previous.dateRange &&
            filterState.customStartDate == previous.customStartDate &&
            filterState.customEndDate == previous.customEndDate &&
            previousSortOrder == sortOrder
        )

        guard filtersCriteriaSame else { return false }

        let currentSearch = filterState.searchText
        guard !previousSearchText.isEmpty, !currentSearch.isEmpty else { return false }

        let previousLowercased = previousSearchText.lowercased()
        let currentLowercased = currentSearch.lowercased()

        return currentLowercased.hasPrefix(previousLowercased) && currentSearch.count > previousSearchText.count
    }

    private func applyIncrementalSearch(on entries: [JournalEntry], searchText: String) -> [JournalEntry] {
        entries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(searchText) ||
            entry.content.localizedCaseInsensitiveContains(searchText) ||
            entry.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private func applySorting(to entries: [JournalEntry]) -> [JournalEntry] {
        var sorted = entries

        switch sortOrder {
        case .dateDescending:
            sorted.sort {
                if $0.isPinned != $1.isPinned { return $0.isPinned }
                return $0.createdAt > $1.createdAt
            }
        case .dateAscending:
            sorted.sort {
                if $0.isPinned != $1.isPinned { return $0.isPinned }
                return $0.createdAt < $1.createdAt
            }
        case .titleAscending:
            sorted.sort {
                if $0.isPinned != $1.isPinned { return $0.isPinned }
                return $0.title < $1.title
            }
        case .titleDescending:
            sorted.sort {
                if $0.isPinned != $1.isPinned { return $0.isPinned }
                return $0.title > $1.title
            }
        }

        return sorted
    }

    private func cacheFilterState() {
        previousFilterState = filterState
        previousSearchText = filterState.searchText
        previousSortOrder = sortOrder
        didReceiveEntriesUpdate = false
    }

    // MARK: - Entry Selection

    func selectEntry(_ id: UUID) {
        selectedEntryId = id
        Log.info("Selected entry: \(id)", category: .journal)
    }

    func deselectEntry() {
        selectedEntryId = nil
        Log.info("Deselected entry", category: .journal)
    }

    // MARK: - Entry Operations

    func deleteEntry(_ entry: JournalEntry) {
        Task {
            guard let model = try? await repository.getEntry(by: entry.id) else { return }

            do {
                try await repository.deleteEntry(model)
                entries.removeAll { $0.id == entry.id }
                updateFilteredEntries()

                if selectedEntryId == entry.id {
                    selectedEntryId = nil
                }

                Log.info("Entry deleted: \(entry.id)", category: .journal)
            } catch {
                self.error = error
                Log.error("Failed to delete entry", error: error, category: .journal)
            }
        }
    }

    func deleteEntryWithAnimation(_ entry: JournalEntry) {
        // Clear selection first to dismiss any open sheets
        if selectedEntryId == entry.id {
            selectedEntryId = nil
        }

        deleteEntry(entry)
    }

    func archiveEntry(_ entry: JournalEntry) {
        Task {
            guard let model = try? await repository.getEntry(by: entry.id) else { return }

            do {
                try await repository.archiveEntry(model)

                // Incremental update: update the entry in place
                if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                    var updatedEntry = entries[index]
                    updatedEntry.isArchived = true
                    entries[index] = updatedEntry
                    updateFilteredEntries()
                }

                Log.info("Entry archived: \(entry.id)", category: .journal)
            } catch {
                self.error = error
                Log.error("Failed to archive entry", error: error, category: .journal)
            }
        }
    }

    func unarchiveEntry(_ entry: JournalEntry) {
        Task {
            guard let model = try? await repository.getEntry(by: entry.id) else { return }

            do {
                try await repository.unarchiveEntry(model)

                // Incremental update: update the entry in place
                if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                    var updatedEntry = entries[index]
                    updatedEntry.isArchived = false
                    entries[index] = updatedEntry
                    updateFilteredEntries()
                }

                Log.info("Entry unarchived: \(entry.id)", category: .journal)
            } catch {
                self.error = error
                Log.error("Failed to unarchive entry", error: error, category: .journal)
            }
        }
    }

    func togglePinEntry(_ entry: JournalEntry) {
        Task {
            guard let model = try? await repository.getEntry(by: entry.id) else { return }

            do {
                try await repository.togglePin(model)

                // Incremental update: update the entry in place
                if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                    var updatedEntry = entries[index]
                    updatedEntry.isPinned.toggle()
                    entries[index] = updatedEntry
                    updateFilteredEntries()
                }

                Log.info("Entry pin toggled: \(entry.id)", category: .journal)
            } catch {
                self.error = error
                Log.error("Failed to toggle pin", error: error, category: .journal)
            }
        }
    }

    // MARK: - Filter Operations

    func resetFilters() {
        filterState.reset()
        updateFilteredEntries()
        Log.debug("Filters reset", category: .journal)
    }

    // MARK: - Multi-Selection Operations

    func toggleSelectionMode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isSelectionMode.toggle()
            if !isSelectionMode {
                selectedEntries.removeAll()
            }
        }
    }

    func toggleSelection(for entry: JournalEntry) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
            if selectedEntries.contains(entry.id) {
                selectedEntries.remove(entry.id)
            } else {
                selectedEntries.insert(entry.id)
            }
        }
    }

    func selectAll() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedEntries = Set(filteredEntries.map(\.id))
        }
    }

    func deselectAll() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedEntries.removeAll()
        }
    }

    func bulkArchive() {
        Task {
            Log.info("Bulk archiving \(selectedEntries.count) entries", category: .journal)

            let entriesToArchive = selectedEntries

            await withTaskGroup(of: Void.self) { group in
                for id in entriesToArchive {
                    group.addTask {
                        if let model = try? await self.repository.getEntry(by: id) {
                            try? await self.repository.archiveEntry(model)
                        }
                    }
                }
            }

            // Incremental update: update all archived entries in place
            for id in entriesToArchive {
                if let index = entries.firstIndex(where: { $0.id == id }) {
                    var updatedEntry = entries[index]
                    updatedEntry.isArchived = true
                    entries[index] = updatedEntry
                }
            }

            isSelectionMode = false
            selectedEntries.removeAll()
            updateFilteredEntries()
        }
    }

    func bulkDelete() {
        Task {
            Log.info("Bulk deleting \(selectedEntries.count) entries", category: .journal)

            let entriesToDelete = selectedEntries

            await withTaskGroup(of: Void.self) { group in
                for id in entriesToDelete {
                    group.addTask {
                        if let model = try? await self.repository.getEntry(by: id) {
                            try? await self.repository.deleteEntry(model)
                        }
                    }
                }
            }

            // Incremental update: remove all deleted entries from array
            entries.removeAll { entriesToDelete.contains($0.id) }

            isSelectionMode = false
            selectedEntries.removeAll()
            updateFilteredEntries()
        }
    }
}
