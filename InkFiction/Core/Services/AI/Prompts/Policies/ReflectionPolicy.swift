//
//  ReflectionPolicy.swift
//  InkFiction
//
//  Prompt policy for generating mood reflections and insights
//

import Foundation

// MARK: - Reflection Policy

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
