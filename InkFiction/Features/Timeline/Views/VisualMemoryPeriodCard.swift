//
//  VisualMemoryPeriodCard.swift
//  InkFiction
//
//  Visual memory card for week and month views in Timeline
//

import SwiftUI

struct VisualMemoryPeriodCard: View {
    @Environment(\.themeManager) private var themeManager
    let periodGroup: DayGroupedEntry
    let filter: TimelineFilter
    let isFirst: Bool
    let isLast: Bool
    let scrollOffset: CGFloat
    @State private var showingDetailSheet = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Period indicator with timeline connector below
            VStack(spacing: 0) {
                PeriodIndicatorView(date: periodGroup.date, filter: filter, isFirst: isFirst, scrollOffset: scrollOffset)
                    .padding(.bottom, 8)

                TimelineConnector(
                    isFirst: isFirst,
                    isLast: isLast,
                    scrollOffset: scrollOffset
                )
            }
            .frame(width: 50)

            Spacer()
                .frame(width: 18)

            // Visual memory stack container
            VStack(alignment: .leading, spacing: 12) {
                // Period header
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(PeriodFormatterUtility.periodLabel(for: periodGroup.date, filter: filter))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                        Text(PeriodFormatterUtility.periodSubLabel(for: periodGroup.date, filter: filter))
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                        HStack(spacing: 12) {
                            // Entry count
                            HStack(spacing: 4) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                                Text("\(periodGroup.entries.count) \(periodGroup.entries.count == 1 ? "entry" : "entries")")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                            }

                            // Image count
                            if !periodGroup.imageContainers.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "photo.stack")
                                        .font(.system(size: 12))
                                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                                    Text("\(periodGroup.imageContainers.count) memories")
                                        .font(.system(size: 12))
                                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                                }
                            }
                        }
                    }

                    Spacer()

                    // Dominant mood indicator
                    Image(systemName: periodGroup.dominantMood.sfSymbolName)
                        .font(.system(size: 28))
                        .foregroundColor(periodGroup.dominantMood.color)
                }
                .padding(.horizontal, 4)

                // Static card stack for images (view-only, tappable)
                if !periodGroup.imageContainers.isEmpty {
                    StaticCardStackView(
                        cards: Array(periodGroup.imageContainers.prefix(6)),
                        maxVisibleCards: min(3, periodGroup.imageContainers.count)
                    )
                    .onTapGesture {
                        showingDetailSheet = true
                    }
                } else {
                    // Fallback mood gradient if no images
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    periodGroup.dominantMood.color.opacity(0.3),
                                    periodGroup.dominantMood.color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: periodGroup.dominantMood.sfSymbolName)
                                    .font(.system(size: 48))
                                    .foregroundColor(periodGroup.dominantMood.color)

                                Text("No visual memories")
                                    .font(.system(size: 14))
                                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                            }
                        )
                        .onTapGesture {
                            showingDetailSheet = true
                        }
                }

                // Mood distribution
                if periodGroup.moodDistribution.count > 1 {
                    MoodDistributionView(moodDistribution: periodGroup.moodDistribution)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.vertical, 12)
        }
        .sheet(isPresented: $showingDetailSheet) {
            EntriesDetailSheet(
                periodGroup: periodGroup,
                filter: filter,
                selectedIndex: .constant(0)
            )
        }
    }
}

// MARK: - Period Summary Header

struct PeriodSummaryHeader: View {
    let periodGroup: DayGroupedEntry
    let filter: TimelineFilter
    @Environment(\.themeManager) private var themeManager

    private var uniqueDays: Int {
        let days = Set(periodGroup.entries.map { entry in
            Calendar.current.startOfDay(for: entry.createdAt)
        })
        return days.count
    }

    var body: some View {
        HStack(spacing: 20) {
            // Dominant mood
            VStack(spacing: 8) {
                Image(systemName: periodGroup.dominantMood.sfSymbolName)
                    .font(.system(size: 36))
                    .foregroundColor(periodGroup.dominantMood.color)

                Text(periodGroup.dominantMood.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Text("Dominant mood")
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(periodGroup.dominantMood.color.opacity(0.1))
            )

            // Statistics
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(periodGroup.entries.count)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        Text("Entries")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(uniqueDays)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        Text("Days")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                }

                Divider()
                    .background(themeManager.currentTheme.strokeColor.opacity(0.2))

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(periodGroup.imageContainers.count)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        Text("Memories")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(periodGroup.moodDistribution.count)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        Text("Moods")
                            .font(.system(size: 11))
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.backgroundColor.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.currentTheme.strokeColor.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}
