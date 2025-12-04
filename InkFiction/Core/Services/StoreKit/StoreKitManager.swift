//
//  StoreKitManager.swift
//  InkFiction
//
//  StoreKit 2 manager for in-app subscriptions
//

import Combine
import Foundation
import StoreKit

// MARK: - StoreKit Manager

@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    // MARK: - Published Properties

    @Published var purchasedProductIDs: Set<String> = []
    @Published var subscriptionTier: SubscriptionTier = .free
    @Published var subscriptionExpiresAt: Date?
    @Published var currentBillingPeriod: SubscriptionPricing.BillingPeriod = .monthly
    @Published var activeProductID: String?
    @Published var isInIntroductoryPeriod: Bool = false
    @Published var products: [Product] = []
    @Published var isLoading: Bool = false

    // MARK: - Private Properties

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization

    private init() {
        // First, load persisted state for immediate UI display
        loadPersistedSubscriptionState()

        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        // Verify subscription status against StoreKit (async)
        Task {
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    func loadProducts() async throws -> [Product] {
        Log.info("Loading StoreKit products...", category: .subscription)
        isLoading = true

        do {
            let products = try await Product.products(for: SubscriptionPricing.allProductIDs)
            let sortedProducts = products.sorted { $0.price < $1.price }

            self.products = sortedProducts
            isLoading = false

            Log.info("Loaded \(sortedProducts.count) products", category: .subscription)
            return sortedProducts
        } catch {
            isLoading = false
            Log.error("Failed to load products", error: error, category: .subscription)
            throw error
        }
    }

    func product(
        for tier: SubscriptionTier,
        period: SubscriptionPricing.BillingPeriod
    ) async throws -> Product? {
        let productID = SubscriptionPricing.productID(for: tier, period: period)
        let products = try await Product.products(for: [productID])
        return products.first
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Transaction? {
        Log.info("Purchasing product: \(product.id)", category: .subscription)

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            // Use the product user purchased for tier detection
            if let purchasedTier = SubscriptionPricing.tier(from: product.id) {
                let purchasedPeriod = SubscriptionPricing.billingPeriod(from: product.id)

                // Update local state
                subscriptionTier = purchasedTier
                subscriptionExpiresAt = transaction.expirationDate
                activeProductID = product.id
                currentBillingPeriod = purchasedPeriod
                purchasedProductIDs.insert(product.id)

                // Persist to UserDefaults
                persistSubscriptionState(
                    tier: purchasedTier,
                    expiresAt: transaction.expirationDate,
                    productID: product.id,
                    billingPeriod: purchasedPeriod
                )

                Log.info(
                    "Purchase successful: \(purchasedTier.displayName) (\(purchasedPeriod.displayName))",
                    category: .subscription
                )
            } else {
                await updateSubscriptionStatus()
            }

            await transaction.finish()
            return transaction

        case .userCancelled:
            Log.info("User cancelled purchase", category: .subscription)
            return nil

        case .pending:
            Log.info("Purchase pending (parental approval or other)", category: .subscription)
            return nil

        @unknown default:
            Log.warning("Unknown purchase result", category: .subscription)
            return nil
        }
    }

    // MARK: - Subscription Status

    func updateSubscriptionStatus() async {
        Log.info("Updating subscription status...", category: .subscription)

        var currentTier: SubscriptionTier = .free
        var expirationDate: Date?
        var detectedProductID: String?
        var detectedBillingPeriod: SubscriptionPricing.BillingPeriod = .monthly

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if let tier = SubscriptionPricing.tier(from: transaction.productID) {
                    if tier.priority > currentTier.priority {
                        currentTier = tier
                        expirationDate = transaction.expirationDate
                        detectedProductID = transaction.productID
                        detectedBillingPeriod = SubscriptionPricing.billingPeriod(
                            from: transaction.productID)
                    }
                }
                purchasedProductIDs.insert(transaction.productID)
            } catch {
                Log.error("Failed to verify transaction", error: error, category: .subscription)
            }
        }

        subscriptionTier = currentTier
        subscriptionExpiresAt = expirationDate
        activeProductID = detectedProductID
        currentBillingPeriod = detectedBillingPeriod

        // Persist to UserDefaults
        persistSubscriptionState(
            tier: currentTier,
            expiresAt: expirationDate,
            productID: detectedProductID,
            billingPeriod: detectedBillingPeriod
        )

        Log.info(
            "Subscription status updated: \(currentTier.displayName)",
            category: .subscription
        )
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        Log.info("Restoring purchases...", category: .subscription)

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            Log.info("Purchases restored successfully", category: .subscription)
        } catch {
            // Still try to update status even if sync fails
            await updateSubscriptionStatus()
            Log.error("Failed to restore purchases", error: error, category: .subscription)
            throw error
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            guard let self = self else { return }

            for await result in Transaction.updates {
                do {
                    let transaction = try await MainActor.run {
                        try self.checkVerified(result)
                    }

                    await MainActor.run {
                        if let tier = SubscriptionPricing.tier(from: transaction.productID) {
                            let period = SubscriptionPricing.billingPeriod(
                                from: transaction.productID)

                            self.subscriptionTier = tier
                            self.subscriptionExpiresAt = transaction.expirationDate
                            self.activeProductID = transaction.productID
                            self.currentBillingPeriod = period
                            self.purchasedProductIDs.insert(transaction.productID)

                            self.persistSubscriptionState(
                                tier: tier,
                                expiresAt: transaction.expirationDate,
                                productID: transaction.productID,
                                billingPeriod: period
                            )

                            Log.info(
                                "Transaction update: \(tier.displayName)",
                                category: .subscription
                            )
                        }
                    }

                    await transaction.finish()
                } catch {
                    Log.error(
                        "Transaction verification failed",
                        error: error,
                        category: .subscription
                    )
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Persistence

    private enum UserDefaultsKeys {
        static let subscriptionTier = "subscription_tier"
        static let subscriptionExpiresAt = "subscription_expires_at"
        static let activeProductID = "subscription_product_id"
        static let billingPeriod = "subscription_billing_period"
    }

    private func persistSubscriptionState(
        tier: SubscriptionTier,
        expiresAt: Date?,
        productID: String?,
        billingPeriod: SubscriptionPricing.BillingPeriod
    ) {
        UserDefaults.standard.set(tier.rawValue, forKey: UserDefaultsKeys.subscriptionTier)
        UserDefaults.standard.set(expiresAt, forKey: UserDefaultsKeys.subscriptionExpiresAt)
        UserDefaults.standard.set(productID, forKey: UserDefaultsKeys.activeProductID)
        UserDefaults.standard.set(billingPeriod.rawValue, forKey: UserDefaultsKeys.billingPeriod)
    }

    func loadPersistedSubscriptionState() {
        Log.info("Loading persisted subscription state...", category: .subscription)

        if let tierRaw = UserDefaults.standard.string(forKey: UserDefaultsKeys.subscriptionTier),
            let tier = SubscriptionTier(rawValue: tierRaw)
        {
            subscriptionTier = tier
            Log.info("Loaded persisted tier: \(tier.displayName)", category: .subscription)
        }

        subscriptionExpiresAt = UserDefaults.standard.object(
            forKey: UserDefaultsKeys.subscriptionExpiresAt) as? Date
        activeProductID = UserDefaults.standard.string(forKey: UserDefaultsKeys.activeProductID)

        if let periodRaw = UserDefaults.standard.string(forKey: UserDefaultsKeys.billingPeriod),
            let period = SubscriptionPricing.BillingPeriod(rawValue: periodRaw)
        {
            currentBillingPeriod = period
        }

        // Validate expiration
        if let expiresAt = subscriptionExpiresAt, expiresAt < Date() {
            // Subscription has expired
            Log.info("Persisted subscription expired at \(expiresAt), resetting to free", category: .subscription)
            subscriptionTier = .free
            subscriptionExpiresAt = nil
            activeProductID = nil
            persistSubscriptionState(
                tier: .free, expiresAt: nil, productID: nil, billingPeriod: .monthly)
        } else if let expiresAt = subscriptionExpiresAt {
            Log.info("Subscription valid until: \(expiresAt)", category: .subscription)
        }
    }

    // MARK: - Debug Methods

    #if DEBUG
        func resetToFreeTier() {
            subscriptionTier = .free
            subscriptionExpiresAt = nil
            activeProductID = nil
            purchasedProductIDs.removeAll()
            persistSubscriptionState(
                tier: .free, expiresAt: nil, productID: nil, billingPeriod: .monthly)
            Log.debug("Reset to free tier", category: .subscription)
        }
    #endif
}

// MARK: - StoreKit Error

enum StoreKitError: Error, LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
}
