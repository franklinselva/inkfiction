//
//  GeminiService.swift
//  InkFiction
//
//  Core API client for Gemini 2.5 Flash via Cloudflare Workers backend
//

import Foundation

// MARK: - Cloudflare Workers Request/Response Types

/// Content format for Gemini text generation
struct GeminiContent: Encodable {
    var role: String?
    var parts: [GeminiPart]
}

/// Part of a Gemini content message
struct GeminiPart: Encodable {
    var text: String?
    var inlineData: InlineData?

    struct InlineData: Encodable {
        let mimeType: String
        let data: String
    }
}

/// Generation configuration for text requests
struct GeminiGenerationConfig: Encodable {
    var temperature: Double?
    var topK: Int?
    var topP: Double?
    var maxOutputTokens: Int?
    var stopSequences: [String]?
    var responseMimeType: String?
}

/// Text generation request for Cloudflare Workers
struct TextGenerationRequest: Encodable {
    let contents: [GeminiContent]
    var generationConfig: GeminiGenerationConfig?
    var operation: String?
}

/// Image generation input
struct ImageGenerationInput: Encodable {
    let prompt: String
    var aspectRatio: String?
    var styleType: String?
    var styleReferenceImages: [String]?
    var magicPrompt: Bool?

    enum CodingKeys: String, CodingKey {
        case prompt
        case aspectRatio = "aspect_ratio"
        case styleType = "style_type"
        case styleReferenceImages = "style_reference_images"
        case magicPrompt = "magic_prompt"
    }
}

/// Image generation request for Cloudflare Workers
struct CFImageGenerationRequest: Encodable {
    var version: String?
    let input: ImageGenerationInput
    var operation: String?
}

/// Image generation response from Cloudflare Workers
struct CFImageGenerationResponse: Decodable {
    let id: String
    let model: String
    let version: String
    let status: String
    let output: String  // data URL with base64
    let metrics: Metrics

    struct Metrics: Decodable {
        let predictTime: Double
        let totalTime: Double

        enum CodingKeys: String, CodingKey {
            case predictTime = "predict_time"
            case totalTime = "total_time"
        }
    }

    /// Extract base64 image data from the output data URL
    var imageData: Data? {
        // Format: data:image/png;base64,<data>
        guard let range = output.range(of: "base64,") else { return nil }
        let base64String = String(output[range.upperBound...])
        return Data(base64Encoded: base64String)
    }

    var mimeType: String {
        // Extract mime type from data URL
        guard let start = output.range(of: "data:"),
              let end = output.range(of: ";base64") else {
            return "image/png"
        }
        return String(output[start.upperBound..<end.lowerBound])
    }
}

/// Error response from Cloudflare Workers
struct CFErrorResponse: Decodable {
    let error: ErrorDetail

    struct ErrorDetail: Decodable {
        let type: String
        let message: String
        let code: Int
        let timestamp: String?
        let retryable: Bool?
        let suggestion: String?
    }
}

// MARK: - Gemini Service

/// Core service for AI operations via Cloudflare Workers backend
@Observable
final class GeminiService {
    static let shared = GeminiService()

    // MARK: - Properties

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let promptManager: PromptManager

    private(set) var isProcessing = false
    private(set) var lastError: AIError?

    // PERF-N005: Track ongoing tasks for cancellation support
    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    private let tasksLock = NSLock()

    /// Base URL for text generation API
    var textBaseURL: String {
        get { UserDefaults.standard.string(forKey: "ai_text_base_url") ?? Constants.AI.textBaseURL }
        set { UserDefaults.standard.set(newValue, forKey: "ai_text_base_url") }
    }

    /// Base URL for image generation API
    var imageBaseURL: String {
        get { UserDefaults.standard.string(forKey: "ai_image_base_url") ?? Constants.AI.imageBaseURL }
        set { UserDefaults.standard.set(newValue, forKey: "ai_image_base_url") }
    }

