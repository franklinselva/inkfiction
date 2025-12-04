//
//  ReflectionPolicy.swift
//  InkFiction
//
//  Prompt policy for generating mood reflections and insights
//  Ported from old app's MoodReflectionPolicy with chunked processing support
//

import Foundation

// MARK: - Reflection Mode

enum ReflectionMode {
    case chunk          // Summarize a chunk of entries (Phase 1 of Map-Reduce)
    case aggregation    // Combine chunk summaries into final reflection (Phase 2)
    case direct         // Process all entries directly (for small sets)
}

// Note: ReflectionDepth is defined in Features/Reflect/Models/ReflectModels.swift

// MARK: - Mood Reflection Policy

struct MoodReflectionPolicy: PromptPolicy {
    static let policyId = "mood_reflection"

    let depth: ReflectionDepth
    let mode: ReflectionMode

    var identifier: String { "\(Self.policyId)_\(depth.rawValue)_\(mode)" }

    init(depth: ReflectionDepth = .standard, mode: ReflectionMode = .direct) {
        self.depth = depth
        self.mode = mode
    }

    var modelRequirements: ModelRequirements {
        let contextWindow: Int
        switch depth {
        case .quick:
            contextWindow = 8192
        case .standard:
            contextWindow = 100_000
        case .deep:
            contextWindow = 500_000
        }

        return ModelRequirements(
            minContextWindow: contextWindow,
            preferredModel: .flash,
            capabilities: [.textGeneration, .structuredOutput],
            temperature: 0.7,
            maxOutputTokens: 2048
        )
    }

    var contextAllocation: ContextAllocation {
        switch depth {
        case .quick:
            return ContextAllocation(
                systemRatio: 0.10,
                userRatio: 0.10,
                contentRatio: 0.65,
                outputRatio: 0.15
            )
        case .standard:
            return ContextAllocation(
                systemRatio: 0.05,
                userRatio: 0.10,
                contentRatio: 0.70,
                outputRatio: 0.15
            )
        case .deep:
            return ContextAllocation(
                systemRatio: 0.05,
                userRatio: 0.10,
                contentRatio: 0.75,
                outputRatio: 0.10
            )
        }
    }

    func validate(context: PromptContext) throws {
        guard context.mood != nil else {
            throw PromptValidationError.missingRequiredContext("mood")
        }

        switch mode {
        case .chunk, .direct:
            if context.journalEntries == nil && context.primaryContent.isEmpty {
                throw PromptValidationError.missingRequiredContext("journalEntries or primaryContent")
            }
        case .aggregation:
            guard context.secondaryContent != nil else {
                throw PromptValidationError.missingRequiredContext("secondaryContent (chunk summaries)")
            }
        }
    }

    func buildPrompt(context: PromptContext) throws -> PromptComponents {
        guard let mood = context.mood else {
            throw PromptValidationError.missingRequiredContext("mood")
        }

        switch mode {
        case .chunk:
            return try buildChunkPrompt(mood: mood, context: context)
        case .aggregation:
            return try buildAggregationPrompt(mood: mood, context: context)
        case .direct:
            return try buildDirectPrompt(mood: mood, context: context)
        }
    }

    // MARK: - Chunk Mode (Phase 1 of Map-Reduce)

    private func buildChunkPrompt(mood: Mood, context: PromptContext) throws -> PromptComponents {
        let moodFocus = getMoodFocus(for: mood)

        let systemPrompt = """
            Summarize \(mood.rawValue.lowercased()) journal entries.
            Focus on: \(moodFocus)

            Provide concise summary capturing essence and emotions.
            """

        let chunkInfo = context.customVariables?["chunkInfo"] ?? "chunk"

        let content = """
            Entries (\(chunkInfo)):
            \(context.primaryContent)

            Provide a JSON response with:
            {
              "summary": "100-150 word summary capturing essence and emotions",
              "themes": ["theme1", "theme2", "theme3"],
              "emotional_tone": "1-2 word description"
            }

            Be concise, insightful, and focus on the emotional journey.
            """

        return PromptComponents(
            systemPrompt: systemPrompt,
            content: content,
            responseFormat: .json
        )
    }

