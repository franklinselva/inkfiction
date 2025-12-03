//
//  JournalFilterModels.swift
//  InkFiction
//
//  Filter and sort models for journal entries
//

import Foundation
import SwiftUI

// MARK: - Date Range Filter

enum DateRangeFilter: String, CaseIterable, Identifiable {
    case today = "Today"
    case yesterday = "Yesterday"
    case thisWeek = "This Week"
    case lastWeek = "Last Week"
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    case last30Days = "Last 30 Days"
    case last90Days = "Last 90 Days"
    case custom = "Custom Range"
    case allTime = "All Time"

    var id: String { rawValue }

    var sfSymbolName: String {
        switch self {
        case .today: return "calendar.circle"
        case .yesterday: return "calendar.badge.clock"
        case .thisWeek: return "calendar.day.timeline.left"
        case .lastWeek: return "calendar.day.timeline.trailing"
        case .thisMonth: return "calendar"
        case .lastMonth: return "calendar.badge.minus"
        case .last30Days: return "30.circle"
        case .last90Days: return "90.circle"
        case .custom: return "calendar.badge.plus"
        case .allTime: return "infinity"
        }
    }

    func getDateRange(customStart: Date? = nil, customEnd: Date? = nil) -> (start: Date?, end: Date?) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)?.addingTimeInterval(-1)
            return (start, end)

        case .yesterday:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
            let start = calendar.startOfDay(for: yesterday)
            let end = calendar.date(byAdding: .day, value: 1, to: start)?.addingTimeInterval(-1)
            return (start, end)

        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            let end = calendar.dateInterval(of: .weekOfYear, for: now)?.end.addingTimeInterval(-1)
            return (start, end)

        case .lastWeek:
            let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
            let start = calendar.dateInterval(of: .weekOfYear, for: lastWeek)?.start
            let end = calendar.dateInterval(of: .weekOfYear, for: lastWeek)?.end.addingTimeInterval(-1)
            return (start, end)

        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start
            let end = calendar.dateInterval(of: .month, for: now)?.end.addingTimeInterval(-1)
            return (start, end)

        case .lastMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
            let start = calendar.dateInterval(of: .month, for: lastMonth)?.start
            let end = calendar.dateInterval(of: .month, for: lastMonth)?.end.addingTimeInterval(-1)
            return (start, end)

        case .last30Days:
            let start = calendar.date(byAdding: .day, value: -30, to: now)
            return (start, now)

        case .last90Days:
            let start = calendar.date(byAdding: .day, value: -90, to: now)
            return (start, now)

        case .custom:
            return (customStart, customEnd)

        case .allTime:
            return (nil, nil)
        }
    }
}

// MARK: - Filter State

struct JournalFilterState: Equatable {
    var dateRange: DateRangeFilter = .allTime
    var customStartDate: Date?
    var customEndDate: Date?
    var searchText: String = ""
    var showArchived: Bool = false

    var isActive: Bool {
        dateRange != .allTime || !searchText.isEmpty || showArchived
    }

    var activeFilterCount: Int {
        var count = 0
        if dateRange != .allTime { count += 1 }
        if !searchText.isEmpty { count += 1 }
        if showArchived { count += 1 }
        return count
    }

    mutating func reset() {
        dateRange = .allTime
        customStartDate = nil
        customEndDate = nil
        searchText = ""
        showArchived = false
    }
}

// MARK: - Sort Order

enum JournalSortOrder: String, CaseIterable {
    case dateDescending = "Newest First"
    case dateAscending = "Oldest First"
    case titleAscending = "Title A-Z"
    case titleDescending = "Title Z-A"

    var sfSymbolName: String {
        switch self {
        case .dateDescending: return "arrow.down.circle"
        case .dateAscending: return "arrow.up.circle"
        case .titleAscending: return "textformat.abc"
        case .titleDescending: return "textformat.abc"
        }
    }
}
