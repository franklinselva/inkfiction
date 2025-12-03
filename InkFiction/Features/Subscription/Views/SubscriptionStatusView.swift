//
//  SubscriptionStatusView.swift
//  InkFiction
//
//  Comprehensive subscription status and management view
//

import SwiftUI

struct SubscriptionStatusView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var paywallViewModel = PaywallViewModel()

    @State private var scrollOffset: CGFloat = 0
    @State private var selectedBillingPeriod: SubscriptionPricing.BillingPeriod = .monthly
    @State private var selectedUpgradeTier: SubscriptionTier? = nil

    private let storeKitManager = StoreKitManager.shared

    var body: some View {
        ZStack {
            AnimatedGradientBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation Header
                NavigationHeaderView(
                    config: NavigationHeaderConfig(
                        title: "Subscription",
                        leftButton: .back(action: { dismiss() }),
                        rightButton: .none
                    ),
                    scrollOffset: scrollOffset
                )

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Current Plan Card
                        currentPlanSection

                        // Upgrade Options (for non-Premium users)
                        if storeKitManager.subscriptionTier != .premium {
                            upgradeSection
                        }

                        // Restore Purchases
                        restorePurchasesSection

                        // Subscription Management (for subscribed users only)
                        if storeKitManager.subscriptionTier != .free {
                            subscriptionManagementSection
                        }

                        // Add bottom padding
                        Color.clear
                            .frame(height: 100)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    scrollOffset = -newValue
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setDefaultUpgradeTier()
        }
        .alert("Error", isPresented: .constant(paywallViewModel.errorMessage != nil)) {
            Button("OK") {
                paywallViewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = paywallViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Current Plan Section

    private var currentPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Plan")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

            PlanCard(
                tier: storeKitManager.subscriptionTier,
                billingPeriod: storeKitManager.currentBillingPeriod,
                currentTier: storeKitManager.subscriptionTier,
                style: .currentPlan,
                isSelected: false,
                onSelect: {}
            )
        }
    }

    // MARK: - Upgrade Section

    private var upgradeSection: some View {
        VStack(spacing: 20) {
            Text("Choose Your Plan")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Billing Period Toggle
            PricingToggleView(selectedPeriod: $selectedBillingPeriod)

            // Plan Cards
            VStack(spacing: 12) {
                ForEach([SubscriptionTier.enhanced, .premium], id: \.self) { tier in
                    if tier.priority > storeKitManager.subscriptionTier.priority {
                        PlanCard(
                            tier: tier,
                            billingPeriod: selectedBillingPeriod,
                            currentTier: storeKitManager.subscriptionTier,
                            style: .upgrade,
                            isSelected: selectedUpgradeTier == tier,
                            onSelect: {
                                withAnimation(.spring()) {
                                    selectedUpgradeTier = tier
                                }
                            }
                        )
                    }
                }
            }

            // Upgrade Button
            if let selectedTier = selectedUpgradeTier {
                UpgradeButton(
                    tier: selectedTier,
                    billingPeriod: selectedBillingPeriod,
                    isProcessing: paywallViewModel.isProcessingPurchase,
                    style: .large,
                    onUpgrade: {
                        Task {
                            await paywallViewModel.purchaseSubscription(
                                tier: selectedTier,
                                period: selectedBillingPeriod
                            )
                        }
                    }
                )
            }
        }
    }

    // MARK: - Restore Purchases Section

    private var restorePurchasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Restore Purchases")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

            RestorePurchasesButton(
                isProcessing: paywallViewModel.isProcessingRestore,
                onRestore: {
                    Task {
                        await paywallViewModel.restorePurchases()
                    }
                },
                style: .card
            )

            Text("If you purchased a subscription on another device, use this to sync it to this device.")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondaryColor.opacity(0.8))
        }
    }

    // MARK: - Subscription Management Section

    private var subscriptionManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manage Subscription")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

            VStack(spacing: 12) {
                // Next billing info
                if let expiresAt = storeKitManager.subscriptionExpiresAt {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                        Text("Renews \(expiresAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.currentTheme.surfaceColor.opacity(0.3))
                    )
                }

                // Manage subscription button
                Button(action: {
                    Task {
                        await openSubscriptionManagement()
                    }
                }) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 14))

                        Text("Manage in App Store")
                            .font(.subheadline)

                        Spacer()

                        Image(systemName: "arrow.up.forward.app")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.currentTheme.surfaceColor.opacity(0.3))
                    )
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func setDefaultUpgradeTier() {
        let currentTier = storeKitManager.subscriptionTier

        switch currentTier {
        case .free:
            selectedUpgradeTier = .enhanced
        case .enhanced:
            selectedUpgradeTier = .premium
        case .premium:
            selectedUpgradeTier = nil
        }
    }

    private func openSubscriptionManagement() async {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            await UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    SubscriptionStatusView()
        .environment(\.themeManager, ThemeManager())
}