    // MARK: - Aggregation Mode (Phase 2 of Map-Reduce)

    private func buildAggregationPrompt(mood: Mood, context: PromptContext) throws -> PromptComponents {
        guard let secondaryContent = context.secondaryContent else {
            throw PromptValidationError.missingRequiredContext("secondaryContent (chunk summaries)")
        }

        let moodContext = getMoodContext(for: mood)

        let systemPrompt = """
            Create a reflective analysis for \(mood.rawValue.lowercased()) mood.

            Generate cohesive reflection that \(moodContext).
            Write with empathy, insight, and encouragement.
            """

        let timeframeText = context.timeframe?.rawValue ?? "recent"
        let entryCount = context.customVariables?["entryCount"] ?? "unknown"

        let content = """
            Timeframe: \(timeframeText)
            Total entries: \(entryCount)

            Period summaries:
            \(secondaryContent)

            Generate a JSON response:
            {
              "summary": "150-200 word cohesive reflection",
              "key_insight": "One powerful takeaway sentence",
              "themes": ["recurring_theme1", "recurring_theme2", "recurring_theme3"],
              "emotional_progression": "How emotions evolved over time (1 sentence)"
            }

            Write with empathy, insight, and encouragement.
            """

        return PromptComponents(
            systemPrompt: systemPrompt,
            content: content,
            responseFormat: .json
        )
    }

    // MARK: - Direct Mode (Small Entry Sets)

    private func buildDirectPrompt(mood: Mood, context: PromptContext) throws -> PromptComponents {
        guard let entries = context.journalEntries, !entries.isEmpty else {
            throw PromptValidationError.missingRequiredContext("journalEntries")
        }

        let systemPrompt = """
            Create a reflective analysis for \(mood.rawValue.lowercased()) mood entries.

            Provide:
            - Summary (150-200 words) that acknowledges the emotional experience
            - Key insight (one powerful takeaway sentence)
            - Top 3-5 recurring themes
            - Emotional progression (how emotions evolved)

            Write with empathy, insight, and encouragement.
            """

        // Add companion-specific mood approach if available
        var userContext = ""
        if let companion = context.companion {
            let moodAnalysisGuidance = CompanionPromptTemplates.moodAnalysisPrompt(
                for: companion,
                emotionalExpression: .moodTracking
            )
            userContext = """
                Companion Approach:
                \(moodAnalysisGuidance)
                """
        }

        let timeframeText = context.timeframe?.rawValue ?? "recent"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        let entriesText = entries.map { entry in
            "\(dateFormatter.string(from: entry.createdAt)): \(entry.content)"
        }.joined(separator: "\n\n")

        let content = """
            Timeframe: \(timeframeText)
            Total entries: \(entries.count)
            Mood: \(mood.rawValue)

            Journal Entries:
            \(entriesText)

            Analyze these journal entries and create a thoughtful reflection with JSON output.
            """

        return PromptComponents(
            systemPrompt: systemPrompt,
            userContext: userContext,
            content: content,
            responseFormat: .json
        )
    }

    // MARK: - Helper Methods

    private func getMoodFocus(for mood: Mood) -> String {
        switch mood {
        case .peaceful:
            return "sources of calm, mindfulness practices, serene moments"
        case .anxious:
            return "triggers, coping strategies, moments of relief, resilience"
        case .happy:
            return "joy sources, gratitude, celebrations, positive connections"
        case .sad:
            return "processing emotions, support systems, healing progress"
        case .excited:
            return "anticipation, energy sources, achievements, aspirations"
        case .thoughtful:
            return "insights, questions explored, learning, self-discovery"
        case .angry:
            return "frustrations, boundaries, resolution attempts, understanding"
        case .neutral:
            return "daily rhythms, observations, stability, routine meaning"
        }
    }

