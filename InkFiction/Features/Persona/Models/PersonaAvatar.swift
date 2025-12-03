//
//  PersonaAvatar.swift
//  InkFiction
//
//  Convenience struct for persona avatar (uses PersonaAvatarModel from SwiftData)
//  Note: AvatarStyle is defined in SwiftDataModels.swift
//

import Foundation
import SwiftUI

// MARK: - Persona Avatar Helper Extensions

extension PersonaAvatarModel {
    /// Get UIImage from stored data
    var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
}
