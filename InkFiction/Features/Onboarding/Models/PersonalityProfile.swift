//
//  PersonalityProfile.swift
//  InkFiction
//
//  Personality profile built from quiz answers
//

import Foundation
import SwiftUI

// MARK: - Journaling Style

/// User's preferred journaling style
enum JournalingStyle: String, Codable, CaseIterable {
    case quickNotes = "quick_notes"
    case detailedStories = "detailed_stories"
    case visualSketches = "visual_sketches"
    case mixedMedia = "mixed_media"

    var displayName: String {
        switch self {
        case .quickNotes:
            return "Quick notes"
        case .detailedStories:
            return "Detailed stories"
        case .visualSketches:
            return "Visual sketches"
        case .mixedMedia:
            return "Mixed media"
        }
    }

    var icon: String {
        switch self {
        case .quickNotes:
            return "bolt.fill"
        case .detailedStories:
            return "book.fill"
        case .visualSketches:
            return "paintbrush.fill"
        case .mixedMedia:
            return "square.grid.2x2.fill"
        }
    }

    var unselectedIcon: String {
        switch self {
        case .quickNotes:
            return "bolt"
        case .detailedStories:
            return "book"
        case .visualSketches:
            return "paintbrush"
        case .mixedMedia:
            return "square.grid.2x2"
        }
    }
}

// MARK: - Emotional Expression

/// User's preferred way of expressing emotions
enum EmotionalExpression: String, Codable, CaseIterable {
    case writingFreely = "writing_freely"
    case structuredPrompts = "structured_prompts"
    case moodTracking = "mood_tracking"
    case creativeExploration = "creative_exploration"

    var displayName: String {
        switch self {
        case .writingFreely:
            return "Writing freely"
        case .structuredPrompts:
            return "Structured prompts"
        case .moodTracking:
            return "Mood tracking"
        case .creativeExploration:
            return "Creative exploration"
        }
    }

    var icon: String {
        switch self {
        case .writingFreely:
            return "wind"
        case .structuredPrompts:
            return "list.bullet.rectangle"
        case .moodTracking:
            return "heart.text.square"
        case .creativeExploration:
            return "sparkles"
        }
    }

    var unselectedIcon: String {
        icon // Same icon for both states
    }
}

// MARK: - Visual Preference

/// User's preferred visual style
enum VisualPreference: String, Codable, CaseIterable {
    case abstractDreamy = "abstract_dreamy"
    case realisticGrounded = "realistic_grounded"
    case minimalistClean = "minimalist_clean"
    case vibrantExpressive = "vibrant_expressive"

    var displayName: String {
        switch self {
        case .abstractDreamy:
            return "Abstract & dreamy"
        case .realisticGrounded:
            return "Realistic & grounded"
        case .minimalistClean:
            return "Minimalist & clean"
        case .vibrantExpressive:
            return "Vibrant & expressive"
        }
    }

    var icon: String {
        switch self {
        case .abstractDreamy:
            return "cloud.fill"
        case .realisticGrounded:
            return "camera.fill"
        case .minimalistClean:
            return "square.fill"
        case .vibrantExpressive:
            return "star.fill"
        }
    }

    var unselectedIcon: String {
        switch self {
        case .abstractDreamy:
            return "cloud"
        case .realisticGrounded:
            return "camera"
        case .minimalistClean:
            return "square"
        case .vibrantExpressive:
            return "star"
        }
    }
}

// MARK: - Personality Profile

/// User's personality profile built from quiz answers
struct PersonalityProfile: Codable {
    let journalingStyle: JournalingStyle
    let emotionalExpression: EmotionalExpression
    let visualPreference: VisualPreference

    /// Get suggested AI companions based on personality profile
    func suggestedCompanions() -> [AICompanion] {
        var companions: [AICompanion] = []

        // Primary suggestion based on dominant traits
        if journalingStyle == .detailedStories && emotionalExpression == .writingFreely {
            companions.append(.poet)
        } else if journalingStyle == .quickNotes && emotionalExpression == .structuredPrompts {
            companions.append(.sage)
        } else if visualPreference == .vibrantExpressive || emotionalExpression == .creativeExploration {
            companions.append(.dreamer)
        } else {
            companions.append(.realist)
        }

        // Add secondary suggestions
        if visualPreference == .abstractDreamy && !companions.contains(.poet) {
            companions.append(.poet)
        }
        if visualPreference == .minimalistClean && !companions.contains(.sage) {
            companions.append(.sage)
        }
        if !companions.contains(.dreamer) && companions.count < 3 {
            companions.append(.dreamer)
        }
        if !companions.contains(.realist) && companions.count < 3 {
            companions.append(.realist)
        }

        return Array(companions.prefix(3))
    }
}
