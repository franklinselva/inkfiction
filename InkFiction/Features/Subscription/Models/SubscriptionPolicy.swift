//
//  SubscriptionPolicy.swift
//  InkFiction
//
//  Centralized subscription policy configuration
//  Single source of truth for all subscription limits and features
//

import Foundation

// MARK: - Paywall Feature

/// Paywall feature display model
struct PaywallFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Subscription Policy

/// Centralized subscription policy configuration
/// This is the SINGLE SOURCE OF TRUTH for all subscription-related limits
struct SubscriptionPolicy {

    // MARK: - Tier Configuration

    static func limits(for tier: SubscriptionTier) -> TierLimits {
        switch tier {
        case .free:
            return TierLimits(
                // AI Image Generation (for journal entries)
                dailyAIImageGenerations: 0,

                // Persona Styles (Avatar Personalization)
                maxPersonaStyles: 0,
                maxPersonaGenerationsPerPeriod: 0,
                personaUpdateFrequencyDays: -1,  // Never

                // AI Features
                hasAIReflections: false,
                hasAISummaries: false,
                hasWeeklyMonthlySummaries: false,
                hasAdvancedAI: false,
                hasSentimentInsights: false,

                // Other Features
                hasEarlyAccess: false,

                // Display
                displayName: "Free",
                badgeIcon: "person.circle",
                gradientColors: ["#6B7280", "#9CA3AF"],

                // Feature List
                features: [
                    "Core journaling (unlimited entries)",
                    "iCloud sync across devices",
                    "Upgrade for AI reflections & images",
                ],
                paywallFeatures: [
                    PaywallFeature(
                        icon: "book.fill",
                        title: "Unlimited Journaling",
                        description: "Create unlimited journal entries with rich text support"
                    ),
                    PaywallFeature(
                        icon: "icloud.fill",
                        title: "iCloud Sync",
                        description: "Securely sync your journal across all your devices"
                    ),
                    PaywallFeature(
                        icon: "lock.fill",
                        title: "Private & Secure",
                        description: "Your thoughts are yours alone, stored securely"
                    ),
                ]
            )

        case .enhanced:
            return TierLimits(
                // AI Image Generation (for journal entries)
                dailyAIImageGenerations: 4,

                // Persona Styles (Avatar Personalization)
                maxPersonaStyles: 3,
                maxPersonaGenerationsPerPeriod: 10,
                personaUpdateFrequencyDays: 30,  // Monthly

                // AI Features
                hasAIReflections: true,
                hasAISummaries: true,
                hasWeeklyMonthlySummaries: false,
                hasAdvancedAI: false,
                hasSentimentInsights: true,

                // Other Features
                hasEarlyAccess: false,

                // Display
                displayName: "Enhanced",
                badgeIcon: "star.circle.fill",
                gradientColors: ["#F59E0B", "#F97316"],

                // Feature List
                features: [
                    "Everything in Free, plus:",
                    "AI reflections & summaries (short-form)",
                    "4 Journal image generations per day",
                    "Up to 3 persona styles (10 generations/month)",
                    "Monthly persona updates",
                    "Sentiment and tone insights",
                ],
                paywallFeatures: [
                    PaywallFeature(
                        icon: "sparkles",
                        title: "4 AI Images Daily",
                        description: "Generate visual art from your journal entries, 4 per day"
                    ),
                    PaywallFeature(
                        icon: "wand.and.stars",
                        title: "AI Reflections",
                        description: "Get AI-powered insights and short-form summaries"
                    ),
                    PaywallFeature(
                        icon: "person.3.fill",
                        title: "3 Persona Styles",
                        description:
                            "Hold 3 styles, 10 generation attempts per month to perfect them"
                    ),
                    PaywallFeature(
                        icon: "chart.bar.fill",
                        title: "Sentiment Insights",
                        description: "Track your emotional patterns and mood trends"
                    ),
                ]
            )

        case .premium:
            return TierLimits(
                // AI Image Generation (for journal entries)
                dailyAIImageGenerations: 20,

                // Persona Styles (Avatar Personalization)
                maxPersonaStyles: 5,
                maxPersonaGenerationsPerPeriod: 20,
                personaUpdateFrequencyDays: 14,  // Bi-weekly

                // AI Features
                hasAIReflections: true,
                hasAISummaries: true,
                hasWeeklyMonthlySummaries: true,
                hasAdvancedAI: true,
                hasSentimentInsights: true,

                // Other Features
                hasEarlyAccess: true,

                // Display
                displayName: "Premium",
                badgeIcon: "crown.fill",
                gradientColors: ["#8B5CF6", "#EC4899"],

                // Feature List
                features: [
                    "Everything in Enhanced, plus:",
                    "Long-form & creative AI reflections",
                    "20 Journal image generations per day",
                    "Up to 5 persona styles (20 generations/2 weeks)",
                    "Bi-weekly persona updates (every 14 days)",
                    "Weekly and monthly AI summaries",
                    "Early access to experimental features",
                ],
                paywallFeatures: [
                    PaywallFeature(
                        icon: "photo.on.rectangle.angled",
                        title: "20 AI Images Daily",
                        description: "Generate stunning visual art from your entries, 20 per day"
                    ),
                    PaywallFeature(
                        icon: "sparkles.rectangle.stack",
                        title: "Advanced AI Reflections",
                        description: "Long-form creative reflections with deep insights"
                    ),
                    PaywallFeature(
                        icon: "person.3.fill",
                        title: "5 Persona Styles",
                        description:
                            "Hold 5 styles, 20 generation attempts every 2 weeks to perfect them"
                    ),
                    PaywallFeature(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Weekly & Monthly Summaries",
                        description: "AI-generated summaries of your emotional journey"
                    ),
                    PaywallFeature(
                        icon: "brain.head.profile",
                        title: "Sentiment Insights",
                        description: "Deep mood analysis and emotional pattern tracking"
                    ),
                    PaywallFeature(
                        icon: "wand.and.stars.inverse",
                        title: "Early Access",
                        description: "Be the first to try new experimental features"
                    ),
                ]
            )
        }
    }