    private func getMoodContext(for mood: Mood) -> String {
        switch mood {
        case .peaceful:
            return "celebrates tranquility and identifies peace patterns"
        case .anxious:
            return "validates concerns while highlighting coping strengths"
        case .happy:
            return "amplifies joy and encourages continued gratitude"
        case .sad:
            return "acknowledges pain while noting healing moments"
        case .excited:
            return "channels enthusiasm toward meaningful goals"
        case .thoughtful:
            return "deepens insights and connects to growth"
        case .angry:
            return "processes frustration constructively"
        case .neutral:
            return "finds meaning in everyday stability"
        }
    }
}

// MARK: - Weekly Summary Policy

struct WeeklySummaryPolicy: PromptPolicy {
    static let policyId = "weekly_summary"

    var identifier: String { Self.policyId }

    var modelRequirements: ModelRequirements {
        ModelRequirements(
            minContextWindow: 32000,
            preferredModel: .flash,
            capabilities: [.textGeneration],
            temperature: 0.7,
            maxOutputTokens: 1024
        )
    }

    var contextAllocation: ContextAllocation {
        ContextAllocation(
            systemRatio: 0.10,
            userRatio: 0.10,
            contentRatio: 0.65,
            outputRatio: 0.15
        )
    }

    func validate(context: PromptContext) throws {
        guard let entries = context.journalEntries, !entries.isEmpty else {
            throw PromptValidationError.missingRequiredContext("journalEntries")
        }
    }

    func buildPrompt(context: PromptContext) throws -> PromptComponents {
        guard let entries = context.journalEntries, !entries.isEmpty else {
            throw PromptValidationError.missingRequiredContext("journalEntries")
        }

        let systemPrompt = """
            Generate a thoughtful weekly reflection summary.

            Structure:
            1. Opening reflection (2-3 sentences)
            2. Key themes from the week
            3. Emotional journey overview
            4. Growth observations
            5. Gentle guidance for the week ahead

            Keep it concise but meaningful (150-200 words).
            """

        var userContext = ""
        if let companion = context.companion {
            userContext = CompanionPromptTemplates.weeklySummaryPrompt(
                for: companion,
                context: CompanionContextAdapter.buildUserAIContext(from: context)
            )
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        let entriesText = entries.map { entry in
            "\(dateFormatter.string(from: entry.createdAt)): \(entry.content)"
        }.joined(separator: "\n\n")

        let content = """
            Week's Journal Entries:

            \(entriesText)

            Create a thoughtful summary of the week.
            """

        return PromptComponents(
            systemPrompt: systemPrompt,
            userContext: userContext,
            content: content,
            responseFormat: .plainText
        )
    }
}

// MARK: - Quick Insight Policy

struct QuickInsightPolicy: PromptPolicy {
    static let policyId = "quick_insight"

    var identifier: String { Self.policyId }

    var modelRequirements: ModelRequirements {
        ModelRequirements(
            minContextWindow: 4000,
            preferredModel: .flash,
            capabilities: [.textGeneration],
            temperature: 0.8,
            maxOutputTokens: 256
        )
    }

    var contextAllocation: ContextAllocation {
        ContextAllocation(
            systemRatio: 0.10,
            userRatio: 0.10,
            contentRatio: 0.70,
            outputRatio: 0.10
        )
    }

    func validate(context: PromptContext) throws {
        guard !context.primaryContent.isEmpty else {
            throw PromptValidationError.emptyContent
        }
    }

