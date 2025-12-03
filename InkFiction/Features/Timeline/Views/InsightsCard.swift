//
//  InsightsCard.swift
//  InkFiction
//
//  Year stats insight card for Timeline
//

import SwiftUI

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