    // MARK: - Tier Limits Model

    struct TierLimits {
        // AI Image Generation (for journal entries)
        let dailyAIImageGenerations: Int  // -1 = unlimited, 0 = none

        // Persona Styles (Avatar Personalization)
        let maxPersonaStyles: Int
        let maxPersonaGenerationsPerPeriod: Int
        let personaUpdateFrequencyDays: Int  // -1 = never, 0 = anytime

        // AI Features
        let hasAIReflections: Bool
        let hasAISummaries: Bool
        let hasWeeklyMonthlySummaries: Bool
        let hasAdvancedAI: Bool
        let hasSentimentInsights: Bool

        // Other Features
        let hasEarlyAccess: Bool

        // Display Information
        let displayName: String
        let badgeIcon: String
        let gradientColors: [String]
        let features: [String]
        let paywallFeatures: [PaywallFeature]

        // MARK: - Computed Properties

        var hasUnlimitedAIImages: Bool {
            dailyAIImageGenerations == -1
        }

        var hasUnlimitedPersonaStyles: Bool {
            maxPersonaStyles == -1
        }

        var canCreatePersonaStyles: Bool {
            maxPersonaStyles > 0
        }

        var canUpdatePersonas: Bool {
            personaUpdateFrequencyDays >= 0
        }

        var keyFeatureSummary: String {
            var parts: [String] = []

            // AI Images
            if dailyAIImageGenerations > 0 {
                if dailyAIImageGenerations == -1 {
                    parts.append("Unlimited AI")
                } else {
                    parts.append("\(dailyAIImageGenerations) AI/day")
                }
            }

            // Persona Styles
            if maxPersonaStyles > 0 {
                if maxPersonaStyles == -1 {
                    parts.append("Unlimited Styles")
                } else {
                    parts.append("\(maxPersonaStyles) Styles")
                }
            }

            // AI Features summary
            if hasAIReflections {
                parts.append("AI Reflections")
            }

            return parts.joined(separator: " • ")
        }

        // MARK: - Validation Methods

        func canGenerateAIImage(currentUsage: Int) -> Bool {
            if dailyAIImageGenerations == 0 {
                return false
            }
            if dailyAIImageGenerations == -1 {
                return true
            }
            return currentUsage < dailyAIImageGenerations
        }

        func canAddMorePersonaStyles(currentStyleCount: Int) -> Bool {
            if maxPersonaStyles == 0 {
                return false
            }
            if maxPersonaStyles == -1 {
                return true
            }
            return currentStyleCount < maxPersonaStyles
        }

        func remainingPersonaStyleSlots(currentStyleCount: Int) -> Int {
            if maxPersonaStyles == 0 {
                return 0
            }
            if maxPersonaStyles == -1 {
                return Int.max
            }
            return max(0, maxPersonaStyles - currentStyleCount)
        }

