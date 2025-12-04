//
//  PromptManager.swift
//  InkFiction
//
//  Central coordinator for all prompt generation
//

import Foundation

// MARK: - Prompt Manager

/// Central coordinator for building and managing AI prompts
final class PromptManager {
    static let shared = PromptManager()

    // Registered policies
    private var policies: [String: any PromptPolicy] = [:]

    private init() {
        registerDefaultPolicies()
    }

    // MARK: - Policy Registration

    private func registerDefaultPolicies() {
        register(MoodAnalysisPolicy())
        register(TitleGenerationPolicy())
        register(JournalEnhancementPolicy())
        register(JournalImagePolicy())
        register(PersonaAvatarPolicy())
        register(PersonaBioPolicy())
        register(ReflectionPolicy())
        register(JournalProcessingPolicy())
    }

    func register(_ policy: any PromptPolicy) {
        policies[policy.identifier] = policy
        Log.debug("Registered prompt policy: \(policy.identifier)", category: .ai)
    }

    func policy(for identifier: String) -> (any PromptPolicy)? {
        policies[identifier]
    }

    // MARK: - Prompt Building

    /// Build a prompt using a specific policy
    func buildPrompt(
        policyIdentifier: String,
        context: PromptContext
    ) throws -> PromptComponents {
        guard let policy = policies[policyIdentifier] else {
            throw PromptManagerError.policyNotFound(policyIdentifier)
        }

        // Validate context
        try policy.validate(context: context)

        // Build prompt
        let components = try policy.buildPrompt(context: context)

        Log.debug(
            "Built prompt with policy '\(policyIdentifier)' - system: \(components.systemPrompt.count) chars, content: \(components.content.count) chars",
            category: .ai
        )

        return components
    }

    /// Build prompt with inline policy
    func buildPrompt(
        policy: any PromptPolicy,
        context: PromptContext
    ) throws -> PromptComponents {
        try policy.validate(context: context)
        return try policy.buildPrompt(context: context)
    }

    // MARK: - Convenience Methods

    /// Quick mood analysis prompt
    func moodAnalysisPrompt(content: String) throws -> PromptComponents {
        let context = PromptContext(primaryContent: content)
        return try buildPrompt(policyIdentifier: MoodAnalysisPolicy.policyId, context: context)
    }

    /// Quick title generation prompt
    func titleGenerationPrompt(content: String, mood: Mood? = nil) throws -> PromptComponents {
        let context = PromptContext(primaryContent: content, mood: mood)
        return try buildPrompt(policyIdentifier: TitleGenerationPolicy.policyId, context: context)
    }

    /// Journal enhancement prompt
    func enhancementPrompt(
        content: String,
        style: EnhancementStyle,
        companion: AICompanion? = nil,
        journalingStyle: JournalingStyle? = nil,
        emotionalExpression: EmotionalExpression? = nil
    ) throws -> PromptComponents {
        var context = PromptContext(primaryContent: content)
        context.companion = companion
        context.journalingStyle = journalingStyle
        context.emotionalExpression = emotionalExpression
        context.customVariables = ["enhancementStyle": style.rawValue]
        return try buildPrompt(policyIdentifier: JournalEnhancementPolicy.policyId, context: context)
    }

    /// Journal image prompt
    func journalImagePrompt(
        sceneDescription: String,
        persona: PersonaProfileModel?,
        mood: Mood?,
        visualPreference: VisualPreference?
    ) throws -> PromptComponents {
        var context = PromptContext(primaryContent: sceneDescription)
        context.persona = persona
        context.mood = mood
        context.visualPreference = visualPreference
        return try buildPrompt(policyIdentifier: JournalImagePolicy.policyId, context: context)
    }

    /// Persona avatar prompt
    func avatarPrompt(
        persona: PersonaProfileModel,
        style: AvatarStyle
    ) throws -> PromptComponents {
        var context = PromptContext(primaryContent: persona.name)
        context.persona = persona
        context.imageStyle = style
        return try buildPrompt(policyIdentifier: PersonaAvatarPolicy.policyId, context: context)
    }

    /// Persona bio prompt (for generating bio from photo)
    func personaBioPrompt(
        personaName: String,
        personaType: PersonaType,
        style: AvatarStyle
    ) throws -> PromptComponents {
        var context = PromptContext(primaryContent: personaName)
        context.imageStyle = style
        context.customVariables = ["personaType": personaType.rawValue]
        return try buildPrompt(policyIdentifier: PersonaBioPolicy.policyId, context: context)
    }

    /// Reflection prompt
    func reflectionPrompt(
        entries: [JournalEntryModel],
        timeframe: TimeFrame,
        companion: AICompanion? = nil
    ) throws -> PromptComponents {
        let entrySummaries = entries.map { entry in
            "[\(entry.mood.rawValue)] \(entry.title): \(String(entry.content.prefix(200)))"
        }.joined(separator: "\n")

        var context = PromptContext(primaryContent: entrySummaries)
        context.journalEntries = entries
        context.timeframe = timeframe
        context.companion = companion
        return try buildPrompt(policyIdentifier: ReflectionPolicy.policyId, context: context)
    }

    /// Full journal processing prompt
    func journalProcessingPrompt(
        content: String,
        persona: PersonaProfileModel?,
        visualPreference: VisualPreference?
    ) throws -> PromptComponents {
        var context = PromptContext(primaryContent: content)
        context.persona = persona
        context.visualPreference = visualPreference
        return try buildPrompt(policyIdentifier: JournalProcessingPolicy.policyId, context: context)
    }

    // MARK: - Token Estimation

    /// Estimate token count for content (rough approximation)
    func estimateTokens(_ text: String) -> Int {
        // Rough estimate: ~4 characters per token for English
        return text.count / 4
    }

    /// Check if content fits within model context
    func canFitInContext(
        content: String,
        model: GeminiModel = .flash,
        reservedForOutput: Int = 2000
    ) -> Bool {
        let estimatedTokens = estimateTokens(content)
        return estimatedTokens + reservedForOutput < model.contextWindow
    }
}

// MARK: - Errors

enum PromptManagerError: LocalizedError {
    case policyNotFound(String)
    case buildFailed(String)

    var errorDescription: String? {
        switch self {
        case .policyNotFound(let id):
            return "Prompt policy not found: \(id)"
        case .buildFailed(let reason):
            return "Failed to build prompt: \(reason)"
        }
    }
}
