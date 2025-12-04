//
//  SubscriptionService.swift
//  InkFiction
//
//  High-level subscription service for entitlement checking and state management
//

import Combine
import Foundation
import SwiftUI

// MARK: - Subscription Service

@MainActor
@Observable
final class SubscriptionService {
    static let shared = SubscriptionService()

    // MARK: - Properties

    var currentTier: SubscriptionTier {
        StoreKitManager.shared.subscriptionTier
    }

    var subscriptionExpiresAt: Date? {
        StoreKitManager.shared.subscriptionExpiresAt
    }

    var billingPeriod: SubscriptionPricing.BillingPeriod {
        StoreKitManager.shared.currentBillingPeriod
    }

    var isSubscribed: Bool {
        currentTier != .free
    }

    var limits: SubscriptionPolicy.TierLimits {
        currentTier.limits
    }

    // MARK: - Paywall State

    var isShowingPaywall: Bool = false
    var paywallContext: SubscriptionPolicy.UpgradeContext = .generic

    // MARK: - Usage Tracking (Local)

    private(set) var dailyJournalImagesUsed: Int = 0
    private(set) var dailyJournalResetAt: Date = Date()
    private(set) var personaImagesUsedThisPeriod: Int = 0
    private(set) var personaUpdatePeriodStart: Date = Date()

    // MARK: - Initialization

    private init() {
        loadUsageFromDefaults()
        checkAndResetDailyUsageIfNeeded()
    }

    // MARK: - Entitlement Checks

    var isFreeTier: Bool { currentTier == .free }
    var isEnhancedTier: Bool { currentTier == .enhanced }
    var isPremiumTier: Bool { currentTier == .premium }

    var hasAIAccess: Bool { currentTier != .free }
    var hasPersonaAccess: Bool { currentTier != .free }

    // MARK: - AI Image Generation

    var dailyJournalImageLimit: Int {
        limits.dailyAIImageGenerations == -1 ? 999 : limits.dailyAIImageGenerations
    }

    var dailyPersonaAvatarLimit: Int {
        limits.maxPersonaStyles == -1 ? 999 : limits.maxPersonaStyles
    }

    var remainingJournalImages: Int {
        getRemainingJournalImages()
    }

    var remainingPersonaAvatars: Int {
        if limits.maxPersonaStyles == -1 { return 999 }
        return max(0, limits.maxPersonaStyles - personaImagesUsedThisPeriod)
    }

    func canGenerateJournalImage() -> Bool {
        checkAndResetDailyUsageIfNeeded()
        return limits.canGenerateAIImage(currentUsage: dailyJournalImagesUsed)
    }

    func canGeneratePersonaAvatar() -> Bool {
        if limits.maxPersonaStyles == -1 { return true }
        if limits.maxPersonaStyles == 0 { return false }
        return personaImagesUsedThisPeriod < limits.maxPersonaStyles
    }

    func recordJournalImageGeneration() {
        incrementJournalImageUsage()
    }

    func recordPersonaAvatarGeneration() {
        personaImagesUsedThisPeriod += 1
        saveUsageToDefaults()
        Log.info("Persona avatar usage: \(personaImagesUsedThisPeriod)/\(limits.maxPersonaStyles)", category: .subscription)
    }

    func validateJournalImageGeneration() -> (allowed: Bool, reason: SubscriptionPolicy.UpgradeContext?) {
        checkAndResetDailyUsageIfNeeded()

        if limits.dailyAIImageGenerations == 0 {
            return (false, .aiImageLimitReached)
        }

        if limits.dailyAIImageGenerations == -1 {
            return (true, nil)  // Unlimited
        }

        if dailyJournalImagesUsed >= limits.dailyAIImageGenerations {
            return (false, .aiImageLimitReached)
        }

        return (true, nil)
    }

    func incrementJournalImageUsage() {
        checkAndResetDailyUsageIfNeeded()
        dailyJournalImagesUsed += 1
        saveUsageToDefaults()
        Log.info("Journal image usage: \(dailyJournalImagesUsed)/\(limits.dailyAIImageGenerations)", category: .subscription)
    }

    func getRemainingJournalImages() -> Int {
        checkAndResetDailyUsageIfNeeded()
        return limits.remainingAIGenerations(currentUsage: dailyJournalImagesUsed)
    }

    func getJournalImageUsageText() -> String {
        checkAndResetDailyUsageIfNeeded()

        if limits.dailyAIImageGenerations == 0 {
            return "AI images not available"
        }

        if limits.dailyAIImageGenerations == -1 {
            return "Unlimited AI images"
        }

        let remaining = getRemainingJournalImages()
        return "\(remaining) of \(limits.dailyAIImageGenerations) images remaining today"
    }

    // MARK: - Persona Validation

