//
//  ReflectModels.swift
//  InkFiction
//
//  Models for the Reflect feature - AI-powered mood reflections
//

import Foundation
import SwiftUI

// MARK: - Mood Reflection

/// AI-generated reflection based on journal entries
struct MoodReflection: Identifiable, Equatable {
    let id: UUID
    let mood: Mood
    let timeframe: TimeFrame
    let summary: String
    let keyInsight: String
    let themes: [String]
    let emotionalProgression: String
    let entryCount: Int
    let processingTime: TimeInterval
    let generatedAt: Date
    let metadata: ProcessingMetadata

    struct ProcessingMetadata: Equatable {
        let totalTokensUsed: Int
        let chunksProcessed: Int
        let averageTokensPerChunk: Int
        let processingStrategy: String
    }

    var isRecent: Bool {
        Date().timeIntervalSince(generatedAt) < 300  // 5 minutes
    }

    var formattedProcessingTime: String {
        String(format: "%.1fs", processingTime)
    }

    var themesDisplay: String {
        themes.prefix(3).joined(separator: " • ")
    }

    static var empty: MoodReflection {
        MoodReflection(
            id: UUID(),
            mood: .neutral,
            timeframe: .thisWeek,
            summary: "",
            keyInsight: "",
            themes: [],
            emotionalProgression: "",
            entryCount: 0,
            processingTime: 0,
            generatedAt: Date(),
            metadata: ProcessingMetadata(
                totalTokensUsed: 0,
                chunksProcessed: 0,
                averageTokensPerChunk: 0,
                processingStrategy: ""
            )
        )
    }
}

// MARK: - Time Frame

/// Time period for filtering and reflection
enum TimeFrame: String, CaseIterable, Identifiable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case thisYear = "This Year"
    case lastYear = "Last Year"
    case allTime = "All Time"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .today: return "sun.max.fill"
        case .thisWeek: return "calendar.badge.clock"
        case .thisMonth: return "calendar"
        case .thisYear: return "calendar.circle"
        case .lastYear: return "clock.arrow.circlepath"
        case .allTime: return "infinity"
        }
    }

    /// Get the date range for this timeframe
    func dateRange(from date: Date = Date()) -> ClosedRange<Date> {
        let calendar = Calendar.current

        switch self {
        case .today:
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!.addingTimeInterval(-1)
            return start...end

        case .thisWeek:
            let weekday = calendar.component(.weekday, from: date)
            let daysFromMonday = (weekday + 5) % 7
            let start = calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: date))!
            let end = calendar.date(byAdding: .day, value: 7, to: start)!.addingTimeInterval(-1)
            return start...end

        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: date)
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!.addingTimeInterval(-1)
            return start...end

        case .thisYear:
            let components = calendar.dateComponents([.year], from: date)
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: .year, value: 1, to: start)!.addingTimeInterval(-1)
            return start...end

        case .lastYear:
            let lastYear = calendar.date(byAdding: .year, value: -1, to: date)!
            let components = calendar.dateComponents([.year], from: lastYear)
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: .year, value: 1, to: start)!.addingTimeInterval(-1)
            return start...end

        case .allTime:
            return Date.distantPast...Date.distantFuture
        }
    }
}

// MARK: - Mood Data

/// Data structure for mood visualization
struct MoodData: Identifiable, Equatable {
    let id = UUID()
    let mood: Mood
    var intensity: Double  // 0.0 to 1.0
    let entryCount: Int
    var position: CGPoint
    let lastEntryDate: Date

    var bubbleColor: Color {
        mood.color
    }

    var gradientColors: [Color] {
        [mood.color.opacity(0.8), mood.color.opacity(0.4)]
    }

    /// Size factor based on intensity and entry count
    var sizeFactor: Double {
        (intensity * 0.7) + (min(Double(entryCount) / 10.0, 1.0) * 0.3)
    }

    /// Base radius for bubble visualization (30-80pt range)
    var baseRadius: Double {
        30 + (sizeFactor * 50)
    }

