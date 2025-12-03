//
//  PersonaProfile.swift
//  InkFiction
//
//  Convenience extensions for PersonaProfileModel
//  Note: PersonaProfileModel and PersonaAttributes are defined in SwiftDataModels.swift
//

import Foundation
import SwiftUI

// MARK: - Persona Profile Helper Extensions

extension PersonaProfileModel {
    /// Get the active avatar's UIImage
    var activeAvatarImage: UIImage? {
        guard let avatarId = activeAvatarId,
              let avatar = avatars?.first(where: { $0.id == avatarId }),
              let imageData = avatar.imageData else {
            return nil
        }
        return UIImage(data: imageData)
    }

    /// Check if persona has any generated avatars
    var hasAvatars: Bool {
        !(avatars?.isEmpty ?? true)
    }

    /// Get available avatar styles that have been generated
    var availableStyles: [AvatarStyle] {
        (avatars ?? []).map { $0.style }
    }

    /// Check if a specific style has been generated
    func hasStyle(_ style: AvatarStyle) -> Bool {
        avatars?.contains { $0.style == style } ?? false
    }

    /// Get avatar for a specific style
    func avatar(for style: AvatarStyle) -> PersonaAvatarModel? {
        avatars?.first { $0.style == style }
    }
}
