//
//  AccountViewModel.swift
//  InkFiction
//
//  ViewModel for account settings and preferences management
//

import Foundation
import SwiftUI

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

    // Repository
    private let settingsRepository = SettingsRepository.shared

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

        // Load from SettingsRepository (synced with iCloud)
        journalingStyle = settingsRepository.journalingStyle
        originalJournalingStyle = journalingStyle

        emotionalExpression = settingsRepository.emotionalExpression
        originalEmotionalExpression = emotionalExpression

        visualPreference = settingsRepository.visualPreference
        originalVisualPreference = visualPreference

        selectedCompanion = settingsRepository.selectedCompanion
        originalCompanion = selectedCompanion

        Log.debug("Loaded user preferences from SettingsRepository", category: .settings)

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
            // Save to SettingsRepository (syncs to iCloud)
            try await settingsRepository.updateJournalPreferences(
                journalingStyle: journalingStyle,
                emotionalExpression: emotionalExpression,
                visualPreference: visualPreference,
                companion: selectedCompanion
            )

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

            Log.info("Preferences saved to iCloud successfully", category: .settings)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            Log.error("Failed to save preferences", error: error, category: .settings)
        }
    }

    // MARK: - Private Methods

    private func checkForChanges() {
        hasChanges = journalingStyle != originalJournalingStyle ||
                     emotionalExpression != originalEmotionalExpression ||
                     visualPreference != originalVisualPreference ||
                     selectedCompanion.id != originalCompanion.id
    }
}
