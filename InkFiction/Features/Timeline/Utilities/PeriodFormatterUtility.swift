//
//  PeriodFormatterUtility.swift
//  InkFiction
//
//  Utility for formatting period labels in Timeline (day, week, month)
//

import Foundation

enum PeriodFormatterUtility {
    // MARK: - Period Number Formatting

    static func periodNumber(for date: Date, filter: TimelineFilter) -> String {
        let calendar = Calendar.current
        switch filter {
        case .day:
            return "\(calendar.component(.day, from: date))"
        case .week:
            return "\(calendar.component(.weekOfYear, from: date))"
        case .month:
            return "\(calendar.component(.month, from: date))"
        }
    }

    // MARK: - Period Label Formatting

    static func periodLabel(for date: Date, filter: TimelineFilter) -> String {
        switch filter {
        case .day:
            return DateFormattingUtility.fullDayName(from: date)
        case .week:
            let weekNum = Calendar.current.component(.weekOfYear, from: date)
            return "Week \(weekNum)"
        case .month:
            return DateFormattingUtility.monthName(from: date)
        }
    }

    static func periodSubLabel(for date: Date, filter: TimelineFilter) -> String {
        switch filter {
        case .day:
            return DateFormattingUtility.dateWithYear(from: date)
        case .week:
            let calendar = Calendar.current
            if let endOfWeek = calendar.date(byAdding: .day, value: 6, to: date) {
                return DateFormattingUtility.dateRange(from: date, to: endOfWeek)
            }
            return ""
        case .month:
            return DateFormattingUtility.year(from: date)
        }
    }

    static func periodIndicatorLabel(for filter: TimelineFilter) -> String {
        switch filter {
        case .day:
            return "DAY"
        case .week:
            return "WEEK"
        case .month:
            return "MONTH"
        }
    }

    // MARK: - Period Title Formatting (for detail sheets)

    static func periodTitle(for date: Date, filter: TimelineFilter) -> String {
        switch filter {
        case .day:
            return DateFormattingUtility.fullDate(from: date)
        case .week:
            let weekNum = Calendar.current.component(.weekOfYear, from: date)
            let calendar = Calendar.current
            if let endOfWeek = calendar.date(byAdding: .day, value: 6, to: date) {
                let range = DateFormattingUtility.dateRange(from: date, to: endOfWeek)
                return "Week \(weekNum): \(range)"
            }
            return "Week \(weekNum)"
        case .month:
            return DateFormattingUtility.monthYear(from: date)
        }
    }
}
