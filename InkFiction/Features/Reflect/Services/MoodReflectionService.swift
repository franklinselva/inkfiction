//
//  MoodReflectionService.swift
//  InkFiction
//
//  Service for generating AI-powered mood reflections with chunked processing
//  Ported from old app's MoodReflectionService
//

import Foundation
import SwiftUI

// MARK: - Reflection Chunk

struct ReflectionChunk: Identifiable {
    let id: UUID
    let entries: [JournalEntryModel]
    let tokenCount: Int
    let dateRange: ClosedRange<Date>
    let chunkIndex: Int
    let totalChunks: Int

    var progressLabel: String {
        "Chunk \(chunkIndex + 1) of \(totalChunks)"
    }

    init(entries: [JournalEntryModel], chunkIndex: Int, totalChunks: Int) {
        self.id = UUID()
        self.entries = entries
        self.chunkIndex = chunkIndex
        self.totalChunks = totalChunks

        // Calculate token count (rough estimate: 1 token ≈ 4 characters)
        let totalText = entries.map { $0.title + " " + $0.content }.joined(separator: " ")
        self.tokenCount = totalText.count / 4

        // Determine date range
        let dates = entries.map { $0.createdAt }.sorted()
        self.dateRange = (dates.first ?? Date())...(dates.last ?? Date())
    }
}

// MARK: - Chunk Processing Result

struct ChunkProcessingResult {
    let chunk: ReflectionChunk
    let summary: String
    let themes: [String]
    let processingTime: TimeInterval
    let tokensUsed: Int
}

// MARK: - Chunk Summary Response

struct ChunkSummaryResponse: Decodable {
    let summary: String
    let themes: [String]
    let emotionalTone: String

    enum CodingKeys: String, CodingKey {
        case summary
        case themes
        case emotionalTone = "emotional_tone"
    }
}

// MARK: - Reflection Response

struct ReflectionResponse: Decodable {
    let summary: String
    let keyInsight: String
    let themes: [String]
    let emotionalProgression: String

    enum CodingKeys: String, CodingKey {
        case summary
        case keyInsight = "key_insight"
        case themes
        case emotionalProgression = "emotional_progression"
    }
}

// MARK: - Reflection Error

enum ReflectionError: LocalizedError {
    case insufficientEntries(minimum: Int, actual: Int)
    case tokenLimitExceeded(used: Int, limit: Int)
    case chunkProcessingFailed(failedChunks: Int, totalChunks: Int)
    case aggregationFailed
    case invalidResponse
    case processingFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .insufficientEntries(let minimum, let actual):
            return "Need at least \(minimum) entries, found \(actual)"
        case .tokenLimitExceeded(let used, let limit):
            return "Token limit exceeded: \(used)/\(limit)"
        case .chunkProcessingFailed(let failed, let total):
            return "Failed to process \(failed) of \(total) chunks"
        case .aggregationFailed:
            return "Failed to generate final reflection"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .processingFailed(let reason):
            return "Processing failed: \(reason)"
        }
    }

    var fallbackStrategy: String {
        switch self {
        case .tokenLimitExceeded:
            return "Try using fewer entries or Quick mode"
        case .chunkProcessingFailed:
            return "Showing partial results from successful chunks"
        default:
            return "Try again or use Quick mode"
        }
    }
}

// MARK: - Mood Reflection Service

@MainActor
@Observable
final class MoodReflectionService {

    // MARK: - Published Properties

    private(set) var isProcessing = false
    private(set) var processingProgress: Double = 0.0
    private(set) var currentBatch: String = ""
    private(set) var error: ReflectionError?

    // MARK: - Private Properties

    private let geminiService: GeminiService
    private let promptManager: PromptManager

    // Cache
    private var reflectionCache: [String: CachedMoodReflection] = [:]

    // MARK: - Initialization

    init(
        geminiService: GeminiService = .shared,
        promptManager: PromptManager = .shared
    ) {
        self.geminiService = geminiService
        self.promptManager = promptManager
    }

    // MARK: - Main Reflection Generation

