//
//  JournalProcessingPolicy.swift
//  InkFiction
//
//  Persona-aware journal processing policy that generates scene descriptions
//  featuring the persona character for consistent, character-driven image generation
//
//  Ported from old app's PersonaAwareJournalProcessingPolicy
//

import Foundation

// MARK: - Journal Processing Policy

struct JournalProcessingPolicy: PromptPolicy {
    static let policyId = "journal_processing"

    var identifier: String { Self.policyId }

    var modelRequirements: ModelRequirements {
        ModelRequirements(
            minContextWindow: 8192,
            preferredModel: .flash,
            capabilities: [.textGeneration, .structuredOutput],
            temperature: 0.7,
            maxOutputTokens: 2048
        )
    }

    var contextAllocation: ContextAllocation {
        ContextAllocation(
            systemRatio: 0.10,
            userRatio: 0.20,
            contentRatio: 0.60,
            outputRatio: 0.10
        )
    }

    func validate(context: PromptContext) throws {
        guard !context.primaryContent.isEmpty else {
            throw PromptValidationError.emptyContent
        }

        if context.primaryContent.count < 20 {
            throw PromptValidationError.invalidContext("Entry too short for full processing")
        }
    }

    func buildPrompt(context: PromptContext) throws -> PromptComponents {
        // Get persona - required for persona-aware processing
        guard let persona = context.persona else {
            throw PromptValidationError.missingRequiredContext("persona")
        }

        // Get user's visual preference for style-aware guidance
        let visualPreference = context.visualPreference ?? .realisticGrounded

        // Build persona description for system prompt
        let personaDescription = buildPersonaDescription(persona)

        // Build style-specific guidance
        let styleGuidance = buildStyleGuidance(
            for: visualPreference,
            persona: persona,
            mood: context.mood
        )

        // Build avatar style guidance
        let avatarStyleGuidance = buildAvatarStyleGuidance(persona: persona)

        // System prompt with persona awareness and style guidance
        let systemPrompt = """
            Analyze journal entries to extract structured information.

            IMPORTANT: This journal belongs to \(persona.name), a character with the following profile:
            \(personaDescription)

            Extract:
            1. title: Concise, meaningful title (3-6 words)
            2. rephrase: Enhanced version maintaining user's voice and perspective (I/me/my)
            3. mood: Exactly ONE mood from the allowed enum values
            4. tags: 2-4 most relevant tags from the allowed enum values
            5. imagePrompt: Scene description featuring \(persona.name) in the context (80-120 words)
            6. artisticStyle: ONE artistic style from available options
            7. moodIntensity: Decimal between 0.0 and 1.0

            For imagePrompt - CRITICAL INSTRUCTIONS:

            \(styleGuidance)

            VISUAL ELEMENTS TO DESCRIBE:

            1. Camera Perspective & Framing:
               - ALWAYS center \(persona.name) in the composition as the primary focal point
               - Choose angle based on activity: back view, over-shoulder, wide shot, close-up, bird's eye
               - Match perspective to emotional tone while keeping \(persona.name) prominently featured

            2. Lighting Conditions (CRITICAL for scene elevation):
               - Specify exact light source: natural window light, golden hour sunlight, soft overhead, warm lamp glow
               - Define direction: front-lit, side-lit, back-lit, rim lighting
               - Describe quality: soft and diffused, hard and dramatic, warm and inviting, cool and calm
               - Match lighting to time of day and mood
               - Example: "warm golden hour sunlight from left creating soft shadows, gentle rim light highlighting silhouette"

            3. Environment Detail: Specify what to emphasize vs blur
               - Foreground/background focus instructions
               - Depth of field guidance
               - Environmental mood-setters

            4. Composition: How elements are arranged
               - \(persona.name) as the central anchor point
               - Use of negative space around character
               - Visual flow directing attention to \(persona.name)

            CRITICAL: Feature \(persona.name) by name as the centered, primary character in EVERY scene.
            DO NOT generate abstract scenes without the character clearly present and the environment / context driving the narrative.

            \(avatarStyleGuidance)

            Preserve:
            - User's perspective (I/me/my)
            - Emotional authenticity
            - Original meaning and intent
            """

        // User context - companion and preferences
        var userContext = ""

        if let companion = context.companion {
            userContext += CompanionPromptTemplates.journalProcessingStyle(for: companion)
            userContext += "\n\n"
        }

        if let visualPref = context.visualPreference {
            userContext += """
                User Preferences:
                - Visual Style: \(visualPref.rawValue)
                """
        }

        // Add persona context
        userContext += """

            Character Context:
            - Name: \(persona.name)
            """

        if let bio = persona.bio, !bio.isEmpty {
            userContext += "\n- Bio: \(bio)"
        }

        // Content with journal entry
        let content = """
            Journal Entry by \(persona.name):
            "\(context.primaryContent)"

            Provide structured JSON output according to the response schema.
            Use ONLY the allowed enum values for mood and tags.
            No markdown formatting - just plain text in all fields.

            IMPORTANT: In imagePrompt, describe a scene where \(persona.name) is centered in frame, actively engaged in the activity or emotion, with specific lighting conditions that elevate the scenario.
            """

        return PromptComponents(
            systemPrompt: systemPrompt,
            userContext: userContext,
            content: content,
            responseFormat: .json
        )
    }

