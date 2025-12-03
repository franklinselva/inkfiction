//
//  MonthlyInsight.swift
//  InkFiction
//
//  Monthly insight data model for Timeline
//

import Foundation

struct MonthlyInsight {
    let month: Date  // Any date in the target month
    let days: [DayInfo]  // All days to display (35-42 items for calendar grid)

    struct DayInfo: Identifiable {
        let id = UUID()
        let date: Date
        let dayNumber: Int
        let entryCount: Int
        let isCurrentMonth: Bool
        let isToday: Bool

        var hasEntry: Bool {
            entryCount > 0
        }
    }

    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }

    var monthNameShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: month)
    }

    var totalEntries: Int {
        days.filter { $0.isCurrentMonth }
            .reduce(0) { $0 + $1.entryCount }
    }

    var daysJournaled: Int {
        days.filter { $0.isCurrentMonth && $0.entryCount > 0 }.count
    }

    var daysOff: Int {
        let calendar = Calendar.current
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: month)?.count else {
            return 0
        }
        return daysInMonth - daysJournaled
    }

    static func empty(for date: Date = Date()) -> MonthlyInsight {
        let calendar = Calendar.current

        // Get the first day of the month
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstDayOfMonth = calendar.date(from: components) else {
            return MonthlyInsight(month: date, days: [])
        }

        // Get the weekday of the first day (Sunday = 1, Monday = 2, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        // Calculate how many days from the previous month to show
        let daysFromPreviousMonth = (firstWeekday - calendar.firstWeekday + 7) % 7

        // Get the range of days in the month
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count
        else {
            return MonthlyInsight(month: date, days: [])
        }

        // Calculate total cells needed (must be multiple of 7)
        let totalDays = daysFromPreviousMonth + daysInMonth
        let weeksNeeded = (totalDays + 6) / 7  // Round up
        let totalCells = weeksNeeded * 7

        var dayInfoArray: [DayInfo] = []

        // Generate all calendar cells
        for offset in 0..<totalCells {
            let adjustedOffset = offset - daysFromPreviousMonth
            guard
                let cellDate = calendar.date(
                    byAdding: .day, value: adjustedOffset, to: firstDayOfMonth)
            else {
                continue
            }

            let isCurrentMonthCell = calendar.isDate(
                cellDate, equalTo: firstDayOfMonth, toGranularity: .month)
            let dayNumber = calendar.component(.day, from: cellDate)

            dayInfoArray.append(
                DayInfo(
                    date: cellDate,
                    dayNumber: dayNumber,
                    entryCount: 0,
                    isCurrentMonth: isCurrentMonthCell,
                    isToday: calendar.isDateInToday(cellDate)
                ))
        }

        return MonthlyInsight(month: firstDayOfMonth, days: dayInfoArray)
    }
}
