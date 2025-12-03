//
//  AccountViewModel.swift
//  InkFiction
//
//  ViewModel for account settings and preferences management
//

import Foundation
import SwiftUI
import Combine

@MainActor
@Observable
final class AccountViewModel {

    // MARK: - Properties

    var journalingStyle: JournalingStyle = .quickNotes
    var emotionalExpression: EmotionalExpression = .writingFreely
    var visualPreference: VisualPreference = .abstractDreamy
    var selectedCompanion: AICompanion = .realist

    var isLoading: Bool = false
    var hasChanges: Bool = false
    var showingSaveSuccess: Bool = false
    var errorMessage: String?
    var showingError: Bool = false

    var showingCompanionPicker: Bool = false

    // Original values for change tracking
    private var originalJournalingStyle: JournalingStyle = .quickNotes
    private var originalEmotionalExpression: EmotionalExpression = .writingFreely
    private var originalVisualPreference: VisualPreference = .abstractDreamy
    private var originalCompanion: AICompanion = .realist

    // MARK: - Computed Properties

    var journalingStyleCompactName: String {
        switch journalingStyle {
        case .quickNotes: return "Quick"
        case .detailedStories: return "Detailed"
        case .visualSketches: return "Visual"
        case .mixedMedia: return "Mixed"
        }
    }

    var emotionalExpressionCompactName: String {
        switch emotionalExpression {
        case .writingFreely: return "Free Flow"
        case .structuredPrompts: return "Guided"
        case .moodTracking: return "Tracking"
        case .creativeExploration: return "Creative"
        }
    }

    var visualPreferenceCompactName: String {
        switch visualPreference {
        case .abstractDreamy: return "Abstract"
        case .realisticGrounded: return "Realistic"
        case .minimalistClean: return "Minimal"
        case .vibrantExpressive: return "Vibrant"
        }
    }

    // MARK: - Initialization

    init() {
        loadUserData()
    }

    // MARK: - Public Methods

    func loadUserData() {
        isLoading = true
        defer { isLoading = false }

        // Load from UserDefaults (saved onboarding data)
        if let jsonString = UserDefaults.standard.string(forKey: "onboardingData"),
           let savedData = SavedOnboardingData.fromJSONString(jsonString) {

            // Load companion
            selectedCompanion = savedData.selectedCompanion
            originalCompanion = savedData.selectedCompanion

            // Load preferences from quiz answers
            for answer in savedData.quizAnswers {
                switch answer.questionId {
                case "q1":
                    if let style = mapToJournalingStyle(answer.answerId) {
                        journalingStyle = style
                        originalJournalingStyle = style
                    }
                case "q2":
                    if let expression = mapToEmotionalExpression(answer.answerId) {
                        emotionalExpression = expression
                        originalEmotionalExpression = expression
                    }
                case "q3":
                    if let preference = mapToVisualPreference(answer.answerId) {
                        visualPreference = preference
                        originalVisualPreference = preference
                    }
                default:
                    break
                }
            }

            Log.debug("Loaded user preferences from onboarding data", category: .settings)
        } else {
            // Load companion ID separately if onboarding data not available
            if let companionId = UserDefaults.standard.string(forKey: "selectedCompanionId") {
                selectedCompanion = AICompanion.all.first { $0.id == companionId } ?? .realist
                originalCompanion = selectedCompanion
            }

            Log.debug("No onboarding data found, using defaults", category: .settings)
        }

        hasChanges = false
    }

    func updateJournalingStyle(_ style: JournalingStyle) {
        journalingStyle = style
        checkForChanges()
    }

    func updateEmotionalExpression(_ expression: EmotionalExpression) {
        emotionalExpression = expression
        checkForChanges()
    }

    func updateVisualPreference(_ preference: VisualPreference) {
        visualPreference = preference
        checkForChanges()
    }

    func updateCompanion(_ companion: AICompanion) {
        selectedCompanion = companion
        showingCompanionPicker = false
        checkForChanges()
    }

    func saveChanges() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Update local storage
            updateLocalStorage()

            // Update original values
            originalJournalingStyle = journalingStyle
            originalEmotionalExpression = emotionalExpression
            originalVisualPreference = visualPreference
            originalCompanion = selectedCompanion

            hasChanges = false

            // Show success
            showingSaveSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showingSaveSuccess = false
            }

            Log.info("Preferences saved successfully", category: .settings)
        }
    }

    // MARK: - Private Methods

    private func checkForChanges() {
        hasChanges = journalingStyle != originalJournalingStyle ||
                     emotionalExpression != originalEmotionalExpression ||
                     visualPreference != originalVisualPreference ||
                     selectedCompanion.id != originalCompanion.id
    }

    private func updateLocalStorage() {
        // Build updated quiz answers
        let quizAnswers = [
            QuizAnswer(questionId: "q1", answerId: journalingStyle.rawValue, answerText: journalingStyle.displayName),
            QuizAnswer(questionId: "q2", answerId: emotionalExpression.rawValue, answerText: emotionalExpression.displayName),
            QuizAnswer(questionId: "q3", answerId: visualPreference.rawValue, answerText: visualPreference.displayName)
        ]

        // Load existing data or create new
        let existingData: SavedOnboardingData?
        if let jsonString = UserDefaults.standard.string(forKey: "onboardingData") {
            existingData = SavedOnboardingData.fromJSONString(jsonString)
        } else {
            existingData = nil
        }

        // Create updated data
        let updatedData = SavedOnboardingData(
            completedAt: existingData?.completedAt ?? Date(),
            quizAnswers: quizAnswers,
            selectedCompanion: selectedCompanion,
            permissionsGranted: existingData?.permissionsGranted ?? [],
            wasSkipped: existingData?.wasSkipped ?? false,
            skippedPermissions: existingData?.skippedPermissions ?? false,
            timeSpent: existingData?.timeSpent ?? 0,
            viewedAllCompanions: existingData?.viewedAllCompanions ?? false,
            changedAnswers: true
        )

        // Save to UserDefaults
        if let jsonString = updatedData.toJSONString() {
            UserDefaults.standard.set(jsonString, forKey: "onboardingData")
        }

        // Update companion ID separately
        UserDefaults.standard.set(selectedCompanion.id, forKey: "selectedCompanionId")
    }

    private func mapToJournalingStyle(_ answerId: String) -> JournalingStyle? {
        JournalingStyle(rawValue: answerId)
    }

    private func mapToEmotionalExpression(_ answerId: String) -> EmotionalExpression? {
        EmotionalExpression(rawValue: answerId)
    }

    private func mapToVisualPreference(_ answerId: String) -> VisualPreference? {
        VisualPreference(rawValue: answerId)
    }
}
