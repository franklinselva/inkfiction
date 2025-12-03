//
//  FeatureRow.swift
//  InkFiction
//
//  Feature row component for paywall feature lists
//

import SwiftUI

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let style: Style
    let gradient: [Color]

    @Environment(\.themeManager) private var themeManager

    enum Style {
        case card  // Card-style with background
        case list  // Simple list item
        case compact  // Compact for smaller spaces
    }

    init(
        icon: String,
        title: String,
        description: String,
        style: Style = .card,
        gradient: [Color] = []
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.style = style
        self.gradient = gradient
    }

    var body: some View {
        switch style {
        case .card:
            cardStyle
        case .list:
            listStyle
        case .compact:
            compactStyle
        }
    }

    // MARK: - Card Style

    private var cardStyle: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: effectiveGradient.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            colors: effectiveGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.surfaceColor.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            themeManager.currentTheme.strokeColor.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - List Style

    private var listStyle: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(
                    LinearGradient(
                        colors: effectiveGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                if !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
            }

            Spacer()
        }
    }

    // MARK: - Compact Style

    private var compactStyle: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(
                    LinearGradient(
                        colors: effectiveGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 20)

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
        }
    }

    // MARK: - Helpers

    private var effectiveGradient: [Color] {
        gradient.isEmpty ? themeManager.currentTheme.gradientColors : gradient
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Card Style")
            .font(.headline)

        FeatureRow(
            icon: "sparkles",
            title: "4 AI Images Daily",
            description: "Generate visual art from your journal entries, 4 per day",
            style: .card
        )

        Text("List Style")
            .font(.headline)

        FeatureRow(
            icon: "sparkles",
            title: "4 AI Images Daily",
            description: "Generate visual art from your journal entries",
            style: .list
        )

        Text("Compact Style")
            .font(.headline)

        FeatureRow(
            icon: "sparkles",
            title: "4 AI Images Daily",
            description: "",
            style: .compact
        )
    }
    .padding()
    .environment(\.themeManager, ThemeManager())
}