    // MARK: - Private Helpers

    private func buildPersonaDescription(_ persona: PersonaProfileModel) -> String {
        var components: [String] = []

        // Bio if available
        if let bio = persona.bio, !bio.isEmpty {
            components.append(bio)
        }

        // Physical attributes summary
        if let attributes = persona.attributes {
            let physicalDesc = buildPhysicalDescription(attributes)
            if !physicalDesc.isEmpty {
                components.append("Physical: \(physicalDesc)")
            }
        }

        return components.joined(separator: "\n")
    }

    private func buildPhysicalDescription(_ attributes: PersonaAttributes) -> String {
        var parts: [String] = []

        parts.append(attributes.gender.rawValue)
        parts.append(attributes.ageRange.promptDescription)
        parts.append("\(attributes.hairStyle.rawValue) hair")
        parts.append("\(attributes.clothingStyle.rawValue) clothing")

        return parts.joined(separator: ", ")
    }

    // MARK: - Avatar Style Selection

    private func buildAvatarStyleGuidance(persona: PersonaProfileModel) -> String {
        let availableStyles = AvatarStyle.allCases

        let stylesList = availableStyles.map { $0.displayName }.joined(separator: ", ")

        // Categorize styles by mood
        var peaceful: [AvatarStyle] = []
        var energetic: [AvatarStyle] = []
        var thoughtful: [AvatarStyle] = []

        for style in availableStyles {
            switch style {
            case .watercolor, .minimalist:
                peaceful.append(style)
            case .cartoon:
                energetic.append(style)
            case .artistic, .sketch:
                thoughtful.append(style)
            }
        }

        var guidelines: [String] = []

        if !peaceful.isEmpty {
            guidelines.append(
                "- Peaceful/calm moods -> \(peaceful.map { $0.displayName }.joined(separator: ", "))"
            )
        }
        if !energetic.isEmpty {
            guidelines.append(
                "- Energetic/happy moods -> \(energetic.map { $0.displayName }.joined(separator: ", "))"
            )
        }
        if !thoughtful.isEmpty {
            guidelines.append(
                "- Thoughtful/reflective moods -> \(thoughtful.map { $0.displayName }.joined(separator: ", "))"
            )
        }

        let guidelinesText =
            guidelines.isEmpty
            ? "Choose the style that best matches the mood and scene aesthetic."
            : guidelines.joined(separator: "\n")

        return """

            ARTISTIC STYLE SELECTION (artisticStyle field):

            IMPORTANT: Choose ONLY from these available styles: \(stylesList)

            Match style to mood and content:
            \(guidelinesText)

            Consider which visual aesthetic best captures the journal entry's essence.
            The chosen style will determine which persona avatar is used as a style reference for image generation.
            """
    }

    // MARK: - Style-Aware Guidance

    private func buildStyleGuidance(
        for visualPreference: VisualPreference,
        persona: PersonaProfileModel,
        mood: Mood?
    ) -> String {
        let styleInstructions = getStyleInstructions(for: visualPreference)
        let example = getStyleExample(visualPreference, persona: persona, mood: mood)

        return """
            VISUAL STYLE: \(visualPreference.displayName)

            \(styleInstructions)

            EXAMPLE FORMAT:
            \(example)
            """
    }

