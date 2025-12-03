//
//  MonthDayCell.swift
//  InkFiction
//
//  Calendar day cell component for monthly insight
//

import SwiftUI

struct MonthDayCell: View {
    let day: MonthlyInsight.DayInfo
    @Environment(\.themeManager) private var themeManager

    private var dayTextColor: Color {
        if day.isCurrentMonth {
            return themeManager.currentTheme.textPrimaryColor
        } else {
            return themeManager.currentTheme.textSecondaryColor.opacity(0.3)
        }
    }

    private var backgroundColor: Color {
        if day.hasEntry && day.isCurrentMonth {
            return themeManager.currentTheme.surfaceColor.opacity(0.5)
        } else {
            return Color.clear
        }
    }

    var body: some View {
        ZStack {
            // Outer circle (empty state or stroke)
            if day.isCurrentMonth {
                Circle()
                    .stroke(
                        day.hasEntry
                            ? themeManager.currentTheme.accentColor
                            : themeManager.currentTheme.textSecondaryColor.opacity(0.3),
                        lineWidth: day.isToday ? 2.0 : 1.5
                    )
                    .frame(width: 10, height: 10)
            } else {
                // Previous/next month days - very subtle
                Circle()
                    .stroke(
                        themeManager.currentTheme.textSecondaryColor.opacity(0.1),
                        lineWidth: 1.0
                    )
                    .frame(width: 10, height: 10)
            }

            // Filled circle for days with entries
            if day.hasEntry && day.isCurrentMonth {
                Circle()
                    .fill(themeManager.currentTheme.accentColor)
                    .frame(width: 7, height: 7)
            }

            // Today indicator (extra emphasis)
            if day.isToday {
                Circle()
                    .stroke(themeManager.currentTheme.accentColor, lineWidth: 2.5)
                    .frame(width: 12, height: 12)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 16)
    }
}
