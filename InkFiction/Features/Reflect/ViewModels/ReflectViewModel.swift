//
//  ReflectViewModel.swift
//  InkFiction
//
//  ViewModel for the Reflect feature - manages mood analysis and reflections
//

import Combine
import Foundation
import SwiftData
import SwiftUI

// MARK: - Reflect ViewModel

@Observable
@MainActor
final class ReflectViewModel {

    // MARK: - Published Properties

    private(set) var moodData: [MoodData] = []
    private(set) var isLoading: Bool = false
    private(set) var isAnalyzing: Bool = false
    private(set) var analysisProgress: Double = 0
    private(set) var selectedMood: MoodData?
    private(set) var latestReflection: MoodReflection?
    private(set) var error: ReflectError?

    var timeframe: TimeFrame = .thisMonth

    var config: ReflectionConfig = .default

    // MARK: - Computed Properties

    var hasData: Bool {
        !moodData.isEmpty
    }

    var totalEntries: Int {
        moodData.reduce(0) { $0 + $1.entryCount }
    }

    var dominantMood: MoodData? {
        moodData.max(by: { $0.entryCount < $1.entryCount })
    }

    var moodDiversity: Double {
        Double(moodData.count) / Double(Mood.allCases.count)
    }

    var averageIntensity: Double {
        guard !moodData.isEmpty else { return 0 }
        return moodData.reduce(0) { $0 + $1.intensity } / Double(moodData.count)
    }

    // MARK: - Private Properties

    private var entries: [JournalEntryModel] = []

    // MARK: - Initialization

    init() {
        Log.debug("ReflectViewModel initialized", category: .moodAnalysis)
    }

    // MARK: - Public Methods

    /// Update with entries directly from SwiftData @Query
    func updateWithEntries(_ newEntries: [JournalEntryModel]) {
        let dateRange = timeframe.dateRange()
        entries = newEntries.filter { entry in
            !entry.isArchived && dateRange.contains(entry.createdAt)
        }

        Log.debug(
            "Updated with \(entries.count) entries for timeframe: \(timeframe.rawValue)",
            category: .moodAnalysis
        )

        analyzeEntries()
    }

    /// Refresh mood analysis data
    func refreshData() {
        Log.debug("Refreshing reflect data for timeframe: \(timeframe.rawValue)", category: .moodAnalysis)
        analyzeEntries()
        Log.info("Reflect data refreshed: \(moodData.count) moods analyzed", category: .moodAnalysis)
    }

    /// Set selected mood for detail view
    func selectMood(_ mood: MoodData?) {
        selectedMood = mood
    }

    /// Get entries for a specific mood
    func entriesForMood(_ mood: Mood) -> [JournalEntryModel] {
        entries.filter { $0.mood == mood }
    }

    /// Get mood trend (entry count over time)
    func moodTrend(for mood: Mood) -> [Int] {
        let calendar = Calendar.current
        let moodEntries = entriesForMood(mood)

        // Group by day for the past 7 days
        var trend: [Int] = []
        for dayOffset in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            let count = moodEntries.filter {
                calendar.isDate($0.createdAt, inSameDayAs: date)
            }.count
            trend.append(count)
        }

