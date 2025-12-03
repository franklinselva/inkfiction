//
//  PricingToggleView.swift
//  InkFiction
//
//  Toggle view for switching between monthly and yearly billing periods
//

import SwiftUI

// MARK: - Pricing Toggle View

struct PricingToggleView: View {
    @Binding var selectedPeriod: SubscriptionPricing.BillingPeriod
    @Environment(\.themeManager) private var themeManager
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SubscriptionPricing.BillingPeriod.allCases, id: \.self) { period in
                periodButton(for: period)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.surfaceColor.opacity(0.3))
        )
    }

    @ViewBuilder
    private func periodButton(for period: SubscriptionPricing.BillingPeriod) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedPeriod = period
            }
        } label: {
            HStack(spacing: 6) {
                Text(period.displayName)
                    .font(.subheadline.weight(.medium))

                if period == .yearly {
                    Text("Save 20%")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.green)
                        )
                }
            }
            .foregroundColor(
                selectedPeriod == period
                    ? themeManager.currentTheme.textPrimaryColor
                    : themeManager.currentTheme.textSecondaryColor
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Group {
                    if selectedPeriod == period {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.currentTheme.surfaceColor)
                            .shadow(
                                color: themeManager.currentTheme.shadowColor.opacity(0.1),
                                radius: 4,
                                y: 2
                            )
                            .matchedGeometryEffect(id: "selection", in: animation)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PricingToggleView(selectedPeriod: .constant(.monthly))
        PricingToggleView(selectedPeriod: .constant(.yearly))
    }
    .padding()
    .environment(\.themeManager, ThemeManager())
}