    // MARK: - Initialization

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.AI.Timeouts.default
        config.timeoutIntervalForResource = Constants.AI.Timeouts.imageGeneration

        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.promptManager = PromptManager.shared
    }

    // MARK: - HTTP Method

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }

    // MARK: - Task Management

    /// Cancel all active requests
    func cancelAllRequests() {
        tasksLock.lock()
        defer { tasksLock.unlock() }

        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
        Log.debug("Cancelled all active AI requests", category: .ai)
    }

    /// Cancel a specific request by ID
    func cancelRequest(_ requestId: UUID) {
        tasksLock.lock()
        defer { tasksLock.unlock() }

        if let task = activeTasks[requestId] {
            task.cancel()
            activeTasks.removeValue(forKey: requestId)
            Log.debug("Cancelled AI request: \(requestId)", category: .ai)
        }
    }

    private func registerTask(_ taskId: UUID, _ task: Task<Void, Never>) {
        tasksLock.lock()
        defer { tasksLock.unlock() }
        activeTasks[taskId] = task
    }

    private func unregisterTask(_ taskId: UUID) {
        tasksLock.lock()
        defer { tasksLock.unlock() }
        activeTasks.removeValue(forKey: taskId)
    }

    // MARK: - Core Text Generation

    /// Generate text content using Gemini via Cloudflare Workers
    func generateText(
        prompt: String,
        systemPrompt: String? = nil,
        operation: String = "chat",
        temperature: Double = 0.7,
        maxTokens: Int = 2048,
        responseFormat: ResponseFormat? = nil
    ) async throws -> String {
        guard !textBaseURL.isEmpty else {
            throw AIError.invalidRequest(reason: "AI text base URL not configured")
        }

        // Build contents array
        var contents: [GeminiContent] = []

        // Add system prompt if provided
        if let systemPrompt = systemPrompt {
            contents.append(GeminiContent(
                role: "user",
                parts: [GeminiPart(text: systemPrompt)]
            ))
            contents.append(GeminiContent(
                role: "model",
                parts: [GeminiPart(text: "Understood. I will follow these instructions.")]
            ))
        }

        // Add user prompt
        contents.append(GeminiContent(
            role: "user",
            parts: [GeminiPart(text: prompt)]
        ))

        // Build generation config
        var generationConfig = GeminiGenerationConfig(
            temperature: temperature,
            maxOutputTokens: maxTokens
        )

        if let format = responseFormat, format.type == .json {
            generationConfig.responseMimeType = "application/json"
        }

        let request = TextGenerationRequest(
            contents: contents,
            generationConfig: generationConfig,
            operation: operation
        )

        let response: GeminiTextResponse = try await sendRequest(
            to: textBaseURL,
            body: request,
            timeout: Constants.AI.Timeouts.textGeneration
        )

        // Extract text from response
        guard var text = response.extractText() else {
            // Log debugging info for empty response
            Log.warning("Empty text from response. Candidates count: \(response.candidates?.count ?? 0)", category: .ai)
            if let firstCandidate = response.candidates?.first {
                Log.warning("First candidate content: \(firstCandidate.content != nil), parts count: \(firstCandidate.content?.parts?.count ?? 0)", category: .ai)
                if let finishReason = firstCandidate.finishReason {
                    Log.warning("Finish reason: \(finishReason)", category: .ai)
                }
            }
            throw AIError.emptyResponse
        }

        // Strip markdown code blocks if present (```json ... ``` or ``` ... ```)
        if text.hasPrefix("```") {
            // Remove opening fence (```json or ```)
            if let endOfFirstLine = text.firstIndex(of: "\n") {
                text = String(text[text.index(after: endOfFirstLine)...])
            }
            // Remove closing fence
            if let lastFence = text.range(of: "```", options: .backwards) {
                text = String(text[..<lastFence.lowerBound])
            }
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return text
    }

    /// Generate text with image input (multimodal)
    func generateTextWithImage(
        prompt: String,
        imageData: Data,
        mimeType: String = "image/jpeg",
        operation: String = "persona_creation",
        temperature: Double = 0.7
    ) async throws -> String {
        guard !textBaseURL.isEmpty else {
            throw AIError.invalidRequest(reason: "AI text base URL not configured")
        }

        let base64Image = imageData.base64EncodedString()

        let contents: [GeminiContent] = [
            GeminiContent(
                role: "user",
                parts: [
                    GeminiPart(text: prompt),
                    GeminiPart(inlineData: GeminiPart.InlineData(mimeType: mimeType, data: base64Image))
                ]
            )
        ]

        let request = TextGenerationRequest(
            contents: contents,
            generationConfig: GeminiGenerationConfig(
                temperature: temperature,
                maxOutputTokens: 2048
            ),
            operation: operation
        )

        let response: GeminiTextResponse = try await sendRequest(
            to: textBaseURL,
            body: request,
            timeout: Constants.AI.Timeouts.textGeneration
        )

        guard let text = response.extractText() else {
            throw AIError.emptyResponse
        }

        return text
    }

    // MARK: - Core Image Generation

    /// Generate an image using Gemini via Cloudflare Workers
    func generateImage(
        prompt: String,
        aspectRatio: String = "1:1",
        styleType: String? = nil,
        referenceImages: [Data]? = nil,
        operation: String = "journal_image"
    ) async throws -> (data: Data, mimeType: String) {
        guard !imageBaseURL.isEmpty else {
            throw AIError.invalidRequest(reason: "AI image base URL not configured")
        }

        // Convert reference images to data URLs
        var styleReferenceImages: [String]?
        if let referenceImages = referenceImages, !referenceImages.isEmpty {
            styleReferenceImages = referenceImages.prefix(Constants.AI.Limits.maxReferenceImages).map { data in
                "data:image/jpeg;base64,\(data.base64EncodedString())"
            }
        }

        let input = ImageGenerationInput(
            prompt: prompt,
            aspectRatio: aspectRatio,
            styleType: styleType,
            styleReferenceImages: styleReferenceImages
        )

        let request = CFImageGenerationRequest(
            version: Constants.AI.imageModelId,
            input: input,
            operation: operation
        )

        let response: CFImageGenerationResponse = try await sendRequest(
            to: imageBaseURL,
            body: request,
            timeout: Constants.AI.Timeouts.imageGeneration
        )

        guard response.status == "succeeded" else {
            throw AIError.imageGenerationFailed(reason: "Image generation failed with status: \(response.status)")
        }

        guard let imageData = response.imageData else {
            throw AIError.invalidImageData
        }

        return (imageData, response.mimeType)
    }

    // MARK: - Private Request Helper

    private func sendRequest<T: Encodable, R: Decodable>(
        to baseURL: String,
        body: T,
        timeout: TimeInterval
    ) async throws -> R {
        // PERF-N005: Check if task is cancelled before starting request
        try Task.checkCancellation()

        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout

        request.httpBody = try encoder.encode(body)

        Log.debug("AI Request: POST \(baseURL)", category: .ai)

        do {
            isProcessing = true
            defer { isProcessing = false }

            // PERF-N005: Check cancellation before network call
            try Task.checkCancellation()

            let (data, response) = try await session.data(for: request)

            // PERF-N005: Check cancellation after network call
            try Task.checkCancellation()

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }

            Log.debug("AI Response: \(httpResponse.statusCode) - \(data.count) bytes", category: .ai)

            // Handle error status codes
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to parse error response
                if let errorResponse = try? decoder.decode(CFErrorResponse.self, from: data) {
                    let error = errorResponse.error
                    let aiError = AIError.apiError(
                        code: error.type,
                        message: error.message,
                        retryable: error.retryable ?? false
                    )
                    lastError = aiError
                    throw aiError
                }
                throw AIError.from(statusCode: httpResponse.statusCode)
            }

            // Decode response
            let result = try decoder.decode(R.self, from: data)
            lastError = nil
            return result

        } catch is CancellationError {
            Log.debug("AI request cancelled", category: .ai)
            throw AIError.networkError(underlying: CancellationError())

        } catch let error as AIError {
            lastError = error
            Log.error("AI Error: \(error.localizedDescription)", category: .ai)
            throw error

        } catch let error as DecodingError {
            let aiError = AIError.parsingError(underlying: error)
            lastError = aiError
            Log.error("AI Parsing Error", error: error, category: .ai)
            throw aiError

        } catch {
            let aiError: AIError
            if (error as NSError).code == NSURLErrorTimedOut {
                aiError = .timeout
            } else if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                aiError = .noConnection
            } else {
                aiError = .networkError(underlying: error)
            }
            lastError = aiError
            Log.error("AI Network Error", error: error, category: .ai)
            throw aiError
        }
    }
}