    func buildPrompt(context: PromptContext) throws -> PromptComponents {
        let systemPrompt = """
            Generate a brief, insightful reflection (50-75 words) that:
            - Acknowledges the emotional experience
            - Offers a supportive insight
            - Ends with a gentle reflection question

            Use warm, encouraging language.
            """

        var userContext = ""
        if let companion = context.companion {
            userContext = CompanionPromptTemplates.insightPrompt(
                for: companion,
                journalingStyle: .quickNotes
            )
        }

        let content = """
            Recent journal entry:

            "\(context.primaryContent)"

            Provide a brief, meaningful insight.
            """

        return PromptComponents(
            systemPrompt: systemPrompt,
            userContext: userContext,
            content: content,
            responseFormat: .plainText
        )
    }
}

// MARK: - Legacy Reflection Policy (for backwards compatibility)

struct ReflectionPolicy: PromptPolicy {
    static let policyId = "reflection"

    var identifier: String { Self.policyId }

    var modelRequirements: ModelRequirements { .reflection }

    var contextAllocation: ContextAllocation { .detailedResponse }

    func validate(context: PromptContext) throws {
        guard !context.primaryContent.isEmpty else {
            throw PromptValidationError.emptyContent
        }

        guard context.timeframe != nil else {
            throw PromptValidationError.missingRequiredContext("timeframe")
        }
    }

    func buildPrompt(context: PromptContext) throws -> PromptComponents {
        let timeframe = context.timeframe ?? .thisWeek
        let companionVoice = buildCompanionVoice(context.companion)
        let entriesContext = buildEntriesContext(context.journalEntries)

        let systemPrompt = """
            You are a thoughtful, empathetic AI companion helping users reflect on their journaling journey.
            \(companionVoice)

            Your role is to:
            - Offer warm, supportive reflections on their emotional patterns
            - Identify positive trends and growth
            - Gently acknowledge challenges without dwelling on negatives
            - Provide actionable, compassionate suggestions
            - Celebrate consistency and self-awareness

            Guidelines:
            - Use "you" language to speak directly to the user
            - Be encouraging but authentic - avoid toxic positivity
            - Reference specific moods or themes from their entries
            - Keep reflections personal and relevant
            - Suggest small, achievable actions when appropriate
            """

        let content = """
            Generate a reflection for \(timeframe.displayName.lowercased()) based on these journal entries:

            \(entriesContext)

            ---

            Entry summaries:
            \(context.primaryContent)

            ---

            Respond with JSON:
            {
              "reflection": "A warm, personalized 2-3 paragraph reflection",
              "insights": ["3-5 key insights or patterns noticed"],
              "suggestions": ["2-3 gentle, actionable suggestions"],
              "moodTrend": {
                "direction": "improving, declining, or stable",
                "dominantMood": "the most frequent mood",
                "variability": "high, medium, or low"
              }
            }
            """

        return PromptComponents(
            systemPrompt: systemPrompt,
            content: content,
            responseFormat: .json
        )
    }

    private func buildCompanionVoice(_ companion: AICompanion?) -> String {
        guard let companion = companion else { return "" }

        return """

            You are embodying \(companion.name), \(companion.tagline).
            Personality: \(companion.personality.joined(separator: ", "))
            Speak in a way that reflects these traits while remaining supportive.
            """
    }

    private func buildEntriesContext(_ entries: [JournalEntryModel]?) -> String {
        guard let entries = entries, !entries.isEmpty else {
            return "No specific entries provided."
        }

        let moodCounts = Dictionary(grouping: entries, by: { $0.mood })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        var context: [String] = []
        context.append("Total entries: \(entries.count)")
        context.append("Mood distribution:")

        for (mood, count) in moodCounts {
            let percentage = Int(Double(count) / Double(entries.count) * 100)
            context.append("  - \(mood.rawValue): \(count) (\(percentage)%)")
        }

        if let firstDate = entries.map({ $0.createdAt }).min(),
           let lastDate = entries.map({ $0.createdAt }).max() {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            context.append("Date range: \(formatter.string(from: firstDate)) to \(formatter.string(from: lastDate))")
        }

        return context.joined(separator: "\n")
    }
}
