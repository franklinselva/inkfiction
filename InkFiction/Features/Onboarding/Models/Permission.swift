//
//  Permission.swift
//  InkFiction
//
//  Permissions requested during onboarding
//

import Foundation
import UIKit

// MARK: - Permission

/// Permissions that can be requested during onboarding
enum Permission: String, CaseIterable, Codable, Hashable {
    case notifications
    case photoLibrary
    case biometric

    var title: String {
        switch self {
        case .notifications:
            return "Daily Reminders"
        case .photoLibrary:
            return "Photo Library"
        case .biometric:
            return "Face ID / Touch ID"
        }
    }

    var description: String {
        switch self {
        case .notifications:
            return "Get gentle reminders to journal and weekly summaries"
        case .photoLibrary:
            return "Create your avatar, save AI art, and add photos to entries"
        case .biometric:
            return "Keep your journal private with biometric security"
        }
    }

    var systemImage: String {
        switch self {
        case .notifications:
            return "bell.badge"
        case .photoLibrary:
            return "photo.on.rectangle"
        case .biometric:
            return UIDevice.current.userInterfaceIdiom == .pad ? "touchid" : "faceid"
        }
    }

    var filledSystemImage: String {
        switch self {
        case .notifications:
            return "bell.badge.fill"
        case .photoLibrary:
            return "photo.fill.on.rectangle.fill"
        case .biometric:
            return UIDevice.current.userInterfaceIdiom == .pad ? "touchid" : "faceid"
        }
    }

    var benefitsList: [String] {
        switch self {
        case .notifications:
            return [
                "Daily journal reminders",
                "Weekly reflection summaries",
                "Achievement celebrations"
            ]
        case .photoLibrary:
            return [
                "Create personalized avatar",
                "Save AI-generated visuals",
                "Attach photos to entries"
            ]
        case .biometric:
            return [
                "Private journal access",
                "Quick unlock",
                "Enhanced security"
            ]
        }
    }
}
