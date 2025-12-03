//
//  TrialOfferBanner.swift
//  InkFiction
//
//  Banner for displaying free trial offers
//

import SwiftUI

// MARK: - Trial Offer Banner

struct TrialOfferBanner: View {
    let isProcessing: Bool
    let onPurchase: () -> Void
    let style: Style

    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false

    enum Style {
        case hero  // Large banner for paywall hero
        case compact  // Compact for inline display
        case card  // Card style
    }

    var body: some View {
        switch style {
        case .hero:
            heroStyle
        case .compact:
            compactStyle
        case .card:
            cardStyle
        }
    }

    // MARK: - Hero Style

    private var heroStyle: some View {
        Button(action: onPurchase) {
            HStack(spacing: 8) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 14))
                }

                Text(isProcessing ? "Starting Trial..." : "Start 7-Day Free Trial")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 34 / 255, green: 197 / 255, blue: 94 / 255),
                                Color(red: 16 / 255, green: 185 / 255, blue: 129 / 255),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(
                        color: Color.green.opacity(0.4),
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

    // MARK: - Compact Style

    private var compactStyle: some View {
        HStack(spacing: 6) {
            Image(systemName: "gift.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)

            Text("7-Day Free Trial")
                .font(.caption.weight(.semibold))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.15))
        )
    }

    // MARK: - Card Style

    private var cardStyle: some View {
        Button(action: onPurchase) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: "gift.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                }

                // Text
                VStack(spacing: 4) {
                    Text("Start Your Free Trial")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    Text("Try Enhanced for 7 days, free")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }

                // CTA
                HStack(spacing: 6) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7)
                    } else {
                        Text("Start Free Trial")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 34 / 255, green: 197 / 255, blue: 94 / 255),
                                    Color(red: 16 / 255, green: 185 / 255, blue: 129 / 255),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.currentTheme.surfaceColor.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .disabled(isProcessing)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        TrialOfferBanner(
            isProcessing: false,
            onPurchase: {},
            style: .hero
        )

        TrialOfferBanner(
            isProcessing: false,
            onPurchase: {},
            style: .compact
        )

        TrialOfferBanner(
            isProcessing: false,
            onPurchase: {},
            style: .card
        )
    }
    .padding()
    .environment(\.themeManager, ThemeManager())
}
