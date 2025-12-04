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
        referenceImage: Data? = nil,
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

        // Use PromptManager to build the avatar prompt using PersonaAvatarPolicy
        let promptComponents = try promptManager.avatarPrompt(persona: persona, style: style)

        progressHandler?(0.2)
        generationProgress = 0.2

        Log.debug("Avatar prompt built via PersonaAvatarPolicy: \(promptComponents.combinedPrompt.prefix(200))...", category: .ai)

        // Generate image using Cloudflare Workers
        let (imageData, _) = try await geminiService.generateImage(
            prompt: promptComponents.combinedPrompt,
            aspectRatio: "1:1",
            styleType: style.cfStyleType,
            referenceImages: referenceImage.map { [$0] },
            operation: Constants.AI.Operations.personaAvatar
        )

        progressHandler?(0.8)
        generationProgress = 0.8

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
        referenceImage: Data? = nil,
        progressHandler: ((AvatarStyle, Double) -> Void)? = nil
    ) async throws -> [AvatarStyle: Data] {
        var results: [AvatarStyle: Data] = [:]

        for (index, style) in styles.enumerated() {
            let overallProgress = Double(index) / Double(styles.count)
            progressHandler?(style, overallProgress)

            do {
                let imageData = try await generatePersonaAvatar(
                    persona: persona,
                    style: style,
                    referenceImage: referenceImage
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
        persona: PersonaProfileModel? = nil,
        visualPreference: VisualPreference? = nil,
        referenceImage: Data? = nil,
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

        // Use PromptManager to build the journal image prompt using JournalImagePolicy
        let promptComponents = try promptManager.journalImagePrompt(
            sceneDescription: sceneDescription,
            persona: persona,
            mood: entry.mood,
            visualPreference: visualPreference
        )

        progressHandler?(0.2)
        generationProgress = 0.2

        Log.debug("Journal image prompt built via JournalImagePolicy: \(promptComponents.combinedPrompt.prefix(200))...", category: .ai)

        // Generate image using Cloudflare Workers with optional reference image
        let (imageData, _) = try await geminiService.generateImage(
            prompt: promptComponents.combinedPrompt,
            aspectRatio: "16:9",
            referenceImages: referenceImage.map { [$0] },
            operation: Constants.AI.Operations.journalImage
        )

        progressHandler?(0.8)
        generationProgress = 0.8

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
        persona: PersonaProfileModel? = nil,
        visualPreference: VisualPreference? = nil,
        referenceImage: Data? = nil,
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
            referenceImage: referenceImage,
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
        !geminiService.imageBaseURL.isEmpty
    }

    /// Check remaining quota
    var remainingAvatarQuota: Int {
        subscriptionService.remainingPersonaGenerations
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
