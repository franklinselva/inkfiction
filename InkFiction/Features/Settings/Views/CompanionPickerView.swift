//
//  CompanionPickerView.swift
//  InkFiction
//
//  Sheet view for selecting an AI companion
//

import SwiftUI

struct CompanionPickerView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss

    let selectedCompanion: AICompanion
    let onSelect: (AICompanion) -> Void

    @State private var currentSelection: AICompanion

    init(selectedCompanion: AICompanion, onSelect: @escaping (AICompanion) -> Void) {
        self.selectedCompanion = selectedCompanion
        self.onSelect = onSelect
        self._currentSelection = State(initialValue: selectedCompanion)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Header description
                        Text("Choose a companion that matches your journaling style")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        // Companion Cards
                        ForEach(AICompanion.all, id: \.id) { companion in
                            CompanionSelectionCard(
                                companion: companion,
                                isSelected: currentSelection.id == companion.id,
                                onSelect: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        currentSelection = companion
                                    }
                                }
                            )
                        }

                        // Bottom spacing
                        Color.clear
                            .frame(height: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Companion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onSelect(currentSelection)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
    }
}

// MARK: - Companion Selection Card

struct CompanionSelectionCard: View {
    let companion: AICompanion
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.themeManager) private var themeManager

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and name
                HStack(alignment: .top, spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(companion.gradient.opacity(isSelected ? 0.3 : 0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: companion.iconName)
                            .font(.system(size: 20))
                            .foregroundStyle(companion.gradient)
                    }

                    // Name and tagline
                    VStack(alignment: .leading, spacing: 2) {
                        Text(companion.name)
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                        Text(companion.tagline)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }

                    Spacer()

                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(companion.gradient)
                    } else {
                        Circle()
                            .stroke(themeManager.currentTheme.strokeColor, lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                    }
                }

                // Description
                Text(companion.description)
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Personality traits
                HStack(spacing: 8) {
                    ForEach(companion.personality, id: \.self) { trait in
                        Text(trait)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                companion.gradient.opacity(isSelected ? 0.25 : 0.12)
                            )
                            .cornerRadius(6)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.currentTheme.surfaceColor.opacity(isSelected ? 0.9 : 0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected
                            ? AnyShapeStyle(companion.gradient)
                            : AnyShapeStyle(themeManager.currentTheme.strokeColor.opacity(0.3)),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? companion.primaryColor.opacity(0.2) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CompanionPickerView(
        selectedCompanion: .poet,
        onSelect: { _ in }
    )
    .environment(\.themeManager, ThemeManager())
}
