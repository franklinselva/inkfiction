//
//  TimelineView.swift
//  InkFiction
//
//  Main Timeline view with day/week/month filtering
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<JournalEntryModel> { !$0.isArchived },
           sort: \JournalEntryModel.createdAt, order: .reverse)
    private var entries: [JournalEntryModel]

    @State private var selectedFilter: TimelineFilter = .day
    @Binding var scrollOffset: CGFloat
    @Namespace private var filterNamespace
    @State private var timelineImages: [UUID: [UUID: UIImage]] = [:]

    private var insightsData: InsightsData {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let entriesThisYear = entries.filter { entry in
            calendar.component(.year, from: entry.createdAt) == currentYear
        }

        let uniqueDays = Set(
            entriesThisYear.map { entry in
                calendar.startOfDay(for: entry.createdAt)
            })

        let currentStreak = calculateCurrentStreak(from: entries, calendar: calendar)

        return InsightsData(
            entriesThisYear: entriesThisYear.count,
            daysJournaled: uniqueDays.count,
            currentStreak: currentStreak
        )
    }

    private func calculateCurrentStreak(from entries: [JournalEntryModel], calendar: Calendar) -> Int {
        guard !entries.isEmpty else { return 0 }

        let uniqueDaysSet = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
        let sortedUniqueDays = uniqueDaysSet.sorted(by: >)

        guard !sortedUniqueDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let mostRecentDate = sortedUniqueDays.first!

        let daysSinceLastEntry =
            calendar.dateComponents([.day], from: mostRecentDate, to: today).day ?? 0

        if daysSinceLastEntry > 1 {
            return 0
        }

        if sortedUniqueDays.count == 1 {
            return 1
        }

        var streak = 1
        for i in 0..<(sortedUniqueDays.count - 1) {
            let currentDay = sortedUniqueDays[i]
            let previousDay = sortedUniqueDays[i + 1]

            let daysDiff =
                calendar.dateComponents([.day], from: previousDay, to: currentDay).day ?? 0

            if daysDiff == 1 {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    private var filteredEntries: [JournalEntryModel] {
        entries.sorted { $0.createdAt > $1.createdAt }
    }

    private var groupedEntries: [(date: Date, entries: [JournalEntryModel])] {
        let calendar = Calendar.current

        switch selectedFilter {
        case .day:
            let grouped = Dictionary(grouping: filteredEntries) { entry in
                calendar.startOfDay(for: entry.createdAt)
            }
            return grouped.sorted { $0.key > $1.key }.map {
                (date: $0.key, entries: $0.value.sorted { $0.createdAt > $1.createdAt })
            }

        case .week:
            let grouped = Dictionary(grouping: filteredEntries) { entry in
                let weekday = calendar.component(.weekday, from: entry.createdAt)
                let daysToSubtract = (weekday - calendar.firstWeekday + 7) % 7
                return calendar.date(
                    byAdding: .day, value: -daysToSubtract,
                    to: calendar.startOfDay(for: entry.createdAt)) ?? entry.createdAt
            }
            return grouped.sorted { $0.key > $1.key }.map {
                (date: $0.key, entries: $0.value.sorted { $0.createdAt > $1.createdAt })
            }

        case .month:
            let grouped = Dictionary(grouping: filteredEntries) { entry in
                let components = calendar.dateComponents([.year, .month], from: entry.createdAt)
                return calendar.date(from: components) ?? entry.createdAt
            }
            return grouped.sorted { $0.key > $1.key }.map {
                (date: $0.key, entries: $0.value.sorted { $0.createdAt > $1.createdAt })
            }
        }
    }

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Insights Card
                        InsightsCard(data: insightsData)
                            .padding(.horizontal, 16)
                            .padding(.top, 20)

                        // Filter Tabs
                        TimelineFilterView(
                            selectedFilter: $selectedFilter,
                            namespace: filterNamespace
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // Timeline content
                        if filteredEntries.isEmpty {
                            EmptyTimelineView(filter: selectedFilter)
                                .padding(.top, 40)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        } else {
                            TimelineContentView(
                                groupedEntries: groupedEntries,
                                filter: selectedFilter,
                                scrollOffset: scrollOffset,
                                timelineImages: timelineImages
                            )
                            .padding(.horizontal, 16)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }

                        Spacer(minLength: 120)
                    }
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    scrollOffset = -newValue
                }
            }
        }
        .navigationBarHidden(true)
        .navigationTitle("Timeline")
        .onAppear {
            scrollOffset = 0
        }
        .task {
            extractTimelineImages()
        }
        .task(id: entries.count) {
            extractTimelineImages()
        }
    }

    @MainActor
    private func extractTimelineImages() {
        Log.debug("Starting image extraction from \(entries.count) total entries", category: .data)

        var imagesDict: [UUID: [UUID: UIImage]] = [:]

        for entry in entries {
            if let images = entry.images, !images.isEmpty {
                var entryImages: [UUID: UIImage] = [:]
                for image in images {
                    if let imageData = image.imageData,
                       let uiImage = UIImage(data: imageData) {
                        entryImages[image.id] = uiImage
                    }
                }
                if !entryImages.isEmpty {
                    imagesDict[entry.id] = entryImages
                }
            }
        }

        timelineImages = imagesDict
        Log.debug("Extracted images from \(imagesDict.count) entries", category: .data)
    }
}