// MARK: - Gemini Text Response

/// Response structure from Gemini text generation
struct GeminiTextResponse: Decodable {
    let candidates: [Candidate]?
    let usageMetadata: UsageMetadata?

    struct Candidate: Decodable {
        let content: Content?
        let finishReason: String?

        struct Content: Decodable {
            let parts: [Part]?
            let role: String?

            struct Part: Decodable {
                let text: String?
            }
        }
    }

    struct UsageMetadata: Decodable {
        let promptTokenCount: Int?
        let candidatesTokenCount: Int?
        let totalTokenCount: Int?
    }

    /// Extract text from the first candidate
    func extractText() -> String? {
        candidates?.first?.content?.parts?.first?.text
    }
}

// MARK: - Convenience Methods Using PromptManager

extension GeminiService {

    /// Analyze mood from text using MoodAnalysisPolicy
    func analyzeMood(content: String) async throws -> MoodAnalysisResult {
        let promptComponents = try promptManager.moodAnalysisPrompt(content: content)
        let requirements = MoodAnalysisPolicy().modelRequirements

        let response = try await generateText(
            prompt: promptComponents.content,
            systemPrompt: promptComponents.systemPrompt,
            operation: Constants.AI.Operations.journalProcessing,
            temperature: requirements.temperature,
            maxTokens: requirements.maxOutputTokens,
            responseFormat: promptComponents.responseFormat
        )

        guard let data = response.data(using: .utf8) else {
            throw AIError.parsingError(underlying: NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response encoding"]))
        }

        return try JSONDecoder().decode(MoodAnalysisResult.self, from: data)
    }

    /// Generate title for content using TitleGenerationPolicy
    func generateTitle(content: String, mood: Mood? = nil) async throws -> TitleGenerationResult {
        let promptComponents = try promptManager.titleGenerationPrompt(content: content, mood: mood)
        let requirements = TitleGenerationPolicy().modelRequirements

        let response = try await generateText(
            prompt: promptComponents.content,
            systemPrompt: promptComponents.systemPrompt,
            operation: Constants.AI.Operations.journalProcessing,
            temperature: requirements.temperature,
            maxTokens: requirements.maxOutputTokens,
            responseFormat: promptComponents.responseFormat
        )

        // Parse JSON response
        guard let data = response.data(using: .utf8) else {
            throw AIError.parsingError(underlying: NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response encoding"]))
        }

        return try JSONDecoder().decode(TitleGenerationResult.self, from: data)
    }

    /// Enhance journal entry using JournalEnhancementPolicy
    func enhanceEntry(
        content: String,
        style: EnhancementStyle,
        companion: AICompanion? = nil,
        journalingStyle: JournalingStyle? = nil,
        emotionalExpression: EmotionalExpression? = nil
    ) async throws -> EntryEnhancementResult {
        let promptComponents = try promptManager.enhancementPrompt(
            content: content,
            style: style,
            companion: companion,
            journalingStyle: journalingStyle,
            emotionalExpression: emotionalExpression
        )
        let requirements = JournalEnhancementPolicy().modelRequirements

        let response = try await generateText(
            prompt: promptComponents.content,
            systemPrompt: promptComponents.systemPrompt,
            operation: Constants.AI.Operations.journalProcessing,
            temperature: requirements.temperature,
            maxTokens: requirements.maxOutputTokens,
            responseFormat: promptComponents.responseFormat
        )

        guard let data = response.data(using: .utf8) else {
            throw AIError.parsingError(underlying: NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response encoding"]))
        }

        return try JSONDecoder().decode(EntryEnhancementResult.self, from: data)
    }

    /// Process full journal entry using JournalProcessingPolicy
    func processJournalEntry(
        content: String,
        persona: PersonaProfileModel? = nil,
        visualPreference: VisualPreference? = nil,
        journalingStyle: JournalingStyle? = nil,
        emotionalExpression: EmotionalExpression? = nil
    ) async throws -> JournalProcessingResult {
        let promptComponents = try promptManager.journalProcessingPrompt(
            content: content,
            persona: persona,
            visualPreference: visualPreference,
            journalingStyle: journalingStyle,
            emotionalExpression: emotionalExpression
        )
        let requirements = JournalProcessingPolicy().modelRequirements

        let response = try await generateText(
            prompt: promptComponents.content,
            systemPrompt: promptComponents.systemPrompt,
            operation: Constants.AI.Operations.journalProcessing,
            temperature: requirements.temperature,
            maxTokens: requirements.maxOutputTokens,
            responseFormat: promptComponents.responseFormat
        )

        guard let data = response.data(using: .utf8) else {
            throw AIError.parsingError(underlying: NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response encoding"]))
        }

        return try JSONDecoder().decode(JournalProcessingResult.self, from: data)
    }

    /// Generate persona avatar image using PersonaAvatarPolicy
    func generatePersonaAvatar(
        persona: PersonaProfileModel,
        style: AvatarStyle,
        referenceImage: Data? = nil
    ) async throws -> (data: Data, mimeType: String) {
        let promptComponents = try promptManager.avatarPrompt(persona: persona, style: style)

        return try await generateImage(
            prompt: promptComponents.combinedPrompt,
            aspectRatio: "1:1",
            styleType: style.cfStyleType,
            referenceImages: referenceImage.map { [$0] },
            operation: Constants.AI.Operations.personaAvatar
        )
    }

    /// Generate journal entry image using JournalImagePolicy
    func generateJournalImage(
        sceneDescription: String,
        persona: PersonaProfileModel? = nil,
        mood: Mood,
        visualPreference: VisualPreference? = nil,
        referenceImage: Data? = nil
    ) async throws -> (data: Data, mimeType: String) {
        let promptComponents = try promptManager.journalImagePrompt(
            sceneDescription: sceneDescription,
            persona: persona,
            mood: mood,
            visualPreference: visualPreference
        )

        return try await generateImage(
            prompt: promptComponents.combinedPrompt,
            aspectRatio: "16:9",
            referenceImages: referenceImage.map { [$0] },
            operation: Constants.AI.Operations.journalImage
        )
    }

    /// Generate reflection for entries using ReflectionPolicy
    func generateReflection(
        entries: [JournalEntryModel],
        timeframe: TimeFrame,
        companion: AICompanion? = nil
    ) async throws -> ReflectionResult {
        let promptComponents = try promptManager.reflectionPrompt(
            entries: entries,
            timeframe: timeframe,
            companion: companion
        )
        let requirements = ReflectionPolicy().modelRequirements

        let response = try await generateText(
            prompt: promptComponents.content,
            systemPrompt: promptComponents.systemPrompt,
            operation: Constants.AI.Operations.weeklyMonthlySummary,
            temperature: requirements.temperature,
            maxTokens: requirements.maxOutputTokens,
            responseFormat: promptComponents.responseFormat
        )

        guard let data = response.data(using: .utf8) else {
            throw AIError.parsingError(underlying: NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response encoding"]))
        }

        return try JSONDecoder().decode(ReflectionResult.self, from: data)
    }

    /// Generate persona bio from photo using PersonaBioPolicy
    func generatePersonaBio(
        photo: Data,
        personaName: String,
        personaType: PersonaType = .casual,
        style: AvatarStyle
    ) async throws -> PersonaBioResult {
        // Use PromptManager to build the bio prompt using PersonaBioPolicy
        let promptComponents = try promptManager.personaBioPrompt(
            personaName: personaName,
            personaType: personaType,
            style: style
        )
        let requirements = PersonaBioPolicy().modelRequirements

        // Use multimodal generation (text + image)
        let response = try await generateTextWithImage(
            prompt: promptComponents.combinedPrompt,
            imageData: photo,
            operation: Constants.AI.Operations.personaCreation,
            temperature: requirements.temperature
        )

        guard let data = response.data(using: .utf8) else {
            throw AIError.parsingError(underlying: NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response encoding"]))
        }

        return try JSONDecoder().decode(PersonaBioResult.self, from: data)
    }
}

// MARK: - Style Extensions

extension AvatarStyle {
    /// Cloudflare Workers style type
    var cfStyleType: String? {
        switch self {
        case .artistic:
            return "realistic"
        case .cartoon:
            return "anime"
        case .minimalist, .watercolor, .sketch:
            return "design"
        }
    }
}

// MARK: - Environment Key

import SwiftUI

private struct GeminiServiceKey: EnvironmentKey {
    static let defaultValue = GeminiService.shared
}

extension EnvironmentValues {
    var geminiService: GeminiService {
        get { self[GeminiServiceKey.self] }
        set { self[GeminiServiceKey.self] = newValue }
    }
}