    private func getStyleInstructions(for preference: VisualPreference) -> String {
        switch preference {
        case .abstractDreamy:
            return """
                Style Approach: WATERCOLOR / ARTISTIC / IMPRESSIONISTIC

                Camera Angles:
                - Prefer atmospheric perspectives: back views, environmental shots, over-shoulder
                - Show character integrated with environment, not isolated
                - Use depth and layering to create dreamlike quality

                Lighting Descriptions:
                - Use soft, poetic language: "gentle glow", "ethereal light", "soft twilight", "diffused radiance"
                - Emphasize atmospheric quality over sharp details
                - Describe light as: diffused, back-lit, ambient, glowing, luminous

                Environment Treatment:
                - Suggest depth of field: "foreground sharp, background dissolves into soft washes"
                - Use impressionistic descriptions: "office fades into gentle watercolor blurs", "surroundings melt into impressions"
                - Emphasize mood-setting elements: sky, nature, atmosphere, transitions
                - Describe color bleeding and soft transitions

                Composition Style:
                - Flowing, organic arrangements
                - Emphasize emotional connection to environment
                - Character becomes part of the atmospheric scene
                - Use phrases like "integrated into", "enveloped by", "immersed in"
                """

        case .realisticGrounded:
            return """
                Style Approach: PHOTOREALISTIC / DOCUMENTARY / PROFESSIONAL PHOTOGRAPHY

                Camera Angles:
                - Use photographer's language: eye-level, over-shoulder, Dutch angle, bird's eye, worm's eye
                - Specify exact perspective: "captured from behind at 45-degree angle"
                - Consider rule of thirds, leading lines, framing

                Lighting Descriptions:
                - Technical, specific descriptions: "golden hour sunlight", "three-point lighting", "natural window light"
                - Specify light source, direction, and quality: "soft key light from left", "hard rim light"
                - Describe shadows and highlights: "creating dimension", "defining contours"
                - Use photography terms: backlighting, side lighting, rembrandt lighting

                Environment Treatment:
                - Specify depth of field technically: "shallow depth f/2.8, subject sharp, background bokeh"
                - Include realistic details: textures, materials, spatial relationships
                - Describe as a photographer would: sharp focus, soft focus, out-of-focus elements
                - Mention specific objects and their states

                Composition Style:
                - Professional photography principles
                - Balanced or intentionally unbalanced for effect
                - Specify focal point clearly
                - Use framing elements: windows, doors, architecture
                """

        case .minimalistClean:
            return """
                Style Approach: MINIMALIST / CLEAN / ZEN AESTHETIC

                Camera Angles:
                - Simple, direct perspectives
                - Often straight-on or profile views
                - Emphasize negative space around subject
                - Clean, uncluttered framing

                Lighting Descriptions:
                - Clean, even lighting descriptions
                - Avoid complex shadow descriptions
                - Use simple terms: "soft even light", "clean ambient lighting", "gentle illumination"
                - Minimal lighting drama

                Environment Treatment:
                - MINIMAL details only - specify what to omit
                - Suggest negative space: "simple background", "clean surroundings", "uncluttered space"
                - Focus on essential elements only
                - Use phrases like "minimal objects", "few elements", "essential features only"
                - Background as breathing room, not detail

                Composition Style:
                - Zen-like simplicity
                - Clear single focal point
                - Lots of negative space
                - Clean lines and geometric simplicity
                - Character has space to breathe
                """

        case .vibrantExpressive:
            return """
                Style Approach: DIGITAL ART / VIBRANT / CONTEMPORARY ILLUSTRATION

                Camera Angles:
                - Dynamic, bold perspectives
                - Low angles for power, high angles for vulnerability, Dutch angles for energy
                - Consider dramatic or unusual viewpoints
                - Contemporary, eye-catching framing

                Lighting Descriptions:
                - Bold, dramatic lighting descriptions
                - High contrast is acceptable and encouraged
                - Use vivid color descriptions: "vibrant purple sky", "bold golden light", "electric blue glow"
                - Dynamic lighting: "dramatic spotlights", "striking contrasts"

                Environment Treatment:
                - Stylized details are encouraged
                - Can be more imaginative/artistic with surroundings
                - Emphasize color and energy in environment
                - Use bold descriptors: "vibrant", "striking", "bold", "dynamic"
                - Contemporary, modern aesthetic

                Composition Style:
                - Bold, eye-catching arrangements
                - Dynamic diagonal lines
                - Energetic, contemporary feel
                - Strong visual impact
                - Modern illustration aesthetic
                """
        }
    }

