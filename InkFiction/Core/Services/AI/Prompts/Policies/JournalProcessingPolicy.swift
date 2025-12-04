//
//  JournalProcessingPolicy.swift
//  InkFiction
//
//  Prompt policy for full journal entry processing (title, mood, tags, image prompt)
//

import Foundation

// MARK: - Journal Processing Policy

struct JournalProcessingPolicy: PromptPolicy {
    static let policyId = "journal_processing"

    var identifier: String { Self.policyId }

    var modelRequirements: ModelRequirements {
        ModelRequirements(
            minContextWindow: 8000,
            preferredModel: .flash,
            capabilities: [.textGeneration, .structuredOutput],
            temperature: 0.7,
            maxOutputTokens: 2048
        )
    }

    var contextAllocation: ContextAllocation { .balanced }

    func validate(context: PromptContext) throws {
        guard !context.primaryContent.isEmpty else {
            throw PromptValidationError.emptyContent
        }

        if context.primaryContent.count < 20 {
            throw PromptValidationError.invalidContext("Entry too short for full processing")
        }
    }

    func buildPrompt(context: PromptContext) throws -> PromptComponents {
        let personaContext = buildPersonaContext(context.persona)
        let visualContext = buildVisualPreferenceContext(context.visualPreference)

        let systemPrompt = """
        You are an AI assistant for a personal journaling app. Your task is to analyze journal entries
        and provide comprehensive metadata to enhance the user's journaling experience.

        \(personaContext)

        Analysis should include:
        1. A compelling, evocative title (3-7 words)
        2. Mood detection with intensity
        3. Relevant tags for organization
        4. A scene description for image generation (if the entry lends itself to visualization)
        5. Suggested artistic style for any generated images

        \(visualContext)

        Be thoughtful and sensitive - these are personal journal entries.
        """

        let responseSchema = """
        {
          "title": "Evocative title, 3-7 words",
          "rephrase": "Optional: slightly polished version of the entry (null if not needed)",
          "mood": "Happy, Excited, Peaceful, Neutral, Thoughtful, Sad, Anxious, or Angry",
          "moodIntensity": 0.0 to 1.0,
          "tags": ["up to 5 relevant tags"],
          "imagePrompt": "Vivid scene description for image generation, or null if not appropriate",
          "artisticStyle": "artistic, cartoon, minimalist, watercolor, or sketch - based on mood/content"
        }
        """

        let content = """
        Analyze this journal entry and provide comprehensive metadata:

        ---
        \(context.primaryContent)
        ---

        Respond with JSON matching this exact structure:
        \(responseSchema)
        """

        return PromptComponents(
            systemPrompt: systemPrompt,
            content: content,
            responseFormat: .json
        )
    }

    private func buildPersonaContext(_ persona: PersonaProfileModel?) -> String {
        guard let persona = persona else { return "" }

        var context = "The user has a persona named '\(persona.name)'."

        if let bio = persona.bio, !bio.isEmpty {
            context += " Bio: \(bio)"
        }

        if let attributes = persona.attributes {
            context += """

            When generating image prompts, the persona should be represented as:
            - \(attributes.gender.rawValue) presenting
            - \(attributes.ageRange.rawValue) age range
            - \(attributes.hairColor.rawValue) \(attributes.hairStyle.rawValue) hair
            - \(attributes.clothingStyle.rawValue) style clothing
            """
        }

        return context
    }

    private func buildVisualPreferenceContext(_ preference: VisualPreference?) -> String {
        guard let preference = preference else { return "" }

        let description: String
        switch preference {
        case .abstractDreamy:
            description = """
            Visual preference: Abstract/Dreamy
            - Favor watercolor and impressionistic styles
            - Soft edges, flowing colors, ethereal lighting
            - Metaphorical and symbolic imagery
            - Dreamlike atmosphere over literal representation
            """

        case .realisticGrounded:
            description = """
            Visual preference: Realistic/Grounded
            - Favor photorealistic and detailed styles
            - Natural lighting, true-to-life colors
            - Documentary-style composition
            - Literal representation of scenes
            """

        case .minimalistClean:
            description = """
            Visual preference: Minimalist/Clean
            - Favor simple, clean designs
            - Limited color palette, geometric shapes
            - Zen aesthetic, negative space
            - Focus on essential elements only
            """

        case .vibrantExpressive:
            description = """
            Visual preference: Vibrant/Expressive
            - Favor bold, dynamic styles
            - Saturated colors, expressive strokes
            - Contemporary/anime-inspired aesthetics
            - Emotional intensity through color and form
            """
        }

        return description
    }
}

// MARK: - Avatar Style Selection

extension JournalProcessingPolicy {
    /// Suggests avatar style based on mood and visual preference
    static func suggestAvatarStyle(mood: Mood?, visualPreference: VisualPreference?) -> AvatarStyle {
        // Default based on visual preference
        if let pref = visualPreference {
            switch pref {
            case .abstractDreamy: return .watercolor
            case .realisticGrounded: return .artistic
            case .minimalistClean: return .minimalist
            case .vibrantExpressive: return .cartoon
            }
        }

        // Or based on mood
        if let mood = mood {
            switch mood {
            case .happy, .excited: return .cartoon
            case .peaceful, .thoughtful: return .watercolor
            case .sad, .anxious: return .sketch
            case .angry: return .artistic
            case .neutral: return .minimalist
            }
        }

        return .artistic
    }
}
