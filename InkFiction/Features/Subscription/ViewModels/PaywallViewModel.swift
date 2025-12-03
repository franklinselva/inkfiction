//
//  PaywallViewModel.swift
//  InkFiction
//
//  View model for paywall and subscription management with StoreKit 2
//

import Combine
import Foundation
import StoreKit
import SwiftUI

// MARK: - Paywall ViewModel

@MainActor
final class PaywallViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var purchaseSuccessful = false
    @Published var isProcessingPurchase = false
    @Published var isProcessingRestore = false
    @Published var errorMessage: String?
    @Published var products: [Product] = []
    @Published var isLoadingProducts = false

    // MARK: - Private Properties

    private let storeKitManager = StoreKitManager.shared

    // MARK: - Initialization

    init() {
        Task {
            await loadProducts()
        }
    }

    // MARK: - Product Loading

    func loadProducts() async {
        isLoadingProducts = true

        do {
            products = try await storeKitManager.loadProducts()
        } catch {
            Log.error("Failed to load products", error: error, category: .subscription)
        }

        isLoadingProducts = false
    }

    // MARK: - Purchase with Free Trial

    func purchaseIntroductoryTrial() async {
        // Purchase Enhanced monthly which has free 7-day trial as intro offer
        await purchaseSubscription(tier: .enhanced, period: .monthly)
    }

    // MARK: - Purchase Subscription

    func purchaseSubscription(
        tier: SubscriptionTier,
        period: SubscriptionPricing.BillingPeriod
    ) async {
        Log.info(
            "Starting purchase: \(tier.displayName) - \(period.displayName)",
            category: .subscription)

        isProcessingPurchase = true
        errorMessage = nil
        purchaseSuccessful = false

        do {
            guard let product = try await storeKitManager.product(for: tier, period: period) else {
                errorMessage = "Subscription not available"
                isProcessingPurchase = false
                return
            }

            Log.info("Purchasing product: \(product.id)", category: .subscription)

            let transaction = try await storeKitManager.purchase(product)

            if transaction != nil {
                Log.info("Purchase transaction completed", category: .subscription)

                // Refresh subscription status
                Log.info("Refreshing subscription state...", category: .subscription)
                await storeKitManager.updateSubscriptionStatus()

                let newTier = storeKitManager.subscriptionTier.displayName
                Log.info("Subscription state refreshed - New tier: \(newTier)", category: .subscription)

                purchaseSuccessful = true
            } else {
                Log.info("Purchase cancelled or pending", category: .subscription)
            }

        } catch {
            handlePurchaseError(error)
        }

        isProcessingPurchase = false
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        Log.info("Starting restore purchases flow", category: .subscription)

        isProcessingRestore = true
        errorMessage = nil
        purchaseSuccessful = false

        // Store previous tier to detect changes
        let previousTier = storeKitManager.subscriptionTier

        do {
            // Attempt to restore purchases from StoreKit
            Log.info("Requesting restore from StoreKit...", category: .subscription)
            try await storeKitManager.restorePurchases()

            // Check if any subscription was restored
            let currentTier = storeKitManager.subscriptionTier

            if currentTier != .free {
                purchaseSuccessful = true

                if currentTier != previousTier {
                    Log.info(
                        "Subscription restored and updated: \(previousTier.displayName) → \(currentTier.displayName)",
                        category: .subscription)
                } else {
                    Log.info(
                        "Subscription confirmed: \(currentTier.displayName)",
                        category: .subscription)
                }
            } else {
                errorMessage =
                    "No active subscription found for this Apple ID. Make sure you're signed in with the same Apple ID used for the original purchase."
                Log.info("No active subscription found during restore", category: .subscription)
            }

        } catch {
            handleRestoreError(error)
        }

        isProcessingRestore = false
        Log.info("Restore flow completed", category: .subscription)
    }

    // MARK: - Error Handling

    private func handlePurchaseError(_ error: Error) {
        let nsError = error as NSError

        // Check for network errors
        if nsError.domain == NSURLErrorDomain {
            errorMessage = "Network error. Please check your internet connection and try again."
        } else if nsError.domain == "SKErrorDomain" {
            // StoreKit specific errors
            switch nsError.code {
            case 2:  // SKError.paymentCancelled
                Log.info("User cancelled purchase", category: .subscription)
                // Don't show error for user cancellation
            default:
                errorMessage = "Unable to complete purchase. Please try again."
            }
        } else {
            errorMessage =
                "Failed to complete purchase. Please try again or contact support if the issue persists."
        }

        Log.error("Purchase failed", error: error, category: .subscription)
        Log.error("Error domain: \(nsError.domain), code: \(nsError.code)", category: .subscription)

        if let localizedDescription = (error as? LocalizedError)?.errorDescription {
            Log.error("Description: \(localizedDescription)", category: .subscription)
        }
    }

    private func handleRestoreError(_ error: Error) {
        let nsError = error as NSError

        if nsError.domain == NSURLErrorDomain {
            errorMessage =
                "Unable to connect to the App Store. Please check your internet connection and try again."
        } else {
            errorMessage =
                "Failed to restore purchases. Please try again later or contact support if the issue persists."
        }

        Log.error("Restore failed", error: error, category: .subscription)
        Log.error("Error domain: \(nsError.domain), code: \(nsError.code)", category: .subscription)
    }

    // MARK: - Reset State

    func resetState() {
        purchaseSuccessful = false
        errorMessage = nil
    }

    // MARK: - Helpers

    var currentTier: SubscriptionTier {
        storeKitManager.subscriptionTier
    }

    var isEligibleForTrial: Bool {
        // TODO: Check with StoreKit if user is eligible for introductory offer
        // For now, return true for free tier users
        currentTier == .free
    }
}
