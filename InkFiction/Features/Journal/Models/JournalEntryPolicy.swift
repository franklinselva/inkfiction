//
//  JournalEntryPolicy.swift
//  InkFiction
//
//  Journal-specific subscription policy helpers
//  Uses SubscriptionPolicy as the single source of truth
//

import Foundation
import SwiftUI

struct JournalEntryPolicy {

    // MARK: - UI Behavior

    static func canShowEnhancementUI(for tier: SubscriptionTier) -> Bool {
        return tier.limits.hasAIReflections
    }

    static func canShowAIImageButton(for tier: SubscriptionTier) -> Bool {
        return tier.limits.dailyAIImageGenerations > 0
    }

    // MARK: - Enhancement Validation

    static func validateEnhancement(
        for tier: SubscriptionTier,
        content: String
    ) -> ValidationResult {
        let limits = tier.limits

        guard limits.hasAIReflections else {
            return ValidationResult(
                allowed: false,
                action: .showPaywall,
                reason: "AI reflections require Enhanced or Premium"
            )
        }

        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ValidationResult(
                allowed: false,
                action: .none,
                reason: "Please enter some content first"
            )
        }

        return ValidationResult(allowed: true, action: .none, reason: nil)
    }

    // MARK: - AI Image Generation Validation

    static func validateAIImageGeneration(
        for tier: SubscriptionTier,
        currentUsage: Int
    ) -> ValidationResult {
        let limits = tier.limits

        // Check if tier has AI image access
        guard limits.dailyAIImageGenerations > 0 else {
            return ValidationResult(
                allowed: false,
                action: .showPaywall,
                reason: "AI image generation requires Enhanced or Premium"
            )
        }

        // Check daily limit
        if !limits.canGenerateAIImage(currentUsage: currentUsage) {
            let action: UpgradeAction = limits.hasUnlimitedAIImages ? .none : .showPaywall
            return ValidationResult(
                allowed: false,
                action: action,
                reason: "Daily journal image limit reached"
            )
        }

        return ValidationResult(allowed: true, action: .none, reason: nil)
    }

    // MARK: - Usage Tracking

    static func shouldTrackAIUsage(for tier: SubscriptionTier) -> Bool {
        let limits = tier.limits

        // Track usage for tiers with limited (not unlimited) AI generations
        return !limits.hasUnlimitedAIImages && limits.dailyAIImageGenerations > 0
    }

    // MARK: - Supporting Types

    struct ValidationResult {
        let allowed: Bool
        let action: UpgradeAction
        let reason: String?
    }

    enum UpgradeAction {
        case none           // No upgrade needed or not applicable
        case showPaywall    // Show paywall for upgrade
    }
}