    func generateMoodReflection(
        mood: Mood,
        entries: [JournalEntryModel],
        timeframe: TimeFrame,
        depth: ReflectionDepth = .standard
    ) async throws -> MoodReflection {
        // Check persistent cache first (24-hour expiry)
        let cacheKey = generateCacheKey(mood: mood, timeframe: timeframe, entries: entries)

        // Check persistent disk cache
        if let cachedReflection = ReflectionCacheManager.shared.getCachedReflection(forKey: cacheKey) {
            Log.info("Using persistent cached reflection for \(mood.rawValue)/\(timeframe.rawValue)", category: .ai)
            return cachedReflection
        }

        // Check in-memory cache (for same session)
        if let cached = reflectionCache[cacheKey], cached.isValid {
            Log.info("Using in-memory cached reflection for \(mood.rawValue)", category: .ai)
            return cached.reflection
        }

        guard !entries.isEmpty else {
            throw ReflectionError.insufficientEntries(minimum: 1, actual: 0)
        }

        isProcessing = true
        processingProgress = 0.0
        error = nil

        let startTime = Date()

        do {
            // Sample entries if too many
            let processableEntries = entries.count > 50 ?
                sampleEntries(entries, targetCount: 40, mood: mood) :
                entries

            // Step 1: Create chunks
            currentBatch = "Preparing entries..."
            processingProgress = 0.1

            let chunks = createChunks(
                entries: processableEntries,
                depth: depth
            )

            Log.info("Created \(chunks.count) chunks for \(processableEntries.count) entries", category: .ai)

            // Step 2: Process chunks
            currentBatch = "Analyzing journal entries..."
            let chunkSummaries = try await processChunks(
                chunks,
                mood: mood
            )

            // Step 3: Aggregate into final reflection
            currentBatch = "Generating reflection..."
            processingProgress = 0.8

            let finalReflection = try await aggregateReflections(
                chunkSummaries: chunkSummaries,
                mood: mood,
                timeframe: timeframe,
                originalEntries: entries,
                processingTime: Date().timeIntervalSince(startTime)
            )

            // Cache the result - both in-memory and persistent
            let cachedReflection = CachedMoodReflection(
                cacheKey: cacheKey,
                mood: mood,
                timeframe: timeframe,
                reflection: finalReflection,
                entryIds: entries.map { $0.id }
            )
            reflectionCache[cacheKey] = cachedReflection

            // Save to persistent cache (24-hour expiry)
            ReflectionCacheManager.shared.cacheReflection(finalReflection, forKey: cacheKey)

            processingProgress = 1.0
            isProcessing = false

            Log.info("Generated and cached reflection for \(mood.rawValue)/\(timeframe.rawValue) in \(finalReflection.formattedProcessingTime)", category: .ai)

            return finalReflection

        } catch {
            self.error = error as? ReflectionError ?? .processingFailed(reason: error.localizedDescription)
            isProcessing = false
            processingProgress = 0.0
            throw error
        }
    }

    // MARK: - Chunk Creation

    private func createChunks(
        entries: [JournalEntryModel],
        depth: ReflectionDepth = .standard
    ) -> [ReflectionChunk] {
        guard !entries.isEmpty else { return [] }

        let sortedEntries = entries.sorted { $0.createdAt < $1.createdAt }
        var chunks: [ReflectionChunk] = []
        var currentChunk: [JournalEntryModel] = []
        var currentTokens = 0

        let maxEntriesPerChunk = depth.entriesPerChunk
        let maxTokensPerChunk = depth.tokensPerChunk

        for entry in sortedEntries {
            let entryTokens = estimateTokens(for: entry)

            // Check if adding this entry would exceed limits
            if !currentChunk.isEmpty &&
               (currentTokens + entryTokens > maxTokensPerChunk ||
                currentChunk.count >= maxEntriesPerChunk) {
                // Save current chunk
                chunks.append(ReflectionChunk(
                    entries: currentChunk,
                    chunkIndex: chunks.count,
                    totalChunks: 0
                ))
                currentChunk = []
                currentTokens = 0
            }

            currentChunk.append(entry)
            currentTokens += entryTokens
        }

        // Add final chunk if not empty
        if !currentChunk.isEmpty {
            chunks.append(ReflectionChunk(
                entries: currentChunk,
                chunkIndex: chunks.count,
                totalChunks: 0
            ))
        }

        // Update total chunks count
        let totalChunks = chunks.count
        return chunks.map { chunk in
            ReflectionChunk(
                entries: chunk.entries,
                chunkIndex: chunk.chunkIndex,
                totalChunks: totalChunks
            )
        }
    }

    // MARK: - Chunk Processing

