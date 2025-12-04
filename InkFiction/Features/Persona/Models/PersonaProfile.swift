//
//  PersonaProfile.swift
//  InkFiction
//
//  Comprehensive persona profile domain model and extensions
//

import Foundation
import SwiftUI

// MARK: - PersonaProfile (Domain Model)

/// Rich domain model for persona with all attributes needed for avatar generation
struct PersonaProfile: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var bio: String?

    // Avatar Configuration
    var avatarStylesMetadata: [PersonaAvatarStyleMetadata]
    var selectedAvatarStyle: AvatarStyle?
    var attributes: PersonaAttributes
    var environmentPreference: EnvironmentPreference

    // Generation Settings
    var consistencySettings: ConsistencySettings
    var preferredMoods: [MoodTag]

    // Multi-Persona Support
    var personaType: PersonaType
    var contextTags: [String]
    var activityKeywords: [String]
    var compatibilityScore: Double

    // Metadata
    let createdAt: Date
    var updatedAt: Date
    var lastGeneratedAt: Date?
    var generationCount: Int

    // Transient Image Data (not persisted)
    var originalPhoto: UIImage?
    var generatedAvatars: [AvatarStyle: UIImage]?

    enum CodingKeys: String, CodingKey {
        case id, name, bio
        case avatarStylesMetadata, selectedAvatarStyle
        case attributes, environmentPreference
        case consistencySettings, preferredMoods
        case personaType, contextTags, activityKeywords, compatibilityScore
        case createdAt, updatedAt, lastGeneratedAt, generationCount
    }

    init(
        id: UUID = UUID(),
        name: String,
        bio: String? = nil,
        avatarStylesMetadata: [PersonaAvatarStyleMetadata] = [],
        selectedAvatarStyle: AvatarStyle? = nil,
        attributes: PersonaAttributes = PersonaAttributes(),
        environmentPreference: EnvironmentPreference = EnvironmentPreference(),
        consistencySettings: ConsistencySettings = ConsistencySettings(),
        preferredMoods: [MoodTag] = [],
        personaType: PersonaType = .casual,
        contextTags: [String] = [],
        activityKeywords: [String] = [],
        compatibilityScore: Double = 0.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastGeneratedAt: Date? = nil,
        generationCount: Int = 0,
        originalPhoto: UIImage? = nil,
        generatedAvatars: [AvatarStyle: UIImage]? = nil
    ) {
        self.id = id
        self.name = name
        self.bio = bio
        self.avatarStylesMetadata = avatarStylesMetadata
        self.selectedAvatarStyle = selectedAvatarStyle
        self.attributes = attributes
        self.environmentPreference = environmentPreference
        self.consistencySettings = consistencySettings
        self.preferredMoods = preferredMoods
        self.personaType = personaType
        self.contextTags = contextTags.isEmpty ? personaType.contextKeywords : contextTags
        self.activityKeywords = activityKeywords.isEmpty ? personaType.contextKeywords : activityKeywords
        self.compatibilityScore = compatibilityScore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastGeneratedAt = lastGeneratedAt
        self.generationCount = generationCount
        self.originalPhoto = originalPhoto
        self.generatedAvatars = generatedAvatars
    }

    static func == (lhs: PersonaProfile, rhs: PersonaProfile) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.bio == rhs.bio &&
        lhs.avatarStylesMetadata == rhs.avatarStylesMetadata &&
        lhs.selectedAvatarStyle == rhs.selectedAvatarStyle &&
        lhs.personaType == rhs.personaType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Consistency Settings

struct ConsistencySettings: Codable, Equatable {
    var seedValue: Int?
    var strengthLevel: ConsistencyStrength
    var lockPose: Bool
    var lockEnvironment: Bool
    var lockClothing: Bool
    var lockAccessories: Bool

    enum ConsistencyStrength: String, Codable, CaseIterable {
        case flexible, moderate, strict, exact

        var weight: Double {
            switch self {
            case .flexible: return 0.3
            case .moderate: return 0.5
            case .strict: return 0.7
            case .exact: return 0.9
            }
        }

        var description: String {
            switch self {
            case .flexible: return "Allow creative variations"
            case .moderate: return "Maintain key features"
            case .strict: return "Preserve most details"
            case .exact: return "Match exactly"
            }
        }
    }

    init(
        seedValue: Int? = nil,
        strengthLevel: ConsistencyStrength = .moderate,
        lockPose: Bool = false,
        lockEnvironment: Bool = false,
        lockClothing: Bool = true,
        lockAccessories: Bool = true
    ) {
        self.seedValue = seedValue
        self.strengthLevel = strengthLevel
        self.lockPose = lockPose
        self.lockEnvironment = lockEnvironment
        self.lockClothing = lockClothing
        self.lockAccessories = lockAccessories
    }
}

