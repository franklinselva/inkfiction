//
//  ReflectView.swift
//  InkFiction
//
//  Main view for the Reflect feature with mood visualization using organic mood orb cluster
//

import SwiftData
import SwiftUI

// MARK: - Reflect View

struct ReflectView: View {
    @Environment(\.themeManager) private var themeManager
    @Query(
        filter: #Predicate<JournalEntryModel> { !$0.isArchived },
        sort: \JournalEntryModel.createdAt, order: .reverse,
        animation: .default
    )
    private var entries: [JournalEntryModel]

    @State private var viewModel = ReflectViewModel()
    @State private var moodOrbData: [OrganicMoodOrbCluster.MoodOrbData] = []
    @State private var isViewActive = false
    @State private var loadTask: Task<Void, Never>?

    @Binding var scrollOffset: CGFloat

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                // Fixed navigation header (isolated from orb animations)
                NavigationHeaderView(
                    config: NavigationHeaderConfig(
                        title: "Reflect",
                        subtitle: moodOrbData.isEmpty
                            ? "No moods tracked"
                            : "\(moodOrbData.count) moods • \(filteredEntries.count) entries",
                        leftButton: .avatar(action: {}),
                        rightButton: .menu("line.3.horizontal.decrease.circle") {
                            timeFilterMenu()
                        }
                    ),
                    scrollOffset: 0
                )
                .zIndex(100)
                .background(Color.clear)

                // Orb cluster container (animation-isolated)
                if isViewActive {
                    if filteredEntries.isEmpty {
                        emptyStateView
                    } else {
                        OrganicMoodOrbCluster(
                            moodData: moodOrbData,
                            timeframe: viewModel.timeframe
                        )
                        .ignoresSafeArea(edges: .bottom)
                        .animation(nil, value: moodOrbData)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 120)
        }
        .onAppear {
            isViewActive = true
            viewModel.updateWithEntries(entries)
            loadMoodOrbData()
        }
        .onDisappear {
            isViewActive = false
            loadTask?.cancel()
            loadTask = nil
        }
        .onChange(of: entries) { _, newEntries in
            viewModel.updateWithEntries(newEntries)
            scheduleMoodOrbDataLoad()
        }
        .onChange(of: viewModel.timeframe) { _, _ in
            viewModel.updateWithEntries(entries)
            scheduleMoodOrbDataLoad()
        }
    }

    // MARK: - Filtered Entries

    private var filteredEntries: [JournalEntryModel] {
        let dateRange = viewModel.timeframe.dateRange()
        // Apply limit to prevent processing too many entries
        return entries.prefix(500).filter { entry in
            !entry.isArchived && dateRange.contains(entry.createdAt)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 60))
                .foregroundColor(
                    themeManager.currentTheme.textSecondaryColor.opacity(0.5)
                )

            Text("No journal entries yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

            Text("Start journaling to see your mood reflections")
                .font(.system(size: 16))
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Load Mood Orb Data

    /// Schedules mood orb data loading with debouncing to prevent redundant calls
    private func scheduleMoodOrbDataLoad() {
        guard isViewActive else { return }

        // Cancel any pending load task
        loadTask?.cancel()

        // Schedule new load with 150ms debounce
        loadTask = Task {
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms

            guard !Task.isCancelled else { return }

            await MainActor.run {
                loadMoodOrbData()
            }
        }
    }

    private func loadMoodOrbData() {
        Log.debug("Loading mood data for ReflectView", category: .moodAnalysis)
        Log.debug("ViewModel has \(viewModel.moodData.count) mood data entries", category: .moodAnalysis)

        moodOrbData = viewModel.moodData.map { data in
            let moodEntries = viewModel.entriesForMood(data.mood)
            Log.debug("Mood \(data.mood.rawValue) has \(moodEntries.count) entries", category: .moodAnalysis)

            let orbMoodType = GlassmorphicMoodOrb.MoodType(from: data.mood)

            return OrganicMoodOrbCluster.MoodOrbData(
                id: data.id,
                mood: orbMoodType,
                entryCount: data.entryCount,
                lastUpdated: data.lastEntryDate,
                entries: moodEntries
            )
        }

        Log.info("Loaded \(moodOrbData.count) mood orbs with entries for display", category: .moodAnalysis)
    }

    // MARK: - Time Filter Menu

    @ViewBuilder
    private func timeFilterMenu() -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 4) {
                ForEach(TimeFrame.allCases, id: \.self) { frame in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.timeframe = frame
                        }
                    } label: {
                        HStack {
                            Text(frame.rawValue)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                            Spacer()

                            if viewModel.timeframe == frame {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReflectView(scrollOffset: .constant(0))
    }
    .environment(\.themeManager, ThemeManager())
    .modelContainer(for: JournalEntryModel.self, inMemory: true)
}
