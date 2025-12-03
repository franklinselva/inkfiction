//
//  CompanionCard.swift
//  InkFiction
//
//  Card component for displaying AI companion options
//

import SwiftUI

struct CompanionCard: View {
    let companion: AICompanion
    let isSelected: Bool
    let isRecommended: Bool
    let showProgressIndicator: Bool
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with icon and title
                HStack(alignment: .top) {
                    Image(systemName: companion.iconName)
                        .font(.system(size: 26))
                        .foregroundColor(isSelected ? companion.primaryColor : themeManager.currentTheme.textPrimaryColor)
                        .symbolRenderingMode(.hierarchical)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(companion.name)
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                            if isRecommended {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 8))
                                    Text("BEST MATCH")
                                        .font(.system(size: 9, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(4)
                                .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                        }

                        Text(companion.tagline)
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }

                    Spacer()

                    if isSelected {
                        if showProgressIndicator {
                            AutoProgressionIndicator(duration: 1.0) {
                                // Timer handles progression
                            }
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(companion.primaryColor)
                        }
                    }
                }

                // Description
                Text(companion.description)
                    .font(.system(size: 15))
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                // Personality Traits Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("PERSONALITY TRAITS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor.opacity(0.6))
                        .tracking(1.2)

                    HStack(spacing: 10) {
                        ForEach(Array(companion.personality.enumerated()), id: \.element) { index, trait in
                            Text(trait)
                                .font(.system(size: index == 0 ? 13 : 12))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    companion.gradient
                                        .opacity(index == 0 ? 0.35 : index == 1 ? 0.28 : 0.22)
                                )
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 4)

                // Signature Style Section
                VStack(alignment: .leading, spacing: 6) {
                    Text(companion.signatureStyle)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor.opacity(0.6))
                        .tracking(1.2)

                    Text(companion.signatureDescription)
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        .lineSpacing(3)
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(
                Group {
                    if isSelected {
                        companion.gradient.opacity(0.15)
                    } else {
                        themeManager.currentTheme.surfaceColor
                    }
                }
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected
                            ? AnyShapeStyle(companion.gradient)
                            : AnyShapeStyle(themeManager.currentTheme.strokeColor.opacity(0.5)),
                        lineWidth: isSelected ? 3 : 1.5
                    )
            )
            .shadow(
                color: isSelected ? companion.primaryColor.opacity(0.3) : .clear,
                radius: isSelected ? 12 : 0,
                x: 0,
                y: 4
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}
