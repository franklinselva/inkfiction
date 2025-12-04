//
//  PromptPolicy.swift
//  InkFiction
//
//  Base protocol and types for prompt generation policies
//

import Foundation

// MARK: - Prompt Policy Protocol

/// Protocol for all prompt generation policies
protocol PromptPolicy {
    /// Unique identifier for the policy
    var identifier: String { get }

    /// Model requirements for this policy
    var modelRequirements: ModelRequirements { get }

    /// Context allocation ratios
    var contextAllocation: ContextAllocation { get }

    /// Build the prompt from context
    func buildPrompt(context: PromptContext) throws -> PromptComponents

    /// Validate context before building prompt
    func validate(context: PromptContext) throws
}

// MARK: - Model Requirements

/// Requirements for the AI model
struct ModelRequirements {
    let minContextWindow: Int
    let preferredModel: GeminiModel
    let capabilities: Set<ModelCapability>
    let temperature: Double
    let maxOutputTokens: Int

    static let textGeneration = ModelRequirements(
        minContextWindow: 8000,
        preferredModel: .flash,
        capabilities: [.textGeneration],
        temperature: 0.7,
        maxOutputTokens: 1024
    )

    static let moodAnalysis = ModelRequirements(
        minContextWindow: 4000,
        preferredModel: .flash,
        capabilities: [.textGeneration, .structuredOutput],
        temperature: 0.3,
        maxOutputTokens: 512
    )

    static let imageGeneration = ModelRequirements(
        minContextWindow: 2000,
        preferredModel: .flash,
        capabilities: [.imageGeneration],
        temperature: 0.8,
        maxOutputTokens: 256
    )

    static let reflection = ModelRequirements(
        minContextWindow: 16000,
        preferredModel: .flash,
        capabilities: [.textGeneration],
        temperature: 0.7,
        maxOutputTokens: 2048
    )
}

/// Gemini model variants
enum GeminiModel: String {
    case flash = "gemini-2.5-flash-preview-05-20"

    var displayName: String {
        switch self {
        case .flash: return "Gemini 2.5 Flash"
        }
    }

    var contextWindow: Int {
        switch self {
        case .flash: return 1_000_000
        }
    }
}

/// Model capabilities
enum ModelCapability: String {
    case textGeneration
    case imageGeneration
    case structuredOutput
    case multiModal
    case streaming
}

// MARK: - Context Allocation

/// How to allocate context budget
struct ContextAllocation {
    let systemRatio: Double
    let userRatio: Double
    let contentRatio: Double
    let outputRatio: Double

    static let balanced = ContextAllocation(
        systemRatio: 0.10,
        userRatio: 0.15,
        contentRatio: 0.60,
        outputRatio: 0.15
    )

    static let contentFocused = ContextAllocation(
        systemRatio: 0.05,
        userRatio: 0.10,
        contentRatio: 0.75,
        outputRatio: 0.10
    )

    static let detailedResponse = ContextAllocation(
        systemRatio: 0.10,
        userRatio: 0.10,
        contentRatio: 0.50,
        outputRatio: 0.30
    )

    func validate() -> Bool {
        let total = systemRatio + userRatio + contentRatio + outputRatio
        return abs(total - 1.0) < 0.01
    }
}

// MARK: - Prompt Context

/// Context for building prompts
struct PromptContext {
    // Primary content
    let primaryContent: String
    var secondaryContent: String?

    // Personalization
    var persona: PersonaProfileModel?
    var companion: AICompanion?
    var visualPreference: VisualPreference?
    var journalingStyle: JournalingStyle?
    var emotionalExpression: EmotionalExpression?

    // Journal-specific
    var journalEntry: JournalEntryModel?
    var journalEntries: [JournalEntryModel]?
    var mood: Mood?
    var enhancedContext: EnhancedJournalContext?

    // Image generation
    var imageStyle: AvatarStyle?
    var referenceImage: Data?

    // Metadata
    var timeframe: TimeFrame?
    var tags: [String]?
    var customVariables: [String: String]?

    init(
        primaryContent: String,
        secondaryContent: String? = nil,
        persona: PersonaProfileModel? = nil,
        companion: AICompanion? = nil,
        visualPreference: VisualPreference? = nil,
        journalingStyle: JournalingStyle? = nil,
        emotionalExpression: EmotionalExpression? = nil,
        journalEntry: JournalEntryModel? = nil,
        journalEntries: [JournalEntryModel]? = nil,
        mood: Mood? = nil,
        enhancedContext: EnhancedJournalContext? = nil,
        imageStyle: AvatarStyle? = nil,
        referenceImage: Data? = nil,
        timeframe: TimeFrame? = nil,
        tags: [String]? = nil,
        customVariables: [String: String]? = nil
    ) {
        self.primaryContent = primaryContent
        self.secondaryContent = secondaryContent
        self.persona = persona
        self.companion = companion
        self.visualPreference = visualPreference
        self.journalingStyle = journalingStyle
        self.emotionalExpression = emotionalExpression
        self.journalEntry = journalEntry
        self.journalEntries = journalEntries
        self.mood = mood
        self.enhancedContext = enhancedContext
        self.imageStyle = imageStyle
        self.referenceImage = referenceImage
        self.timeframe = timeframe
        self.tags = tags
        self.customVariables = customVariables
    }
}

// Note: TimeFrame is defined in Features/Reflect/Models/ReflectModels.swift

// MARK: - Prompt Components

/// Components of a built prompt
struct PromptComponents {
    let systemPrompt: String
    let userContext: String?
    let content: String
    let responseFormat: ResponseFormat?

    init(
        systemPrompt: String,
        userContext: String? = nil,
        content: String,
        responseFormat: ResponseFormat? = nil
    ) {
        self.systemPrompt = systemPrompt
        self.userContext = userContext
        self.content = content
        self.responseFormat = responseFormat
    }

    /// Combined prompt for simple requests
    var combinedPrompt: String {
        var parts: [String] = []

        if !systemPrompt.isEmpty {
            parts.append(systemPrompt)
        }

        if let context = userContext, !context.isEmpty {
            parts.append(context)
        }

        parts.append(content)

        if let format = responseFormat {
            parts.append(format.instruction)
        }

        return parts.joined(separator: "\n\n")
    }
}

/// Expected response format
struct ResponseFormat {
    let type: FormatType
    let schema: String?
    let instruction: String

    enum FormatType {
        case json
        case plainText
        case markdown
    }

    static let json = ResponseFormat(
        type: .json,
        schema: nil,
        instruction: "Respond with valid JSON only. No markdown code blocks."
    )

    static let plainText = ResponseFormat(
        type: .plainText,
        schema: nil,
        instruction: ""
    )

    static func jsonWithSchema(_ schema: String) -> ResponseFormat {
        ResponseFormat(
            type: .json,
            schema: schema,
            instruction: "Respond with valid JSON matching this schema:\n\(schema)"
        )
    }
}

// MARK: - Prompt Validation Error

enum PromptValidationError: LocalizedError {
    case emptyContent
    case contentTooLong(max: Int, actual: Int)
    case missingRequiredContext(String)
    case invalidContext(String)

    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "Content cannot be empty"
        case .contentTooLong(let max, let actual):
            return "Content too long (\(actual) chars). Maximum: \(max)"
        case .missingRequiredContext(let field):
            return "Missing required context: \(field)"
        case .invalidContext(let reason):
            return "Invalid context: \(reason)"
        }
    }
}
