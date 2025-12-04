//
//  TitleGenerationPolicy.swift
//  InkFiction
//
//  Prompt policy for generating journal entry titles
//  Ported from old app's TitleGenerationPolicy
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
            temperature: 0.7,
            maxOutputTokens: 256
        )
    }

    var contextAllocation: ContextAllocation {
        ContextAllocation(
            systemRatio: 0.10,
            userRatio: 0.15,
            contentRatio: 0.65,
            outputRatio: 0.10
        )
    }

    func validate(context: PromptContext) throws {
        guard !context.primaryContent.isEmpty else {
            throw PromptValidationError.emptyContent
        }

        if context.primaryContent.count < 10 {
            throw PromptValidationError.invalidContext("Content too short for meaningful title")
        }
    }

    func buildPrompt(context: PromptContext) throws -> PromptComponents {
        let systemPrompt = """
            Generate concise, meaningful journal entry titles.

            Rules:
            - 3-6 words maximum
            - Capture the essence of the entry
            - No quotation marks or special formatting
            - Plain text only
            - Be memorable and meaningful
            """

        var userContext = ""
        if let companion = context.companion {
            // Use full companion template
            userContext = CompanionPromptTemplates.titlePrompt(
                for: companion,
                visualPreference: context.visualPreference ?? .abstractDreamy
            )
        } else {
            // Generic title generation guidance
            userContext = """
                Title Style Guidelines:
                - Descriptive: Capture the main theme
                - Evocative: Spark memory and emotion
                - Concise: Use impactful words
                - Authentic: Match the entry's tone
                """
        }

        let content = """
            Journal Entry:
            "\(context.primaryContent)"

            Generate a title that captures the essence.
            """

        return PromptComponents(
            systemPrompt: systemPrompt,
            userContext: userContext,
            content: content,
            responseFormat: .plainText
        )
    }
}
