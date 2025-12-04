//
//  AIFeaturesView.swift
//  InkFiction
//
//  View for managing AI-related settings and features
//

import SwiftUI

struct AIFeaturesView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(Router.self) private var router
    @State private var viewModel = AIFeaturesViewModel()
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack {
            AnimatedGradientBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation header
                NavigationHeaderView(
                    config: NavigationHeaderConfig(
                        title: "AI Features",
                        leftButton: .back(action: {
                            router.pop()
                        }),
                        rightButton: .none
                    ),
                    scrollOffset: scrollOffset
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // AI Enhancement Section
                        aiEnhancementSection

                        // AI Companion Section
                        aiCompanionSection

                        // About AI Section
                        aboutAISection

                        // Bottom spacing
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
        .task {
            await viewModel.loadSettings()
        }
    }

    // MARK: - AI Enhancement Section

    private var aiEnhancementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Writing Enhancement")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                // Auto-enhance toggle
                Toggle(isOn: $viewModel.aiAutoEnhanceEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 18))
                            .foregroundColor(.purple)
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.purple.opacity(0.15))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Enhance Writing")
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                            Text("Suggest improvements to your journal entries")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        }
                    }
                }
                .tint(themeManager.currentTheme.accentColor)
                .padding()
                .onChange(of: viewModel.aiAutoEnhanceEnabled) { _, newValue in
                    Task {
                        await viewModel.setAutoEnhance(newValue)
                    }
                }

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                // Auto-title toggle
                Toggle(isOn: $viewModel.aiAutoTitleEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "textformat")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(0.15))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Generate Titles")
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                            Text("Create titles based on entry content")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        }
                    }
                }
                .tint(themeManager.currentTheme.accentColor)
                .padding()
                .onChange(of: viewModel.aiAutoTitleEnabled) { _, newValue in
                    Task {
                        await viewModel.setAutoTitle(newValue)
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

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: themeManager.currentTheme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your AI Companion")
                            .font(.body.weight(.medium))
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                        Text("Personalized insights and reflections based on your journaling style")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }

                    Spacer()
                }

                Button {
                    router.push(.settingsSection(section: .account))
                } label: {
                    HStack {
                        Text("Customize Companion")
                            .font(.subheadline.weight(.medium))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.currentTheme.accentColor.opacity(0.1))
                    )
                }
            }
            .padding()
            .gradientCard()
        }
    }

    // MARK: - About AI Section

    private var aboutAISection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About AI in InkFiction")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 16) {
                AIInfoRow(
                    icon: "lock.shield.fill",
                    title: "Private & Secure",
                    description: "Your journal data is processed securely and never shared with third parties."
                )

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                AIInfoRow(
                    icon: "cpu",
                    title: "Powered by AI",
                    description: "Advanced language models help enhance your writing and provide insights."
                )

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                AIInfoRow(
                    icon: "hand.raised.fill",
                    title: "You're in Control",
                    description: "Enable or disable AI features anytime. Your preferences are respected."
                )
            }
            .padding()
            .gradientCard()
        }
    }
}

// MARK: - AI Info Row

private struct AIInfoRow: View {
    let icon: String
    let title: String
    let description: String

    @Environment(\.themeManager) private var themeManager

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(themeManager.currentTheme.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - View Model

@MainActor
@Observable
final class AIFeaturesViewModel {
    var aiAutoEnhanceEnabled: Bool = true
    var aiAutoTitleEnabled: Bool = true
    var isLoading: Bool = false

    private let settingsRepository = SettingsRepository.shared

    func loadSettings() async {
        isLoading = true
        defer { isLoading = false }

        aiAutoEnhanceEnabled = settingsRepository.aiAutoEnhanceEnabled
        aiAutoTitleEnabled = settingsRepository.aiAutoTitleEnabled
    }

    func setAutoEnhance(_ enabled: Bool) async {
        do {
            if enabled != settingsRepository.aiAutoEnhanceEnabled {
                try await settingsRepository.toggleAIAutoEnhance()
            }
        } catch {
            Log.error("Failed to toggle AI auto-enhance", error: error, category: .settings)
            // Revert UI state on error
            aiAutoEnhanceEnabled = settingsRepository.aiAutoEnhanceEnabled
        }
    }

    func setAutoTitle(_ enabled: Bool) async {
        do {
            if enabled != settingsRepository.aiAutoTitleEnabled {
                try await settingsRepository.toggleAIAutoTitle()
            }
        } catch {
            Log.error("Failed to toggle AI auto-title", error: error, category: .settings)
            // Revert UI state on error
            aiAutoTitleEnabled = settingsRepository.aiAutoTitleEnabled
        }
    }
}

// MARK: - Preview

#Preview {
    AIFeaturesView()
        .environment(\.themeManager, ThemeManager())
        .environment(Router())
}
