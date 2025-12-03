//
//  AICompanionSelectionView.swift
//  InkFiction
//
//  AI companion selection with recommended companion highlighted
//

import SwiftUI

struct AICompanionSelectionView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.themeManager) private var themeManager
    @Environment(\.accessibilityVoiceOverEnabled) var voiceOverEnabled

    // MARK: - State

    @State private var animateCards = false
    @State private var selectedCompanion: AICompanion?
    @State private var autoProgressTimer: Timer?
    @State private var showAutoProgressOverlay = false
    @State private var isAutoProgressing = false

    // MARK: - Computed Properties

    var recommendedCompanion: AICompanion? {
        viewModel.getSuggestedCompanions().first
    }

    var allCompanions: [AICompanion] {
        var companions = AICompanion.all
        if let recommended = recommendedCompanion,
           let index = companions.firstIndex(where: { $0.id == recommended.id }) {
            companions.remove(at: index)
            companions.insert(recommended, at: 0)
        }
        return companions
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Choose Your AI Companion")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Text("Each companion offers a unique perspective on your journey")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 8)

            // Companion Cards
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(Array(allCompanions.enumerated()), id: \.element.id) { index, companion in
                        CompanionCard(
                            companion: companion,
                            isSelected: selectedCompanion?.id == companion.id,
                            isRecommended: companion.id == recommendedCompanion?.id,
                            showProgressIndicator: showAutoProgressOverlay && selectedCompanion?.id == companion.id,
                            action: {
                                selectCompanion(companion)
                            }
                        )
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(Double(index) * 0.12),
                            value: animateCards
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)

            Spacer()

            // Continue Button (VoiceOver only)
            if voiceOverEnabled {
                Button(action: {
                    if let companion = selectedCompanion {
                        viewModel.selectCompanion(companion)
                        viewModel.nextStep()
                    }
                }) {
                    HStack {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(themeManager.currentTheme.gradientOverlayTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: selectedCompanion != nil
                                ? themeManager.currentTheme.tabBarSelectionGradient
                                : [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .animation(.easeInOut(duration: 0.2), value: selectedCompanion)
                }
                .disabled(selectedCompanion == nil)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onboardingNavigation(
            showBackButton: true,
            backAction: {
                cancelAutoProgression()
                viewModel.previousStep()
            }
        )
        .heroSymbol(
            (selectedCompanion ?? recommendedCompanion)?.iconName ?? "sparkles",
            color: themeManager.currentTheme.accentColor
        )
        .onAppear {
            if selectedCompanion == nil {
                selectedCompanion = recommendedCompanion
            }
            withAnimation(.easeOut(duration: 0.4)) {
                animateCards = true
            }
        }
    }

    // MARK: - Actions

    private func selectCompanion(_ companion: AICompanion) {
        cancelAutoProgression()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedCompanion = companion
            viewModel.selectCompanion(companion)
        }

        if !voiceOverEnabled {
            startAutoProgression()
        }
    }

    // MARK: - Auto-Progression

    private func startAutoProgression() {
        withAnimation(.easeIn(duration: 0.2)) {
            showAutoProgressOverlay = true
        }

        autoProgressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            Task { @MainActor in
                if let companion = selectedCompanion {
                    viewModel.selectCompanion(companion)
                    viewModel.nextStep()
                }
            }
        }

        isAutoProgressing = true
    }

    private func cancelAutoProgression() {
        autoProgressTimer?.invalidate()
        autoProgressTimer = nil

        withAnimation(.easeOut(duration: 0.2)) {
            showAutoProgressOverlay = false
        }

        isAutoProgressing = false
    }
}
