//
//  AIModels.swift
//  InkFiction
//
//  Core models for AI services - request/response types for Gemini 2.5 Flash
//

import Foundation
import SwiftUI

// MARK: - API Configuration

/// Configuration for AI API endpoints (Vercel backend)
struct AIConfiguration {
    let baseURL: String
    let timeout: TimeInterval
    let maxRetries: Int

    static let `default` = AIConfiguration(
        baseURL: "", // Set via environment or config
        timeout: 30,
        maxRetries: 2
    )

    static let imageGeneration = AIConfiguration(
        baseURL: "",
        timeout: 120,
        maxRetries: 1
    )
}

// MARK: - Request Models

/// Base request for all AI operations
struct AIRequest: Encodable {
    let operation: AIOperation
    let content: String
    let context: AIContext?
    let options: AIOptions?
}

/// AI operation types
enum AIOperation: String, Codable {
    case analyzeMood = "analyze_mood"
    case generateTitle = "generate_title"
    case enhanceEntry = "enhance_entry"
    case generateImage = "generate_image"
    case generateReflection = "generate_reflection"
    case processJournal = "process_journal"
    case generatePersonaBio = "generate_persona_bio"
}

/// Context for AI operations
struct AIContext: Codable {
    var personaName: String?
    var personaAttributes: PersonaAttributesDTO?
    var avatarStyle: String?
    var visualPreference: String?
    var mood: String?
    var tags: [String]?
    var timeframe: String?
    var companionId: String?
    var previousEntries: [JournalEntrySummary]?

    init(
        personaName: String? = nil,
        personaAttributes: PersonaAttributesDTO? = nil,
        avatarStyle: String? = nil,
        visualPreference: String? = nil,
        mood: String? = nil,
        tags: [String]? = nil,
        timeframe: String? = nil,
        companionId: String? = nil,
        previousEntries: [JournalEntrySummary]? = nil
    ) {
        self.personaName = personaName
        self.personaAttributes = personaAttributes
        self.avatarStyle = avatarStyle
        self.visualPreference = visualPreference
        self.mood = mood
        self.tags = tags
        self.timeframe = timeframe
        self.companionId = companionId
        self.previousEntries = previousEntries
    }
}

/// Simplified persona attributes for API
struct PersonaAttributesDTO: Codable {
    var gender: String?
    var ageRange: String?
    var ethnicity: String?
    var hairStyle: String?
    var hairColor: String?
    var eyeColor: String?
    var facialFeatures: [String]?
    var clothingStyle: String?
    var accessories: [String]?

    init(from attributes: PersonaAttributes) {
        self.gender = attributes.gender.rawValue
        self.ageRange = attributes.ageRange.rawValue
        self.ethnicity = attributes.ethnicity.rawValue
        self.hairStyle = attributes.hairStyle.rawValue
        self.hairColor = attributes.hairColor.rawValue
        self.eyeColor = attributes.eyeColor.rawValue
        self.facialFeatures = attributes.facialFeatures.map { $0.rawValue }
        self.clothingStyle = attributes.clothingStyle.rawValue
        self.accessories = attributes.accessories.map { $0.rawValue }
    }
}

/// Journal entry summary for context
struct JournalEntrySummary: Codable {
    let title: String
    let mood: String
    let date: Date
    let snippet: String
}

/// Options for AI operations
struct AIOptions: Codable {
    var temperature: Double?
    var maxTokens: Int?
    var style: String?
    var aspectRatio: String?
    var enhancementStyle: EnhancementStyle?

    init(
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        style: String? = nil,
        aspectRatio: String? = nil,
        enhancementStyle: EnhancementStyle? = nil
    ) {
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.style = style
        self.aspectRatio = aspectRatio
        self.enhancementStyle = enhancementStyle
    }
}

/// Enhancement styles for entry enhancement
enum EnhancementStyle: String, Codable, CaseIterable {
    case expand = "expand"
    case refine = "refine"
    case poetic = "poetic"
    case concise = "concise"

    var displayName: String {
        switch self {
        case .expand: return "Expand"
        case .refine: return "Refine"
        case .poetic: return "Poetic"
        case .concise: return "Concise"
        }
    }

    var description: String {
        switch self {
        case .expand: return "Add more detail and depth"
        case .refine: return "Improve clarity and flow"
        case .poetic: return "Add artistic expression"
        case .concise: return "Make it more concise"
        }
    }
}

