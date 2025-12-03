//
//  PaywallView.swift
//  InkFiction
//
//  Premium paywall with mood orb showcase
//

import SwiftUI

// MARK: - Paywall View

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.themeManager) private var themeManager
    @StateObject private var viewModel = PaywallViewModel()
    @State private var selectedTier: SubscriptionTier = .premium
    @State private var selectedBillingPeriod: SubscriptionPricing.BillingPeriod = .monthly

    let context: PaywallDisplayManager.PaywallContext
    private let displayManager = PaywallDisplayManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Theme-based background
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                AnimatedGradientBackground()
                    .ignoresSafeArea()
                    .opacity(0.3)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Hero Section
                        heroSection
                            .padding(.top, 20)

                        // Mood Orb Showcase
                        moodOrbShowcase
                            .padding(.horizontal)

                        // Feature Showcase
                        featureShowcase
                            .padding(.horizontal)

                        // Billing Period Toggle
                        PricingToggleView(selectedPeriod: $selectedBillingPeriod)
                            .padding(.horizontal)

                        // Plan Cards
                        planCards
                            .padding(.horizontal)

                        // CTA Button
                        ctaButton
                            .padding(.horizontal)

                        // Trust Elements
                        trustSection
                            .padding(.horizontal)

                        // Footer
                        footerSection
                            .padding(.bottom, 40)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handleDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                themeManager.currentTheme.textSecondaryColor.opacity(0.6))
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .interactiveDismissDisabled(context == .firstLaunch)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 20) {
            // Icon with theme gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: themeManager.currentTheme.gradientColors.map {
                                $0.opacity(0.3)
                            },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)

                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: themeManager.currentTheme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 12) {
                Text(heroTitle)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Text(heroSubtitle)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    .padding(.horizontal, 20)
            }

            // Trial badge (only for eligible users)
            if viewModel.isEligibleForTrial {
                TrialOfferBanner(
                    isProcessing: viewModel.isProcessingPurchase,
                    onPurchase: {
                        Task {
                            await purchaseIntroductoryTrial()
                        }
                    },
                    style: .hero
                )
            }
        }
        .padding(.horizontal)
    }

    private var heroTitle: String {
        switch context {
        case .firstLaunch:
            return "Your Journal, Beautifully Transformed"
        case .periodicReminder:
            return "Ready to Unlock Premium?"
        case .featureLimitHit:
            return "You've Hit Your Limit"
        case .manualOpen:
            return "Upgrade to Premium"
        }
    }

    private var heroSubtitle: String {
        switch context {
        case .firstLaunch:
            return
                "Transform your thoughts into stunning visual art with AI-powered mood visualization"
        case .periodicReminder:
            return "Join others experiencing their journal in a whole new way"
        case .featureLimitHit:
            return "Upgrade now to continue creating unlimited AI-generated mood visuals"
        case .manualOpen:
            return "Unlock unlimited AI generations, advanced insights, and more"
        }
    }

    // MARK: - Mood Orb Showcase

    private var moodOrbShowcase: some View {
        VStack(spacing: 16) {
            Text("See Your Emotions Come to Life")
                .font(.title3.bold())
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

            // Sample mood orb visualization
            OrganicMoodOrbCluster(
                moodData: sampleMoodData
            )
            .frame(height: 280)

            Text("Each journal entry generates a unique visual representation of your mood")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var sampleMoodData: [OrganicMoodOrbCluster.MoodOrbData] {
        [
            OrganicMoodOrbCluster.MoodOrbData(
                id: UUID(),
                mood: .peaceful,
                entryCount: 4,
                lastUpdated: Date(),
                entries: []
            ),
            OrganicMoodOrbCluster.MoodOrbData(
                id: UUID(),
                mood: .happy,
                entryCount: 3,
                lastUpdated: Date(),
                entries: []
            ),
            OrganicMoodOrbCluster.MoodOrbData(
                id: UUID(),
                mood: .reflective,
                entryCount: 2,
                lastUpdated: Date(),
                entries: []
            ),
        ]
    }

    // MARK: - Feature Showcase

    private var featureShowcase: some View {
        VStack(spacing: 16) {
            Text("Everything You Get")
                .font(.title3.bold())
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                ForEach(selectedTier.limits.paywallFeatures) { feature in
                    FeatureRow(
                        icon: feature.icon,
                        title: feature.title,
                        description: feature.description,
                        style: .card,
                        gradient: themeManager.currentTheme.gradientColors
                    )
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.15), value: selectedTier)
            .id("features-\(selectedTier.rawValue)")
        }
    }

    // MARK: - Plan Cards

    private var planCards: some View {
        VStack(spacing: 16) {
            PlanCard(
                tier: .enhanced,
                billingPeriod: selectedBillingPeriod,
                currentTier: .free,
                style: .selection,
                isSelected: selectedTier == .enhanced,
                onSelect: {
                    withAnimation(.spring()) {
                        selectedTier = .enhanced
                    }
                }
            )

            PlanCard(
                tier: .premium,
                billingPeriod: selectedBillingPeriod,
                currentTier: .free,
                style: .selection,
                isSelected: selectedTier == .premium,
                onSelect: {
                    withAnimation(.spring()) {
                        selectedTier = .premium
                    }
                }
            )
        }
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        UpgradeButton(
            tier: selectedTier,
            billingPeriod: selectedBillingPeriod,
            isProcessing: viewModel.isProcessingPurchase,
            style: .large,
            onUpgrade: {
                Task {
                    await purchaseSubscription()
                }
            }
        )
    }

    // MARK: - Trust Section

    private var trustSection: some View {
        HStack(spacing: 20) {
            TrustBadge(icon: "checkmark.shield.fill", text: "Secure Payment")
            TrustBadge(icon: "arrow.clockwise", text: "Cancel Anytime")
            TrustBadge(icon: "lock.fill", text: "Privacy First")
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 16) {
            if context != .firstLaunch {
                Button(action: handleDismiss) {
                    Text("Maybe Later")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
            }

            RestorePurchasesButton(
                isProcessing: viewModel.isProcessingRestore,
                onRestore: {
                    Task {
                        await restorePurchases()
                    }
                },
                style: .footer
            )

            HStack(spacing: 16) {
                Button("Terms of Service") {
                    if let url = URL(string: "https://inkfiction.app/terms") {
                        openURL(url)
                    }
                }
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondaryColor.opacity(0.6))

                Button("Privacy Policy") {
                    if let url = URL(string: "https://inkfiction.app/privacy") {
                        openURL(url)
                    }
                }
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondaryColor.opacity(0.6))
            }

            Text(
                "Subscription automatically renews unless cancelled at least 24 hours before the end of the current period"
            )
            .font(.caption2)
            .foregroundColor(themeManager.currentTheme.textSecondaryColor.opacity(0.5))
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
    }

    // MARK: - Actions

    private func purchaseIntroductoryTrial() async {
        displayManager.logPaywallEvent(.purchaseStarted(tier: .enhanced))

        await viewModel.purchaseIntroductoryTrial()

        if viewModel.purchaseSuccessful {
            displayManager.recordPurchase(tier: .enhanced)
            dismiss()
        }
    }

    private func purchaseSubscription() async {
        displayManager.logPaywallEvent(.purchaseStarted(tier: selectedTier))

        await viewModel.purchaseSubscription(
            tier: selectedTier,
            period: selectedBillingPeriod
        )

        if viewModel.purchaseSuccessful {
            displayManager.recordPurchase(tier: selectedTier)
            dismiss()
        }
    }

    private func restorePurchases() async {
        await viewModel.restorePurchases()
        if viewModel.purchaseSuccessful {
            let currentTier = viewModel.currentTier
            displayManager.recordPurchase(tier: currentTier)
            dismiss()
        }
    }

    private func handleDismiss() {
        displayManager.dismissPaywall()
        dismiss()
    }
}

// MARK: - Trust Badge Component

struct TrustBadge: View {
    let icon: String
    let text: String
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(
                    LinearGradient(
                        colors: themeManager.currentTheme.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(text)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    PaywallView(context: .firstLaunch)
        .environment(\.themeManager, ThemeManager())
}
