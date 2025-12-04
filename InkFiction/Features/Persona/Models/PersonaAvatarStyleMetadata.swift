//
//  PersonaAvatarStyleMetadata.swift
//  InkFiction
//
//  Metadata for individual avatar styles with favor ratings and usage tracking
//

import Foundation

// MARK: - PersonaAvatarStyleMetadata

struct PersonaAvatarStyleMetadata: Codable, Identifiable, Equatable, Comparable {
    let id: UUID
    let avatarStyle: AvatarStyle
    let createdAt: Date
    var favorRating: Double  // 0.0 to 1.0, user preference rating
    var usageCount: Int
    var lastUsedAt: Date?

    init(
        id: UUID = UUID(),
        avatarStyle: AvatarStyle,
        createdAt: Date = Date(),
        favorRating: Double = 0.5,
        usageCount: Int = 0,
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.avatarStyle = avatarStyle
        self.createdAt = createdAt
        self.favorRating = max(0, min(1, favorRating))  // Clamp to 0-1
        self.usageCount = usageCount
        self.lastUsedAt = lastUsedAt
    }

    // MARK: - Comparable

    /// Sort by favor rating (descending), then usage count (descending), then creation date (descending)
    static func < (lhs: PersonaAvatarStyleMetadata, rhs: PersonaAvatarStyleMetadata) -> Bool {
        if lhs.favorRating != rhs.favorRating {
            return lhs.favorRating > rhs.favorRating
        }
        if lhs.usageCount != rhs.usageCount {
            return lhs.usageCount > rhs.usageCount
        }
        return lhs.createdAt > rhs.createdAt
    }

    // MARK: - Methods

    /// Update the favor rating (clamped to 0-1)
    mutating func updateRating(_ newRating: Double) {
        favorRating = max(0, min(1, newRating))
    }

    /// Record usage of this avatar style
    mutating func recordUsage() {
        usageCount += 1
        lastUsedAt = Date()
    }

    /// Get rating as percentage string
    var ratingPercentage: String {
        "\(Int(favorRating * 100))%"
    }

    /// Caption prefix for display (e.g., "Artistic version of")
    var captionPrefix: String {
        avatarStyle.captionPrefix
    }
}

// MARK: - AvatarStyle Extension for Caption

extension AvatarStyle {
    var captionPrefix: String {
        switch self {
        case .artistic: return "Artistic"
        case .cartoon: return "Cartoon"
        case .minimalist: return "Minimalist"
        case .watercolor: return "Watercolor"
        case .sketch: return "Sketch"
        }
    }

    var promptDescription: String {
        switch self {
        case .artistic:
            return "artistic portrait, creative interpretation, expressive brushstrokes, vibrant colors"
        case .cartoon:
            return "cartoon style character, western animation, clean lines, expressive features"
        case .minimalist:
            return "minimalist portrait, clean design, simple shapes, limited color palette"
        case .watercolor:
            return "watercolor painting style, soft edges, flowing colors, artistic wash effects"
        case .sketch:
            return "pencil sketch portrait, detailed linework, cross-hatching, artistic shading"
        }
    }

    var negativePrompt: String {
        switch self {
        case .artistic:
            return "photorealistic, 3D render, anime, blurry"
        case .cartoon:
            return "realistic, photographic, 3D, anime style"
        case .minimalist:
            return "complex, detailed, photorealistic, busy background"
        case .watercolor:
            return "digital art, sharp edges, photorealistic, vector"
        case .sketch:
            return "colored, painted, digital, photorealistic"
        }
    }

    /// Recommended generation settings for this style
    var recommendedSettings: GenerationSettings {
        switch self {
        case .artistic:
            return GenerationSettings(steps: 30, cfgScale: 7.5, denoisingStrength: 0.7)
        case .cartoon:
            return GenerationSettings(steps: 25, cfgScale: 8.0, denoisingStrength: 0.75)
        case .minimalist:
            return GenerationSettings(steps: 20, cfgScale: 9.0, denoisingStrength: 0.8)
        case .watercolor:
            return GenerationSettings(steps: 35, cfgScale: 7.0, denoisingStrength: 0.65)
        case .sketch:
            return GenerationSettings(steps: 25, cfgScale: 8.5, denoisingStrength: 0.7)
        }
    }
}

// MARK: - Generation Settings

struct GenerationSettings: Codable, Equatable {
    let steps: Int
    let cfgScale: Double
    let denoisingStrength: Double
    var samplerType: String = "euler_ancestral"

    init(
        steps: Int = 30,
        cfgScale: Double = 7.5,
        denoisingStrength: Double = 0.7,
        samplerType: String = "euler_ancestral"
    ) {
        self.steps = steps
        self.cfgScale = cfgScale
        self.denoisingStrength = denoisingStrength
        self.samplerType = samplerType
    }
}
