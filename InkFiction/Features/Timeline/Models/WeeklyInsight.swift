//
//  WeeklyInsight.swift
//  InkFiction
//
//  Weekly insight data model for Timeline
//

import Foundation

struct WeeklyInsight {
    let startDate: Date  // First day of the week
    let endDate: Date    // Last day of the week
    let dailyEntries: [DayEntry]  // 7 items

    struct DayEntry: Identifiable {
        let id = UUID()
        let date: Date
        let entryCount: Int
        let isToday: Bool

        var dayLabel: String {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: date)
            // Convert to Sunday-first format
            switch weekday {
            case 1: return "S"
            case 2: return "M"
            case 3: return "T"
            case 4: return "W"
            case 5: return "T"
            case 6: return "F"
            case 7: return "S"
            default: return ""
            }
        }

        var hasEntry: Bool {
            entryCount > 0
        }
    }

    var totalEntries: Int {
        dailyEntries.reduce(0) { $0 + $1.entryCount }
    }

    var activeDays: Int {
        dailyEntries.filter { $0.entryCount > 0 }.count
    }

    var restDays: Int {
        7 - activeDays
    }

    var weekRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let start = formatter.string(from: startDate)

        // Check if start and end are in the same month
        let calendar = Calendar.current
        if calendar.isDate(startDate, equalTo: endDate, toGranularity: .month) {
            let endDay = calendar.component(.day, from: endDate)
            return "\(start) - \(endDay)"
        } else {
            let end = formatter.string(from: endDate)
            return "\(start) - \(end)"
        }
    }

    static func empty(for date: Date = Date()) -> WeeklyInsight {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let daysToSubtract = (weekday - calendar.firstWeekday + 7) % 7

        guard let startOfWeek = calendar.date(
            byAdding: .day,
            value: -daysToSubtract,
            to: calendar.startOfDay(for: date)
        ) else {
            return WeeklyInsight(startDate: date, endDate: date, dailyEntries: [])
        }

        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            return WeeklyInsight(startDate: startOfWeek, endDate: startOfWeek, dailyEntries: [])
        }

        let dailyEntries = (0..<7).compactMap { offset -> DayEntry? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else {
                return nil
            }
            return DayEntry(
                date: day,
                entryCount: 0,
                isToday: calendar.isDateInToday(day)
            )
        }

        return WeeklyInsight(
            startDate: startOfWeek,
            endDate: endOfWeek,
            dailyEntries: dailyEntries
        )
    }
}
