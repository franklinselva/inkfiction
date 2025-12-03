//
//  PersonaViewModel.swift
//  InkFiction
//
//  ViewModel for persona management
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class PersonaViewModel {

    // MARK: - Properties

    private let repository = PersonaRepository.shared

    /// Current persona profile
    var currentPersona: PersonaProfileModel? {
        repository.currentPersona
    }

    /// Whether a persona exists
    var hasPersona: Bool {
        repository.hasPersona
    }

    /// Loading state
    var isLoading: Bool = false

    /// Error message
    var errorMessage: String?

    /// Form fields for creation/edit
    var nameField: String = ""
    var bioField: String = ""
    var selectedGender: PersonaAttributes.Gender = .neutral
    var selectedAgeRange: PersonaAttributes.AgeRange = .adult
    var selectedHairStyle: PersonaAttributes.HairStyle = .medium
    var selectedHairColor: PersonaAttributes.HairColor = .brown
    var selectedClothingStyle: PersonaAttributes.ClothingStyle = .casual

    // MARK: - Initialization

    init() {
        Log.debug("PersonaViewModel initialized", category: .persona)
    }

    // MARK: - Computed Properties

    /// Get the active avatar image
    var activeAvatarImage: UIImage? {
        currentPersona?.activeAvatarImage
    }

    /// Get all available styles
    var availableStyles: [AvatarStyle] {
        repository.availableStyles
    }

    /// Check if form is valid
    var isFormValid: Bool {
        !nameField.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    /// Load persona
    func loadPersona() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.loadPersona()

            // Populate form fields if persona exists
            if let persona = currentPersona {
                nameField = persona.name
                bioField = persona.bio ?? ""
                if let attrs = persona.attributes {
                    selectedGender = attrs.gender
                    selectedAgeRange = attrs.ageRange
                    selectedHairStyle = attrs.hairStyle
                    selectedHairColor = attrs.hairColor
                    selectedClothingStyle = attrs.clothingStyle
                }
            }

            Log.info("Persona loaded in ViewModel", category: .persona)
        } catch {
            errorMessage = error.localizedDescription
            Log.error("Failed to load persona in ViewModel", error: error, category: .persona)
        }
    }

    /// Create new persona
    func createPersona() async -> Bool {
        guard isFormValid else {
            errorMessage = "Please enter a name"
            return false
        }

        isLoading = true
        defer { isLoading = false }

        let attributes = PersonaAttributes(
            gender: selectedGender,
            ageRange: selectedAgeRange,
            hairStyle: selectedHairStyle,
            hairColor: selectedHairColor,
            clothingStyle: selectedClothingStyle
        )

        do {
            _ = try await repository.createPersona(
                name: nameField.trimmingCharacters(in: .whitespacesAndNewlines),
                bio: bioField.isEmpty ? nil : bioField,
                attributes: attributes
            )

            Log.info("Persona created in ViewModel", category: .persona)
            return true
        } catch {
            errorMessage = error.localizedDescription
            Log.error("Failed to create persona in ViewModel", error: error, category: .persona)
            return false
        }
    }

    /// Update persona
    func updatePersona() async -> Bool {
        guard isFormValid else {
            errorMessage = "Please enter a name"
            return false
        }

        isLoading = true
        defer { isLoading = false }

        let attributes = PersonaAttributes(
            gender: selectedGender,
            ageRange: selectedAgeRange,
            hairStyle: selectedHairStyle,
            hairColor: selectedHairColor,
            clothingStyle: selectedClothingStyle
        )

        do {
            _ = try await repository.updatePersona(
                name: nameField.trimmingCharacters(in: .whitespacesAndNewlines),
                bio: bioField.isEmpty ? nil : bioField,
                attributes: attributes
            )

            Log.info("Persona updated in ViewModel", category: .persona)
            return true
        } catch {
            errorMessage = error.localizedDescription
            Log.error("Failed to update persona in ViewModel", error: error, category: .persona)
            return false
        }
    }

    /// Delete persona
    func deletePersona() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.deletePersona()
            resetForm()

            Log.info("Persona deleted in ViewModel", category: .persona)
            return true
        } catch {
            errorMessage = error.localizedDescription
            Log.error("Failed to delete persona in ViewModel", error: error, category: .persona)
            return false
        }
    }

    /// Set active avatar
    func setActiveAvatar(_ avatar: PersonaAvatarModel) async {
        do {
            try await repository.setActiveAvatar(avatar)
            Log.info("Active avatar set in ViewModel", category: .persona)
        } catch {
            errorMessage = error.localizedDescription
            Log.error("Failed to set active avatar in ViewModel", error: error, category: .persona)
        }
    }

    /// Add avatar with image data
    func addAvatar(style: AvatarStyle, imageData: Data) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await repository.addAvatar(style: style, imageData: imageData)
            Log.info("Avatar added in ViewModel", category: .persona)
            return true
        } catch {
            errorMessage = error.localizedDescription
            Log.error("Failed to add avatar in ViewModel", error: error, category: .persona)
            return false
        }
    }

    /// Remove avatar
    func removeAvatar(_ avatar: PersonaAvatarModel) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.removeAvatar(avatar)
            Log.info("Avatar removed in ViewModel", category: .persona)
            return true
        } catch {
            errorMessage = error.localizedDescription
            Log.error("Failed to remove avatar in ViewModel", error: error, category: .persona)
            return false
        }
    }

    /// Clear error
    func clearError() {
        errorMessage = nil
    }

    /// Reset form fields
    func resetForm() {
        nameField = ""
        bioField = ""
        selectedGender = PersonaAttributes.Gender.neutral
        selectedAgeRange = PersonaAttributes.AgeRange.adult
        selectedHairStyle = PersonaAttributes.HairStyle.medium
        selectedHairColor = PersonaAttributes.HairColor.brown
        selectedClothingStyle = PersonaAttributes.ClothingStyle.casual
    }
}
