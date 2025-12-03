//
//  OnboardingState.swift
//  InkFiction
//
//  Onboarding state and step definitions
//

import Foundation

// MARK: - Onboarding Step

/// Steps in the onboarding flow
enum OnboardingStep: Int, CaseIterable, Equatable, Hashable {
    case welcome = 0
    case quiz = 1
    case companionSelection = 2
    case permissions = 3

    /// Progress through onboarding (0.0 to 1.0)
    var progress: Double {
        guard self != .welcome else { return 0 }
        // Calculate progress starting from quiz (index 1)
        let adjustedStep = max(0, self.rawValue - 1)
        let totalSteps = OnboardingStep.allCases.count - 1 // Exclude welcome
        return Double(adjustedStep + 1) / Double(totalSteps)
    }

    /// Display title for the step
    var title: String {
        switch self {
        case .welcome:
            return "Welcome"
        case .quiz:
            return "Personality Discovery"
        case .companionSelection:
            return "Choose Your AI Companion"
        case .permissions:
            return "Final Setup"
        }
    }
}

// MARK: - Quiz Answer

/// A single quiz answer
struct QuizAnswer: Codable, Equatable {
    let questionId: String
    let answerId: String
    let answerText: String
}

// MARK: - Onboarding State

/// Complete onboarding state
struct OnboardingState: Codable {
    var currentStep: Int = 0
    var quizAnswers: [QuizAnswer] = []
    var selectedCompanion: AICompanion?
    var permissionsGranted: Set<Permission> = []
    var isCompleted: Bool = false
    var isSkipped: Bool = false

    /// Reset the onboarding state
    mutating func reset() {
        currentStep = 0
        quizAnswers = []
        selectedCompanion = nil
        permissionsGranted = []
        isCompleted = false
        isSkipped = false
    }
}

// MARK: - Saved Onboarding Data

/// Data saved after onboarding completion
struct SavedOnboardingData: Codable {
    let completedAt: Date
    let quizAnswers: [QuizAnswer]
    let selectedCompanion: AICompanion
    let permissionsGranted: Set<Permission>
    let wasSkipped: Bool
    let skippedPermissions: Bool
    let timeSpent: TimeInterval
    let viewedAllCompanions: Bool
    let changedAnswers: Bool

    /// Convert to JSON string
    func toJSONString() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Create from JSON string
    static func fromJSONString(_ json: String) -> SavedOnboardingData? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(SavedOnboardingData.self, from: data)
    }
}
