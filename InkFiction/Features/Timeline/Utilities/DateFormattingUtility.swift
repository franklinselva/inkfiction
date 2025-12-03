//
//  DateFormattingUtility.swift
//  InkFiction
//
//  Centralized date formatting utilities for Timeline feature
//

import Foundation

enum DateFormattingUtility {
    // MARK: - Shared Formatters

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    private static let dayNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    private static let dayNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private static let fullDayNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let monthNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()

    private static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    private static let dateWithYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()

    private static let shortDateRangeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private static let dayHeaderFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()

    // MARK: - Public Formatting Methods

    static func monthAbbreviation(from date: Date) -> String {
        monthFormatter.string(from: date).uppercased()
    }

    static func dayNumber(from date: Date) -> String {
        dayNumberFormatter.string(from: date)
    }

    static func dayName(from date: Date) -> String {
        dayNameFormatter.string(from: date).uppercased()
    }

    static func fullDayName(from date: Date) -> String {
        fullDayNameFormatter.string(from: date)
    }

    static func time(from date: Date) -> String {
        timeFormatter.string(from: date)
    }

    static func monthName(from date: Date) -> String {
        monthNameFormatter.string(from: date)
    }

    static func year(from date: Date) -> String {
        yearFormatter.string(from: date)
    }

    static func fullDate(from date: Date) -> String {
        fullDateFormatter.string(from: date)
    }

    static func dateWithYear(from date: Date) -> String {
        dateWithYearFormatter.string(from: date)
    }

    static func monthYear(from date: Date) -> String {
        monthYearFormatter.string(from: date)
    }

    // MARK: - Smart Date Labels (Today/Yesterday)

    static func smartDayLabel(from date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return fullDayName(from: date)
        }
    }

    static func smartDayHeader(from date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return dayHeaderFormatter.string(from: date)
        }
    }

    // MARK: - Date Range Formatting

    static func dateRange(from startDate: Date, to endDate: Date) -> String {
        let start = shortDateRangeFormatter.string(from: startDate)
        let end = shortDateRangeFormatter.string(from: endDate)
        return "\(start) - \(end)"
    }
}
