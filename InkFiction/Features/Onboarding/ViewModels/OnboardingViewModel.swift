//
//  OnboardingViewModel.swift
//  InkFiction
//
//  ViewModel managing the onboarding flow
//

import SwiftUI
import Combine

// MARK: - Onboarding ViewModel

@MainActor
@Observable
final class OnboardingViewModel {

    // MARK: - Published State

    var state = OnboardingState()
    var currentStep = OnboardingStep.welcome
    var isAnimating = false
    var isCompletingOnboarding = false

    // MARK: - Tracking

    var viewedAllCompanions = false
    var changedAnswers = false

    // MARK: - Private Properties

    private let startTime = Date()

    // MARK: - Navigation

    /// Move to the next step
    func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                currentStep = .quiz
            case .quiz:
                if state.quizAnswers.count >= 3 {
                    currentStep = .companionSelection
                }
            case .companionSelection:
                if state.selectedCompanion != nil {
                    currentStep = .permissions
                }
            case .permissions:
                Task {
                    await completeOnboarding()
                }
            }
            state.currentStep = currentStep.rawValue
        }
    }

    /// Move to the previous step
    func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                break
            case .quiz:
                currentStep = .welcome
            case .companionSelection:
                currentStep = .quiz
            case .permissions:
                currentStep = .companionSelection
            }
            state.currentStep = currentStep.rawValue
        }
    }

    /// Skip onboarding and use defaults
    func skipOnboarding() {
        state.isSkipped = true
        state.selectedCompanion = .realist // Default companion
        Task {
            await completeOnboarding()
        }
    }

    // MARK: - Onboarding Completion

    /// Complete onboarding and save data
    func completeOnboarding(skippedPermissions: Bool = false) async {
        guard !isCompletingOnboarding else {
            Log.warning("completeOnboarding already in progress", category: .app)
            return
        }

        isCompletingOnboarding = true

        // Calculate time spent
        let timeSpent = Date().timeIntervalSince(startTime)

        // Get personality profile for saving
        let profile = getPersonalityProfile()
        let companion = state.selectedCompanion ?? .realist

        // Create saved data object (for legacy compatibility)
        let savedData = SavedOnboardingData(
            completedAt: Date(),
            quizAnswers: state.quizAnswers,
            selectedCompanion: companion,
            permissionsGranted: state.permissionsGranted,
            wasSkipped: state.isSkipped,
            skippedPermissions: skippedPermissions,
            timeSpent: timeSpent,
            viewedAllCompanions: viewedAllCompanions,
            changedAnswers: changedAnswers
        )

        // Save to UserDefaults (legacy)
        if let jsonString = savedData.toJSONString() {
            UserDefaults.standard.set(jsonString, forKey: "onboardingData")
        }

        // Mark as completed
        state.isCompleted = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        // Save to iCloud via settings repository
        do {
            let settingsRepository = SettingsRepository.shared

            // Save journal preferences to iCloud
            try await settingsRepository.updateJournalPreferences(
                journalingStyle: profile?.journalingStyle ?? .quickNotes,
                emotionalExpression: profile?.emotionalExpression ?? .writingFreely,
                visualPreference: profile?.visualPreference ?? .abstractDreamy,
                companion: companion
            )

            // Mark onboarding as completed
            try await settingsRepository.completeOnboarding()

            Log.info("Onboarding completed and saved to iCloud", category: .app)
        } catch {
            Log.error("Failed to save onboarding to iCloud", error: error, category: .app)
        }

        isCompletingOnboarding = false

        // Post notification
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
    }

    // MARK: - Quiz Management

    /// Record a quiz answer
    func answerQuizQuestion(questionId: String, answerId: String, answerText: String) {
        let answer = QuizAnswer(
            questionId: questionId,
            answerId: answerId,
            answerText: answerText
        )

        // Check if changing an existing answer
        if state.quizAnswers.contains(where: { $0.questionId == questionId }) {
            changedAnswers = true
        }

        // Remove any existing answer for this question
        state.quizAnswers.removeAll { $0.questionId == questionId }
        state.quizAnswers.append(answer)
    }

    /// Get personality profile from quiz answers
    func getPersonalityProfile() -> PersonalityProfile? {
        guard state.quizAnswers.count >= 3 else { return nil }

        let journalingStyle = mapToJournalingStyle(state.quizAnswers[0].answerId)
        let emotionalExpression = mapToEmotionalExpression(state.quizAnswers[1].answerId)
        let visualPreference = mapToVisualPreference(state.quizAnswers[2].answerId)

        return PersonalityProfile(
            journalingStyle: journalingStyle,
            emotionalExpression: emotionalExpression,
            visualPreference: visualPreference
        )
    }

    // MARK: - Companion Selection

    /// Select an AI companion
    func selectCompanion(_ companion: AICompanion) {
        withAnimation(.spring()) {
            state.selectedCompanion = companion
        }
    }

    /// Get suggested companions based on quiz answers
    func getSuggestedCompanions() -> [AICompanion] {
        guard let profile = getPersonalityProfile() else {
            return [.poet, .sage, .dreamer]
        }
        return profile.suggestedCompanions()
    }

    // MARK: - Permissions

    /// Grant a permission
    func grantPermission(_ permission: Permission) {
        state.permissionsGranted.insert(permission)
    }

    /// Revoke a permission
    func revokePermission(_ permission: Permission) {
        state.permissionsGranted.remove(permission)
    }

    // MARK: - State Management

    /// Reset onboarding state
    func resetOnboarding() {
        state.reset()
        currentStep = .welcome
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "selectedCompanionId")
        UserDefaults.standard.removeObject(forKey: "onboardingData")
        // Also clear new preference keys
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.journalingStyle)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.emotionalExpression)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.visualPreference)

        // Post notification
        NotificationCenter.default.post(name: .restartOnboarding, object: nil)
    }

    // MARK: - Private Mapping Functions

    private func mapToJournalingStyle(_ answerId: String) -> JournalingStyle {
        switch answerId {
        case "quick_notes": return .quickNotes
        case "detailed_stories": return .detailedStories
        case "visual_sketches": return .visualSketches
        case "mixed_media": return .mixedMedia
        default: return .quickNotes
        }
    }

    private func mapToEmotionalExpression(_ answerId: String) -> EmotionalExpression {
        switch answerId {
        case "writing_freely": return .writingFreely
        case "structured_prompts": return .structuredPrompts
        case "mood_tracking": return .moodTracking
        case "creative_exploration": return .creativeExploration
        default: return .writingFreely
        }
    }

    private func mapToVisualPreference(_ answerId: String) -> VisualPreference {
        switch answerId {
        case "abstract_dreamy": return .abstractDreamy
        case "realistic_grounded": return .realisticGrounded
        case "minimalist_clean": return .minimalistClean
        case "vibrant_expressive": return .vibrantExpressive
        default: return .abstractDreamy
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("OnboardingCompleted")
    static let restartOnboarding = Notification.Name("RestartOnboarding")
}
