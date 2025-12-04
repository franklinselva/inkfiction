//
//  JournalEnhancementPolicy.swift
//  InkFiction
//
//  Prompt policy for enhancing journal entry content
//

import Foundation

// MARK: - Journal Enhancement Policy

struct JournalEnhancementPolicy: PromptPolicy {
    static let policyId = "journal_enhancement"

    var identifier: String { Self.policyId }

    var modelRequirements: ModelRequirements {
        ModelRequirements(
            minContextWindow: 8000,
            preferredModel: .flash,
            capabilities: [.textGeneration],
            temperature: 0.7,
            maxOutputTokens: 4096
        )
    }

    var contextAllocation: ContextAllocation { .balanced }

    func validate(context: PromptContext) throws {
        guard !context.primaryContent.isEmpty else {
            throw PromptValidationError.emptyContent
        }

        if context.primaryContent.count > 30000 {
            throw PromptValidationError.contentTooLong(max: 30000, actual: context.primaryContent.count)
        }
    }

    func buildPrompt(context: PromptContext) throws -> PromptComponents {
        let styleRaw = context.customVariables?["enhancementStyle"] ?? EnhancementStyle.refine.rawValue
        let style = EnhancementStyle(rawValue: styleRaw) ?? .refine

        let companionContext = buildCompanionContext(context.companion)
        let styleInstructions = buildStyleInstructions(style)

        let systemPrompt = """
        You are a skilled writing assistant helping to enhance personal journal entries.
        \(companionContext)

        Core principles:
        - Preserve the author's authentic voice and perspective
        - Maintain all factual information and personal details
        - Keep the first-person narrative style
        - Never add fictional events or emotions not implied in the original
        - Respect the privacy and personal nature of journal writing

        \(styleInstructions)
        """

        let content = """
        Enhance this journal entry using the '\(style.displayName)' style:

        ---
        \(context.primaryContent)
        ---

        Respond with JSON:
        {
          "enhancedContent": "The enhanced journal entry text",
          "changes": ["Brief description of changes made"]
        }
        """

        return PromptComponents(
            systemPrompt: systemPrompt,
            content: content,
            responseFormat: .json
        )
    }

    private func buildCompanionContext(_ companion: AICompanion?) -> String {
        guard let companion = companion else { return "" }

        return """

        You are channeling the voice of \(companion.name), the \(companion.tagline).
        Writing style traits: \(companion.personality.joined(separator: ", "))
        """
    }

    private func buildStyleInstructions(_ style: EnhancementStyle) -> String {
        switch style {
        case .expand:
            return """
            EXPAND style instructions:
            - Add sensory details (sights, sounds, smells, textures)
            - Elaborate on emotions and their nuances
            - Include reflective thoughts that deepen the narrative
            - Expand brief mentions into fuller descriptions
            - Aim for 50-100% longer than original
            """

        case .refine:
            return """
            REFINE style instructions:
            - Improve sentence structure and flow
            - Fix grammar and punctuation
            - Enhance word choice for clarity and impact
            - Maintain similar length to original
            - Polish without changing the core message
            """

        case .poetic:
            return """
            POETIC style instructions:
            - Add metaphors and imagery where appropriate
            - Use more lyrical, expressive language
            - Include sensory-rich descriptions
            - Create rhythm and flow in the prose
            - Transform mundane descriptions into evocative passages
            """

        case .concise:
            return """
            CONCISE style instructions:
            - Remove unnecessary words and redundancy
            - Tighten sentences while preserving meaning
            - Focus on the essential emotions and events
            - Aim for 30-50% shorter than original
            - Keep the emotional core intact
            """
        }
    }
}
