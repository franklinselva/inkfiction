//
//  PersonaAvatarPolicy.swift
//  InkFiction
//
//  Prompt policy for generating persona avatar images
//

import Foundation

// MARK: - Persona Avatar Policy

struct PersonaAvatarPolicy: PromptPolicy {
    static let policyId = "persona_avatar"

    var identifier: String { Self.policyId }

    var modelRequirements: ModelRequirements { .imageGeneration }

    var contextAllocation: ContextAllocation { .contentFocused }

    func validate(context: PromptContext) throws {
        guard context.persona != nil else {
            throw PromptValidationError.missingRequiredContext("persona")
        }

        guard context.imageStyle != nil else {
            throw PromptValidationError.missingRequiredContext("imageStyle (avatar style)")
        }
    }

    func buildPrompt(context: PromptContext) throws -> PromptComponents {
        guard let persona = context.persona,
              let style = context.imageStyle else {
            throw PromptValidationError.missingRequiredContext("persona and imageStyle")
        }

        let avatarPrompt = buildAvatarPrompt(persona: persona, style: style)

        let systemPrompt = """
        Generate a character portrait/avatar that maintains consistency and captures the persona's essence.
        The avatar should be suitable for a personal journaling app - warm, inviting, and personal.
        """

        return PromptComponents(
            systemPrompt: systemPrompt,
            content: avatarPrompt,
            responseFormat: .plainText
        )
    }

    private func buildAvatarPrompt(persona: PersonaProfileModel, style: AvatarStyle) -> String {
        var parts: [String] = []

        // Style-specific prefix
        parts.append(stylePrefix(for: style))

        // Character description
        if let attributes = persona.attributes {
            parts.append(buildCharacterDescription(attributes))
        } else {
            parts.append("portrait of \(persona.name)")
        }

        // Style modifiers
        parts.append(styleModifiers(for: style))

        // Quality and framing
        parts.append("portrait composition, centered, looking at viewer, friendly expression")
        parts.append("high quality, detailed")

        // Negative elements (what to avoid)
        let negatives = "no text, no watermark, no signature, no frame"

        return parts.joined(separator: ", ") + ". Avoid: \(negatives)"
    }

    private func buildCharacterDescription(_ attributes: PersonaAttributes) -> String {
        var description: [String] = []

        // Base description
        description.append("\(attributes.gender.rawValue) person")
        description.append("\(attributes.ageRange.displayName) age")

        // Physical features
        if attributes.hairStyle != .bald {
            description.append("\(attributes.hairColor.rawValue) \(attributes.hairStyle.rawValue) hair")
        } else {
            description.append("bald")
        }

        description.append("\(attributes.eyeColor.rawValue) eyes")

        // Facial features
        if !attributes.facialFeatures.isEmpty {
            description.append(attributes.facialFeatures.map { $0.rawValue }.joined(separator: ", "))
        }

        // Clothing
        description.append("\(attributes.clothingStyle.rawValue) clothing")

        // Accessories
        if !attributes.accessories.isEmpty {
            description.append("wearing \(attributes.accessories.map { $0.rawValue }.joined(separator: ", "))")
        }

        return description.joined(separator: ", ")
    }

    private func stylePrefix(for style: AvatarStyle) -> String {
        switch style {
        case .artistic:
            return "artistic portrait painting"
        case .cartoon:
            return "cartoon character portrait, western animation style"
        case .minimalist:
            return "minimalist portrait illustration, simple shapes"
        case .watercolor:
            return "watercolor portrait painting, soft edges"
        case .sketch:
            return "pencil sketch portrait, hand-drawn style"
        }
    }

    private func styleModifiers(for style: AvatarStyle) -> String {
        switch style {
        case .artistic:
            return "oil painting style, expressive brushstrokes, rich colors, museum quality, classical technique"

        case .cartoon:
            return "clean lines, vibrant colors, friendly style, Disney/Pixar inspired, appealing design"

        case .minimalist:
            return "flat colors, geometric shapes, limited palette, clean design, modern aesthetic"

        case .watercolor:
            return "soft washes, flowing colors, paper texture, delicate details, impressionistic"

        case .sketch:
            return "graphite pencil, detailed linework, cross-hatching, traditional drawing, artistic shading"
        }
    }
}

// MARK: - Age Range Display Names

extension PersonaAttributes.AgeRange {
    var displayName: String {
        switch self {
        case .child: return "child"
        case .teen: return "teenage"
        case .youngAdult: return "young adult"
        case .adult: return "adult"
        case .middleAge: return "middle-aged"
        case .senior: return "senior"
        }
    }
}
