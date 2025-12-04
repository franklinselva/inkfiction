//
//  ImageGenerationService.swift
//  InkFiction
//
//  Service for AI image generation (avatars and journal images)
//

import Foundation
import SwiftUI

// MARK: - Image Generation Service

/// Service for generating AI images for personas and journal entries
@Observable
final class ImageGenerationService {
    static let shared = ImageGenerationService()

    // MARK: - Properties

    private let geminiService: GeminiService
    private let promptManager: PromptManager
    private let subscriptionService: SubscriptionService

    private(set) var isGenerating = false
    private(set) var generationProgress: Double = 0
    private(set) var lastError: AIError?

    // Image cache
    private let imageCache = NSCache<NSString, NSData>()

    // MARK: - Initialization

    private init(
        geminiService: GeminiService = .shared,
        promptManager: PromptManager = .shared,
        subscriptionService: SubscriptionService = .shared
    ) {
        self.geminiService = geminiService
        self.promptManager = promptManager
        self.subscriptionService = subscriptionService

        // Configure cache
        imageCache.countLimit = 50
        imageCache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
    }

    // MARK: - Avatar Generation

    /// Generate a persona avatar in a specific style
    func generatePersonaAvatar(
        persona: PersonaProfileModel,
        style: AvatarStyle,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> Data {
        // Check subscription
        guard subscriptionService.canGeneratePersonaAvatar() else {
            throw AIError.dailyLimitReached(feature: "Persona avatars", limit: subscriptionService.dailyPersonaAvatarLimit)
        }

        isGenerating = true
        generationProgress = 0
        defer {
            isGenerating = false
            generationProgress = 0
        }

        Log.info("Generating persona avatar: \(persona.name) in \(style.displayName) style", category: .ai)

        // Build prompt
        let context = PromptContext(
            primaryContent: persona.name,
            persona: persona,
            imageStyle: style
        )

        let promptComponents = try promptManager.buildPrompt(
            policyIdentifier: PersonaAvatarPolicy.policyId,
            context: context
        )

        progressHandler?(0.2)
        generationProgress = 0.2

        // Generate image
        let result = try await geminiService.generateImage(
            prompt: promptComponents.combinedPrompt,
            style: style,
            type: .avatar,
            aspectRatio: .square
        )

        progressHandler?(0.8)
        generationProgress = 0.8

        guard let imageData = result.imageData else {
            throw AIError.invalidImageData
        }

        // Record usage
        subscriptionService.recordPersonaAvatarGeneration()

        progressHandler?(1.0)
        generationProgress = 1.0

        Log.info("Avatar generated successfully: \(imageData.count) bytes", category: .ai)

        return imageData
    }

    /// Generate multiple avatar styles for a persona
    func generatePersonaAvatars(
        persona: PersonaProfileModel,
        styles: [AvatarStyle],
        progressHandler: ((AvatarStyle, Double) -> Void)? = nil
    ) async throws -> [AvatarStyle: Data] {
        var results: [AvatarStyle: Data] = [:]

        for (index, style) in styles.enumerated() {
            let overallProgress = Double(index) / Double(styles.count)
            progressHandler?(style, overallProgress)

            do {
                let imageData = try await generatePersonaAvatar(
                    persona: persona,
                    style: style
                ) { progress in
                    let adjustedProgress = overallProgress + (progress / Double(styles.count))
                    progressHandler?(style, adjustedProgress)
                }
                results[style] = imageData
            } catch {
                Log.error("Failed to generate \(style.displayName) avatar", error: error, category: .ai)
                // Continue with other styles
            }
        }

        return results
    }

    // MARK: - Journal Image Generation

    /// Generate an image for a journal entry
    func generateJournalImage(
        entry: JournalEntryModel,
        sceneDescription: String,
        persona: PersonaProfileModel?,
        visualPreference: VisualPreference?,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> Data {
        // Check subscription
        guard subscriptionService.canGenerateJournalImage() else {
            throw AIError.dailyLimitReached(feature: "Journal images", limit: subscriptionService.dailyJournalImageLimit)
        }

        isGenerating = true
        generationProgress = 0
        defer {
            isGenerating = false
            generationProgress = 0
        }

        Log.info("Generating journal image for entry: \(entry.title)", category: .ai)

        // Determine style based on mood and preference
        let style = JournalProcessingPolicy.suggestAvatarStyle(
            mood: entry.mood,
            visualPreference: visualPreference
        )

        // Build prompt
        let context = PromptContext(
            primaryContent: sceneDescription,
            persona: persona,
            visualPreference: visualPreference,
            journalEntry: entry,
            mood: entry.mood,
            imageStyle: style
        )

        let promptComponents = try promptManager.buildPrompt(
            policyIdentifier: JournalImagePolicy.policyId,
            context: context
        )

        progressHandler?(0.2)
        generationProgress = 0.2

        // Generate image
        let result = try await geminiService.generateImage(
            prompt: promptComponents.combinedPrompt,
            style: style,
            type: .journal,
            aspectRatio: .landscape
        )

        progressHandler?(0.8)
        generationProgress = 0.8

        guard let imageData = result.imageData else {
            throw AIError.invalidImageData
        }

        // Record usage
        subscriptionService.recordJournalImageGeneration()

        progressHandler?(1.0)
        generationProgress = 1.0

        Log.info("Journal image generated successfully: \(imageData.count) bytes", category: .ai)

        return imageData
    }

    /// Generate image from processed journal result
    func generateJournalImage(
        from processingResult: JournalProcessingResult,
        entry: JournalEntryModel,
        persona: PersonaProfileModel?,
        visualPreference: VisualPreference?,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> Data? {
        guard let imagePrompt = processingResult.imagePrompt, !imagePrompt.isEmpty else {
            Log.debug("No image prompt in processing result", category: .ai)
            return nil
        }

        return try await generateJournalImage(
            entry: entry,
            sceneDescription: imagePrompt,
            persona: persona,
            visualPreference: visualPreference,
            progressHandler: progressHandler
        )
    }

    // MARK: - Caching

    /// Get cached image if available
    func getCachedImage(for key: String) -> Data? {
        imageCache.object(forKey: key as NSString) as Data?
    }

    /// Cache an image
    func cacheImage(_ data: Data, for key: String) {
        imageCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
    }

    /// Clear image cache
    func clearCache() {
        imageCache.removeAllObjects()
        Log.debug("Image cache cleared", category: .ai)
    }

    // MARK: - Validation

    /// Check if image generation is available
    var isAvailable: Bool {
        !geminiService.baseURL.isEmpty
    }

    /// Check remaining quota
    var remainingAvatarQuota: Int {
        subscriptionService.remainingPersonaAvatars
    }

    var remainingJournalImageQuota: Int {
        subscriptionService.remainingJournalImages
    }
}

// MARK: - Environment Key

private struct ImageGenerationServiceKey: EnvironmentKey {
    static let defaultValue = ImageGenerationService.shared
}

extension EnvironmentValues {
    var imageGenerationService: ImageGenerationService {
        get { self[ImageGenerationServiceKey.self] }
        set { self[ImageGenerationServiceKey.self] = newValue }
    }
}
