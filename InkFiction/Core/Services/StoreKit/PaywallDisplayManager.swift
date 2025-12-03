//
//  PaywallDisplayManager.swift
//  InkFiction
//
//  Manages paywall display timing with exponential backoff
//

import Combine
import Foundation
import SwiftUI

// MARK: - Paywall Display Manager

@MainActor
@Observable
final class PaywallDisplayManager {
    static let shared = PaywallDisplayManager()

    // MARK: - Properties

    var shouldShowPaywall: Bool = false
    var paywallContext: PaywallContext = .firstLaunch

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let firstLaunchDate = "paywall_first_launch_date"
        static let lastShownDate = "paywall_last_shown_date"
        static let dismissCount = "paywall_dismiss_count"
        static let lastMonthlyReset = "paywall_last_monthly_reset"
        static let hasSeenFirstLaunch = "paywall_has_seen_first_launch"
    }

    // MARK: - Paywall Context

    enum PaywallContext: String {
        case firstLaunch  // Show on first app launch
        case periodicReminder  // Show after exponential backoff
        case featureLimitHit  // User hit usage limit
        case manualOpen  // User opened from Settings

        var analyticsName: String { rawValue }
    }

    // MARK: - Initialization

    private init() {
        // Initialize first launch date if not set
        if UserDefaults.standard.object(forKey: Keys.firstLaunchDate) == nil {
            UserDefaults.standard.set(Date(), forKey: Keys.firstLaunchDate)
        }
    }

    // MARK: - Public Methods

    func checkShouldShowPaywall() {
        let currentTier = StoreKitManager.shared.subscriptionTier

        guard currentTier == .free else {
            shouldShowPaywall = false
            return
        }

        // Check monthly reset
        checkAndResetIfNeeded()

        // First launch check
        if !hasSeenFirstLaunchPaywall {
            paywallContext = .firstLaunch
            shouldShowPaywall = true
            Log.info("Showing first launch paywall", category: .subscription)
            return
        }

        // Periodic reminder check
        if shouldShowPeriodicReminder {
            paywallContext = .periodicReminder
            shouldShowPaywall = true
            Log.info(
                "Showing periodic reminder paywall (dismiss count: \(currentDismissCount))",
                category: .subscription)
            return
        }

        shouldShowPaywall = false
    }

    func showPaywall(context: PaywallContext) {
        paywallContext = context
        shouldShowPaywall = true

        // Track analytics
        logPaywallEvent(.shown(context: context, dismissCount: currentDismissCount))
    }

    func dismissPaywall() {
        shouldShowPaywall = false

        // Update last shown date
        UserDefaults.standard.set(Date(), forKey: Keys.lastShownDate)

        // Increment dismiss count (only for non-manual contexts)
        if paywallContext != .manualOpen {
            incrementDismissCount()
        }

        // Mark first launch as seen
        if paywallContext == .firstLaunch {
            UserDefaults.standard.set(true, forKey: Keys.hasSeenFirstLaunch)
        }

        // Track analytics
        logPaywallEvent(.dismissed(context: paywallContext))

        Log.info(
            "Paywall dismissed (context: \(paywallContext.analyticsName), new dismiss count: \(currentDismissCount))",
            category: .subscription)
    }

    func recordPurchase(tier: SubscriptionTier) {
        // Reset all tracking on successful purchase
        resetTracking()
        logPaywallEvent(.purchaseCompleted(tier: tier))
        Log.info("Purchase completed, paywall tracking reset", category: .subscription)
    }

    // MARK: - Developer Tools

    func resetForTesting() {
        resetTracking()
        UserDefaults.standard.set(false, forKey: Keys.hasSeenFirstLaunch)
        Log.debug("Paywall tracking reset for testing", category: .subscription)
    }

    func getDebugInfo() -> String {
        let dismissCount = currentDismissCount
        let lastShown =
            lastShownDate?.formatted(date: .abbreviated, time: .shortened) ?? "Never"
        let nextShow =
            calculateNextShowDate()?.formatted(date: .abbreviated, time: .shortened) ?? "N/A"
        let daysUntilShow = daysUntilNextShow

        return """
            Paywall Debug Info:
            - Has seen first launch: \(hasSeenFirstLaunchPaywall)
            - Dismiss count: \(dismissCount)
            - Last shown: \(lastShown)
            - Next show: \(nextShow)
            - Days until show: \(daysUntilShow)
            - Should show now: \(shouldShowPeriodicReminder)
            """
    }

    // MARK: - Private Properties

    private var hasSeenFirstLaunchPaywall: Bool {
        UserDefaults.standard.bool(forKey: Keys.hasSeenFirstLaunch)
    }

    private var currentDismissCount: Int {
        UserDefaults.standard.integer(forKey: Keys.dismissCount)
    }

    private var lastShownDate: Date? {
        UserDefaults.standard.object(forKey: Keys.lastShownDate) as? Date
    }

    private var lastMonthlyReset: Date? {
        UserDefaults.standard.object(forKey: Keys.lastMonthlyReset) as? Date
    }

    // MARK: - Timing Logic

    private var shouldShowPeriodicReminder: Bool {
        guard hasSeenFirstLaunchPaywall else { return false }
        guard let nextShowDate = calculateNextShowDate() else { return true }
        return Date() >= nextShowDate
    }

    private var daysUntilNextShow: Int {
        guard let nextShowDate = calculateNextShowDate() else { return 0 }
        let days =
            Calendar.current.dateComponents([.day], from: Date(), to: nextShowDate).day ?? 0
        return max(0, days)
    }

    private func calculateNextShowDate() -> Date? {
        guard let lastShown = lastShownDate else { return nil }

        let dismissCount = currentDismissCount

        // Exponential backoff: 2^dismissCount days
        // 0 dismissals = 1 day
        // 1 dismissal = 2 days
        // 2 dismissals = 4 days
        // 3 dismissals = 8 days
        // 4 dismissals = 16 days
        // 5+ dismissals = 30 days (cap)

        let daysToAdd = min(Int(pow(2.0, Double(dismissCount))), 30)

        return Calendar.current.date(byAdding: .day, value: daysToAdd, to: lastShown)
    }

    private func incrementDismissCount() {
        let newCount = currentDismissCount + 1
        UserDefaults.standard.set(newCount, forKey: Keys.dismissCount)
    }

    // MARK: - Monthly Reset

    private func checkAndResetIfNeeded() {
        let lastReset = lastMonthlyReset ?? Date()
        let daysSinceReset =
            Calendar.current.dateComponents([.day], from: lastReset, to: Date()).day ?? 0

        if daysSinceReset >= 30 {
            // Reset dismiss count
            UserDefaults.standard.set(0, forKey: Keys.dismissCount)
            UserDefaults.standard.set(Date(), forKey: Keys.lastMonthlyReset)
            Log.info("Monthly paywall reset triggered (30 days elapsed)", category: .subscription)
        }
    }

    private func resetTracking() {
        UserDefaults.standard.set(0, forKey: Keys.dismissCount)
        UserDefaults.standard.removeObject(forKey: Keys.lastShownDate)
        UserDefaults.standard.set(Date(), forKey: Keys.lastMonthlyReset)
    }

    // MARK: - Analytics

    enum PaywallEvent {
        case shown(context: PaywallContext, dismissCount: Int)
        case dismissed(context: PaywallContext)
        case ctaTapped(tier: SubscriptionTier)
        case featureCardTapped(feature: String)
        case pricingToggled(period: SubscriptionPricing.BillingPeriod)
        case purchaseStarted(tier: SubscriptionTier)
        case purchaseCompleted(tier: SubscriptionTier)
        case purchaseFailed(error: String)
    }

    func logPaywallEvent(_ event: PaywallEvent) {
        // TODO: Integrate with analytics platform (Firebase, Mixpanel, etc.)
        switch event {
        case .shown(let context, let dismissCount):
            Log.debug(
                "[Analytics] Paywall shown - context: \(context.analyticsName), dismissCount: \(dismissCount)",
                category: .subscription)
        case .dismissed(let context):
            Log.debug(
                "[Analytics] Paywall dismissed - context: \(context.analyticsName)",
                category: .subscription)
        case .ctaTapped(let tier):
            Log.debug(
                "[Analytics] CTA tapped - tier: \(tier.displayName)", category: .subscription)
        case .featureCardTapped(let feature):
            Log.debug(
                "[Analytics] Feature card tapped - feature: \(feature)", category: .subscription)
        case .pricingToggled(let period):
            Log.debug(
                "[Analytics] Pricing toggled - period: \(period.displayName)",
                category: .subscription)
        case .purchaseStarted(let tier):
            Log.debug(
                "[Analytics] Purchase started - tier: \(tier.displayName)", category: .subscription)
        case .purchaseCompleted(let tier):
            Log.debug(
                "[Analytics] Purchase completed - tier: \(tier.displayName)",
                category: .subscription)
        case .purchaseFailed(let error):
            Log.debug("[Analytics] Purchase failed - error: \(error)", category: .subscription)
        }
    }
}