    private func processChunks(
        _ chunks: [ReflectionChunk],
        mood: Mood
    ) async throws -> [ChunkProcessingResult] {
        var results: [ChunkProcessingResult] = []
        let totalChunks = chunks.count

        for (index, chunk) in chunks.enumerated() {
            currentBatch = "Processing chunk \(index + 1) of \(totalChunks)..."
            processingProgress = 0.2 + (0.5 * Double(index) / Double(totalChunks))

            let chunkStartTime = Date()

            do {
                let summary = try await processChunk(chunk, mood: mood)
                let processingTime = Date().timeIntervalSince(chunkStartTime)

                results.append(ChunkProcessingResult(
                    chunk: chunk,
                    summary: summary.summary,
                    themes: summary.themes,
                    processingTime: processingTime,
                    tokensUsed: chunk.tokenCount
                ))

                Log.debug("Processed chunk \(index + 1)/\(totalChunks) in \(String(format: "%.2f", processingTime))s", category: .ai)

            } catch {
                Log.error("Failed to process chunk \(index + 1): \(error)", category: .ai)
                // Continue with other chunks
                if chunks.count > 1 {
                    continue
                } else {
                    throw error
                }
            }
        }

        guard !results.isEmpty else {
            throw ReflectionError.chunkProcessingFailed(failedChunks: chunks.count, totalChunks: totalChunks)
        }

        return results
    }

    private func processChunk(
        _ chunk: ReflectionChunk,
        mood: Mood
    ) async throws -> ChunkSummaryResponse {
        let entriesText = chunk.entries.map { entry in
            truncateEntry(entry, maxTokens: 400)
        }.joined(separator: "\n---\n")

        // Build prompt using MoodReflectionPolicy (chunk mode)
        let context = PromptContext(
            primaryContent: entriesText,
            mood: mood,
            customVariables: ["chunkInfo": chunk.progressLabel]
        )

        let policy = MoodReflectionPolicy(depth: .standard, mode: .chunk)
        let components = try policy.buildPrompt(context: context)

        // Validate entries have content
        if entriesText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Log.warning("Chunk has no entry content", category: .ai)
            throw ReflectionError.processingFailed(reason: "No entry content to analyze")
        }

        Log.debug("Processing chunk with \(chunk.entries.count) entries, ~\(entriesText.count) chars", category: .ai)

        let response = try await geminiService.generateText(
            prompt: components.content,
            systemPrompt: components.systemPrompt,
            operation: Constants.AI.Operations.weeklyMonthlySummary,
            temperature: 0.7,
            maxTokens: 2048,
            responseFormat: components.responseFormat
        )

        guard let data = response.data(using: .utf8) else {
            Log.error("Empty response from AI service", category: .ai)
            throw ReflectionError.invalidResponse
        }

