//
//  UpgradeButton.swift
//  InkFiction
//
//  CTA button for subscription purchases
//

import SwiftUI

// MARK: - Upgrade Button

struct UpgradeButton: View {
    let tier: SubscriptionTier
    let billingPeriod: SubscriptionPricing.BillingPeriod
    let isProcessing: Bool
    let style: Style
    let onUpgrade: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false

    enum Style {
        case large  // Full-width CTA
        case medium  // Standard size
        case small  // Compact
    }

    var body: some View {
        Button(action: onUpgrade) {
            HStack(spacing: 12) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: buttonIcon)
                        .font(iconFont)

                    Text(buttonText)
                        .font(textFont)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: style == .large ? .infinity : nil)
            .padding(buttonPadding)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: tier.uiGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(
                        color: tier.primaryGradientColor.opacity(0.4),
                        radius: isPressed ? 4 : 8,
                        y: isPressed ? 2 : 4
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .disabled(isProcessing)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Computed Properties

    private var buttonIcon: String {
        switch tier {
        case .free: "arrow.up.circle.fill"
        case .enhanced: "star.circle.fill"
        case .premium: "crown.fill"
        }
    }

    private var buttonText: String {
        let price = SubscriptionPricing.formattedPrice(for: tier, period: billingPeriod)
        let period = billingPeriod == .monthly ? "/mo" : "/yr"

        switch style {
        case .large:
            return "Subscribe to \(tier.displayName) - \(price)\(period)"
        case .medium:
            return "Upgrade - \(price)\(period)"
        case .small:
            return "Upgrade"
        }
    }

    private var iconFont: Font {
        switch style {
        case .large: .system(size: 18)
        case .medium: .system(size: 16)
        case .small: .system(size: 14)
        }
    }

    private var textFont: Font {
        switch style {
        case .large: .system(size: 17, weight: .semibold)
        case .medium: .system(size: 15, weight: .semibold)
        case .small: .system(size: 13, weight: .semibold)
        }
    }

    private var buttonPadding: EdgeInsets {
        switch style {
        case .large:
            return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        case .medium:
            return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        case .small:
            return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        UpgradeButton(
            tier: .enhanced,
            billingPeriod: .monthly,
            isProcessing: false,
            style: .large,
            onUpgrade: {}
        )

        UpgradeButton(
            tier: .premium,
            billingPeriod: .yearly,
            isProcessing: false,
            style: .medium,
            onUpgrade: {}
        )

        UpgradeButton(
            tier: .enhanced,
            billingPeriod: .monthly,
            isProcessing: true,
            style: .large,
            onUpgrade: {}
        )
    }
    .padding()
    .environment(\.themeManager, ThemeManager())
}
