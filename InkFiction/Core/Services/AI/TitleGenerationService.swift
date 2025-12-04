//
//  TitleGenerationService.swift
//  InkFiction
//
//  Service for AI-powered title generation for journal entries
//

import Foundation
import SwiftUI

// MARK: - Title Generation Service

/// Service for generating titles and enhancing journal entries
@Observable
final class TitleGenerationService {
    static let shared = TitleGenerationService()

    // MARK: - Properties

    private let geminiService: GeminiService
    private let promptManager: PromptManager

    private(set) var isGenerating = false
    private(set) var lastError: AIError?

    // MARK: - Initialization

    private init(
        geminiService: GeminiService = .shared,
        promptManager: PromptManager = .shared
    ) {
        self.geminiService = geminiService
        self.promptManager = promptManager
    }

    // MARK: - Title Generation

    /// Generate a title for journal content
    func generateTitle(content: String, mood: Mood? = nil) async throws -> String {
        guard !content.isEmpty else {
            throw AIError.invalidRequest(reason: "Content cannot be empty")
        }

        guard content.count >= 10 else {
            throw AIError.invalidRequest(reason: "Content too short for title generation")
        }

        isGenerating = true
        defer { isGenerating = false }

        Log.info("Generating title for content: \(content.prefix(50))...", category: .ai)

        do {
            let result = try await geminiService.generateTitle(content: content, mood: mood)

            Log.info("Title generated: \(result.title)", category: .ai)

            lastError = nil
            return result.title

        } catch {
            lastError = error as? AIError ?? AIError.unknown(message: error.localizedDescription)
            throw error
        }
    }

    /// Generate title with alternatives
    func generateTitleWithAlternatives(content: String, mood: Mood? = nil) async throws -> (title: String, alternatives: [String]) {
        guard !content.isEmpty else {
            throw AIError.invalidRequest(reason: "Content cannot be empty")
        }

        isGenerating = true
        defer { isGenerating = false }

        do {
            let result = try await geminiService.generateTitle(content: content, mood: mood)
            return (result.title, result.alternatives ?? [])
        } catch {
            lastError = error as? AIError ?? AIError.unknown(message: error.localizedDescription)
            throw error
        }
    }

    /// Generate title with fallback to local generation
    func generateTitleWithFallback(content: String, mood: Mood? = nil) async -> String {
        do {
            return try await generateTitle(content: content, mood: mood)
        } catch {
            Log.warning("AI title generation failed, using fallback", category: .ai)
            return generateLocalTitle(content: content)
        }
    }

    // MARK: - Local Title Generation (Fallback)

    /// Generate a simple title locally (when offline)
    func generateLocalTitle(content: String) -> String {
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to use first sentence
        if let firstSentenceEnd = cleanContent.firstIndex(where: { ".!?".contains($0) }) {
            let firstSentence = String(cleanContent[..<firstSentenceEnd])
            if firstSentence.count <= 50 && firstSentence.count >= 3 {
                return firstSentence.trimmingCharacters(in: .whitespaces)
            }
        }

        // Use first few words
        let words = cleanContent.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let titleWords = Array(words.prefix(5))

        if titleWords.count >= 2 {
            return titleWords.joined(separator: " ") + "..."
        }

        // Default
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d"
        return "Entry - \(dateFormatter.string(from: Date()))"
    }

    // MARK: - Entry Enhancement

    /// Enhance a journal entry
    func enhanceEntry(
        content: String,
        style: EnhancementStyle,
        companion: AICompanion? = nil
    ) async throws -> String {
        guard !content.isEmpty else {
            throw AIError.invalidRequest(reason: "Content cannot be empty")
        }

        isGenerating = true
        defer { isGenerating = false }

        Log.info("Enhancing entry with \(style.displayName) style", category: .ai)

        do {
            let result = try await geminiService.enhanceEntry(
                content: content,
                style: style,
                companion: companion
            )

            Log.info("Entry enhanced successfully", category: .ai)

            lastError = nil
            return result.enhancedContent

        } catch {
            lastError = error as? AIError ?? AIError.unknown(message: error.localizedDescription)
            throw error
        }
    }

    // MARK: - Full Journal Processing

    /// Process a journal entry for all metadata (title, mood, tags, image prompt)
    func processJournalEntry(
        content: String,
        persona: PersonaProfileModel? = nil,
        visualPreference: VisualPreference? = nil
    ) async throws -> JournalProcessingResult {
        guard !content.isEmpty else {
            throw AIError.invalidRequest(reason: "Content cannot be empty")
        }

        guard content.count >= 20 else {
            throw AIError.invalidRequest(reason: "Content too short for full processing")
        }

        isGenerating = true
        defer { isGenerating = false }

        Log.info("Processing journal entry: \(content.prefix(50))...", category: .ai)

        do {
            let result = try await geminiService.processJournalEntry(
                content: content,
                persona: persona,
                visualPreference: visualPreference
            )

            Log.info("Journal processed - Title: \(result.title), Mood: \(result.mood)", category: .ai)

            lastError = nil
            return result

        } catch {
            lastError = error as? AIError ?? AIError.unknown(message: error.localizedDescription)
            throw error
        }
    }
}

// MARK: - Environment Key

private struct TitleGenerationServiceKey: EnvironmentKey {
    static let defaultValue = TitleGenerationService.shared
}

extension EnvironmentValues {
    var titleGenerationService: TitleGenerationService {
        get { self[TitleGenerationServiceKey.self] }
        set { self[TitleGenerationServiceKey.self] = newValue }
    }
}
