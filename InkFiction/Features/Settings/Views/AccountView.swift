//
//  AccountView.swift
//  InkFiction
//
//  Account settings view with journal preferences and AI companion selection
//

import SwiftUI

struct AccountView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AccountViewModel()
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                // Navigation header with save button
                NavigationHeaderView(
                    config: NavigationHeaderConfig(
                        title: "Account",
                        leftButton: .back(action: { dismiss() }),
                        rightButton: viewModel.hasChanges
                            ? .icon("checkmark.circle.fill", action: { Task { await viewModel.saveChanges() } })
                            : (viewModel.showingSaveSuccess ? .icon("checkmark.circle.fill", action: {}) : .none)
                    ),
                    scrollOffset: scrollOffset
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Journal Preferences Section
                        journalPreferencesSection

                        // AI Companion Section
                        aiCompanionSection

                        // Add bottom spacing to avoid tab bar overlap
                        Color.clear
                            .frame(height: 120)
                    }
                    .padding()
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    scrollOffset = -newValue
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showingCompanionPicker) {
            CompanionPickerView(
                selectedCompanion: viewModel.selectedCompanion,
                onSelect: { companion in
                    viewModel.updateCompanion(companion)
                }
            )
        }
        .overlay {
            if viewModel.isLoading {
                themeManager.currentTheme.overlayColor
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .progressViewStyle(
                                CircularProgressViewStyle(
                                    tint: themeManager.currentTheme.textPrimaryColor
                                )
                            )
                            .scaleEffect(1.5)
                    }
            }
        }
    }

    // MARK: - Journal Preferences Section

    private var journalPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Journal Preferences")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                // Journaling Style
                preferenceRow(
                    icon: "pencil.and.scribble",
                    iconColor: .blue,
                    title: "Style",
                    currentValue: viewModel.journalingStyleCompactName
                ) {
                    ForEach(JournalingStyle.allCases, id: \.self) { style in
                        Button {
                            viewModel.updateJournalingStyle(style)
                        } label: {
                            HStack {
                                Image(systemName: style.icon)
                                Text(style.displayName)
                                if viewModel.journalingStyle == style {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                // Emotional Expression
                preferenceRow(
                    icon: "heart.fill",
                    iconColor: .pink,
                    title: "Mood",
                    currentValue: viewModel.emotionalExpressionCompactName
                ) {
                    ForEach(EmotionalExpression.allCases, id: \.self) { expression in
                        Button {
                            viewModel.updateEmotionalExpression(expression)
                        } label: {
                            HStack {
                                Image(systemName: expression.icon)
                                Text(expression.displayName)
                                if viewModel.emotionalExpression == expression {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                // Visual Preference
                preferenceRow(
                    icon: "paintbrush.fill",
                    iconColor: .purple,
                    title: "Visuals",
                    currentValue: viewModel.visualPreferenceCompactName
                ) {
                    ForEach(VisualPreference.allCases, id: \.self) { preference in
                        Button {
                            viewModel.updateVisualPreference(preference)
                        } label: {
                            HStack {
                                Image(systemName: preference.icon)
                                Text(preference.displayName)
                                if viewModel.visualPreference == preference {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            .gradientCard()
        }
    }

    // MARK: - AI Companion Section

    private var aiCompanionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Companion")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            Button {
                viewModel.showingCompanionPicker = true
            } label: {
                HStack(spacing: 16) {
                    // Companion Icon
                    ZStack {
                        Circle()
                            .fill(viewModel.selectedCompanion.gradient.opacity(0.2))
                            .frame(width: 50, height: 50)

                        Image(systemName: viewModel.selectedCompanion.iconName)
                            .font(.system(size: 22))
                            .foregroundStyle(viewModel.selectedCompanion.gradient)
                    }

                    // Companion Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.selectedCompanion.name)
                            .font(.body.weight(.semibold))
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                        Text(viewModel.selectedCompanion.tagline)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
                .padding()
                .gradientCard()
            }

            // Companion Description
            Text(viewModel.selectedCompanion.description)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                .padding(.horizontal, 4)
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func preferenceRow<MenuContent: View>(
        icon: String,
        iconColor: Color,
        title: String,
        currentValue: String,
        @ViewBuilder menu: () -> MenuContent
    ) -> some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(iconColor)
                    .frame(width: 24)

                Text(title)
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
            }

            Spacer()

            Menu {
                menu()
            } label: {
                HStack(spacing: 4) {
                    Text(currentValue)
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
            }
        }
        .padding()
    }
}

#Preview {
    AccountView()
        .environment(\.themeManager, ThemeManager())
}