        return try JSONDecoder().decode(ChunkSummaryResponse.self, from: data)
    }

    // MARK: - Aggregation

    private func aggregateReflections(
        chunkSummaries: [ChunkProcessingResult],
        mood: Mood,
        timeframe: TimeFrame,
        originalEntries: [JournalEntryModel],
        processingTime: TimeInterval
    ) async throws -> MoodReflection {

        let summaries = chunkSummaries.map { $0.summary }
        let summariesText = summaries.enumerated()
            .map { "Period \($0.offset + 1): \($0.element)" }
            .joined(separator: "\n\n")

        // Build prompt using MoodReflectionPolicy (aggregation mode)
        let context = PromptContext(
            primaryContent: "Aggregating \(chunkSummaries.count) chunk summaries",
            secondaryContent: summariesText,
            mood: mood,
            timeframe: timeframe,
            customVariables: ["entryCount": "\(originalEntries.count)"]
        )

        let policy = MoodReflectionPolicy(depth: .standard, mode: .aggregation)
        let components = try policy.buildPrompt(context: context)

        Log.debug("Aggregating \(chunkSummaries.count) chunk summaries", category: .ai)

        let response = try await geminiService.generateText(
            prompt: components.content,
            systemPrompt: components.systemPrompt,
            operation: Constants.AI.Operations.weeklyMonthlySummary,
            temperature: 0.7,
            maxTokens: 2048,
            responseFormat: components.responseFormat
        )

        guard let data = response.data(using: .utf8) else {
            Log.error("Empty response from AI service during aggregation", category: .ai)
            throw ReflectionError.aggregationFailed
        }

        let reflectionResponse = try JSONDecoder().decode(ReflectionResponse.self, from: data)

        // Calculate metadata
        let totalTokens = chunkSummaries.reduce(0) { $0 + $1.tokensUsed }
        let avgTokensPerChunk = chunkSummaries.isEmpty ? 0 :
            totalTokens / chunkSummaries.count

        let metadata = MoodReflection.ProcessingMetadata(
            totalTokensUsed: totalTokens,
            chunksProcessed: chunkSummaries.count,
            averageTokensPerChunk: avgTokensPerChunk,
            processingStrategy: "Chunked Processing"
        )

        return MoodReflection(
            id: UUID(),
            mood: mood,
            timeframe: timeframe,
            summary: reflectionResponse.summary,
            keyInsight: reflectionResponse.keyInsight,
            themes: reflectionResponse.themes,
            emotionalProgression: reflectionResponse.emotionalProgression,
            entryCount: originalEntries.count,
            processingTime: processingTime,
            generatedAt: Date(),
            metadata: metadata
        )
    }

    // MARK: - Helper Methods

    private func estimateTokens(for entry: JournalEntryModel) -> Int {
        let text = "\(entry.title) \(entry.content)"
        return Int(Double(text.count) / 3.6)
    }

    private func truncateEntry(_ entry: JournalEntryModel, maxTokens: Int = 500) -> String {
        let fullText = entry.title.isEmpty ?
            entry.content :
            "\(entry.title): \(entry.content)"

        let currentTokens = Int(Double(fullText.count) / 3.6)
        if currentTokens <= maxTokens {
            return fullText
        }

        let maxChars = maxTokens * 3
        if fullText.count <= maxChars {
            return fullText
        }

        let beginChars = Int(Double(maxChars) * 0.7)
        let endChars = maxChars - beginChars - 20

        let beginning = String(fullText.prefix(beginChars))
        let ending = String(fullText.suffix(endChars))

        return "\(beginning)... [content trimmed] ...\(ending)"
    }

    // MARK: - Intelligent Sampling

    private func sampleEntries(
        _ entries: [JournalEntryModel],
        targetCount: Int = 30,
        mood: Mood? = nil
    ) -> [JournalEntryModel] {
        guard entries.count > targetCount else { return entries }

        var sampledIds = Set<UUID>()
        var sampledEntries = [JournalEntryModel]()

        // 40% most recent entries
        let recentCount = Int(Double(targetCount) * 0.4)
        let recentEntries = Array(entries.sorted { $0.createdAt > $1.createdAt }.prefix(recentCount))
        for entry in recentEntries {
            if sampledIds.insert(entry.id).inserted {
                sampledEntries.append(entry)
            }
        }

        // 30% highest emotional intensity
        let intensityCount = Int(Double(targetCount) * 0.3)
        let intensityEntries = entries
            .sorted { estimateEmotionalIntensity($0) > estimateEmotionalIntensity($1) }
            .prefix(intensityCount)
        for entry in intensityEntries {
            if sampledIds.insert(entry.id).inserted {
                sampledEntries.append(entry)
            }
        }

        // 20% longest/most detailed entries
        let detailCount = Int(Double(targetCount) * 0.2)
        let detailedEntries = entries
            .sorted { $0.content.count > $1.content.count }
            .prefix(detailCount)
        for entry in detailedEntries {
            if sampledIds.insert(entry.id).inserted {
                sampledEntries.append(entry)
            }
        }

        // Fill remaining with evenly distributed entries
        let remainingCount = targetCount - sampledEntries.count
        if remainingCount > 0 {
            let step = max(1, entries.count / remainingCount)
            for i in stride(from: 0, to: entries.count, by: step) {
                if sampledEntries.count >= targetCount { break }
                if sampledIds.insert(entries[i].id).inserted {
                    sampledEntries.append(entries[i])
                }
            }
        }

        return sampledEntries.sorted { $0.createdAt < $1.createdAt }
    }

    private func estimateEmotionalIntensity(_ entry: JournalEntryModel) -> Double {
        let emotionalWords = [
            "love", "hate", "amazing", "terrible", "wonderful", "awful",
            "excited", "depressed", "anxious", "peaceful", "angry", "happy",
            "sad", "frustrated", "grateful", "blessed", "worried", "scared"
        ]

        let text = entry.content.lowercased()
        var intensity = 0.0

        for word in emotionalWords {
            if text.contains(word) {
                intensity += 0.1
            }
        }

        intensity += Double(text.filter { $0 == "!" }.count) * 0.05
        intensity += Double(text.filter { $0 == "?" }.count) * 0.03
        intensity += min(0.2, Double(text.count) / 5000)

        return min(1.0, intensity)
    }

    // MARK: - Cache Management

    private func generateCacheKey(mood: Mood, timeframe: TimeFrame, entries: [JournalEntryModel]) -> String {
        // Simple key based on mood + timeframe (not entry IDs, so same mood/timeframe returns cached result)
        return "\(mood.rawValue)_\(timeframe.rawValue)"
    }

    func clearCache() {
        reflectionCache.removeAll()
        ReflectionCacheManager.shared.clearAllCache()
        Log.debug("Reflection cache cleared", category: .ai)
    }

    /// Force regenerate reflection (bypass cache)
    func regenerateReflection(
        mood: Mood,
        entries: [JournalEntryModel],
        timeframe: TimeFrame,
        depth: ReflectionDepth = .standard
    ) async throws -> MoodReflection {
        // Clear cache for this key
        let cacheKey = generateCacheKey(mood: mood, timeframe: timeframe, entries: entries)
        reflectionCache.removeValue(forKey: cacheKey)
        ReflectionCacheManager.shared.removeCache(forKey: cacheKey)

        // Generate fresh reflection
        return try await generateMoodReflection(
            mood: mood,
            entries: entries,
            timeframe: timeframe,
            depth: depth
        )
    }
}

