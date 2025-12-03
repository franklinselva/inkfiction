//
//  EntriesDetailSheet.swift
//  InkFiction
//
//  Unified detail sheet for viewing entries (day, week, month)
//

import SwiftUI

struct EntriesDetailSheet: View {
    let periodGroup: DayGroupedEntry
    let filter: TimelineFilter
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeManager) private var themeManager
    @State private var showFullScreenGallery = false

    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Show summary only for week and month views
                        if filter != .day {
                            PeriodSummaryHeader(periodGroup: periodGroup, filter: filter)
                                .padding(.horizontal)
                        }

                        // Visual memories section
                        if !periodGroup.imageContainers.isEmpty {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Visual Memories")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                                    Spacer()

                                    Button(action: {
                                        showFullScreenGallery = true
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                .font(.system(size: 14))
                                            Text("Fullscreen")
                                                .font(.system(size: 14))
                                        }
                                        .foregroundColor(themeManager.currentTheme.accentColor)
                                    }
                                }
                                .padding(.horizontal)

                                SwipeableCardStack(
                                    cards: periodGroup.imageContainers,
                                    maxVisibleCards: min(4, periodGroup.imageContainers.count)
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: 450)
                                .padding(.bottom, 8)
                            }
                        }

                        // Divider
                        Rectangle()
                            .fill(themeManager.currentTheme.strokeColor.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal)

                        // Journal entries section
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Journal Entries")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                                .padding(.horizontal)

                            // For multi-day periods, group by day
                            if filter != .day {
                                let entriesByDay = Dictionary(grouping: periodGroup.entries) { entry in
                                    Calendar.current.startOfDay(for: entry.createdAt)
                                }.sorted { $0.key > $1.key }

                                ForEach(entriesByDay, id: \.key) { date, dayEntries in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(DateFormattingUtility.smartDayHeader(from: date))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                                            .padding(.horizontal)

                                        ForEach(
                                            dayEntries.sorted { $0.createdAt > $1.createdAt },
                                            id: \.id
                                        ) { entry in
                                            TimelineJournalEntryCard(entry: entry)
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                            } else {
                                // For day view, just list entries
                                ForEach(Array(periodGroup.entries.enumerated()), id: \.element.id) { index, entry in
                                    TimelineJournalEntryCard(entry: entry)
                                        .padding(.horizontal)
                                        .onTapGesture {
                                            selectedIndex = index
                                        }
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle(
                PeriodFormatterUtility.periodTitle(for: periodGroup.date, filter: filter)
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showFullScreenGallery) {
            FullScreenImageGallery(
                images: periodGroup.imageContainers,
                selectedIndex: 0
            )
        }
    }
}

// MARK: - Timeline Journal Entry Card

struct TimelineJournalEntryCard: View {
    let entry: JournalEntryModel
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: entry.mood.sfSymbolName)
                    .font(.system(size: 20))
                    .foregroundColor(entry.mood.color)

                Text(entry.mood.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Spacer()

                Text(DateFormattingUtility.time(from: entry.createdAt))
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
            }

            if !entry.title.isEmpty {
                Text(entry.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
            }

            Text(entry.content)
                .font(.system(size: 14))
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            if let images = entry.images, !images.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    Text("\(images.count) image\(images.count == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.backgroundColor.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(entry.mood.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Full Screen Image Gallery

struct FullScreenImageGallery: View {
    let images: [ImageContainer]
    @State var selectedIndex: Int
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor.edgesIgnoringSafeArea(.all)

            // Swipeable card stack in full screen
            SwipeableCardStack(
                cards: images,
                maxVisibleCards: min(4, images.count)
            )

            // Close button overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor.opacity(0.8))
                            .background(Circle().fill(themeManager.currentTheme.surfaceColor))
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}
