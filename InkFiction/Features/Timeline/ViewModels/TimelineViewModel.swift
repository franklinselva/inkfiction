//
//  TimelineViewModel.swift
//  InkFiction
//
//  ViewModel for Timeline feature - manages data aggregation and calculations
//

import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class TimelineViewModel {

    // MARK: - Properties

    private(set) var frequencyData: FrequencyData = .empty
    private(set) var calendarNavigation = CalendarNavigation()
    private(set) var isLoading = false

    // MARK: - Public Methods

    /// Calculate insights data from journal entries
    func calculateInsights(from entries: [JournalEntryModel]) -> InsightsData {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        let entriesThisYear = entries.filter { entry in
            calendar.component(.year, from: entry.createdAt) == currentYear
        }

        let uniqueDays = Set(
            entriesThisYear.map { entry in
                calendar.startOfDay(for: entry.createdAt)
            }
        )

        let currentStreak = calculateCurrentStreak(from: entries, calendar: calendar)

        return InsightsData(
            entriesThisYear: entriesThisYear.count,
            daysJournaled: uniqueDays.count,
            currentStreak: currentStreak
        )
    }

    /// Calculate current journaling streak
    func calculateCurrentStreak(from entries: [JournalEntryModel], calendar: Calendar) -> Int {
        guard !entries.isEmpty else { return 0 }

        let uniqueDaysSet = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
        let sortedUniqueDays = uniqueDaysSet.sorted(by: >)

        guard !sortedUniqueDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let mostRecentDate = sortedUniqueDays.first!

        let daysSinceLastEntry =
            calendar.dateComponents([.day], from: mostRecentDate, to: today).day ?? 0

        if daysSinceLastEntry > 1 {
            return 0 // Streak is broken
        }

        if sortedUniqueDays.count == 1 {
            return 1
        }

        var streak = 1
        for i in 0..<(sortedUniqueDays.count - 1) {
            let currentDay = sortedUniqueDays[i]
            let previousDay = sortedUniqueDays[i + 1]

            let daysDiff =
                calendar.dateComponents([.day], from: previousDay, to: currentDay).day ?? 0

            if daysDiff == 1 {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    /// Calculate longest streak ever achieved
    func calculateLongestStreak(from entries: [JournalEntryModel], calendar: Calendar) -> Int {
        guard !entries.isEmpty else { return 0 }

        let uniqueDaysSet = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
        let sortedUniqueDays = uniqueDaysSet.sorted()

        guard !sortedUniqueDays.isEmpty else { return 0 }

        var longestStreak = 1
        var currentStreak = 1

        for i in 1..<sortedUniqueDays.count {
            let previousDay = sortedUniqueDays[i - 1]
            let currentDay = sortedUniqueDays[i]

            let daysDiff =
                calendar.dateComponents([.day], from: previousDay, to: currentDay).day ?? 0

            if daysDiff == 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return longestStreak
    }

    /// Calculate mood distribution from entries
    func calculateMoodDistribution(from entries: [JournalEntryModel]) -> [Mood: Int] {
        entries.reduce(into: [:]) { counts, entry in
            counts[entry.mood, default: 0] += 1
        }
    }

    /// Get dominant mood from entries
    func getDominantMood(from entries: [JournalEntryModel]) -> Mood? {
        let distribution = calculateMoodDistribution(from: entries)
        return distribution.max(by: { $0.value < $1.value })?.key
    }

    /// Group entries by day
    func groupEntriesByDay(_ entries: [JournalEntryModel]) -> [(date: Date, entries: [JournalEntryModel])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.createdAt)
        }
        return grouped.sorted { $0.key > $1.key }.map {
            (date: $0.key, entries: $0.value.sorted { $0.createdAt > $1.createdAt })
        }
    }

    /// Group entries by week
    func groupEntriesByWeek(_ entries: [JournalEntryModel]) -> [(date: Date, entries: [JournalEntryModel])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            let weekday = calendar.component(.weekday, from: entry.createdAt)
            let daysToSubtract = (weekday - calendar.firstWeekday + 7) % 7
            return calendar.date(
                byAdding: .day, value: -daysToSubtract,
                to: calendar.startOfDay(for: entry.createdAt)) ?? entry.createdAt
        }
        return grouped.sorted { $0.key > $1.key }.map {
            (date: $0.key, entries: $0.value.sorted { $0.createdAt > $1.createdAt })
        }
    }

    /// Group entries by month
    func groupEntriesByMonth(_ entries: [JournalEntryModel]) -> [(date: Date, entries: [JournalEntryModel])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            let components = calendar.dateComponents([.year, .month], from: entry.createdAt)
            return calendar.date(from: components) ?? entry.createdAt
        }
        return grouped.sorted { $0.key > $1.key }.map {
            (date: $0.key, entries: $0.value.sorted { $0.createdAt > $1.createdAt })
        }
    }

    /// Calculate word count statistics
    func calculateWordCountStats(from entries: [JournalEntryModel]) -> WordCountStats {
        guard !entries.isEmpty else { return .empty }

        let wordCounts = entries.map { entry -> Int in
            entry.content.split(separator: " ").count
        }

        let totalWords = wordCounts.reduce(0, +)
        let averageWords = Double(totalWords) / Double(entries.count)
        let longestEntry = wordCounts.max() ?? 0
        let shortestEntry = wordCounts.min() ?? 0

        // Calculate trend based on recent entries
        let recentEntries = entries.sorted { $0.createdAt > $1.createdAt }.prefix(10)
        let olderEntries = entries.sorted { $0.createdAt > $1.createdAt }.dropFirst(10).prefix(10)

        let recentAverage = recentEntries.isEmpty ? 0.0 :
            Double(recentEntries.map { $0.content.split(separator: " ").count }.reduce(0, +)) / Double(recentEntries.count)
        let olderAverage = olderEntries.isEmpty ? 0.0 :
            Double(olderEntries.map { $0.content.split(separator: " ").count }.reduce(0, +)) / Double(olderEntries.count)

        let trend: WordCountTrend
        if recentAverage > olderAverage * 1.1 {
            trend = .increasing
        } else if recentAverage < olderAverage * 0.9 {
            trend = .decreasing
        } else {
            trend = .stable
        }

        return WordCountStats(
            totalWords: totalWords,
            averageWordsPerEntry: averageWords,
            longestEntry: longestEntry,
            shortestEntry: shortestEntry,
            recentTrend: trend
        )
    }

    /// Calculate daily pattern (which days of week user journals most)
    func calculateDailyPattern(from entries: [JournalEntryModel]) -> [DayOfWeek: Int] {
        entries.reduce(into: [:]) { counts, entry in
            let dayOfWeek = DayOfWeek.from(date: entry.createdAt)
            counts[dayOfWeek, default: 0] += 1
        }
    }

    /// Calculate time of day pattern
    func calculateTimeOfDayPattern(from entries: [JournalEntryModel]) -> [Hour: Int] {
        entries.reduce(into: [:]) { counts, entry in
            let hour = Hour.from(date: entry.createdAt)
            counts[hour, default: 0] += 1
        }
    }

    // MARK: - Calendar Navigation

    func moveToNextMonth() {
        calendarNavigation.moveToNextMonth()
    }

    func moveToPreviousMonth() {
        calendarNavigation.moveToPreviousMonth()
    }

    func moveToToday() {
        calendarNavigation.moveToToday()
    }

    func moveToMonth(_ date: Date) {
        calendarNavigation.moveToMonth(date)
    }

    // MARK: - Full Frequency Data Calculation

    func calculateFullFrequencyData(from entries: [JournalEntryModel]) {
        let calendar = Calendar.current
        let currentStreak = calculateCurrentStreak(from: entries, calendar: calendar)
        let longestStreak = calculateLongestStreak(from: entries, calendar: calendar)
        let wordCountStats = calculateWordCountStats(from: entries)
        let dailyPattern = calculateDailyPattern(from: entries)
        let timeOfDayStats = calculateTimeOfDayPattern(from: entries)
        let moodDistribution = calculateMoodDistribution(from: entries)

        // Calculate weekly average
        let calendar2 = Calendar.current
        let fourWeeksAgo = calendar2.date(byAdding: .weekOfYear, value: -4, to: Date()) ?? Date()
        let recentEntries = entries.filter { $0.createdAt >= fourWeeksAgo }
        let weeklyAverage = Double(recentEntries.count) / 4.0

        frequencyData = FrequencyData(
            totalEntries: entries.count,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            weeklyAverage: weeklyAverage,
            monthlyStats: [],
            dailyPattern: dailyPattern,
            timeOfDayStats: timeOfDayStats,
            wordCountStats: wordCountStats,
            moodDistribution: moodDistribution.reduce(into: [:]) { $0[$1.key.rawValue] = $1.value },
            tagsFrequency: [:]
        )
    }
}
