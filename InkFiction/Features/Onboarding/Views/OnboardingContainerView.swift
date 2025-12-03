//
//  OnboardingContainerView.swift
//  InkFiction
//
//  Main container view for the onboarding flow with navigation
//

import SwiftUI

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.themeManager) private var themeManager

    // MARK: - Navigation Configuration State

    @State private var navigationConfig = OnboardingNavigationConfiguration.default
    @State private var heroSymbolConfig = HeroSymbolConfiguration.default

    // Total steps (excluding welcome): Quiz, Companion, Permissions = 3 steps
    private let totalSteps = 3

    // MARK: - Computed Properties

    private var currentStep: OnboardingStep {
        viewModel.currentStep
    }

    /// Current step number for progress bar (1-indexed, 0 for welcome)
    private var currentStepNumber: Int {
        switch currentStep {
        case .welcome: return 0
        case .quiz: return 1
        case .companionSelection: return 2
        case .permissions: return 3
        }
    }

    /// Whether to show back button
    private var showBackButton: Bool {
        switch currentStep {
        case .welcome: return false
        case .quiz: return true
        case .companionSelection: return true
        case .permissions: return true
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Theme-aware background
            AnimatedGradientBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation bar (hidden on welcome)
                if currentStep != .welcome {
                    OnboardingNavigationBar(
                        currentStep: currentStepNumber,
                        totalSteps: totalSteps,
                        configuration: OnboardingNavigationConfiguration(
                            showBackButton: showBackButton,
                            backAction: { viewModel.previousStep() }
                        )
                    )
                }

                // Hero Symbol (hidden on welcome)
                if currentStep != .welcome {
                    MorphSymbolView(
                        symbol: heroSymbolConfig.symbol,
                        config: .init(
                            font: .system(size: 80, weight: .bold),
                            frame: CGSize(width: 120, height: 120),
                            radius: 15,
                            foregroundColor: heroSymbolConfig.color ?? themeManager.currentTheme.accentColor,
                            keyFrameDuration: 0.4
                        )
                    )
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                }

                // Content
                Group {
                    switch currentStep {
                    case .welcome:
                        WelcomeView(viewModel: viewModel)
                    case .quiz:
                        PersonalityQuizView(viewModel: viewModel)
                    case .companionSelection:
                        AICompanionSelectionView(viewModel: viewModel)
                    case .permissions:
                        PermissionsView(viewModel: viewModel)
                    }
                }
                .onPreferenceChange(OnboardingHeroSymbolPreferenceKey.self) { newSymbolConfig in
                    heroSymbolConfig = newSymbolConfig
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}

// MARK: - Preview

#Preview {
    OnboardingContainerView()
        .environment(\.themeManager, ThemeManager())
}
