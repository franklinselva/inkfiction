//
//  CompanionContextAdapter.swift
//  InkFiction
//
//  Shared utility for converting PromptContext to UserAIContext
//  Used by companion-aware prompt policies
//  Ported from old app
//

import Foundation

// MARK: - User AI Context

/// Context for personalized AI interactions
struct UserAIContext {
    let profile: OnboardingProfile
    let companion: CompanionContext
    let preferences: EnhancementPreferences

    var promptPersonalization: String {
        return """
            User Profile:
            - Journaling Style: \(profile.journalingStyle.rawValue)
            - Emotional Expression: \(profile.emotionalExpression.rawValue)
            - Visual Preference: \(profile.visualPreference.rawValue)

            Companion: \(companion.companionId)
            Encouragement Style: \(companion.encouragementStyle.rawValue)
            """
    }
}

// MARK: - Onboarding Profile

struct OnboardingProfile {
    let journalingStyle: JournalingStyle
    let emotionalExpression: EmotionalExpression
    let visualPreference: VisualPreference
    let selectedCompanion: AICompanion
    let personalityTraits: PersonalityTraits
    let completedAt: Date

    struct PersonalityTraits {
        let openness: Double
        let conscientiousness: Double
        let extraversion: Double
        let agreeableness: Double
        let emotionalStability: Double
    }
}

// MARK: - Companion Context

struct CompanionContext {
    let companionId: String
    let persona: CompanionPersona
    let preferredPrompts: [String]
    let encouragementStyle: EncouragementStyle

    struct CompanionPersona {
        let tone: String
        let style: String
        let approach: String
        let vocabulary: VocabularyLevel
    }
}

// MARK: - Enhancement Preferences

struct EnhancementPreferences {
    var preferredEnhancementStyle: EnhancementStyle = .refine
    var vocabularyLevel: VocabularyLevel = .moderate
    var topicInterests: Set<String> = []
}

// MARK: - Supporting Enums (not already defined in app)

enum VocabularyLevel: String {
    case simple = "simple"
    case moderate = "moderate"
    case advanced = "advanced"
    case poetic = "poetic"
}

enum EncouragementStyle: String {
    case motivational = "motivational"
    case gentle = "gentle"
    case direct = "direct"
    case philosophical = "philosophical"
    case playful = "playful"
}

// MARK: - Companion Context Adapter

/// Adapter for converting between PromptContext and UserAIContext
struct CompanionContextAdapter {

    /// Convert PromptContext to UserAIContext for companion template usage
    ///
    /// - Parameters:
    ///   - context: The prompt context from centralized system
    ///   - enhancementStyle: Optional enhancement style override
    /// - Returns: UserAIContext suitable for CompanionPromptTemplates
    static func buildUserAIContext(
        from context: PromptContext,
        enhancementStyle: EnhancementStyle? = nil
    ) -> UserAIContext {

        // Extract companion or use default
        let companion = context.companion ?? .sage

        // Build onboarding profile from context
        let profile = OnboardingProfile(
            journalingStyle: inferJournalingStyle(from: context),
            emotionalExpression: inferEmotionalExpression(from: context),
            visualPreference: context.visualPreference ?? .abstractDreamy,
            selectedCompanion: companion,
            personalityTraits: OnboardingProfile.PersonalityTraits(
                openness: 0.5,
                conscientiousness: 0.5,
                extraversion: 0.5,
                agreeableness: 0.5,
                emotionalStability: 0.5
            ),
            completedAt: Date()
        )

        // Build companion context
        let companionContext = CompanionContext(
            companionId: companion.id,
            persona: CompanionContext.CompanionPersona(
                tone: companion.tagline,
                style: companion.id,
                approach: companion.description,
                vocabulary: .moderate
            ),
            preferredPrompts: [],
            encouragementStyle: inferEncouragementStyle(from: companion)
        )

        // Build enhancement preferences
        var preferences = EnhancementPreferences()
        preferences.preferredEnhancementStyle = enhancementStyle ?? .refine
        preferences.vocabularyLevel = .moderate
        preferences.topicInterests = []

        return UserAIContext(
            profile: profile,
            companion: companionContext,
            preferences: preferences
        )
    }

    // MARK: - Private Helpers

    /// Infer journaling style from context
    private static func inferJournalingStyle(from context: PromptContext) -> JournalingStyle {
        // Check for structured journal entries
        if let entries = context.journalEntries, !entries.isEmpty {
            let avgLength = entries.map { $0.content.count }.reduce(0, +) / entries.count

            if avgLength > 500 {
                return .detailedStories
            } else if avgLength > 200 {
                return .mixedMedia
            } else {
                return .quickNotes
            }
        }

        // Check primary content length
        let contentLength = context.primaryContent.count
        if contentLength > 500 {
            return .detailedStories
        } else if contentLength > 200 {
            return .mixedMedia
        }

        return .quickNotes
    }

    /// Infer emotional expression from mood intensity
    private static func inferEmotionalExpression(from context: PromptContext) -> EmotionalExpression {
        if context.mood != nil {
            return .moodTracking
        }

        // Check if content has creative/poetic elements
        let contentLower = context.primaryContent.lowercased()
        let creativeKeywords = ["imagine", "dream", "wonder", "feel like", "as if"]
        let hasCreativeLanguage = creativeKeywords.contains { contentLower.contains($0) }

        if hasCreativeLanguage {
            return .creativeExploration
        }

        return .writingFreely
    }

    /// Infer encouragement style from companion type
    private static func inferEncouragementStyle(from companion: AICompanion) -> EncouragementStyle {
        switch companion.id {
        case "poet":
            return .philosophical
        case "sage":
            return .philosophical
        case "dreamer":
            return .playful
        case "realist":
            return .direct
        default:
            return .gentle
        }
    }
}