// MARK: - Response Models

/// Base response wrapper
struct AIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: AIErrorResponse?
}

/// Error response from API
struct AIErrorResponse: Decodable {
    let code: String
    let message: String
    let retryable: Bool?
}

/// Mood analysis response
struct MoodAnalysisResult: Decodable {
    let mood: String
    let confidence: Double
    let keywords: [String]
    let sentiment: Sentiment
    let intensity: Double

    enum Sentiment: String, Decodable {
        case positive
        case negative
        case neutral
        case mixed
    }

    var moodEnum: Mood? {
        Mood.allCases.first { $0.rawValue.lowercased() == mood.lowercased() }
    }
}

/// Title generation response
struct TitleGenerationResult: Decodable {
    let title: String
    let alternatives: [String]?
}

/// Entry enhancement response
struct EntryEnhancementResult: Decodable {
    let enhancedContent: String
    let changes: [String]?
}

/// Journal processing response (full analysis)
struct JournalProcessingResult: Decodable {
    let title: String
    let rephrase: String?
    let mood: String
    let moodIntensity: Double
    let tags: [String]
    let imagePrompt: String?
    let artisticStyle: String?

    var moodEnum: Mood? {
        Mood.allCases.first { $0.rawValue.lowercased() == mood.lowercased() }
    }

    var avatarStyleEnum: AvatarStyle? {
        AvatarStyle.allCases.first { $0.rawValue.lowercased() == artisticStyle?.lowercased() }
    }
}

/// Image generation response
struct ImageGenerationResult: Decodable {
    let imageBase64: String
    let mimeType: String
    let prompt: String?

    var imageData: Data? {
        Data(base64Encoded: imageBase64)
    }
}

/// Reflection generation response
struct ReflectionResult: Decodable {
    let reflection: String
    let insights: [String]?
    let suggestions: [String]?
    let moodTrend: MoodTrend?
}

/// Mood trend in reflections
struct MoodTrend: Decodable {
    let direction: String // "improving", "declining", "stable"
    let dominantMood: String
    let variability: String // "high", "medium", "low"
}

/// Persona bio generation response
struct PersonaBioResult: Decodable {
    let bio: String
    let traits: [String]?
}

// MARK: - Image Generation Types

/// Image generation request
struct ImageGenerationRequest: Encodable {
    let prompt: String
    let style: String
    let type: ImageType
    let aspectRatio: AspectRatio
    let referenceImageBase64: String?

    enum ImageType: String, Encodable {
        case avatar
        case journal
    }

    enum AspectRatio: String, Encodable {
        case square = "1:1"
        case portrait = "3:4"
        case landscape = "4:3"
        case wide = "16:9"
    }
}

// MARK: - Enhanced Journal Context

/// Rich context extracted from journal entry for better AI prompts
struct EnhancedJournalContext: Codable {
    var detectedLocation: String?
    var detectedActivity: String?
    var environmentDescriptors: [String]
    var timeContext: TimeContext?
    var weatherMentions: [String]
    var emotionalNuances: [String]
    var socialContext: SocialContext?
    var activityLevel: ActivityLevel?
    var settingType: SettingType?

    init(
        detectedLocation: String? = nil,
        detectedActivity: String? = nil,
        environmentDescriptors: [String] = [],
        timeContext: TimeContext? = nil,
        weatherMentions: [String] = [],
        emotionalNuances: [String] = [],
        socialContext: SocialContext? = nil,
        activityLevel: ActivityLevel? = nil,
        settingType: SettingType? = nil
    ) {
        self.detectedLocation = detectedLocation
        self.detectedActivity = detectedActivity
        self.environmentDescriptors = environmentDescriptors
        self.timeContext = timeContext
        self.weatherMentions = weatherMentions
        self.emotionalNuances = emotionalNuances
        self.socialContext = socialContext
        self.activityLevel = activityLevel
        self.settingType = settingType
    }

    enum TimeContext: String, Codable {
        case morning, afternoon, evening, night, lateNight
    }

    enum SocialContext: String, Codable {
        case alone, family, friends, coworkers, strangers, mixed
    }

    enum ActivityLevel: String, Codable {
        case sedentary, light, moderate, vigorous
    }

    enum SettingType: String, Codable {
        case home, workplace, gym, nature, social, transit, other
    }
}
