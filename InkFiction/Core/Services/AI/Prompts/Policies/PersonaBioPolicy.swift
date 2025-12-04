//
//  PersonaBioPolicy.swift
//  InkFiction
//
//  Prompt policy for generating persona bio from photo analysis
//  Ported from old app's GeminiAPIService.buildPersonaBioPrompt
//

import Foundation

// MARK: - Persona Bio Policy

struct PersonaBioPolicy: PromptPolicy {
    static let policyId = "persona_bio"

    var identifier: String { Self.policyId }

    var modelRequirements: ModelRequirements {
        ModelRequirements(
            minContextWindow: 4000,
            preferredModel: .flash,
            capabilities: [.textGeneration, .multiModal, .structuredOutput],
            temperature: 0.8,
            maxOutputTokens: 200
        )
    }

    var contextAllocation: ContextAllocation { .balanced }

    func validate(context: PromptContext) throws {
        guard !context.primaryContent.isEmpty else {
            throw PromptValidationError.missingRequiredContext("personaName (in primaryContent)")
        }

        guard context.imageStyle != nil else {
            throw PromptValidationError.missingRequiredContext("imageStyle (avatar style)")
        }
    }

    func buildPrompt(context: PromptContext) throws -> PromptComponents {
        let personaName = context.primaryContent
        let style = context.imageStyle ?? .artistic

        // Get persona type from customVariables, default to casual
        let personaTypeRaw = context.customVariables?["personaType"] ?? "casual"
        let personaType = PersonaType(rawValue: personaTypeRaw) ?? .casual

        // Exact prompt from old app: GeminiAPIService.swift lines 319-340
        let content = """
        Analyze this photo and create a compelling 2-3 sentence bio for an AI journaling companion named \(personaName).

        Persona type: \(personaType.rawValue)
        Visual style: \(style.rawValue)

        The bio should:
        - Describe their personality and how they'll guide journaling
        - Reference visual elements from the photo (mood, appearance, style)
        - Match the \(personaType.rawValue) tone (casual = friendly/warm, professional = polished/supportive, creative = inspiring/artistic)
        - Be warm and encouraging
        - Be written in third person, present tense
        - NOT mention that it's an AI or digital entity

        Keep it concise (2-3 sentences max). Make it feel personal and unique to this persona.
        """

        // Response format for structured output
        let responseSchema = """
        {
            "bio": "The 2-3 sentence bio text",
            "traits": ["trait1", "trait2", "trait3", "trait4", "trait5"]
        }
        """

        return PromptComponents(
            systemPrompt: "",
            userContext: nil,
            content: content,
            responseFormat: .jsonWithSchema(responseSchema)
        )
    }
}
