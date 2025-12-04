//
//  CompanionPromptTemplates.swift
//  InkFiction
//
//  Companion-specific prompt templates for personalized AI interactions
//  Ported from old app
//

import Foundation

struct CompanionPromptTemplates {

    // MARK: - Journal Enhancement Templates

    static func enhancementPrompt(for companion: AICompanion, context: UserAIContext) -> String {
        let basePrompt = context.promptPersonalization
        let companionSpecific = companionEnhancementStyle(for: companion)

        return """
            \(basePrompt)

            \(companionSpecific)

            Enhance this journal entry while:
            - Maintaining the user's voice and perspective
            - Using vocabulary level: \(context.preferences.vocabularyLevel.rawValue)
            - Focusing on \(context.preferences.preferredEnhancementStyle.description) style
            - Preserving the emotional authenticity
            """
    }

    private static func companionEnhancementStyle(for companion: AICompanion) -> String {
        switch companion.id {
        case "poet":
            return """
                As the Poet companion:
                - Use metaphors and similes to express emotions
                - Find rhythm and flow in the language
                - Paint vivid imagery with words
                - Transform mundane moments into poetic observations
                - Example: "The coffee was good" -> "The morning coffee whispered promises of clarity"
                """

        case "sage":
            return """
                As the Sage companion:
                - Draw wisdom from experiences
                - Connect events to larger life themes
                - Offer thoughtful perspectives
                - Find lessons in challenges
                - Example: "Had a tough day" -> "Today's challenges offered lessons in resilience"
                """

        case "dreamer":
            return """
                As the Dreamer companion:
                - Explore imaginative possibilities
                - See magic in everyday moments
                - Encourage creative thinking
                - Transform reality with wonder
                - Example: "Went for a walk" -> "Wandered through a world of hidden stories"
                """

        case "realist":
            return """
                As the Realist companion:
                - Focus on concrete observations
                - Identify practical insights
                - Maintain clarity and directness
                - Ground emotions in specific experiences
                - Example: "Feeling stressed" -> "Work deadlines are creating pressure that needs addressing"
                """

        default:
            return """
                As your companion:
                - Enhance your journal entries thoughtfully
                - Maintain your authentic voice
                - Support your emotional expression
                """
        }
    }

    // MARK: - Weekly Summary Templates

    static func weeklySummaryPrompt(for companion: AICompanion, context: UserAIContext) -> String {
        let companionVoice = weeklyVoice(for: companion)

        return """
            \(context.promptPersonalization)

            Generate a weekly reflection summary with these guidelines:

            \(companionVoice)

            Structure:
            1. Opening reflection (2-3 sentences in companion's voice)
            2. Key themes discovered this week
            3. Emotional journey overview
            4. Growth observations
            5. Gentle guidance for the week ahead

            Tone: \(context.companion.encouragementStyle.rawValue)
            Length: Keep it concise but meaningful (150-200 words)
            """
    }

    private static func weeklyVoice(for companion: AICompanion) -> String {
        switch companion.id {
        case "poet":
            return """
                Weekly Reflection Style:
                - Open with a poetic observation about the week's emotional landscape
                - Use metaphors to describe patterns and growth
                - Find beauty in both struggles and victories
                - Close with an inspiring image or metaphor for the week ahead
                """

        case "sage":
            return """
                Weekly Reflection Style:
                - Begin with a wise observation about the week's journey
                - Identify deeper patterns and life lessons
                - Connect individual days to broader wisdom
                - Offer philosophical perspective on growth
                """

        case "dreamer":
            return """
                Weekly Reflection Style:
                - Start with wonder about the week's possibilities realized
                - Celebrate imagination and creative moments
                - See the week as chapters in an ongoing adventure
                - Inspire dreams for the upcoming week
                """

        case "realist":
            return """
                Weekly Reflection Style:
                - Open with practical observations about the week
                - Identify concrete achievements and challenges
                - Provide actionable insights from patterns
                - Suggest realistic goals for improvement
                """

        default:
            return """
                Weekly Reflection Style:
                - Reflect on the week's journey
                - Identify key moments and patterns
                - Look ahead with clarity
                """
        }
    }

    // MARK: - Mood Analysis Templates

