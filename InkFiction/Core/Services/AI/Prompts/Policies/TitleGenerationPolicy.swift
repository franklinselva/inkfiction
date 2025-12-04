//
//  TitleGenerationPolicy.swift
//  InkFiction
//
//  Prompt policy for generating journal entry titles
//

import Foundation

// MARK: - Title Generation Policy

struct TitleGenerationPolicy: PromptPolicy {
    static let policyId = "title_generation"

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

    var contextAllocation: ContextAllocation { .contentFocused }

    func validate(context: PromptContext) throws {
        guard !context.primaryContent.isEmpty else {
            throw PromptValidationError.emptyContent
        }

        if context.primaryContent.count < 10 {
            throw PromptValidationError.invalidContext("Content too short for meaningful title")
        }
    }

    func buildPrompt(context: PromptContext) throws -> PromptComponents {
        let moodContext = context.mood.map { "The entry has a \($0.rawValue.lowercased()) mood." } ?? ""

        let systemPrompt = """
        You are a creative writer specializing in crafting evocative, memorable titles for personal journal entries.

        Guidelines for titles:
        - Be concise: 3-7 words ideal
        - Capture the essence or emotion of the entry
        - Use evocative language that draws readers in
        - Avoid generic titles like "My Day" or "Journal Entry"
        - Don't use dates in titles
        - Match the tone of the content (serious, playful, reflective, etc.)
        - Can use metaphors, questions, or intriguing phrases

        Good examples:
        - "The Quiet After the Storm"
        - "Chasing Sunsets Again"
        - "Why I Finally Said Yes"
        - "Coffee, Chaos, and Small Victories"
        - "Learning to Let Go"
        """

        let content = """
        Generate a title for this journal entry:
        \(moodContext)

        ---
        \(String(context.primaryContent.prefix(2000)))
        ---

        Respond with JSON:
        {
          "title": "Your main title suggestion",
          "alternatives": ["Alternative 1", "Alternative 2"]
        }
        """

        return PromptComponents(
            systemPrompt: systemPrompt,
            content: content,
            responseFormat: .json
        )
    }
}
