//
//  OnboardingNavigationBar.swift
//  InkFiction
//
//  Navigation bar with segmented progress indicator and back button for onboarding
//

import SwiftUI

// MARK: - Navigation Configuration

/// Configuration for the onboarding navigation bar
struct OnboardingNavigationConfiguration: Equatable {
    let showBackButton: Bool
    let backAction: (() -> Void)?

    static let `default` = OnboardingNavigationConfiguration(
        showBackButton: false,
        backAction: nil
    )

    static func == (lhs: OnboardingNavigationConfiguration, rhs: OnboardingNavigationConfiguration) -> Bool {
        lhs.showBackButton == rhs.showBackButton
    }
}

// MARK: - Preference Keys

struct OnboardingNavigationPreferenceKey: PreferenceKey {
    static var defaultValue = OnboardingNavigationConfiguration.default

    static func reduce(value: inout OnboardingNavigationConfiguration, nextValue: () -> OnboardingNavigationConfiguration) {
        value = nextValue()
    }
}

struct OnboardingHeroSymbolPreferenceKey: PreferenceKey {
    static var defaultValue = HeroSymbolConfiguration.default

    static func reduce(value: inout HeroSymbolConfiguration, nextValue: () -> HeroSymbolConfiguration) {
        value = nextValue()
    }
}

/// Configuration for the hero symbol
struct HeroSymbolConfiguration: Equatable {
    let symbol: String
    let color: Color?

    static let `default` = HeroSymbolConfiguration(symbol: "book.fill", color: nil)
}

// MARK: - View Extension

extension View {
    /// Configure onboarding navigation for this view
    func onboardingNavigation(showBackButton: Bool, backAction: @escaping () -> Void) -> some View {
        self.preference(
            key: OnboardingNavigationPreferenceKey.self,
            value: OnboardingNavigationConfiguration(showBackButton: showBackButton, backAction: backAction)
        )
    }

    /// Set the hero symbol for this onboarding step
    func heroSymbol(_ symbol: String, color: Color? = nil) -> some View {
        self.preference(
            key: OnboardingHeroSymbolPreferenceKey.self,
            value: HeroSymbolConfiguration(symbol: symbol, color: color)
        )
    }
}

// MARK: - Navigation Bar

struct OnboardingNavigationBar: View {
    let currentStep: Int
    let totalSteps: Int
    let configuration: OnboardingNavigationConfiguration
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        HStack(spacing: 16) {
            // Back button or spacer placeholder
            if configuration.showBackButton, let backAction = configuration.backAction {
                OnboardingBackButton(action: backAction)
            } else {
                // Maintain consistent layout when no back button
                Color.clear
                    .frame(width: 44, height: 44)
            }

            // Segmented progress bar
            OnboardingProgressBar(currentStep: currentStep, totalSteps: totalSteps)

            // Trailing spacer for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

// MARK: - Back Button

struct OnboardingBackButton: View {
    let action: () -> Void
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background circle
                Circle()
                    .fill(themeManager.currentTheme.surfaceColor)
                    .frame(width: 44, height: 44)

                // Chevron icon
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                // Gradient stroke
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: themeManager.currentTheme.tabBarSelectionGradient.map { $0.opacity(0.6) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 44, height: 44)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Go back")
        .accessibilityHint("Returns to the previous step")
    }
}

// MARK: - Segmented Progress Bar

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                StepIndicator(
                    isActive: index < currentStep,
                    isCurrent: index == currentStep - 1
                )
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Step Indicator

struct StepIndicator: View {
    let isActive: Bool
    let isCurrent: Bool
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                isActive ?
                LinearGradient(
                    colors: themeManager.currentTheme.tabBarSelectionGradient,
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [themeManager.currentTheme.strokeColor.opacity(0.5), themeManager.currentTheme.strokeColor.opacity(0.5)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 4)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isActive)
            .scaleEffect(y: isCurrent ? 1.2 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCurrent)
    }
}

// MARK: - Auto Progression Indicator

struct AutoProgressionIndicator: View {
    let duration: Double
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        ZStack {
            Circle()
                .stroke(themeManager.currentTheme.strokeColor.opacity(0.3), lineWidth: 2)
                .frame(width: 24, height: 24)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    themeManager.currentTheme.gradientOverlayTextColor,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: 24, height: 24)
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            withAnimation(.linear(duration: duration)) {
                progress = 1.0
            }
        }
    }
}