// MARK: - Mood Tags

enum MoodTag: String, Codable, CaseIterable {
    case happy, peaceful, energetic, thoughtful, creative
    case confident, relaxed, inspired, grateful, hopeful
    case focused, expressive, neutral

    var color: Color {
        switch self {
        case .happy: return .yellow
        case .peaceful: return .blue
        case .energetic: return .orange
        case .thoughtful: return .purple
        case .creative: return .pink
        case .confident: return .red
        case .relaxed: return .green
        case .inspired: return .indigo
        case .grateful: return .teal
        case .hopeful: return .cyan
        case .focused: return .gray
        case .expressive: return .mint
        case .neutral: return .secondary
        }
    }

    var icon: String {
        switch self {
        case .happy: return "sun.max.fill"
        case .peaceful: return "leaf.fill"
        case .energetic: return "bolt.fill"
        case .thoughtful: return "brain"
        case .creative: return "paintbrush.fill"
        case .confident: return "star.fill"
        case .relaxed: return "moon.fill"
        case .inspired: return "sparkles"
        case .grateful: return "heart.fill"
        case .hopeful: return "rainbow"
        case .focused: return "target"
        case .expressive: return "theatermasks.fill"
        case .neutral: return "circle"
        }
    }
}

// MARK: - PersonaProfile Extensions

extension PersonaProfile {
    var effectiveAvatarStyle: AvatarStyle {
        selectedAvatarStyle ?? avatarStylesMetadata.sorted().first?.avatarStyle ?? .artistic
    }

    var hasMultipleStyles: Bool {
        avatarStylesMetadata.count > 1
    }

    var availableAvatarStyles: [AvatarStyle] {
        avatarStylesMetadata.map { $0.avatarStyle }
    }

    func metadata(for style: AvatarStyle) -> PersonaAvatarStyleMetadata? {
        avatarStylesMetadata.first { $0.avatarStyle == style }
    }

    var basePrompt: String {
        var components: [String] = []
        components.append(effectiveAvatarStyle.promptDescription)
        components.append(attributes.promptDescription)
        if consistencySettings.strengthLevel != .flexible {
            components.append("consistent character design")
            if consistencySettings.lockClothing { components.append("same outfit") }
            if consistencySettings.lockAccessories { components.append("same accessories") }
        }
        if !consistencySettings.lockEnvironment {
            components.append(environmentPreference.description)
        }
        return components.joined(separator: ", ")
    }

    func promptWithMood(_ mood: MoodTag, journalContext: String? = nil) -> String {
        var prompt = basePrompt
        prompt += ", \(mood.rawValue) expression"
        if let context = journalContext { prompt += ", \(context)" }
        prompt += ", high quality, detailed, professional lighting"
        return prompt
    }

    var needsUpdate: Bool {
        guard let lastGenerated = lastGeneratedAt else { return true }
        let days = Calendar.current.dateComponents([.day], from: lastGenerated, to: Date()).day ?? 0
        return days > 7
    }

    mutating func recordGeneration() {
        lastGeneratedAt = Date()
        generationCount += 1
        updatedAt = Date()
    }

    var daysSinceLastUpdate: Int {
        Calendar.current.dateComponents([.day], from: updatedAt, to: Date()).day ?? 0
    }

    var formattedLastUpdate: String {
        let days = daysSinceLastUpdate
        switch days {
        case 0: return "Today"
        case 1: return "Yesterday"
        case 2...7: return "\(days) days ago"
        case 8...30: return "\(days / 7) weeks ago"
        case 31...365: return "\(days / 30) months ago"
        default: return "Over a year ago"
        }
    }
}

// MARK: - PersonaProfileModel Extensions

extension PersonaProfileModel {
    /// Get the active avatar's UIImage
    var activeAvatarImage: UIImage? {
        guard let avatarId = activeAvatarId,
              let avatar = avatars?.first(where: { $0.id == avatarId }),
              let imageData = avatar.imageData else {
            return nil
        }
        return UIImage(data: imageData)
    }

    /// Check if persona has any generated avatars
    var hasAvatars: Bool {
        !(avatars?.isEmpty ?? true)
    }

    /// Get available avatar styles that have been generated
    var availableStyles: [AvatarStyle] {
        (avatars ?? []).map { $0.style }
    }

    /// Check if a specific style has been generated
    func hasStyle(_ style: AvatarStyle) -> Bool {
        avatars?.contains { $0.style == style } ?? false
    }

    /// Get avatar for a specific style
    func avatar(for style: AvatarStyle) -> PersonaAvatarModel? {
        avatars?.first { $0.style == style }
    }

    /// Get all available avatar styles (matching PersonaProfile interface)
    var availableAvatarStyles: [AvatarStyle] {
        availableStyles
    }
}
