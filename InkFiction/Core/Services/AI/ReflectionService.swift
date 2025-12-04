//
//  ReflectionService.swift
//  InkFiction
//
//  Service for generating AI-powered mood reflections and insights
//

import Foundation
import SwiftUI

// MARK: - Reflection Service

/// Service for generating personalized reflections on journal entries
@Observable
final class ReflectionService {
    static let shared = ReflectionService()

    // MARK: - Properties

    private let geminiService: GeminiService
    private let promptManager: PromptManager

    private(set) var isGenerating = false
    private(set) var lastError: AIError?

    // Reflection cache
    private var reflectionCache: [String: ServiceCachedReflection] = [:]
    private let cacheExpiration: TimeInterval = 3600 // 1 hour

    // MARK: - Initialization

    private init(
        geminiService: GeminiService = .shared,
        promptManager: PromptManager = .shared
    ) {
        self.geminiService = geminiService
        self.promptManager = promptManager
    }

    // MARK: - Reflection Generation

    /// Generate a reflection for journal entries within a timeframe
    func generateReflection(
        entries: [JournalEntryModel],
        timeframe: TimeFrame,
        companion: AICompanion? = nil
    ) async throws -> ReflectionResult {
        guard !entries.isEmpty else {
            throw AIError.invalidRequest(reason: "No entries to reflect on")
        }

        // Check cache
        let cacheKey = buildCacheKey(entries: entries, timeframe: timeframe, companion: companion)
        if let cached = reflectionCache[cacheKey], !cached.isExpired {
            Log.debug("Returning cached reflection", category: .ai)
            return cached.result
        }

        isGenerating = true
        defer { isGenerating = false }

        Log.info("Generating \(timeframe.displayName) reflection for \(entries.count) entries", category: .ai)

        do {
            let result = try await geminiService.generateReflection(
                entries: entries,
                timeframe: timeframe,
                companion: companion
            )

            // Cache result
            reflectionCache[cacheKey] = ServiceCachedReflection(result: result)

            Log.info("Reflection generated successfully", category: .ai)

            lastError = nil
            return result

        } catch {
            lastError = error as? AIError ?? AIError.unknown(message: error.localizedDescription)
            throw error
        }
    }

    /// Generate daily insight for today's entries
    func generateDailyInsight(entries: [JournalEntryModel]) async throws -> ReflectionResult {
        let todayEntries = entries.filter { Calendar.current.isDateInToday($0.createdAt) }

        guard !todayEntries.isEmpty else {
            throw AIError.invalidRequest(reason: "No entries from today")
        }

        return try await generateReflection(
            entries: todayEntries,
            timeframe: .today
        )
    }

    /// Generate weekly summary
    func generateWeeklySummary(entries: [JournalEntryModel]) async throws -> ReflectionResult {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let weekEntries = entries.filter { $0.createdAt >= weekAgo }

        guard !weekEntries.isEmpty else {
            throw AIError.invalidRequest(reason: "No entries from this week")
        }

        return try await generateReflection(
            entries: weekEntries,
            timeframe: .thisWeek
        )
    }

    /// Generate monthly summary
    func generateMonthlySummary(entries: [JournalEntryModel]) async throws -> ReflectionResult {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!
        let monthEntries = entries.filter { $0.createdAt >= monthAgo }

        guard !monthEntries.isEmpty else {
            throw AIError.invalidRequest(reason: "No entries from this month")
        }

        return try await generateReflection(
            entries: monthEntries,
            timeframe: .thisMonth
        )
    }

    // MARK: - Insight Helpers

    /// Get key themes from entries
    func extractKeyThemes(from entries: [JournalEntryModel]) -> [String] {
        // Collect all tags
        let allTags = entries.flatMap { $0.tags }
        let tagCounts = Dictionary(grouping: allTags, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        // Return top 5 tags as themes
        return Array(tagCounts.prefix(5).map { $0.key })
    }

    /// Calculate mood trend direction
    func calculateMoodTrend(entries: [JournalEntryModel]) -> String {
        guard entries.count >= 2 else { return "stable" }

        // Sort by date
        let sorted = entries.sorted { $0.createdAt < $1.createdAt }

        // Assign numeric values to moods
        let moodValues: [Mood: Int] = [
            .happy: 4, .excited: 4, .peaceful: 3,
            .neutral: 2, .thoughtful: 2,
            .sad: 1, .anxious: 1, .angry: 0
        ]

        // Calculate first half vs second half average
        let midpoint = sorted.count / 2
        let firstHalf = Array(sorted.prefix(midpoint))
        let secondHalf = Array(sorted.suffix(sorted.count - midpoint))

        let firstAvg = Double(firstHalf.compactMap { moodValues[$0.mood] }.reduce(0, +)) / Double(max(1, firstHalf.count))
        let secondAvg = Double(secondHalf.compactMap { moodValues[$0.mood] }.reduce(0, +)) / Double(max(1, secondHalf.count))

        let diff = secondAvg - firstAvg
        if diff > 0.5 { return "improving" }
        if diff < -0.5 { return "declining" }
        return "stable"
    }

    /// Calculate journaling streak
    func calculateStreak(entries: [JournalEntryModel]) -> Int {
        guard !entries.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get unique days with entries
        let entryDays = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
            .sorted(by: >)

        var streak = 0
        var currentDay = today

        for day in entryDays {
            if calendar.isDate(day, inSameDayAs: currentDay) ||
               calendar.isDate(day, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDay)!) {
                streak += 1
                currentDay = day
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Cache Management

    private func buildCacheKey(entries: [JournalEntryModel], timeframe: TimeFrame, companion: AICompanion?) -> String {
        let entryIds = entries.map { $0.id.uuidString }.sorted().joined()
        let companionId = companion?.id ?? "none"
        return "\(timeframe.rawValue)-\(companionId)-\(entryIds.hashValue)"
    }

    /// Clear reflection cache
    func clearCache() {
        reflectionCache.removeAll()
        Log.debug("Reflection cache cleared", category: .ai)
    }

    /// Remove expired cache entries
    func pruneCache() {
        reflectionCache = reflectionCache.filter { !$0.value.isExpired }
    }
}

// MARK: - Service Cached Reflection

/// Internal cached reflection for ReflectionService
private struct ServiceCachedReflection {
    let result: ReflectionResult
    let timestamp: Date

    init(result: ReflectionResult) {
        self.result = result
        self.timestamp = Date()
    }

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 3600 // 1 hour
    }
}

// MARK: - Environment Key

private struct ReflectionServiceKey: EnvironmentKey {
    static let defaultValue = ReflectionService.shared
}

extension EnvironmentValues {
    var reflectionService: ReflectionService {
        get { self[ReflectionServiceKey.self] }
        set { self[ReflectionServiceKey.self] = newValue }
    }
}