// MARK: - Insights Card

struct InsightsCard: View {
    @Environment(\.themeManager) private var themeManager
    let data: InsightsData

    private var entriesText: String {
        data.entriesThisYear <= 1 ? "Entry This Year" : "Entries This Year"
    }

    private var daysText: String {
        data.daysJournaled <= 1 ? "Active Day" : "Active Days"
    }

    private var streakText: String {
        data.currentStreak <= 1 ? "Day Streak" : "Days Streak"
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 20) {
                // Large number on the left (65% width)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Insights")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    Text("\(data.entriesThisYear)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    Text(entriesText)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
                .frame(width: geometry.size.width * 0.65, alignment: .leading)

                Spacer()

                // Metrics grid on the right (35% width)
                VStack(alignment: .leading, spacing: 16) {
                    // Days Journaled
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.accentColor)

                            Text("\(data.daysJournaled)")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        }

                        Text(daysText)
                            .font(.caption2)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }

                    // Current Streak
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.accentColor)

                            Text("\(data.currentStreak)")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        }

                        Text(streakText)
                            .font(.caption2)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                }
                .frame(width: geometry.size.width * 0.35, alignment: .leading)
            }
        }
        .frame(height: 120)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentTheme.accentColor.opacity(0.15))
                .shadow(
                    color: themeManager.currentTheme.accentColor.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
}

// MARK: - Timeline Content View

struct TimelineContentView: View {
    @Environment(\.themeManager) private var themeManager
    let groupedEntries: [(date: Date, entries: [JournalEntryModel])]
    let filter: TimelineFilter
    let scrollOffset: CGFloat
    let timelineImages: [UUID: [UUID: UIImage]]

    var body: some View {
        VStack(alignment: .leading, spacing: filter == .day ? 20 : 24) {
            ForEach(Array(groupedEntries.enumerated()), id: \.element.date) { index, group in
                TimelinePeriodCardWrapper(
                    group: group,
                    filter: filter,
                    isFirst: index == 0,
                    isLast: index == groupedEntries.count - 1,
                    scrollOffset: scrollOffset,
                    index: index,
                    timelineImages: timelineImages
                )
            }
        }
    }
}

// MARK: - Timeline Period Card Wrapper

struct TimelinePeriodCardWrapper: View {
    let group: (date: Date, entries: [JournalEntryModel])
    let filter: TimelineFilter
    let isFirst: Bool
    let isLast: Bool
    let scrollOffset: CGFloat
    let index: Int
    let timelineImages: [UUID: [UUID: UIImage]]

    @Environment(\.themeManager) private var themeManager

    // Compute merged images for all entries in this group
    private var mergedImages: [UUID: UIImage] {
        var result: [UUID: UIImage] = [:]
        for entry in group.entries {
            if let entryImages = timelineImages[entry.id] {
                result.merge(entryImages) { current, _ in current }
            }
        }
        return result
    }

    var body: some View {
        let periodGroup = DayGroupedEntry(
            date: group.date,
            entries: group.entries,
            loadedImages: mergedImages
        )

        VisualMemoryPeriodCard(
            periodGroup: periodGroup,
            filter: filter,
            isFirst: isFirst,
            isLast: isLast,
            scrollOffset: scrollOffset
        )
        .transition(
            .asymmetric(
                insertion: .push(from: .trailing).combined(with: .opacity),
                removal: .push(from: .leading).combined(with: .opacity)
            )
        )
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8)
                .delay(Double(index) * 0.05),
            value: group.date
        )
    }
}