    func canCreatePersona(currentStyleCount: Int) -> Bool {
        return limits.canAddMorePersonaStyles(currentStyleCount: currentStyleCount)
    }

    func validatePersonaCreation(currentStyleCount: Int) -> (allowed: Bool, reason: SubscriptionPolicy.UpgradeContext?) {
        if limits.maxPersonaStyles == 0 {
            return (false, .personaLimitReached)
        }

        if limits.maxPersonaStyles == -1 {
            return (true, nil)  // Unlimited
        }

        if currentStyleCount >= limits.maxPersonaStyles {
            return (false, .personaLimitReached)
        }

        return (true, nil)
    }

    func getPersonaUsageText(currentStyleCount: Int) -> String {
        if limits.maxPersonaStyles == 0 {
            return "Persona styles not available"
        }

        if limits.maxPersonaStyles == -1 {
            return "Unlimited persona styles"
        }

        let remaining = limits.remainingPersonaStyleSlots(currentStyleCount: currentStyleCount)
        return "\(remaining) of \(limits.maxPersonaStyles) styles remaining"
    }

    // MARK: - Paywall Methods

    func showPaywall(context: SubscriptionPolicy.UpgradeContext = .generic) {
        paywallContext = context
        isShowingPaywall = true
        Log.info("Showing paywall: \(context)", category: .subscription)
    }

    func dismissPaywall() {
        isShowingPaywall = false
        Log.info("Paywall dismissed", category: .subscription)
    }

    func getUpgradeMessage() -> String {
        SubscriptionPolicy.upgradeMessage(from: currentTier, context: paywallContext)
    }

    // MARK: - Subscription Refresh

    func refreshSubscription() async {
        Log.info("Refreshing subscription status...", category: .subscription)
        await StoreKitManager.shared.updateSubscriptionStatus()
    }

    func restorePurchases() async throws {
        Log.info("Restoring purchases...", category: .subscription)
        try await StoreKitManager.shared.restorePurchases()
    }

    // MARK: - Usage Reset Logic

    private func checkAndResetDailyUsageIfNeeded() {
        let calendar = Calendar.current
        let now = Date()

        // Check if we've passed midnight since last reset
        if !calendar.isDate(dailyJournalResetAt, inSameDayAs: now) {
            dailyJournalImagesUsed = 0
            dailyJournalResetAt = now
            saveUsageToDefaults()
            Log.info("Daily usage reset", category: .subscription)
        }
    }

    // MARK: - Persistence

    private enum Keys {
        static let dailyJournalImagesUsed = "subscription_daily_journal_images_used"
        static let dailyJournalResetAt = "subscription_daily_journal_reset_at"
        static let personaImagesUsedThisPeriod = "subscription_persona_images_used"
        static let personaUpdatePeriodStart = "subscription_persona_period_start"
    }

    private func loadUsageFromDefaults() {
        dailyJournalImagesUsed = UserDefaults.standard.integer(forKey: Keys.dailyJournalImagesUsed)
        dailyJournalResetAt = UserDefaults.standard.object(forKey: Keys.dailyJournalResetAt) as? Date ?? Date()
        personaImagesUsedThisPeriod = UserDefaults.standard.integer(forKey: Keys.personaImagesUsedThisPeriod)
        personaUpdatePeriodStart = UserDefaults.standard.object(forKey: Keys.personaUpdatePeriodStart) as? Date ?? Date()
    }

    private func saveUsageToDefaults() {
        UserDefaults.standard.set(dailyJournalImagesUsed, forKey: Keys.dailyJournalImagesUsed)
        UserDefaults.standard.set(dailyJournalResetAt, forKey: Keys.dailyJournalResetAt)
        UserDefaults.standard.set(personaImagesUsedThisPeriod, forKey: Keys.personaImagesUsedThisPeriod)
        UserDefaults.standard.set(personaUpdatePeriodStart, forKey: Keys.personaUpdatePeriodStart)
    }

    // MARK: - Debug Methods

    #if DEBUG
    func resetUsageForTesting() {
        dailyJournalImagesUsed = 0
        dailyJournalResetAt = Date()
        personaImagesUsedThisPeriod = 0
        personaUpdatePeriodStart = Date()
        saveUsageToDefaults()
        Log.debug("Usage reset for testing", category: .subscription)
    }

    func setUsageForTesting(journalImages: Int) {
        dailyJournalImagesUsed = journalImages
        saveUsageToDefaults()
        Log.debug("Set journal images usage to \(journalImages) for testing", category: .subscription)
    }
    #endif
}

// MARK: - Environment Key

private struct SubscriptionServiceKey: EnvironmentKey {
    static let defaultValue = SubscriptionService.shared
}

extension EnvironmentValues {
    var subscriptionService: SubscriptionService {
        get { self[SubscriptionServiceKey.self] }
        set { self[SubscriptionServiceKey.self] = newValue }
    }
}
