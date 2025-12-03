//
//  JournalListView.swift
//  InkFiction
//
//  Main journal list view with entries, search, and filtering
//

import SwiftData
import SwiftUI

struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themeManager) private var themeManager
    @Environment(Router.self) private var router

    @Bindable var viewModel: JournalListViewModel
    @Binding var scrollOffset: CGFloat

    @State private var hasLoadedInitialEntries = false

    var body: some View {
        ZStack {
            // Background
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation Header
                navigationHeader

                if viewModel.isLoading && viewModel.entries.isEmpty {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Spacer()
                } else {
                    journalList
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: Binding(
            get: { viewModel.selectedEntry },
            set: { newValue in
                viewModel.selectedEntryId = newValue?.id
            }
        )) { selectedEntry in
            if viewModel.entries.contains(where: { $0.id == selectedEntry.id }) {
                JournalEntryDetailView(
                    entry: selectedEntry,
                    onDelete: { entry in
                        viewModel.deleteEntryWithAnimation(entry)
                    },
                    onEdit: { entry in
                        viewModel.selectedEntryId = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            router.push(.journalEditor(entryId: entry.id))
                        }
                    }
                )
            } else {
                Color.clear
                    .onAppear {
                        viewModel.selectedEntryId = nil
                    }
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            scrollOffset = 0
        }
        .task {
            if !hasLoadedInitialEntries {
                hasLoadedInitialEntries = true
                viewModel.loadEntries()
            }
        }
        .onChange(of: viewModel.filterState) { _, _ in
            viewModel.updateFilteredEntries()
        }
        .onChange(of: viewModel.sortOrder) { _, _ in
            viewModel.updateFilteredEntries()
        }
        .onReceive(NotificationCenter.default.publisher(for: .journalEntryUpdated)) { _ in
            viewModel.loadEntries()
        }
    }

    // MARK: - Navigation Header

    private var navigationHeader: some View {
        NavigationHeaderView(
            config: NavigationHeaderConfig(
                title: navigationHeaderTitle,
                leftButton: viewModel.isSelectionMode
                    ? .icon("xmark.circle.fill", action: { viewModel.toggleSelectionMode() })
                    : .icon("checkmark.circle", action: { viewModel.toggleSelectionMode() }),
                rightButton: viewModel.isSelectionMode
                    ? (viewModel.selectedEntries.isEmpty
                        ? .none
                        : .icon("ellipsis.circle.fill", action: {}))
                    : .icon(
                        viewModel.filterState.showArchived ? "archivebox.fill" : "archivebox",
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                viewModel.filterState.showArchived.toggle()
                            }
                        }
                    )
            ),
            scrollOffset: scrollOffset
        )
        .overlay(alignment: .topTrailing) {
            // Selection menu overlay when in selection mode with items selected
            if viewModel.isSelectionMode && !viewModel.selectedEntries.isEmpty {
                Menu {
                    Button(action: {
                        if viewModel.selectedEntries.count == viewModel.filteredEntries.count {
                            viewModel.deselectAll()
                        } else {
                            viewModel.selectAll()
                        }
                    }) {
                        Label(
                            viewModel.selectedEntries.count == viewModel.filteredEntries.count
                                ? "Deselect All" : "Select All",
                            systemImage: viewModel.selectedEntries.count == viewModel.filteredEntries.count
                                ? "checkmark.circle" : "checkmark.circle.fill"
                        )
                    }

                    Divider()

                    Button(action: {
                        viewModel.bulkArchive()
                    }) {
                        Label(
                            viewModel.filterState.showArchived
                                ? "Unarchive (\(viewModel.selectedEntries.count))"
                                : "Archive (\(viewModel.selectedEntries.count))",
                            systemImage: viewModel.filterState.showArchived
                                ? "tray.and.arrow.up.fill" : "archivebox.fill"
                        )
                    }

                    Button(role: .destructive) {
                        viewModel.bulkDelete()
                    } label: {
                        Label(
                            "Delete (\(viewModel.selectedEntries.count))",
                            systemImage: "trash.fill"
                        )
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.surfaceColor)
                            .frame(width: 44, height: 44)

                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.accentColor)

                        Circle()
                            .stroke(
                                themeManager.currentTheme.strokeColor.opacity(0.3),
                                lineWidth: 1.5
                            )
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.trailing, 16)
                .padding(.top, 12)
            }
        }
    }

    private var navigationHeaderTitle: String {
        if viewModel.isSelectionMode {
            return "\(viewModel.selectedEntries.count) Selected"
        }
        return viewModel.filterState.showArchived ? "Archived" : "Journal"
    }

    // MARK: - Search and Filter View

    private var searchAndFilterView: some View {
        VStack(spacing: 12) {
            ExpandableSearchBar(filterState: $viewModel.filterState)

            // Clear Filters Button
            if viewModel.filterState.isActive
                && viewModel.filterState.activeFilterCount > (viewModel.filterState.showArchived ? 1 : 0) {
                HStack {
                    Text("\(viewModel.filteredEntries.count) results")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            let preserveArchived = viewModel.filterState.showArchived
                            viewModel.filterState.reset()
                            viewModel.filterState.showArchived = preserveArchived
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Clear Filters")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.15))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Journal List

    @ViewBuilder
    private var journalList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Search and Filter
                searchAndFilterView
                    .padding(.horizontal, 16)

                // Entries
                if viewModel.filteredEntries.isEmpty {
                    emptyStateView
                        .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredEntries) { entry in
                            Button(action: {
                                if viewModel.isSelectionMode {
                                    viewModel.toggleSelection(for: entry)
                                } else {
                                    viewModel.selectEntry(entry.id)
                                }
                            }) {
                                JournalEntryCard(
                                    entry: entry,
                                    isSelectionMode: viewModel.isSelectionMode,
                                    isSelected: viewModel.selectedEntries.contains(entry.id)
                                )
                            }
                            .buttonStyle(JournalCardButtonStyle())
                            .contextMenu {
                                if !viewModel.isSelectionMode {
                                    Button {
                                        viewModel.togglePinEntry(entry)
                                    } label: {
                                        Label(
                                            entry.isPinned ? "Unpin" : "Pin",
                                            systemImage: entry.isPinned ? "pin.slash.fill" : "pin.fill"
                                        )
                                    }

                                    Button {
                                        router.push(.journalEditor(entryId: entry.id))
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }

                                    Button {
                                        if entry.isArchived {
                                            viewModel.unarchiveEntry(entry)
                                        } else {
                                            viewModel.archiveEntry(entry)
                                        }
                                    } label: {
                                        Label(
                                            entry.isArchived ? "Unarchive" : "Archive",
                                            systemImage: entry.isArchived ? "tray.and.arrow.up.fill" : "archivebox.fill"
                                        )
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        viewModel.deleteEntryWithAnimation(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Bottom spacer for tab bar
                Spacer(minLength: 120)
            }
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, newValue in
            scrollOffset = -newValue
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: viewModel.filterState.showArchived ? "archivebox" : "book.closed")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)

            Text(viewModel.filterState.showArchived ? "No archived entries" : "No entries yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

            Text(
                viewModel.filterState.showArchived
                    ? "Archived entries will appear here"
                    : "Start your journaling journey by creating your first entry"
            )
            .font(.body)
            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Journal Entry Detail View

struct JournalEntryDetailView: View {
    let entry: JournalEntry
    let onDelete: (JournalEntry) -> Void
    let onEdit: (JournalEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @Environment(Router.self) private var router

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(entry.title.isEmpty ? "Untitled" : entry.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                            Spacer()

                            // Mood indicator
                            HStack(spacing: 4) {
                                Image(systemName: entry.mood.sfSymbolName)
                                Text(entry.mood.rawValue)
                                    .font(.caption)
                            }
                            .foregroundColor(entry.mood.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(entry.mood.color.opacity(0.2))
                            )
                        }

                        Text(entry.createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }

                    // Content
                    Text(entry.content)
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    // Tags
                    if !entry.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(entry.tags, id: \.self) { tag in
                                    TagChip(tag: tag)
                                }
                            }
                        }
                    }

                    // Images
                    if entry.hasImages {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Images")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(entry.images) { image in
                                        if let uiImage = image.uiImage {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 200, height: 200)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .overlay(
                                                    image.isAIGenerated
                                                        ? AnyView(
                                                            VStack {
                                                                Spacer()
                                                                HStack {
                                                                    HStack(spacing: 2) {
                                                                        Image(systemName: "sparkles")
                                                                            .font(.system(size: 10, weight: .bold))
                                                                        Text("AI")
                                                                            .font(.system(size: 9, weight: .bold))
                                                                    }
                                                                    .foregroundColor(.white)
                                                                    .padding(.horizontal, 5)
                                                                    .padding(.vertical, 2)
                                                                    .background(
                                                                        Capsule()
                                                                            .fill(
                                                                                LinearGradient(
                                                                                    colors: themeManager.currentTheme.gradientColors,
                                                                                    startPoint: .topLeading,
                                                                                    endPoint: .bottomTrailing
                                                                                )
                                                                            )
                                                                    )
                                                                    .padding(6)

                                                                    Spacer()
                                                                }
                                                            }
                                                        )
                                                        : AnyView(EmptyView())
                                                )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            dismiss()
                            onEdit(entry)
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive, action: {
                            onDelete(entry)
                            dismiss()
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            }
        }
    }
}
