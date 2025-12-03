//
//  MonthlyInsightCard.swift
//  InkFiction
//
//  Monthly insight card with calendar grid visualization
//

import SwiftUI

struct MonthlyInsightCard: View {
    let insight: MonthlyInsight
    @Environment(\.themeManager) private var themeManager

    private let weekdayHeaders = ["S", "M", "T", "W", "T", "F", "S"]

    private var activeDaysText: String {
        insight.daysJournaled <= 1 ? "Active Day" : "Active Days"
    }

    private var entriesText: String {
        insight.totalEntries <= 1 ? "Entry" : "Entries"
    }

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 20
            let availableWidth = geometry.size.width - spacing
            let leftWidth = availableWidth * 0.35
            let rightWidth = availableWidth * 0.65

            HStack(spacing: spacing) {
                // Left side: Header + Metrics (35% width)
                VStack(alignment: .leading, spacing: 16) {
                    // Month Header
                    Text(insight.monthNameShort)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    // Active Days
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.accentColor)

                            Text("\(insight.daysJournaled)")
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
                .frame(width: leftWidth, alignment: .leading)

                // Right side: Calendar Grid Only (65% width)
                VStack(alignment: .leading, spacing: 6) {
                    // Weekday Headers
                    HStack(spacing: 0) {
                        ForEach(weekdayHeaders, id: \.self) { header in
                            Text(header)
                                .font(.system(size: 9, weight: .medium, design: .default))
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor.opacity(0.6))
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // Calendar Grid with circular dots
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                        spacing: 4
                    ) {
                        ForEach(insight.days) { day in
                            MonthDayCell(day: day)
                        }
                    }
                }
                .frame(width: rightWidth, alignment: .leading)
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