    static func moodAnalysisPrompt(
        for companion: AICompanion,
        emotionalExpression: EmotionalExpression  // Uses EmotionalExpression from PersonalityProfile.swift
    ) -> String {
        let companionApproach = moodApproach(for: companion)
        let expressionContext = expressionStyleDescription(for: emotionalExpression)

        return """
            Analyze the emotional content of this journal entry.

            \(companionApproach)
            \(expressionContext)

            Return:
            1. Primary mood (from allowed values)
            2. Mood intensity (0.0-1.0)
            3. Emotional nuances detected
            4. Suggested support or celebration based on mood
            """
    }

    private static func moodApproach(for companion: AICompanion) -> String {
        switch companion.id {
        case "poet":
            return "Look for emotional metaphors and imagery that reveal feelings"
        case "sage":
            return "Identify the deeper emotional wisdom and patterns"
        case "dreamer":
            return "Discover the emotional possibilities and imaginative expressions"
        case "realist":
            return "Focus on directly expressed emotions and their practical context"
        default:
            return "Understand the emotional content and context"
        }
    }

    private static func expressionStyleDescription(for expression: EmotionalExpression) -> String {
        switch expression {
        case .writingFreely:
            return "User expresses emotions through free-flowing thoughts"
        case .structuredPrompts:
            return "User prefers structured emotional exploration"
        case .moodTracking:
            return "User focuses on identifying and tracking specific moods"
        case .creativeExploration:
            return "User explores emotions through creative and abstract expression"
        }
    }

    // MARK: - Insight Generation Templates

    static func insightPrompt(for companion: AICompanion, journalingStyle: JournalingStyle) -> String {
        return """
            As the \(companion.name) companion, generate a brief insight (2-3 sentences).

            Companion approach: \(insightStyle(for: companion))
            User's journaling style: \(journalingStyle.rawValue.replacingOccurrences(of: "_", with: " "))

            The insight should:
            - Feel personal and relevant
            - Match the companion's voice
            - Offer value without being preachy
            - Be encouraging and supportive
            """
    }

    private static func insightStyle(for companion: AICompanion) -> String {
        switch companion.id {
        case "poet":
            return "Create a beautiful, metaphorical observation"
        case "sage":
            return "Share a piece of wisdom or life lesson"
        case "dreamer":
            return "Inspire with imaginative possibilities"
        case "realist":
            return "Offer a practical, actionable insight"
        default:
            return "Provide a meaningful insight"
        }
    }

    // MARK: - Title Generation Templates

    static func titlePrompt(for companion: AICompanion, visualPreference: VisualPreference) -> String {
        let styleGuide = titleStyle(for: companion)
        let visualContext = visualInfluence(for: visualPreference)

        return """
            Generate a title (3-6 words) for this journal entry.

            \(styleGuide)
            \(visualContext)

            Requirements:
            - Capture the essence of the entry
            - Match the companion's voice
            - Be memorable and meaningful
            - No quotation marks or special formatting
            """
    }

    private static func titleStyle(for companion: AICompanion) -> String {
        switch companion.id {
        case "poet":
            return "Style: Lyrical and evocative titles (e.g., 'Whispers of Morning Light')"
        case "sage":
            return "Style: Thoughtful and meaningful titles (e.g., 'Lessons from Stillness')"
        case "dreamer":
            return "Style: Imaginative and whimsical titles (e.g., 'Dancing with Possibilities')"
        case "realist":
            return "Style: Clear and descriptive titles (e.g., 'Progress Through Challenge')"
        default:
            return "Style: Meaningful and descriptive titles"
        }
    }

    private static func visualInfluence(for preference: VisualPreference) -> String {
        switch preference {
        case .abstractDreamy:
            return "Visual influence: Abstract and ethereal concepts"
        case .realisticGrounded:
            return "Visual influence: Concrete and tangible imagery"
        case .minimalistClean:
            return "Visual influence: Simple and essential elements"
        case .vibrantExpressive:
            return "Visual influence: Bold and dynamic expressions"
        }
    }

    // MARK: - Journal Processing Templates