    private func getStyleExample(
        _ preference: VisualPreference,
        persona: PersonaProfileModel,
        mood: Mood?
    ) -> String {
        let moodDesc = mood?.rawValue.lowercased() ?? "contemplative"
        let genderDesc = persona.attributes?.gender.rawValue ?? "person"

        switch preference {
        case .abstractDreamy:
            return """
                "Seen from behind at a gentle angle, \(persona.name) gazes through the large window into the twilight sky. The home office dissolves into soft watercolor washes in the background—desk and books rendered as gentle suggestions of form, colors bleeding into each other. The October evening dominates the scene: deep blues melting into purples, stars emerging as delicate points of light scattered across the atmospheric sky. Soft glow from the window creates an ethereal halo around \(persona.name)'s silhouette, \(genderDesc) figure peaceful and still. The \(moodDesc) mood is captured in the dreamy, flowing quality of the scene—a moment suspended in gentle color and impressionistic light, where \(persona.name) becomes one with the serene evening atmosphere."
                """

        case .realisticGrounded:
            return """
                "Captured from over the shoulder at eye level, \(persona.name) stands at the home office window, \(genderDesc) figure framed by the window mullions. Natural twilight from outside provides three-point lighting: key light from the window casting soft, cool-toned illumination on \(persona.name)'s profile, fill light from the desk lamp adding warm ambient glow, subtle rim light from the hallway defining the edge of the silhouette. The office is rendered with f/2.8 shallow depth of field—desk, computer, and bookshelves visible and recognizable but slightly soft. Through the window, the October sky shows realistic detail: natural gradient from deep blue at zenith to purple-pink near horizon, actual constellation patterns beginning to emerge, distant aircraft contrails catching the last light. Professional photography aesthetic capturing this candid, documentary moment of \(moodDesc) reflection."
                """

        case .minimalistClean:
            return """
                "\(persona.name) shown in clean profile at the window, \(genderDesc) silhouette simply rendered against the evening sky. Minimal environment: just the essential window frame as a geometric element, creating clean lines. The office behind is suggested but not detailed—simple, uncluttered space in soft shadow. Even, gentle lighting creates subtle gradients. The October sky is rendered with minimalist elegance: smooth transition from blue to purple, few stars as clean points of light. Lots of negative space frames \(persona.name), giving the \(moodDesc) moment room to breathe. Zen composition focusing only on the essential: the character, the window, the sky, the quiet contemplation."
                """

        case .vibrantExpressive:
            return """
                "Dynamic low-angle perspective showing \(persona.name) framed dramatically against the vibrant twilight sky, \(genderDesc) silhouette striking and bold. The October evening explodes with contemporary color: deep indigo blues, rich electric purples, stars rendered as bright dynamic points creating visual energy. The home office is stylized with modern digital art interpretation—clean lines, bold shapes, contemporary aesthetic with striking color accents. Dramatic lighting creates high contrast: strong rim light from the window creates a powerful edge light on \(persona.name)'s figure, bold separation from the environment. The composition uses dynamic diagonal lines and energetic framing, capturing the \(moodDesc) mood with bold, eye-catching style. Modern illustration aesthetic with vibrant, confident energy."
                """
        }
    }
}

// MARK: - Age Range Extension

extension PersonaAttributes.AgeRange {
    var promptDescription: String {
        switch self {
        case .child: return "child age"
        case .teen: return "teenage"
        case .youngAdult: return "young adult"
        case .adult: return "adult"
        case .middleAge: return "middle-aged"
        case .senior: return "senior"
        }
    }
}

// MARK: - Avatar Style Selection Helper

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
