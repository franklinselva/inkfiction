//
//  CalendarModels.swift
//  InkFiction
//
//  Calendar data models for Timeline feature
//

import Foundation
import SwiftUI

// MARK: - Calendar Data Models

struct CalendarEntry: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let entries: [JournalEntryModel]
    let thumbnailImagePath: String?
    let entryCount: Int
    let dominantMood: Mood?

    var hasEntries: Bool {
        entryCount > 0
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    static func == (lhs: CalendarEntry, rhs: CalendarEntry) -> Bool {
        lhs.id == rhs.id && lhs.date == rhs.date && lhs.entryCount == rhs.entryCount
    }
}

struct CalendarMonth: Identifiable {
    let id = UUID()
    let month: Date
    let days: [CalendarDay]
    let stats: MonthlyStats

    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }

    var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: month)
    }

    var daysWithEntries: Int {
        days.filter { $0.hasEntries }.count
    }

    var totalEntries: Int {
        days.reduce(0) { $0 + $1.entryCount }
    }
}

struct CalendarDay: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let entryCount: Int
    let entries: [JournalEntryModel]
    let thumbnailImagePath: String?
    let dominantMood: Mood?
    let isCurrentMonth: Bool

    var hasEntries: Bool {
        entryCount > 0
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    var entryIndicator: EntryIndicator {
        switch entryCount {
        case 0:
            return .none
        case 1:
            return .single
        case 2:
            return .double
        case 3:
            return .triple
        default:
            return .multiple
        }
    }

    static func == (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        lhs.id == rhs.id && lhs.date == rhs.date && lhs.entryCount == rhs.entryCount
    }
}

enum EntryIndicator {
    case none
    case single
    case double
    case triple
    case multiple

    var dotCount: Int {
        switch self {
        case .none: return 0
        case .single: return 1
        case .double: return 2
        case .triple: return 3
        case .multiple: return 4
        }
    }

    var opacity: Double {
        switch self {
        case .none: return 0.0
        case .single: return 0.4
        case .double: return 0.6
        case .triple: return 0.8
        case .multiple: return 1.0
        }
    }
}

// MARK: - Calendar Statistics

struct MonthlyStats: Identifiable {
    let id = UUID()
    let month: Date
    let totalEntries: Int
    let activeDays: Int
    let averageWordsPerDay: Double
    let dominantMood: Mood?
    let longestStreak: Int
    let moodDistribution: [Mood: Int]
    let completionRate: Double

    var monthProgress: Double {
        let calendar = Calendar.current
        let today = Date()
        let monthStart = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let monthEnd = calendar.dateInterval(of: .month, for: month)?.end ?? month

        if today >= monthEnd {
            return 1.0
        } else if today <= monthStart {
            return 0.0
        } else {
            let totalDaysInMonth = calendar.dateComponents([.day], from: monthStart, to: monthEnd).day ?? 1
            let daysPassed = calendar.dateComponents([.day], from: monthStart, to: today).day ?? 0
            return Double(daysPassed) / Double(totalDaysInMonth)
        }
    }

    static let empty = MonthlyStats(
        month: Date(),
        totalEntries: 0,
        activeDays: 0,
        averageWordsPerDay: 0.0,
        dominantMood: nil,
        longestStreak: 0,
        moodDistribution: [:],
        completionRate: 0.0
    )
}

// MARK: - Calendar View Models

enum CalendarViewMode {
    case month
    case year

    var displayName: String {
        switch self {
        case .month: return "Month"
        case .year: return "Year"
        }
    }

    var systemImage: String {
        switch self {
        case .month: return "calendar"
        case .year: return "calendar.badge.clock"
        }
    }
}

struct CalendarGridConfiguration {
    let cellSize: CGSize
    let spacing: CGFloat
    let cornerRadius: CGFloat
    let showImageBackgrounds: Bool
    let showMoodIndicators: Bool
    let showEntryDots: Bool

    static let `default` = CalendarGridConfiguration(
        cellSize: CGSize(width: 40, height: 40),
        spacing: 4,
        cornerRadius: 8,
        showImageBackgrounds: true,
        showMoodIndicators: true,
        showEntryDots: true
    )

    static let compact = CalendarGridConfiguration(
        cellSize: CGSize(width: 32, height: 32),
        spacing: 2,
        cornerRadius: 6,
        showImageBackgrounds: false,
        showMoodIndicators: true,
        showEntryDots: true
    )

    static let large = CalendarGridConfiguration(
        cellSize: CGSize(width: 48, height: 48),
        spacing: 6,
        cornerRadius: 10,
        showImageBackgrounds: true,
        showMoodIndicators: true,
        showEntryDots: true
    )
}

// MARK: - Calendar Navigation

struct CalendarNavigation {
    private(set) var currentMonth: Date
    private let calendar = Calendar.current

    init(startingMonth: Date = Date()) {
        self.currentMonth = calendar.dateInterval(of: .month, for: startingMonth)?.start ?? startingMonth
    }

    mutating func moveToNextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }

    mutating func moveToPreviousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }

    mutating func moveToMonth(_ date: Date) {
        currentMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
    }

    mutating func moveToToday() {
        currentMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
    }

    func monthsInYear(_ year: Int) -> [Date] {
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? Date()
        return (0..<12).compactMap { monthOffset in
            calendar.date(byAdding: .month, value: monthOffset, to: startOfYear)
        }
    }

    var currentYear: Int {
        calendar.component(.year, from: currentMonth)
    }

    var canMoveForward: Bool {
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        return nextMonth <= Date()
    }

    var canMoveBackward: Bool {
        // Allow going back up to 2 years for reasonable data range
        let twoYearsAgo = calendar.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        return currentMonth >= twoYearsAgo
    }
}

// MARK: - Calendar Image Cache

@MainActor
@Observable
final class CalendarImageCache {
    private var cache: [String: UIImage] = [:]
    private let maxCacheSize = 100

    func image(for path: String?) -> UIImage? {
        guard let path = path else { return nil }
        return cache[path]
    }

    func setImage(_ image: UIImage, for path: String) {
        if cache.count >= maxCacheSize {
            // Remove oldest entries (simple FIFO)
            let keysToRemove = Array(cache.keys.prefix(10))
            keysToRemove.forEach { cache.removeValue(forKey: $0) }
        }
        cache[path] = image
    }

    func clearCache() {
        cache.removeAll()
    }

    var cacheSize: Int {
        cache.count
    }
}