    static func journalProcessingStyle(for companion: AICompanion) -> String {
        switch companion.id {
        case "poet":
            return """
                As the Poet companion, when analyzing this journal entry:
                - Create titles with lyrical, evocative language
                - Enhance entries with metaphors and vivid imagery
                - Generate image prompts with poetic, flowing descriptions
                - Example title: "Whispers of Morning Light"
                - Example enhancement: "The coffee whispered promises of clarity as morning light painted the kitchen gold"
                """

        case "sage":
            return """
                As the Sage companion, when analyzing this journal entry:
                - Create thoughtful, meaningful titles that capture deeper themes
                - Enhance entries by drawing wisdom from experiences
                - Generate image prompts with contemplative, serene elements
                - Example title: "Lessons from Stillness"
                - Example enhancement: "Today's challenges offered lessons in resilience and the power of patience"
                """

        case "dreamer":
            return """
                As the Dreamer companion, when analyzing this journal entry:
                - Create imaginative, whimsical titles full of wonder
                - Enhance entries by exploring creative possibilities
                - Generate image prompts with magical, dreamlike qualities
                - Example title: "Dancing with Possibilities"
                - Example enhancement: "I wandered through a world of hidden stories, each moment a chapter waiting to unfold"
                """

        case "realist":
            return """
                As the Realist companion, when analyzing this journal entry:
                - Create clear, descriptive titles that state the essence directly
                - Enhance entries with concrete observations and practical insights
                - Generate image prompts with grounded, tangible elements
                - Example title: "Progress Through Challenge"
                - Example enhancement: "Work deadlines are creating pressure that needs addressing through focused action"
                """

        default:
            return """
                When analyzing this journal entry:
                - Create meaningful titles that capture the essence
                - Enhance entries thoughtfully while maintaining authenticity
                - Generate image prompts that reflect the emotional tone
                """
        }
    }

    // MARK: - Encouragement Messages

    static func encouragementMessage(for style: EncouragementStyle, mood: Mood) -> String {
        switch style {
        case .motivational:
            return motivationalMessage(for: mood)
        case .gentle:
            return gentleMessage(for: mood)
        case .direct:
            return directMessage(for: mood)
        case .philosophical:
            return philosophicalMessage(for: mood)
        case .playful:
            return playfulMessage(for: mood)
        }
    }

    private static func motivationalMessage(for mood: Mood) -> String {
        switch mood {
        case .happy, .excited:
            return "Your positive energy is powerful - keep riding this wave!"
        case .peaceful:
            return "This calm strength you've found is your superpower."
        case .neutral:
            return "Every moment is a fresh start - you've got this!"
        case .thoughtful:
            return "Your reflection is building wisdom - trust the process."
        case .sad:
            return "These feelings are temporary - you're stronger than you know."
        case .anxious:
            return "You've overcome challenges before - you'll conquer this too."
        case .angry:
            return "Channel this energy into positive change - you have the power."
        }
    }

    private static func gentleMessage(for mood: Mood) -> String {
        switch mood {
        case .happy, .excited:
            return "What a beautiful moment to cherish."
        case .peaceful:
            return "This tranquility is well-deserved."
        case .neutral:
            return "Sometimes just being is enough."
        case .thoughtful:
            return "Your thoughts matter and deserve space."
        case .sad:
            return "It's okay to feel this way - be gentle with yourself."
        case .anxious:
            return "Take a breath - you're doing better than you think."
        case .angry:
            return "Your feelings are valid - give them room to breathe."
        }
    }

    private static func directMessage(for mood: Mood) -> String {
        switch mood {
        case .happy, .excited:
            return "Good energy today. Use it well."
        case .peaceful:
            return "You've found balance. Maintain it."
        case .neutral:
            return "Steady state. Keep moving forward."
        case .thoughtful:
            return "Reflection brings clarity. Good work."
        case .sad:
            return "Acknowledge it, then take one small step."
        case .anxious:
            return "Focus on what you can control. One thing at a time."
        case .angry:
            return "Feel it, then decide your next move."
        }
    }

    private static func philosophicalMessage(for mood: Mood) -> String {
        switch mood {
        case .happy, .excited:
            return "Joy is the soul's recognition of its own light."
        case .peaceful:
            return "In stillness, we find our truest self."
        case .neutral:
            return "The middle path often holds the greatest wisdom."
        case .thoughtful:
            return "The examined life reveals its own meaning."
        case .sad:
            return "Even rain nourishes tomorrow's growth."
        case .anxious:
            return "Storms pass; your essence remains."
        case .angry:
            return "Fire can destroy or forge - the choice is yours."
        }
    }

    private static func playfulMessage(for mood: Mood) -> String {
        switch mood {
        case .happy, .excited:
            return "Look at you, sparkling like stardust!"
        case .peaceful:
            return "You're giving zen master vibes today."
        case .neutral:
            return "Perfectly balanced, as all things should be."
        case .thoughtful:
            return "Deep thoughts by you - love to see it!"
        case .sad:
            return "Even clouds need their moment - tomorrow's forecast: brighter."
        case .anxious:
            return "Plot twist: You're going to handle this beautifully."
        case .angry:
            return "Spicy feelings today - you're still amazing though!"
        }
    }
}
