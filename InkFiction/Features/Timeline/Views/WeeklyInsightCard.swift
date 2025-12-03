//
//  WeeklyInsightCard.swift
//  InkFiction
//
//  Weekly insight card with bar chart visualization
//

import SwiftUI

struct WeeklyInsightCard: View {
    let insight: WeeklyInsight
    @Environment(\.themeManager) private var themeManager

    private var maxEntries: Int {
        insight.dailyEntries.map { $0.entryCount }.max() ?? 1
    }

    private var activeDaysText: String {
        insight.activeDays <= 1 ? "Active Day" : "Active Days"
    }

    private var entriesText: String {
        insight.totalEntries <= 1 ? "Entry" : "Entries"
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 20) {
                // Left side: Bar Chart (65% width)
                VStack(alignment: .leading, spacing: 20) {
                    Text("Weekly Activity")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(insight.dailyEntries) { dayEntry in
                            BarColumn(
                                dayLabel: dayEntry.dayLabel,
                                entryCount: dayEntry.entryCount,
                                isToday: dayEntry.isToday,
                                maxEntries: maxEntries
                            )
                        }
                    }
                    .frame(height: 80)
                }
                .frame(width: geometry.size.width * 0.65, alignment: .leading)

                Spacer()

                // Right side: Metrics (35% width)
                VStack(alignment: .leading, spacing: 16) {
                    // Active Days
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.accentColor)

                            Text("\(insight.activeDays)")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        }

                        Text(activeDaysText)
                            .font(.caption2)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }

                    // Total Entries
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.accentColor)

                            Text("\(insight.totalEntries)")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        }

                        Text(entriesText)
                            .font(.caption2)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                }
                .frame(width: geometry.size.width * 0.35, alignment: .leading)
            }
        }
        .frame(height: 120)  // Match InsightsCard height
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