        return trend
    }

    /// Generate mood summary text
    func generateMoodSummary() -> String {
        guard let dominant = dominantMood else {
            return "Start journaling to see your mood patterns."
        }

        let diversity = moodDiversity > 0.5 ? "diverse" : "focused"
        let intensity = averageIntensity > 0.6 ? "intense" : "balanced"

        return "Your \(timeframe.displayName.lowercased()) has been \(intensity) and \(diversity). " +
            "\(dominant.mood.rawValue) has been your most common mood with \(dominant.entryCount) entries."
    }

    /// Get quick mood insights
    func getMoodInsights() -> [MoodInsight] {
        var insights: [MoodInsight] = []

        // Most frequent mood
        if let dominant = dominantMood {
            insights.append(MoodInsight(
                title: "Most Frequent",
                description: "\(dominant.mood.rawValue) appears in \(dominant.entryCount) entries",
                icon: dominant.mood.sfSymbolName,
                color: dominant.mood.color
            ))
        }

        // Mood diversity
        let diversityLabel =
            moodDiversity > 0.7 ? "Rich"
            : moodDiversity > 0.4 ? "Balanced"
            : "Focused"
        insights.append(MoodInsight(
            title: "Emotional Range",
            description: "\(diversityLabel) - \(moodData.count) different moods",
            icon: "rainbow",
            color: .purple
        ))

        // Recent trend
        if let recent = moodData.max(by: { $0.lastEntryDate < $1.lastEntryDate }) {
            insights.append(MoodInsight(
                title: "Recent Mood",
                description: recent.mood.rawValue,
                icon: recent.mood.sfSymbolName,
                color: recent.mood.color
            ))
        }

        return insights
    }

    // MARK: - Private Methods

    private func analyzeEntries() {
        isAnalyzing = true
        analysisProgress = 0
        defer {
            isAnalyzing = false
            analysisProgress = 1
        }

        guard !entries.isEmpty else {
            moodData = []
            return
        }

        // Group entries by mood
        var moodGroups: [Mood: [JournalEntryModel]] = [:]
        for entry in entries {
            moodGroups[entry.mood, default: []].append(entry)
        }

        // Calculate mood data for each mood
        var newMoodData: [MoodData] = []
        let totalProgress = Double(moodGroups.count)
        var currentProgress: Double = 0

        for (mood, moodEntries) in moodGroups {
            // Calculate intensity from entry content
            let intensity = calculateMoodIntensity(for: moodEntries)

            // Find last entry date
            let lastEntry = moodEntries.max(by: { $0.createdAt < $1.createdAt })

            let data = MoodData(
                mood: mood,
                intensity: intensity,
                entryCount: moodEntries.count,
                position: .zero,  // Will be calculated by layout
                lastEntryDate: lastEntry?.createdAt ?? Date()
            )
            newMoodData.append(data)

            currentProgress += 1
            analysisProgress = currentProgress / totalProgress
        }

        // Sort by entry count
        newMoodData.sort { $0.entryCount > $1.entryCount }

        // Calculate positions for bubble layout
        moodData = calculateBubblePositions(for: newMoodData)

        Log.info("Analyzed \(moodData.count) moods from \(entries.count) entries", category: .moodAnalysis)
    }

    private func calculateMoodIntensity(for entries: [JournalEntryModel]) -> Double {
        guard !entries.isEmpty else { return 0 }

        var totalIntensity: Double = 0

        for entry in entries {
            // Base intensity from mood keywords in content
            let keywordScore = calculateKeywordScore(entry.content, mood: entry.mood)

            // Sentiment modifier
            let modifier = SentimentAnalysis.calculateIntensityModifier(text: entry.content)

            // Recency boost (more recent = higher intensity)
            let daysSince = Date().timeIntervalSince(entry.createdAt) / (24 * 60 * 60)
            let recencyBoost = max(0, 1.0 - (daysSince / 30.0))

            let intensity = (keywordScore * modifier * (1 + recencyBoost * 0.3))
            totalIntensity += min(1.0, intensity)
        }

        return min(1.0, totalIntensity / Double(entries.count))
    }

    private func calculateKeywordScore(_ text: String, mood: Mood) -> Double {
        let keywords = MoodDetectionKeywords.keywords(for: mood)
        let lowercased = text.lowercased()

        var matchCount = 0
        for keyword in keywords {
            if lowercased.contains(keyword) {
                matchCount += 1
            }
        }

        // Base score of 0.3 + keyword matches
        let keywordBoost = Double(matchCount) * 0.1
        return min(1.0, 0.3 + keywordBoost)
    }

    private func calculateBubblePositions(for data: [MoodData]) -> [MoodData] {
        var positioned = data

        // Simple circle packing algorithm
        let centerX: CGFloat = 150
        let centerY: CGFloat = 150
        let baseRadius: CGFloat = 100

        for (index, mood) in positioned.enumerated() {
            let angle = (2 * .pi / CGFloat(positioned.count)) * CGFloat(index)
            let radius = baseRadius * (1 - CGFloat(mood.sizeFactor) * 0.3)

            positioned[index].position = CGPoint(
                x: centerX + cos(angle) * radius,
                y: centerY + sin(angle) * radius
            )
        }

        return positioned
    }
}

// MARK: - Mood Insight

struct MoodInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - Reflect Error

enum ReflectError: Error, LocalizedError {
    case fetchFailed
    case analysisFailed
    case reflectionGenerationFailed
    case networkError
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Failed to load journal entries"
        case .analysisFailed:
            return "Failed to analyze mood patterns"
        case .reflectionGenerationFailed:
            return "Failed to generate reflection"
        case .networkError:
            return "Network connection unavailable"
        case .apiError(let message):
            return message
        }
    }
}
