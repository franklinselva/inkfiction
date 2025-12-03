//
//  PlanCard.swift
//  InkFiction
//
//  Unified plan card component for paywall and subscription views
//

import SwiftUI

// MARK: - Plan Card

struct PlanCard: View {
    let tier: SubscriptionTier
    let billingPeriod: SubscriptionPricing.BillingPeriod
    let currentTier: SubscriptionTier
    let style: Style
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false

    enum Style {
        case selection  // For PaywallView (compact with selection)
        case upgrade  // For subscription status upgrade section
        case currentPlan  // For current plan display
        case full  // Full standalone card
    }

    private var isCurrentPlan: Bool {
        tier == currentTier
    }

    private var isPremium: Bool {
        tier == .premium
    }

    private var isRecommended: Bool {
        isPremium && style == .selection
    }

    var body: some View {
        Group {
            switch style {
            case .selection:
                selectionCard
            case .upgrade:
                upgradeCard
            case .currentPlan:
                currentPlanCard
            case .full:
                fullCard
            }
        }
    }

    // MARK: - Selection Card

    private var selectionCard: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: tier.badgeIcon)
                    .font(.title2)
                    .foregroundStyle(tier.gradient())
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 6) {
                    // Title
                    Text(tier.displayName)
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    // Recommended badge
                    if isRecommended {
                        Text("RECOMMENDED")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: themeManager.currentTheme.gradientColors,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }

                    // Key feature
                    Text(tier.limits.keyFeatureSummary)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        .padding(.top, isRecommended ? 2 : 0)
                }

                Spacer()

                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(SubscriptionPricing.formattedPrice(for: tier, period: billingPeriod))
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    Text(billingPeriod == .monthly ? "/month" : "/year")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor.opacity(0.8))

                    if billingPeriod == .yearly && isPremium {
                        Text(
                            "Save $\(String(format: "%.0f", SubscriptionPricing.yearlySavings(for: tier)))"
                        )
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(
                        isSelected
                            ? tier.primaryGradientColor
                            : themeManager.currentTheme.textSecondaryColor.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.currentTheme.surfaceColor.opacity(isSelected ? 0.5 : 0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected
                                    ? tier.gradient(
                                        opacity: 0.6, startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(
                                        colors: [themeManager.currentTheme.strokeColor],
                                        startPoint: .leading, endPoint: .trailing),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Upgrade Card

    private var upgradeCard: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 16) {
                // Plan icon
                Image(systemName: tier.badgeIcon)
                    .font(.title2)
                    .foregroundStyle(tier.gradient())
                    .frame(width: 36)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 6) {
                    // Title
                    Text(tier.displayName)
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    // Badge for premium
                    if isPremium {
                        Text("MOST POPULAR")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color(red: 255 / 255, green: 204 / 255, blue: 0 / 255))
                            )
                    }

                    // Key features list
                    VStack(alignment: .leading, spacing: 4) {
                        let limits = tier.limits

                        if limits.dailyAIImageGenerations > 0 {
                            FeatureListItem(
                                text:
                                    limits.dailyAIImageGenerations == -1
                                    ? "Unlimited AI images"
                                    : "\(limits.dailyAIImageGenerations) AI images per day"
                            )
                        }

                        if limits.maxPersonaStyles > 0 {
                            FeatureListItem(
                                text:
                                    limits.maxPersonaStyles == -1
                                    ? "Unlimited persona styles"
                                    : "\(limits.maxPersonaStyles) persona styles"
                            )
                        }

                        if limits.hasAIReflections {
                            FeatureListItem(text: "AI Reflections & Summaries")
                        }
                    }
                    .padding(.top, isPremium ? 2 : 0)
                }

                Spacer()

                // Price and selection
                VStack(alignment: .trailing, spacing: 8) {
                    if !isCurrentPlan {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(SubscriptionPricing.formattedPrice(for: tier, period: billingPeriod))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                            Text(billingPeriod == .monthly ? "/month" : "/year")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                            if billingPeriod == .yearly {
                                Text("Save $\(Int(SubscriptionPricing.yearlySavings(for: tier)))")
                                    .font(.caption2.bold())
                                    .foregroundColor(.green)
                            }
                        }
                    } else {
                        Text("Current")
                            .font(.caption.bold())
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }

                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(
                            isSelected
                                ? (isPremium
                                    ? Color(red: 255 / 255, green: 204 / 255, blue: 0 / 255)
                                    : tier.primaryGradientColor)
                                : .gray.opacity(0.3))
                }
                .padding(.top, 4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.currentTheme.surfaceColor.opacity(isSelected ? 0.5 : 0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected
                                    ? LinearGradient(
                                        colors: isPremium
                                            ? [
                                                Color(
                                                    red: 255 / 255, green: 204 / 255, blue: 0 / 255
                                                ).opacity(0.6)
                                            ]
                                            : tier.uiGradientColors.map { $0.opacity(0.6) },
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.white.opacity(0.1)], startPoint: .leading,
                                        endPoint: .trailing),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isCurrentPlan)
        .opacity(isCurrentPlan ? 0.5 : 1.0)
    }

    // MARK: - Current Plan Card

    private var currentPlanCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    // Plan Icon
                    ZStack {
                        Circle()
                            .fill(tier.gradient(opacity: 0.2))
                            .frame(width: 56, height: 56)

                        Image(systemName: tier.badgeIcon)
                            .font(.system(size: 28))
                            .foregroundStyle(tier.gradient())
                    }

                    // Plan Info
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(tier.displayName)
                                .font(.title2.bold())
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                            if isPremium {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title3)
                                    .foregroundColor(
                                        Color(red: 255 / 255, green: 204 / 255, blue: 0 / 255))
                            }
                        }

                        if currentTier != .free {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(billingPeriod.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                            }
                        } else {
                            Text("Your current plan")
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        }
                    }

                    Spacer()
                }

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                // Benefits List
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's Included")
                        .font(.subheadline.bold())
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(tier.limits.features, id: \.self) { feature in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(tier.gradient())

                                Text(feature)
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                                    .fixedSize(horizontal: false, vertical: true)

                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.currentTheme.surfaceColor.opacity(0.4),
                                themeManager.currentTheme.surfaceColor.opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                tier.gradient(opacity: 0.3),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: tier.primaryGradientColor.opacity(0.1),
                        radius: 10,
                        x: 0,
                        y: 5
                    )
            )
        }
    }

    // MARK: - Full Card

    private var fullCard: some View {
        Button(action: onSelect) {
            VStack(spacing: 20) {
                // Header with badge
                VStack(spacing: 12) {
                    if isPremium {
                        Text("MOST POPULAR")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: themeManager.currentTheme.gradientColors,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }

                    HStack(spacing: 12) {
                        Image(systemName: tier.badgeIcon)
                            .font(.title)
                            .foregroundStyle(tier.gradient())

                        Text(tier.displayName)
                            .font(.title2.bold())
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                    }

                    // Pricing
                    VStack(spacing: 4) {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text(SubscriptionPricing.formattedPrice(for: tier, period: billingPeriod))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                            Text(billingPeriod.periodSuffix)
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                                .padding(.bottom, 6)
                        }

                        if billingPeriod == .yearly {
                            VStack(spacing: 2) {
                                Text(
                                    "Just \(SubscriptionPricing.formattedMonthlyEquivalent(for: tier))/month"
                                )
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                                Text("Save \(SubscriptionPricing.formattedSavings(for: tier))")
                                    .font(.caption.bold())
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                        }
                    }
                }

                // Features list
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(tier.benefits.prefix(5), id: \.self) { benefit in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.currentTheme.accentColor)

                            Text(benefit)
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                                .multilineTextAlignment(.leading)

                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 4)

                Spacer()

                // CTA Button
                if isCurrentPlan {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Current Plan")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .stroke(themeManager.currentTheme.strokeColor, lineWidth: 1)
                    )
                } else {
                    Text(currentTier == .free ? "Subscribe" : "Upgrade")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(tier.gradient(startPoint: .leading, endPoint: .trailing))
                        )
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 450)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.currentTheme.surfaceColor.opacity(0.6),
                                themeManager.currentTheme.surfaceColor.opacity(0.3),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                tier.gradient(opacity: 0.5),
                                lineWidth: isCurrentPlan ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Feature List Item

private struct FeatureListItem: View {
    let text: String
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.system(size: 10))
                .foregroundColor(.blue.opacity(0.8))
                .frame(width: 12)

            Text(text)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("Selection Style")
                .font(.headline)

            PlanCard(
                tier: .enhanced,
                billingPeriod: .monthly,
                currentTier: .free,
                style: .selection,
                isSelected: false,
                onSelect: {}
            )

            PlanCard(
                tier: .premium,
                billingPeriod: .monthly,
                currentTier: .free,
                style: .selection,
                isSelected: true,
                onSelect: {}
            )
        }
        .padding()
    }
    .environment(\.themeManager, ThemeManager())
}
