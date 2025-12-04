//
//  JournalEnhancementPolicy.swift
//  InkFiction
//
//  Prompt policy for enhancing journal entry content
//  Ported from old app's JournalEnhancementPolicy
//

import Foundation

// MARK: - Journal Enhancement Policy

struct JournalEnhancementPolicy: PromptPolicy {
    static let policyId = "journal_enhancement"

    private let enhancementStyle: EnhancementStyle

    init(style: EnhancementStyle = .refine) {
        self.enhancementStyle = style
    }

    var identifier: String { "\(Self.policyId)_\(enhancementStyle.rawValue)" }

    var modelRequirements: ModelRequirements {
        ModelRequirements(
            minContextWindow: 8000,
            preferredModel: .flash,
            capabilities: [.textGeneration],
            temperature: 0.7,
            maxOutputTokens: 4096
        )
    }

    var contextAllocation: ContextAllocation {
        ContextAllocation(
            systemRatio: 0.10,
            userRatio: 0.15,
            contentRatio: 0.60,
            outputRatio: 0.15
        )
    }

    func validate(context: PromptContext) throws {
        guard !context.primaryContent.isEmpty else {
            throw PromptValidationError.emptyContent
        }

        if context.primaryContent.count > 30000 {
            throw PromptValidationError.contentTooLong(max: 30000, actual: context.primaryContent.count)
        }
    }

    func buildPrompt(context: PromptContext) throws -> PromptComponents {
        let systemPrompt = """
            Enhance journal entries in a \(enhancementStyle.description) style.

            Rules:
            - Maintain the user's voice and perspective (I/me/my)
            - Preserve emotional authenticity
            - Return ONLY the enhanced text
            - No markdown, asterisks, or formatting
            - Plain text only
            """

        var userContext = ""
        if let companion = context.companion {
            userContext = CompanionPromptTemplates.enhancementPrompt(
                for: companion,
                context: CompanionContextAdapter.buildUserAIContext(
                    from: context,
                    enhancementStyle: enhancementStyle
                )
            )
        }

        let content = """
            Enhance this journal entry:

            "\(context.primaryContent)"

            Make it more \(enhancementStyle.description) while preserving meaning.
            """

        return PromptComponents(
            systemPrompt: systemPrompt,
            userContext: userContext,
            content: content,
            responseFormat: .plainText
        )
    }

    private func buildCompanionContext(_ companion: AICompanion?, context: PromptContext) -> String {
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