    /// Animation duration based on mood
    var animationDuration: Double {
        switch mood {
        case .excited: return 1.5
        case .anxious: return 1.2
        case .happy: return 2.0
        case .peaceful: return 3.0
        case .thoughtful: return 2.5
        case .neutral: return 2.2
        case .sad: return 2.8
        case .angry: return 1.3
        }
    }

    /// Animation amplitude for floating effect
    var animationAmplitude: Double {
        switch mood {
        case .excited, .anxious, .angry: return 8
        case .happy, .thoughtful: return 5
        case .peaceful, .neutral, .sad: return 3
        }
    }

    /// Relative frequency (0-1) based on entry count
    var relativeFrequency: Double {
        min(Double(entryCount) / 20.0, 1.0)
    }

    /// Recency factor (1.0 for today, decays over 30 days)
    var recencyFactor: Double {
        let daysSince = Date().timeIntervalSince(lastEntryDate) / (24 * 60 * 60)
        return max(0, 1.0 - (daysSince / 30.0))
    }

    static var empty: MoodData {
        MoodData(
            mood: .neutral,
            intensity: 0,
            entryCount: 0,
            position: .zero,
            lastEntryDate: Date()
        )
    }
}

// MARK: - Reflection Depth

/// Depth level for AI reflection generation
enum ReflectionDepth: String, CaseIterable, Identifiable {
    case quick = "Quick"
    case standard = "Standard"
    case deep = "Deep"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .quick: return "Fast analysis, key themes"
        case .standard: return "Balanced depth and speed"
        case .deep: return "Comprehensive analysis"
        }
    }

    /// Maximum API calls for this depth
    var maxAPICalls: Int {
        switch self {
        case .quick: return 1
        case .standard: return 3
        case .deep: return 5
        }
    }

    /// Entries per chunk
    var entriesPerChunk: Int {
        switch self {
        case .quick: return 5
        case .standard: return 10
        case .deep: return 15
        }
    }

    /// Maximum tokens per chunk
    var tokensPerChunk: Int {
        switch self {
        case .quick: return 2000
        case .standard: return 4000
        case .deep: return 6000
        }
    }
}

// MARK: - Reflection Style

/// Style preference for AI reflections
enum ReflectionStyle: String, CaseIterable, Identifiable {
    case encouraging = "Encouraging"
    case analytical = "Analytical"
    case poetic = "Poetic"
    case therapeutic = "Therapeutic"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .encouraging: return "sun.max.fill"
        case .analytical: return "chart.bar.fill"
        case .poetic: return "sparkles"
        case .therapeutic: return "heart.fill"
        }
    }

    var description: String {
        switch self {
        case .encouraging: return "Uplifting and supportive tone"
        case .analytical: return "Data-driven observations"
        case .poetic: return "Metaphorical and expressive"
        case .therapeutic: return "Gentle and introspective"
        }
    }
}

// MARK: - Reflection Focus

/// Focus area for AI reflections
enum ReflectionFocus: String, CaseIterable, Identifiable {
    case patterns = "Patterns"
    case growth = "Growth"
    case gratitude = "Gratitude"
    case insights = "Insights"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .patterns: return "arrow.triangle.branch"
        case .growth: return "leaf.fill"
        case .gratitude: return "heart.text.square.fill"
        case .insights: return "lightbulb.fill"
        }
    }

    var description: String {
        switch self {
        case .patterns: return "Recurring themes and behaviors"
        case .growth: return "Personal development moments"
        case .gratitude: return "Positive moments and appreciation"
        case .insights: return "Key realizations and learnings"
        }
    }
}

// MARK: - Reflection Config

/// Configuration for reflection generation
struct ReflectionConfig: Equatable {
    var depth: ReflectionDepth
    var style: ReflectionStyle
    var focus: ReflectionFocus
    var timeframe: TimeFrame

    static var `default`: ReflectionConfig {
        ReflectionConfig(
            depth: .standard,
            style: .encouraging,
            focus: .insights,
            timeframe: .thisWeek
        )
    }
}

// MARK: - Cached Reflection

/// Cached reflection with expiration
struct CachedReflection: Identifiable, Equatable {
    let id: UUID
    let cacheKey: String
    let mood: Mood
    let timeframe: TimeFrame
    let reflection: MoodReflection
    let entryIdsHash: String
    let createdAt: Date
    let expiresAt: Date