// MARK: - Reflection Cache Manager (Persistent)

@MainActor
final class ReflectionCacheManager {
    static let shared = ReflectionCacheManager()

    private let cacheKey = "reflection_cache_v1"
    private let cacheExpiryHours: Double = 24

    private init() {
        // Clean expired cache on init
        cleanExpiredCache()
    }

    // MARK: - Public Methods

    func getCachedReflection(forKey key: String) -> MoodReflection? {
        guard let cache = loadCache(),
              let entry = cache[key],
              !entry.isExpired else {
            return nil
        }
        Log.info("Using cached reflection for key: \(key)", category: .ai)
        return entry.reflection
    }

    func cacheReflection(_ reflection: MoodReflection, forKey key: String) {
        var cache = loadCache() ?? [:]
        let entry = CachedReflectionEntry(
            reflection: reflection,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(cacheExpiryHours * 3600)
        )
        cache[key] = entry
        saveCache(cache)
        Log.debug("Cached reflection for key: \(key), expires in \(cacheExpiryHours) hours", category: .ai)
    }

    func removeCache(forKey key: String) {
        var cache = loadCache() ?? [:]
        cache.removeValue(forKey: key)
        saveCache(cache)
    }

    func clearAllCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        Log.debug("All reflection cache cleared", category: .ai)
    }

    // MARK: - Private Methods

    private func loadCache() -> [String: CachedReflectionEntry]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else {
            return nil
        }
        do {
            return try JSONDecoder().decode([String: CachedReflectionEntry].self, from: data)
        } catch {
            Log.warning("Failed to load reflection cache: \(error)", category: .ai)
            return nil
        }
    }

    private func saveCache(_ cache: [String: CachedReflectionEntry]) {
        do {
            let data = try JSONEncoder().encode(cache)
            UserDefaults.standard.set(data, forKey: cacheKey)
        } catch {
            Log.error("Failed to save reflection cache: \(error)", category: .ai)
        }
    }

    private func cleanExpiredCache() {
        guard var cache = loadCache() else { return }
        let initialCount = cache.count
        cache = cache.filter { !$0.value.isExpired }
        if cache.count < initialCount {
            saveCache(cache)
            Log.debug("Cleaned \(initialCount - cache.count) expired cache entries", category: .ai)
        }
    }
}

// MARK: - Cached Reflection Entry (Codable for persistence)

private struct CachedReflectionEntry: Codable {
    let reflection: MoodReflection
    let createdAt: Date
    let expiresAt: Date

    var isExpired: Bool {
        Date() > expiresAt
    }
}

// MARK: - In-Memory Cached Mood Reflection

private struct CachedMoodReflection {
    let cacheKey: String
    let mood: Mood
    let timeframe: TimeFrame
    let reflection: MoodReflection
    let entryIdsHash: String
    let createdAt: Date
    let expiresAt: Date

    init(cacheKey: String, mood: Mood, timeframe: TimeFrame, reflection: MoodReflection, entryIds: [UUID]) {
        self.cacheKey = cacheKey
        self.mood = mood
        self.timeframe = timeframe
        self.reflection = reflection
        self.entryIdsHash = Self.generateEntriesHash(entryIds)
        self.createdAt = Date()
        self.expiresAt = Date().addingTimeInterval(24 * 60 * 60) // 24 hours
    }

    var isExpired: Bool {
        Date() > expiresAt
    }

    var isValid: Bool {
        !isExpired
    }

    private static func generateEntriesHash(_ ids: [UUID]) -> String {
        let sortedIds = ids.map { $0.uuidString }.sorted()
        let combined = sortedIds.joined(separator: ",")
        return String(combined.hash)
    }
}
