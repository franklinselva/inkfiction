//
//  RestorePurchasesButton.swift
//  InkFiction
//
//  Button to restore previous purchases
//

import SwiftUI

// MARK: - Restore Purchases Button

struct RestorePurchasesButton: View {
    let isProcessing: Bool
    let onRestore: () -> Void
    let style: Style

    @Environment(\.themeManager) private var themeManager

    enum Style {
        case footer  // Link style for paywall footer
        case card  // Card style for settings
    }

    var body: some View {
        switch style {
        case .footer:
            footerStyle
        case .card:
            cardStyle
        }
    }

    // MARK: - Footer Style

    private var footerStyle: some View {
        Button(action: onRestore) {
            HStack(spacing: 6) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.6)
                }

                Text(isProcessing ? "Restoring..." : "Restore Purchases")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
        }
        .disabled(isProcessing)
    }

    // MARK: - Card Style

    private var cardStyle: some View {
        Button(action: onRestore) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: themeManager.currentTheme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Restore Purchases")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    Text("Restore your previous subscription")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }

                Spacer()

                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor.opacity(0.5))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.surfaceColor.opacity(0.3))
            )
        }
        .disabled(isProcessing)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        RestorePurchasesButton(
            isProcessing: false,
            onRestore: {},
            style: .footer
        )

        RestorePurchasesButton(
            isProcessing: true,
            onRestore: {},
            style: .footer
        )

        RestorePurchasesButton(
            isProcessing: false,
            onRestore: {},
            style: .card
        )
    }
    .padding()
    .environment(\.themeManager, ThemeManager())
}
