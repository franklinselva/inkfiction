//
//  SubscriptionTier.swift
//  InkFiction
//
//  Subscription tier definitions for the app
//

import SwiftUI

// MARK: - Subscription Tier

/// Represents the user's subscription tier
enum SubscriptionTier: String, CaseIterable, Codable {
    case free
    case enhanced
    case premium

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .free: "Free"
        case .enhanced: "Enhanced"
        case .premium: "Premium"
        }
    }

    var badgeIcon: String {
        switch self {
        case .free: "person.circle"
        case .enhanced: "star.circle.fill"
        case .premium: "crown.fill"
        }
    }

    var gradientColors: [String] {
        switch self {
        case .free: ["#6B7280", "#9CA3AF"]
        case .enhanced: ["#F59E0B", "#F97316"]
        case .premium: ["#8B5CF6", "#EC4899"]
        }
    }

    // MARK: - Priority (for upgrade comparisons)

    var priority: Int {
        switch self {
        case .free: 0
        case .enhanced: 1
        case .premium: 2
        }
    }

    // MARK: - Convenience Computed Properties

    var limits: SubscriptionPolicy.TierLimits {
        SubscriptionPolicy.limits(for: self)
    }

    var benefits: [String] {
        limits.features
    }

    var shortBenefits: [String] {
        let limits = self.limits

        // Free tier special case
        if self == .free {
            return ["Basic journaling", "iCloud sync"]
        }

        var benefits: [String] = []

        // AI Images
        if limits.dailyAIImageGenerations > 0 {
            if limits.dailyAIImageGenerations == -1 {
                benefits.append("Unlimited AI")
            } else {
                benefits.append("\(limits.dailyAIImageGenerations) AI/day")
            }
        }

        // Persona Styles
        if limits.maxPersonaStyles > 0 {
            if limits.maxPersonaStyles == -1 {
                benefits.append("Unlimited styles")
            } else {
                benefits.append("\(limits.maxPersonaStyles) styles")
            }
        }

        // AI Reflections
        if limits.hasAIReflections {
            benefits.append("AI Reflections")
        }

        return benefits
    }

    // MARK: - Color Helpers

    var uiGradientColors: [Color] {
        gradientColors.compactMap { Color(hex: $0) }
    }

    var primaryGradientColor: Color {
        uiGradientColors.first ?? .blue
    }

    func gradient(
        opacity: Double = 1.0,
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) -> LinearGradient {
        LinearGradient(
            colors: uiGradientColors.map { $0.opacity(opacity) },
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}
