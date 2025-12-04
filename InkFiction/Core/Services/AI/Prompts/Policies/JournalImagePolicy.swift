//
//  JournalImagePolicy.swift
//  InkFiction
//
//  Prompt policy for generating journal entry images
//

import Foundation

// MARK: - Journal Image Policy

struct JournalImagePolicy: PromptPolicy {
    static let policyId = "journal_image"

    var identifier: String { Self.policyId }

    var modelRequirements: ModelRequirements { .imageGeneration }

    var contextAllocation: ContextAllocation { .contentFocused }

    func validate(context: PromptContext) throws {
        guard !context.primaryContent.isEmpty else {
            throw PromptValidationError.emptyContent
        }
    }

    func buildPrompt(context: PromptContext) throws -> PromptComponents {
        let visualStyle = buildVisualStyleInstructions(context.visualPreference)
        let moodAtmosphere = buildMoodAtmosphere(context.mood)
        let personaElements = buildPersonaElements(context.persona)

        // Build the image generation prompt
        let imagePrompt = buildImagePrompt(
            sceneDescription: context.primaryContent,
            visualStyle: visualStyle,
            moodAtmosphere: moodAtmosphere,
            personaElements: personaElements
        )

        let systemPrompt = """
        You are an expert at creating vivid, emotionally resonant image prompts for journal visualization.
        Your prompts should translate written experiences into compelling visual narratives.
        """

        return PromptComponents(
            systemPrompt: systemPrompt,
            content: imagePrompt,
            responseFormat: .plainText
        )
    }

    private func buildImagePrompt(
        sceneDescription: String,
        visualStyle: String,
        moodAtmosphere: String,
        personaElements: String
    ) -> String {
        var parts: [String] = []

        // Core scene
        parts.append(sceneDescription)

        // Visual style
        if !visualStyle.isEmpty {
            parts.append(visualStyle)
        }

        // Mood atmosphere
        if !moodAtmosphere.isEmpty {
            parts.append(moodAtmosphere)
        }

        // Persona elements (if character should appear)
        if !personaElements.isEmpty {
            parts.append(personaElements)
        }

        // Quality modifiers
        parts.append("high quality, detailed, professional illustration")

        return parts.joined(separator: ", ")
    }

    private func buildVisualStyleInstructions(_ preference: VisualPreference?) -> String {
        guard let preference = preference else {
            return "artistic illustration style"
        }

        switch preference {
        case .abstractDreamy:
            return "watercolor style, soft edges, dreamy atmosphere, impressionistic, flowing colors, ethereal lighting"

        case .realisticGrounded:
            return "realistic style, detailed textures, natural lighting, photorealistic elements, grounded composition"

        case .minimalistClean:
            return "minimalist design, clean lines, limited color palette, simple shapes, zen aesthetic, negative space"

        case .vibrantExpressive:
            return "vibrant colors, bold strokes, expressive style, dynamic composition, contemporary art style"
        }
    }

    private func buildMoodAtmosphere(_ mood: Mood?) -> String {
        guard let mood = mood else { return "" }

        switch mood {
        case .happy:
            return "warm golden lighting, bright atmosphere, uplifting mood, sunny tones"

        case .excited:
            return "dynamic energy, vibrant colors, movement, sparkling elements, celebration"

        case .peaceful:
            return "serene atmosphere, soft light, calm waters, gentle breeze, tranquil setting"

        case .neutral:
            return "balanced lighting, natural tones, everyday atmosphere"

        case .thoughtful:
            return "contemplative mood, soft shadows, muted colors, introspective atmosphere, quiet moment"

        case .sad:
            return "melancholic atmosphere, cool blue tones, soft rain, gentle shadows, quiet solitude"

        case .anxious:
            return "restless energy, swirling elements, contrasting shadows, uncertain atmosphere"

        case .angry:
            return "intense colors, dramatic shadows, stormy elements, bold contrasts"
        }
    }

    private func buildPersonaElements(_ persona: PersonaProfileModel?) -> String {
        guard let persona = persona, let attributes = persona.attributes else {
            return ""
        }

        var elements: [String] = []

        // Add character description if persona should appear in scene
        elements.append("\(attributes.gender.rawValue) figure")

        if attributes.hairStyle != .bald {
            elements.append("\(attributes.hairColor.rawValue) \(attributes.hairStyle.rawValue) hair")
        }

        if !attributes.accessories.isEmpty {
            elements.append(attributes.accessories.map { $0.rawValue }.joined(separator: ", "))
        }

        return elements.isEmpty ? "" : "featuring: \(elements.joined(separator: ", "))"
    }
}

// MARK: - Visual Preference Extension

extension VisualPreference {
    /// Style type for image generation APIs
    var imageStyleType: String {
        switch self {
        case .abstractDreamy: return "design"
        case .realisticGrounded: return "realistic"
        case .minimalistClean: return "design"
        case .vibrantExpressive: return "anime"
        }
    }
}