    /// Check if cache is valid
    var isValid: Bool {
        Date() < expiresAt
    }

    /// Create a cache key from mood and timeframe
    static func cacheKey(mood: Mood, timeframe: TimeFrame) -> String {
        "\(mood.rawValue)_\(timeframe.rawValue)"
    }

    /// Create expiration date (midnight of next day)
    static func expirationDate() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        return calendar.startOfDay(for: tomorrow)
    }

    /// Hash entry IDs for validation
    static func hashEntryIds(_ ids: [UUID]) -> String {
        let sortedIds = ids.sorted { $0.uuidString < $1.uuidString }
        let concatenated = sortedIds.map { $0.uuidString }.joined()
        return String(concatenated.hashValue)
    }
}

// MARK: - Mood Detection Keywords

/// Keywords for mood detection from text
struct MoodDetectionKeywords {

    static let happy = [
        "joy", "cheerful", "delighted", "glad", "pleased",
        "content", "elated", "thrilled", "wonderful", "great"
    ]

    static let excited = [
        "thrilled", "energized", "enthusiastic", "eager", "pumped",
        "ecstatic", "animated", "lively", "passionate", "exhilarated"
    ]

    static let peaceful = [
        "calm", "serene", "tranquil", "relaxed", "composed",
        "still", "quiet", "centered", "balanced", "harmonious"
    ]

    static let neutral = [
        "okay", "fine", "alright", "normal", "usual",
        "regular", "standard", "ordinary", "average", "moderate"
    ]

    static let thoughtful = [
        "reflective", "contemplative", "pensive", "considering",
        "pondering", "introspective", "meditative", "wondering", "curious"
    ]

    static let sad = [
        "down", "unhappy", "melancholy", "gloomy", "somber",
        "dejected", "disappointed", "heartbroken", "tearful", "blue"
    ]

    static let anxious = [
        "worried", "nervous", "stressed", "tense", "uneasy",
        "apprehensive", "restless", "panicked", "overwhelmed", "uncertain"
    ]

    static let angry = [
        "frustrated", "irritated", "annoyed", "furious", "enraged",
        "upset", "mad", "hostile", "resentful", "agitated"
    ]

    /// Get keywords for a specific mood
    static func keywords(for mood: Mood) -> [String] {
        switch mood {
        case .happy: return happy
        case .excited: return excited
        case .peaceful: return peaceful
        case .neutral: return neutral
        case .thoughtful: return thoughtful
        case .sad: return sad
        case .anxious: return anxious
        case .angry: return angry
        }
    }

    /// All moods and their keywords
    static var all: [(mood: Mood, keywords: [String])] {
        Mood.allCases.map { ($0, keywords(for: $0)) }
    }
}

// MARK: - Sentiment Analysis

/// Sentiment analysis helpers
struct SentimentAnalysis {

    /// Intensifier words that amplify sentiment
    static let intensifiers = [
        "very", "extremely", "incredibly", "really", "so",
        "absolutely", "completely", "totally", "utterly", "deeply"
    ]

    /// Diminisher words that reduce sentiment
    static let diminishers = [
        "slightly", "somewhat", "a bit", "kind of", "sort of",
        "maybe", "perhaps", "barely", "hardly", "mildly"
    ]

    /// Calculate intensity modifier from text
    static func calculateIntensityModifier(text: String) -> Double {
        let lowercased = text.lowercased()
        var modifier = 1.0

        // Check for intensifiers
        for word in intensifiers {
            if lowercased.contains(word) {
                modifier += 0.15
            }
        }

        // Check for diminishers
        for word in diminishers {
            if lowercased.contains(word) {
                modifier -= 0.1
            }
        }

        // Check for exclamation marks
        let exclamationCount = text.filter { $0 == "!" }.count
        modifier += Double(exclamationCount) * 0.05

        // Check for question marks (uncertainty)
        let questionCount = text.filter { $0 == "?" }.count
        modifier -= Double(questionCount) * 0.03

        return max(0.3, min(2.0, modifier))  // Clamp between 0.3 and 2.0
    }
}
