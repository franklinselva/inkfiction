//
//  GeminiService.swift
//  InkFiction
//
//  Core API client for Gemini 2.5 Flash via Vercel backend
//

import Foundation

// MARK: - Gemini Service

/// Core service for AI operations via Vercel backend
@Observable
final class GeminiService {
    static let shared = GeminiService()

    // MARK: - Properties

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private(set) var isProcessing = false
    private(set) var lastError: AIError?

    /// Base URL for AI API (Vercel backend)
    var baseURL: String {
        get { UserDefaults.standard.string(forKey: "ai_base_url") ?? Constants.AI.baseURL }
        set { UserDefaults.standard.set(newValue, forKey: "ai_base_url") }
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
    }

    // MARK: - Core Request Methods

    /// Send a request to the AI backend
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .post,
        body: Encodable? = nil,
        timeout: TimeInterval? = nil
    ) async throws -> T {
        guard !baseURL.isEmpty else {
            throw AIError.invalidRequest(reason: "AI base URL not configured")
        }

        let url = URL(string: "\(baseURL)/\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let timeout = timeout {
            request.timeoutInterval = timeout
        }

        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        Log.debug("AI Request: \(method.rawValue) \(endpoint)", category: .ai)

        do {
            isProcessing = true
            defer { isProcessing = false }

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }

            // Log response status
            Log.debug("AI Response: \(httpResponse.statusCode) - \(data.count) bytes", category: .ai)

            // Handle error status codes
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to parse error response
                if let errorResponse = try? decoder.decode(AIResponse<EmptyResponse>.self, from: data),
                   let error = errorResponse.error {
                    throw AIError.from(response: error)
                }
                throw AIError.from(statusCode: httpResponse.statusCode)
            }

            // Decode response
            let result = try decoder.decode(T.self, from: data)
            lastError = nil
            return result

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

    /// Send request with retry logic
    func requestWithRetry<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .post,
        body: Encodable? = nil,
        maxRetries: Int = 2,
        timeout: TimeInterval? = nil
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0...maxRetries {
            do {
                if attempt > 0 {
                    // Exponential backoff
                    let delay = pow(2.0, Double(attempt - 1))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    Log.info("AI Retry attempt \(attempt) for \(endpoint)", category: .ai)
                }

                return try await request(endpoint: endpoint, method: method, body: body, timeout: timeout)

            } catch let error as AIError where error.isRetryable {
                lastError = error
                continue

            } catch {
                throw error
            }
        }

        throw lastError ?? AIError.unknown(message: "Request failed after \(maxRetries) retries")
    }

    // MARK: - HTTP Method

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
}

// MARK: - Empty Response

private struct EmptyResponse: Decodable {}

// MARK: - Convenience Methods

extension GeminiService {
    /// Analyze mood from text
    func analyzeMood(content: String) async throws -> MoodAnalysisResult {
        let body = AIRequest(
            operation: .analyzeMood,
            content: content,
            context: nil,
            options: nil
        )

        let response: AIResponse<MoodAnalysisResult> = try await request(
            endpoint: "ai/analyze-mood",
            body: body
        )

        guard let result = response.data else {
            if let error = response.error {
                throw AIError.from(response: error)
            }
            throw AIError.emptyResponse
        }

        return result
    }

    /// Generate title for content
    func generateTitle(content: String, mood: Mood? = nil) async throws -> TitleGenerationResult {
        let context = AIContext(mood: mood?.rawValue)
        let body = AIRequest(
            operation: .generateTitle,
            content: content,
            context: context,
            options: nil
        )

        let response: AIResponse<TitleGenerationResult> = try await request(
            endpoint: "ai/generate-title",
            body: body
        )

        guard let result = response.data else {
            if let error = response.error {
                throw AIError.from(response: error)
            }
            throw AIError.emptyResponse
        }

        return result
    }

