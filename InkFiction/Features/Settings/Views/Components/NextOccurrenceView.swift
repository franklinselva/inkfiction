//
//  NextOccurrenceView.swift
//  InkFiction
//
//  Shows next occurrence of a reminder
//

import SwiftUI

struct NextOccurrenceView: View {
    let reminderType: ReminderType
    let time: Date
    let weekday: Int?
    let dayOfMonth: Int?

    @Environment(\.themeManager) private var themeManager

    enum ReminderType {
        case weekly
        case monthly
    }

    var nextOccurrence: Date? {
        let calendar = Calendar.current
        let now = Date()

        switch reminderType {
        case .weekly:
            guard let weekday = weekday else { return nil }
            return calendar.nextDate(
                after: now,
                matching: DateComponents(
                    hour: calendar.component(.hour, from: time),
                    minute: calendar.component(.minute, from: time),
                    weekday: weekday
                ),
                matchingPolicy: .nextTime
            )

        case .monthly:
            guard let dayOfMonth = dayOfMonth else { return nil }
            var components = DateComponents()
            components.day = dayOfMonth
            components.hour = calendar.component(.hour, from: time)
            components.minute = calendar.component(.minute, from: time)

            // Try current month first
            let currentMonth = calendar.component(.month, from: now)
            let currentYear = calendar.component(.year, from: now)
            components.month = currentMonth
            components.year = currentYear

            if let date = calendar.date(from: components), date > now {
                return date
            }

            // Otherwise, next month
            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) {
                components.month = calendar.component(.month, from: nextMonth)
                components.year = calendar.component(.year, from: nextMonth)
                return calendar.date(from: components)
            }

            return nil
        }
    }

    var body: some View {
        if let occurrence = nextOccurrence {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Reminder")
                        .font(.caption.weight(.medium))
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                    Text(formatNextOccurrence(occurrence))
                        .font(.body.weight(.semibold))
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    Text(formatRelativeTime(occurrence))
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }

                Spacer()

                Image(systemName: "bell.badge.fill")
                    .font(.title3)
                    .foregroundColor(themeManager.currentTheme.accentColor.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.accentColor.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.currentTheme.accentColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    private func formatNextOccurrence(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: now, to: date)

        if let days = components.day, days > 0 {
            if days == 1 {
                return "Tomorrow"
            } else if days < 7 {
                return "In \(days) days"
            } else {
                let weeks = days / 7
                return "In \(weeks) week\(weeks > 1 ? "s" : "")"
            }
        } else if let hours = components.hour, hours > 0 {
            return "In \(hours) hour\(hours > 1 ? "s" : "")"
        } else if let minutes = components.minute, minutes > 0 {
            return "In \(minutes) minute\(minutes > 1 ? "s" : "")"
        }

        return "Soon"
    }
}
