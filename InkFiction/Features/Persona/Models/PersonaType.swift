//
//  PersonaType.swift
//  InkFiction
//
//  Persona type categorization for context-aware avatar selection
//

import Foundation
import SwiftUI

// MARK: - PersonaType

enum PersonaType: String, Codable, CaseIterable {
    case professional
    case creative
    case fitness
    case relaxed
    case social
    case adventurous
    case focused
    case expressive
    case peaceful
    case energetic
    case cozy
    case active
    case casual
    case thoughtful

    var displayName: String {
        rawValue.capitalized
    }

    var description: String {
        switch self {
        case .professional: return "Work and career focused"
        case .creative: return "Artistic and imaginative"
        case .fitness: return "Health and exercise oriented"
        case .relaxed: return "Calm and laid-back"
        case .social: return "Outgoing and people-oriented"
        case .adventurous: return "Thrill-seeking and explorative"
        case .focused: return "Concentrated and determined"
        case .expressive: return "Emotionally open and communicative"
        case .peaceful: return "Serene and tranquil"
        case .energetic: return "High energy and enthusiastic"
        case .cozy: return "Comfortable and homey"
        case .active: return "Dynamic and on-the-go"
        case .casual: return "Easygoing and informal"
        case .thoughtful: return "Reflective and contemplative"
        }
    }

    var icon: String {
        switch self {
        case .professional: return "briefcase.fill"
        case .creative: return "paintbrush.fill"
        case .fitness: return "figure.run"
        case .relaxed: return "leaf.fill"
        case .social: return "person.3.fill"
        case .adventurous: return "mountain.2.fill"
        case .focused: return "target"
        case .expressive: return "theatermasks.fill"
        case .peaceful: return "moon.stars.fill"
        case .energetic: return "bolt.fill"
        case .cozy: return "house.fill"
        case .active: return "figure.walk"
        case .casual: return "cup.and.saucer.fill"
        case .thoughtful: return "brain"
        }
    }

    var color: Color {
        switch self {
        case .professional: return .blue
        case .creative: return .purple
        case .fitness: return .green
        case .relaxed: return .teal
        case .social: return .orange
        case .adventurous: return .red
        case .focused: return .indigo
        case .expressive: return .pink
        case .peaceful: return .cyan
        case .energetic: return .yellow
        case .cozy: return .brown
        case .active: return .mint
        case .casual: return .gray
        case .thoughtful: return .secondary
        }
    }

    var preferredMoods: [MoodTag] {
        switch self {
        case .professional: return [.confident, .focused, .thoughtful]
        case .creative: return [.creative, .inspired, .expressive]
        case .fitness: return [.energetic, .confident, .focused]
        case .relaxed: return [.relaxed, .peaceful, .grateful]
        case .social: return [.happy, .energetic, .expressive]
        case .adventurous: return [.energetic, .confident, .hopeful]
        case .focused: return [.focused, .thoughtful, .confident]
        case .expressive: return [.expressive, .creative, .inspired]
        case .peaceful: return [.peaceful, .grateful, .relaxed]
        case .energetic: return [.energetic, .happy, .confident]
        case .cozy: return [.relaxed, .peaceful, .grateful]
        case .active: return [.energetic, .happy, .confident]
        case .casual: return [.relaxed, .happy, .neutral]
        case .thoughtful: return [.thoughtful, .peaceful, .inspired]
        }
    }

    var contextKeywords: [String] {
        switch self {
        case .professional: return ["work", "office", "meeting", "career", "business"]
        case .creative: return ["art", "design", "create", "imagine", "inspire"]
        case .fitness: return ["exercise", "workout", "gym", "health", "run"]
        case .relaxed: return ["relax", "calm", "rest", "peaceful", "unwind"]
        case .social: return ["friends", "party", "gathering", "connect", "chat"]
        case .adventurous: return ["travel", "explore", "discover", "adventure", "journey"]
        case .focused: return ["concentrate", "study", "learn", "work", "goal"]
        case .expressive: return ["feel", "emotion", "express", "share", "communicate"]
        case .peaceful: return ["meditate", "quiet", "serene", "tranquil", "zen"]
        case .energetic: return ["energy", "active", "dynamic", "vibrant", "alive"]
        case .cozy: return ["home", "comfort", "warm", "snug", "cozy"]
        case .active: return ["move", "activity", "sport", "outdoor", "dynamic"]
        case .casual: return ["everyday", "normal", "regular", "simple", "easy"]
        case .thoughtful: return ["think", "reflect", "consider", "ponder", "contemplate"]
        }
    }
}

// MARK: - PersonaType Extensions

extension PersonaType {
    /// Calculate compatibility score with journal entry content
    func compatibilityScore(with content: String, mood: Mood?) -> Double {
        var score = 0.0
        let lowercaseContent = content.lowercased()

        // Check keyword matches
        for keyword in contextKeywords {
            if lowercaseContent.contains(keyword) {
                score += 0.15
            }
        }

        // Check mood compatibility
        if let mood = mood {
            let moodTag = mood.toMoodTag
            if preferredMoods.contains(moodTag) {
                score += 0.3
            }
        }

        return min(1.0, score)
    }

    /// Suggest best persona type for given context
    static func suggestType(for content: String, mood: Mood?) -> PersonaType {
        var bestMatch: PersonaType = .casual
        var highestScore: Double = 0

        for type in PersonaType.allCases {
            let score = type.compatibilityScore(with: content, mood: mood)
            if score > highestScore {
                highestScore = score
                bestMatch = type
            }
        }

        return bestMatch
    }
}

// MARK: - Mood to MoodTag Conversion

extension Mood {
    var toMoodTag: MoodTag {
        switch self {
        case .happy: return .happy
        case .excited: return .energetic
        case .peaceful: return .peaceful
        case .neutral: return .neutral
        case .thoughtful: return .thoughtful
        case .sad: return .peaceful  // Default to calming
        case .anxious: return .focused
        case .angry: return .energetic
        }
    }
}
