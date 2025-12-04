//
//  PersonaCreationViewModel.swift
//  InkFiction
//
//  ViewModel for persona creation flow
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class PersonaCreationViewModel {

    // MARK: - Properties

    private let repository = PersonaRepository.shared

    /// Whether creation is in progress
    var isCreating: Bool = false

    /// Error state
    var error: Error?

    /// Progress (0-1)
    var creationProgress: Double = 0

    /// Show upgrade sheet for tier-locked features
    var showUpgradeSheet: Bool = false

    // MARK: - Validation

    enum ValidationError: LocalizedError {
        case nameTooShort
        case nameTooLong
        case noImageSelected
        case noStylesSelected
        case quotaExceeded

        var errorDescription: String? {
            switch self {
            case .nameTooShort:
                return "Name must be at least 2 characters"
            case .nameTooLong:
                return "Name must be 50 characters or less"
            case .noImageSelected:
                return "Please select a photo"
            case .noStylesSelected:
                return "Please select at least one style"
            case .quotaExceeded:
                return "You've reached your persona style limit"
            }
        }
    }

    // MARK: - Initialization

    init() {
        Log.debug("PersonaCreationViewModel initialized", category: .persona)
    }

    // MARK: - Validation Methods

    func validateName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2 && trimmed.count <= 50
    }

    // MARK: - Save Persona

    /// Save persona with photo and generated avatars
    func savePersona(
        name: String,
        photo: UIImage,
        generatedAvatars: [AvatarStyle: UIImage]
    ) async {
        isCreating = true
        creationProgress = 0

        defer {
            isCreating = false
        }

        // Validate
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateName(trimmedName) else {
            error = ValidationError.nameTooShort
            Log.warning("Persona name validation failed: \(name)", category: .persona)
            return
        }

        guard !generatedAvatars.isEmpty else {
            error = ValidationError.noStylesSelected
            Log.warning("No avatar styles generated", category: .persona)
            return
        }

        do {
            // Check if persona already exists
            if repository.currentPersona != nil {
                // Update existing persona with new avatars
                Log.info("Updating existing persona with new styles", category: .persona)

                var progress = 0.0
                let progressStep = 1.0 / Double(generatedAvatars.count)

                for (style, image) in generatedAvatars {
                    // Check if style already exists - if so, remove it first
                    if let existingAvatar = repository.currentPersona?.avatar(for: style) {
                        try await repository.removeAvatar(existingAvatar)
                        Log.debug("Removed existing avatar for style: \(style.rawValue)", category: .persona)
                    }

                    // Add new avatar
                    guard let imageData = image.jpegData(compressionQuality: 0.85) else {
                        Log.warning("Failed to convert image to data for style: \(style.rawValue)", category: .persona)
                        continue
                    }

                    _ = try await repository.addAvatar(style: style, imageData: imageData)
                    Log.debug("Added avatar for style: \(style.rawValue)", category: .persona)

                    progress += progressStep
                    creationProgress = min(progress, 1.0)
                }

                // Update name if changed
                _ = try await repository.updatePersona(name: trimmedName)

            } else {
                // Create new persona
                Log.info("Creating new persona: \(trimmedName)", category: .persona)

                _ = try await repository.createPersona(name: trimmedName)
                creationProgress = 0.2

                var progress = 0.2
                let progressStep = 0.8 / Double(generatedAvatars.count)

                for (style, image) in generatedAvatars {
                    guard let imageData = image.jpegData(compressionQuality: 0.85) else {
                        Log.warning("Failed to convert image to data for style: \(style.rawValue)", category: .persona)
                        continue
                    }

                    _ = try await repository.addAvatar(style: style, imageData: imageData)
                    Log.debug("Added avatar for style: \(style.rawValue)", category: .persona)

                    progress += progressStep
                    creationProgress = min(progress, 1.0)
                }
            }

            creationProgress = 1.0
            Log.info("Persona saved successfully", category: .persona)

            // Post notification for any observers
            NotificationCenter.default.post(
                name: .personaUpdated,
                object: nil,
                userInfo: ["personaId": repository.currentPersona?.id.uuidString ?? ""]
            )

        } catch {
            self.error = error
            Log.error("Failed to save persona", error: error, category: .persona)
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let personaUpdated = Notification.Name("personaUpdated")
    static let personaCreated = Notification.Name("personaCreated")
    static let personaDeleted = Notification.Name("personaDeleted")
}