    /// Enhance journal entry
    func enhanceEntry(
        content: String,
        style: EnhancementStyle,
        companion: AICompanion? = nil
    ) async throws -> EntryEnhancementResult {
        let context = AIContext(companionId: companion?.id)
        let options = AIOptions(enhancementStyle: style)
        let body = AIRequest(
            operation: .enhanceEntry,
            content: content,
            context: context,
            options: options
        )

        let response: AIResponse<EntryEnhancementResult> = try await request(
            endpoint: "ai/enhance-entry",
            body: body
        )

        guard let result = response.data else {
            if let error = response.error {
                throw AIError.from(response: error)
            }
            throw AIError.emptyResponse
        }

        return result
    }

    /// Process full journal entry
    func processJournalEntry(
        content: String,
        persona: PersonaProfileModel? = nil,
        visualPreference: VisualPreference? = nil
    ) async throws -> JournalProcessingResult {
        var context = AIContext(visualPreference: visualPreference?.rawValue)

        if let persona = persona {
            context.personaName = persona.name
            if let attributes = persona.attributes {
                context.personaAttributes = PersonaAttributesDTO(from: attributes)
            }
        }

        let body = AIRequest(
            operation: .processJournal,
            content: content,
            context: context,
            options: nil
        )

        let response: AIResponse<JournalProcessingResult> = try await request(
            endpoint: "ai/process-journal",
            body: body
        )

        guard let result = response.data else {
            if let error = response.error {
                throw AIError.from(response: error)
            }
            throw AIError.emptyResponse
        }

        return result
    }

    /// Generate image
    func generateImage(
        prompt: String,
        style: AvatarStyle,
        type: ImageGenerationRequest.ImageType,
        aspectRatio: ImageGenerationRequest.AspectRatio = .square,
        referenceImage: Data? = nil
    ) async throws -> ImageGenerationResult {
        let request = ImageGenerationRequest(
            prompt: prompt,
            style: style.rawValue,
            type: type,
            aspectRatio: aspectRatio,
            referenceImageBase64: referenceImage?.base64EncodedString()
        )

        let response: AIResponse<ImageGenerationResult> = try await self.requestWithRetry(
            endpoint: "ai/generate-image",
            body: request,
            maxRetries: 1,
            timeout: Constants.AI.Timeouts.imageGeneration
        )

        guard let result = response.data else {
            if let error = response.error {
                throw AIError.from(response: error)
            }
            throw AIError.emptyResponse
        }

        guard result.imageData != nil else {
            throw AIError.invalidImageData
        }

        return result
    }

    /// Generate reflection
    func generateReflection(
        entries: [JournalEntryModel],
        timeframe: TimeFrame,
        companion: AICompanion? = nil
    ) async throws -> ReflectionResult {
        let summaries = entries.map { entry in
            JournalEntrySummary(
                title: entry.title,
                mood: entry.mood.rawValue,
                date: entry.createdAt,
                snippet: String(entry.content.prefix(200))
            )
        }

        let context = AIContext(
            timeframe: timeframe.rawValue,
            companionId: companion?.id,
            previousEntries: summaries
        )

        let body = AIRequest(
            operation: .generateReflection,
            content: "Generate reflection for \(timeframe.displayName)",
            context: context,
            options: nil
        )

        let response: AIResponse<ReflectionResult> = try await request(
            endpoint: "ai/generate-reflection",
            body: body
        )

        guard let result = response.data else {
            if let error = response.error {
                throw AIError.from(response: error)
            }
            throw AIError.emptyResponse
        }

        return result
    }

    /// Generate persona bio from photo
    func generatePersonaBio(
        photo: Data,
        personaName: String,
        style: AvatarStyle
    ) async throws -> PersonaBioResult {
        let context = AIContext(
            personaName: personaName,
            avatarStyle: style.rawValue
        )

        let body = AIRequest(
            operation: .generatePersonaBio,
            content: photo.base64EncodedString(),
            context: context,
            options: nil
        )

        let response: AIResponse<PersonaBioResult> = try await request(
            endpoint: "ai/generate-persona-bio",
            body: body
        )

        guard let result = response.data else {
            if let error = response.error {
                throw AIError.from(response: error)
            }
            throw AIError.emptyResponse
        }

        return result
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
