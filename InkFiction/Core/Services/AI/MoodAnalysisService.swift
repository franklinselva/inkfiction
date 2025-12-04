//
//  MoodAnalysisService.swift
//  InkFiction
//
//  Service for AI-powered mood detection from journal entries
//

import Foundation
import SwiftUI

// MARK: - Mood Analysis Service

/// Service for detecting mood from text content
@Observable
final class MoodAnalysisService {
    static let shared = MoodAnalysisService()

    // MARK: - Properties

    private let geminiService: GeminiService
    private let promptManager: PromptManager

    private(set) var isAnalyzing = false
    private(set) var lastError: AIError?

    // Analysis cache
    private var analysisCache: [String: CachedAnalysis] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes

    // MARK: - Initialization

    private init(
        geminiService: GeminiService = .shared,
        promptManager: PromptManager = .shared
    ) {
        self.geminiService = geminiService
        self.promptManager = promptManager
    }

    // MARK: - Mood Analysis

    /// Analyze mood from text content using AI
    func analyzeMood(content: String) async throws -> MoodAnalysisResult {
        guard !content.isEmpty else {
            throw AIError.invalidRequest(reason: "Content cannot be empty")
        }

        // Check cache
        let cacheKey = content.hashValue.description
        if let cached = analysisCache[cacheKey], !cached.isExpired {
            Log.debug("Returning cached mood analysis", category: .moodAnalysis)
            return cached.result
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        Log.info("Analyzing mood for content: \(content.prefix(50))...", category: .moodAnalysis)

        do {
            let result = try await geminiService.analyzeMood(content: content)

            // Cache result
            analysisCache[cacheKey] = CachedAnalysis(result: result)

            Log.info("Mood detected: \(result.mood) (confidence: \(String(format: "%.2f", result.confidence)))", category: .moodAnalysis)

            lastError = nil
            return result

        } catch {
            lastError = error as? AIError ?? AIError.unknown(message: error.localizedDescription)
            throw error
        }
    }

    /// Quick local mood detection (fallback when offline)
    func analyzeLocalMood(content: String) -> (mood: Mood, confidence: Double) {
        MoodDetectionKeywords.detectMood(from: content)
    }

    /// Analyze mood with fallback to local detection
    func analyzeMoodWithFallback(content: String) async -> MoodAnalysisResult {
        do {
            return try await analyzeMood(content: content)
        } catch {
            Log.warning("AI mood analysis failed, using local fallback", category: .moodAnalysis)

            let (mood, confidence) = analyzeLocalMood(content: content)
            return MoodAnalysisResult(
                mood: mood.rawValue,
                confidence: confidence,
                keywords: [],
                sentiment: .neutral,
                intensity: 0.5
            )
        }
    }

    // MARK: - Batch Analysis

    /// Analyze moods for multiple entries
    func analyzeMoods(entries: [JournalEntryModel]) async -> [UUID: MoodAnalysisResult] {
        var results: [UUID: MoodAnalysisResult] = [:]

        // Use TaskGroup with concurrency limit to avoid overwhelming API
        await withTaskGroup(of: (UUID, MoodAnalysisResult)?.self) { group in
            var activeTaskCount = 0
            let maxConcurrentTasks = 3

            for entry in entries {
                guard !entry.content.isEmpty else { continue }

                // Wait if we've reached the concurrency limit
                if activeTaskCount >= maxConcurrentTasks {
                    if let result = await group.next() {
                        if let (id, analysisResult) = result {
                            results[id] = analysisResult
                        }
                        activeTaskCount -= 1
                    }
                }

                // Add new task
                group.addTask {
                    let result = await self.analyzeMoodWithFallback(content: entry.content)
                    return (entry.id, result)
                }
                activeTaskCount += 1
            }

            // Collect remaining results
            for await result in group {
                if let (id, analysisResult) = result {
                    results[id] = analysisResult
                }
            }
        }

        return results
    }

    // MARK: - Mood Insights

    /// Calculate mood distribution for a set of entries
    func calculateMoodDistribution(entries: [JournalEntryModel]) -> [Mood: Double] {
        let total = Double(entries.count)
        guard total > 0 else { return [:] }

        var counts: [Mood: Int] = [:]
        for entry in entries {
            counts[entry.mood, default: 0] += 1
        }

        return counts.mapValues { Double($0) / total }
    }

    /// Calculate average mood intensity
    func calculateAverageIntensity(results: [MoodAnalysisResult]) -> Double {
        guard !results.isEmpty else { return 0.5 }
        return results.map { $0.intensity }.reduce(0, +) / Double(results.count)
    }

    /// Get dominant mood from analysis results
    func getDominantMood(results: [MoodAnalysisResult]) -> Mood? {
        let moodCounts = Dictionary(grouping: results.compactMap { $0.moodEnum }, by: { $0 })
            .mapValues { $0.count }

        return moodCounts.max(by: { $0.value < $1.value })?.key
    }

    /// Get overall sentiment
    func getOverallSentiment(results: [MoodAnalysisResult]) -> MoodAnalysisResult.Sentiment {
        let sentiments = results.map { $0.sentiment }
        let positiveCount = sentiments.filter { $0 == .positive }.count
        let negativeCount = sentiments.filter { $0 == .negative }.count
        let total = results.count

        guard total > 0 else { return .neutral }

        let positiveRatio = Double(positiveCount) / Double(total)
        let negativeRatio = Double(negativeCount) / Double(total)

        if positiveRatio > 0.6 { return .positive }
        if negativeRatio > 0.6 { return .negative }
        if positiveRatio > 0.3 && negativeRatio > 0.3 { return .mixed }
        return .neutral
    }

    // MARK: - Cache Management

    /// Clear analysis cache
    func clearCache() {
        analysisCache.removeAll()
        Log.debug("Mood analysis cache cleared", category: .moodAnalysis)
    }

    /// Remove expired cache entries
    func pruneCache() {
        analysisCache = analysisCache.filter { !$0.value.isExpired }
    }
}

// MARK: - Cached Analysis

private struct CachedAnalysis {
    let result: MoodAnalysisResult
    let timestamp: Date

    init(result: MoodAnalysisResult) {
        self.result = result
        self.timestamp = Date()
    }

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 300 // 5 minutes
    }
}

// MARK: - Environment Key

private struct MoodAnalysisServiceKey: EnvironmentKey {
    static let defaultValue = MoodAnalysisService.shared
}

extension EnvironmentValues {
    var moodAnalysisService: MoodAnalysisService {
        get { self[MoodAnalysisServiceKey.self] }
        set { self[MoodAnalysisServiceKey.self] = newValue }
    }
}