        func canUpdatePersona(lastUpdateDate: Date?) -> (canUpdate: Bool, daysRemaining: Int?) {
            guard canUpdatePersonas else {
                return (false, nil)
            }

            if personaUpdateFrequencyDays == 0 {
                return (true, nil)  // Anytime
            }

            guard let lastUpdate = lastUpdateDate else {
                return (true, nil)  // Never updated before
            }

            let daysSinceUpdate =
                Calendar.current.dateComponents(
                    [.day],
                    from: lastUpdate,
                    to: Date()
                ).day ?? 0

            let canUpdateNow = daysSinceUpdate >= personaUpdateFrequencyDays
            let daysRemaining = canUpdateNow ? nil : (personaUpdateFrequencyDays - daysSinceUpdate)

            return (canUpdateNow, daysRemaining)
        }

        func remainingAIGenerations(currentUsage: Int) -> Int {
            if dailyAIImageGenerations == -1 {
                return Int.max
            }
            if dailyAIImageGenerations == 0 {
                return 0
            }
            return max(0, dailyAIImageGenerations - currentUsage)
        }
    }

    // MARK: - Upgrade Context

    enum UpgradeContext {
        case generic
        case aiImageLimitReached
        case personaLimitReached
        case personaUpdateCooldown
    }

    // MARK: - Helper Messages

    static func upgradeMessage(from tier: SubscriptionTier, context: UpgradeContext) -> String {
        switch context {
        case .aiImageLimitReached:
            switch tier {
            case .free:
                return
                    "AI image generation is available starting from the Enhanced tier. Upgrade to generate 4 AI images per day."
            case .enhanced:
                return
                    "You've used all 4 daily AI images. Upgrade to Premium for 20 images per day, or wait until tomorrow."
            case .premium:
                return "You've reached your daily limit of 20 AI images. Your quota resets tomorrow."
            }

        case .personaLimitReached:
            switch tier {
            case .free:
                return
                    "Persona styles are available starting from the Enhanced tier. Upgrade to create up to 3 styles."
            case .enhanced:
                return
                    "You've reached your limit of 3 persona styles. Upgrade to Premium for up to 5 styles."
            case .premium:
                return "You've reached your limit of 5 persona styles."
            }

        case .personaUpdateCooldown:
            switch tier {
            case .free:
                return "Persona updates are not available on the Free tier."
            case .enhanced:
                return
                    "You can update your personas once per month on the Enhanced tier. Upgrade to Premium for bi-weekly updates."
            case .premium:
                return "You can update your personas every 2 weeks on the Premium tier."
            }

        case .generic:
            switch tier {
            case .free:
                return
                    "Upgrade to Enhanced or Premium to unlock AI reflections, image generation, and persona styles."
            case .enhanced:
                return
                    "Upgrade to Premium for more AI generations, persona styles, and advanced features."
            case .premium:
                return "You have access to all premium features."
            }
        }
    }

    // MARK: - Retention Offer Configuration

    struct RetentionOffer {
        let tier: SubscriptionTier
        let discountedPrice: Decimal
        let regularPrice: Decimal
        let duration: RetentionDuration
        let savings: String
        let transitionMessage: String

        enum RetentionDuration {
            case oneMonth
            case threeMonths

            var displayText: String {
                switch self {
                case .oneMonth: "1 month"
                case .threeMonths: "3 months"
                }
            }

            var months: Int {
                switch self {
                case .oneMonth: 1
                case .threeMonths: 3
                }
            }
        }

        var formattedPrice: String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.locale = Locale(identifier: "en_US")
            return formatter.string(from: discountedPrice as NSDecimalNumber) ?? "$\(discountedPrice)"
        }

        var formattedRegularPrice: String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.locale = Locale(identifier: "en_US")
            return formatter.string(from: regularPrice as NSDecimalNumber) ?? "$\(regularPrice)"
        }
    }

    static func retentionOffer(for tier: SubscriptionTier) -> RetentionOffer? {
        switch tier {
        case .free:
            return nil

        case .enhanced:
            return RetentionOffer(
                tier: .enhanced,
                discountedPrice: 2.99,
                regularPrice: 4.99,
                duration: .threeMonths,
                savings: "Save 40% for 3 months",
                transitionMessage: "then $4.99/month"
            )

        case .premium:
            return RetentionOffer(
                tier: .premium,
                discountedPrice: 6.99,
                regularPrice: 12.99,
                duration: .threeMonths,
                savings: "Save 46% for 3 months",
                transitionMessage: "then $12.99/month"
            )
        }
    }
}
