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
        // Build user preference instructions
        let preferenceInstructions = buildPreferenceInstructions(
            journalingStyle: context.journalingStyle,
            emotionalExpression: context.emotionalExpression
        )

        let systemPrompt = """
            Enhance journal entries in a \(enhancementStyle.description) style.

            \(preferenceInstructions)

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

    private func buildPreferenceInstructions(
        journalingStyle: JournalingStyle?,
        emotionalExpression: EmotionalExpression?
    ) -> String {
        var instructions: [String] = []

        // Add journaling style instructions
        if let style = journalingStyle {
            instructions.append(buildJournalingStyleInstructions(style))
        }

        // Add emotional expression instructions
        if let expression = emotionalExpression {
            instructions.append(buildEmotionalExpressionInstructions(expression))
        }

        guard !instructions.isEmpty else { return "" }

        return """
            User Preferences:
            \(instructions.joined(separator: "\n"))
            """
    }

    private func buildJournalingStyleInstructions(_ style: JournalingStyle) -> String {
        switch style {
        case .quickNotes:
            return "- The user prefers quick notes: Keep enhancements concise and to-the-point. Focus on clarity over elaboration."
        case .detailedStories:
            return "- The user prefers detailed stories: Feel free to expand on descriptions, add sensory details, and develop the narrative arc."
        case .visualSketches:
            return "- The user prefers visual expression: Enhance with vivid imagery, descriptive language that paints a picture, and sensory-rich details."
        case .mixedMedia:
            return "- The user prefers mixed media: Balance narrative text with moments that could pair well with images. Include evocative, scene-setting language."
        }
    }

    private func buildEmotionalExpressionInstructions(_ expression: EmotionalExpression) -> String {
        switch expression {
        case .writingFreely:
            return "- The user expresses emotions freely: Embrace raw, authentic emotional language. Don't hold back on expressing feelings deeply and openly."
        case .structuredPrompts:
            return "- The user prefers structured expression: Organize emotions clearly, perhaps with distinct sections for feelings, reflections, and takeaways."
        case .moodTracking:
            return "- The user focuses on mood tracking: Clearly highlight the emotional journey and mood shifts. Make emotions explicit and identifiable."
        case .creativeExploration:
            return "- The user explores emotions creatively: Use metaphors, analogies, and creative language to express emotions in unique, artistic ways."
        }
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
