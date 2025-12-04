//
//  MoodAnalysisPolicy.swift
//  InkFiction
//
//  Prompt policy for mood detection from journal entries
//

import Foundation

// MARK: - Mood Analysis Policy

struct MoodAnalysisPolicy: PromptPolicy {
    static let policyId = "mood_analysis"

    var identifier: String { Self.policyId }

    var modelRequirements: ModelRequirements { .moodAnalysis }

    var contextAllocation: ContextAllocation { .contentFocused }

    func validate(context: PromptContext) throws {
        guard !context.primaryContent.isEmpty else {
            throw PromptValidationError.emptyContent
        }

        if context.primaryContent.count > 50000 {
            throw PromptValidationError.contentTooLong(max: 50000, actual: context.primaryContent.count)
        }
    }

    func buildPrompt(context: PromptContext) throws -> PromptComponents {
        let systemPrompt = """
        You are an expert emotional intelligence analyst specializing in journal entry analysis.
        Your task is to detect the primary mood from a journal entry with high accuracy.

        Analyze the text for:
        1. Explicit emotional words and phrases
        2. Implicit emotional cues (tone, word choice, sentence structure)
        3. Context clues about the writer's state of mind
        4. Overall sentiment and intensity

        Available moods (pick the most dominant one):
        - Happy: Joy, contentment, satisfaction, pleasure
        - Excited: Enthusiasm, anticipation, eagerness, thrill
        - Peaceful: Calm, serene, relaxed, tranquil
        - Neutral: Balanced, matter-of-fact, objective
        - Thoughtful: Contemplative, reflective, pensive, introspective
        - Sad: Melancholy, grief, disappointment, sorrow
        - Anxious: Worried, nervous, stressed, overwhelmed
        - Angry: Frustrated, irritated, resentful, annoyed
        """

        let responseSchema = """
        {
          "mood": "one of: Happy, Excited, Peaceful, Neutral, Thoughtful, Sad, Anxious, Angry",
          "confidence": 0.0 to 1.0,
          "keywords": ["up to 5 emotional keywords found in the text"],
          "sentiment": "positive, negative, neutral, or mixed",
          "intensity": 0.0 to 1.0 (how strongly the mood is expressed)
        }
        """

        let content = """
        Analyze the mood of this journal entry:

        ---
        \(context.primaryContent)
        ---

        Respond with JSON matching this exact structure:
        \(responseSchema)
        """

        return PromptComponents(
            systemPrompt: systemPrompt,
            content: content,
            responseFormat: .json
        )
    }
}

// MARK: - Mood Detection Extension

// Note: MoodDetectionKeywords is defined in Features/Reflect/Models/ReflectModels.swift

extension MoodDetectionKeywords {
    /// Quick client-side mood detection
    static func detectMood(from text: String) -> (mood: Mood, confidence: Double) {
        let lowercased = text.lowercased()
        var scores: [Mood: Int] = [:]

        // Count keyword matches for each mood
        for mood in Mood.allCases {
            let keywords = MoodDetectionKeywords.keywords(for: mood)
            scores[mood] = keywords.filter { lowercased.contains($0) }.count
        }

        // Find max score
        let maxScore = scores.values.max() ?? 0
        let totalScore = scores.values.reduce(0, +)

        if maxScore == 0 {
            return (.neutral, 0.5)
        }

        let detectedMood = scores.first { $0.value == maxScore }?.key ?? .neutral
        let confidence = totalScore > 0 ? min(Double(maxScore) / Double(totalScore + 2), 0.9) : 0.5

        return (detectedMood, confidence)
    }
}
