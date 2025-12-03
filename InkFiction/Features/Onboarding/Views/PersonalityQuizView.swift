//
//  PersonalityQuizView.swift
//  InkFiction
//
//  Personality quiz with 3 questions to determine AI companion suggestion
//

import SwiftUI

// MARK: - Quiz Models

struct QuizQuestion {
    let id: String
    let question: String
    let answers: [QuizOption]
}

struct QuizOption: Identifiable {
    let id: String
    let text: String
    let icon: String
    let unselectedIcon: String
}

// MARK: - PersonalityQuizView

struct PersonalityQuizView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.themeManager) private var themeManager
    @Environment(\.accessibilityVoiceOverEnabled) var voiceOverEnabled

    // MARK: - State

    @State private var currentQuestionIndex = 0
    @State private var selectedAnswers: [String: String] = [:]
    @State private var animateCards = false
    @State private var autoProgressTimer: Timer?
    @State private var showAutoProgressIndicator = false
    @State private var isAutoProgressing = false

    // MARK: - Questions

    let questions: [QuizQuestion] = [
        QuizQuestion(
            id: "journaling_style",
            question: "How do you prefer to capture your thoughts?",
            answers: JournalingStyle.allCases.map { style in
                QuizOption(id: style.rawValue, text: style.displayName, icon: style.icon, unselectedIcon: style.unselectedIcon)
            }
        ),
        QuizQuestion(
            id: "emotional_expression",
            question: "What helps you process emotions best?",
            answers: EmotionalExpression.allCases.map { expression in
                QuizOption(id: expression.rawValue, text: expression.displayName, icon: expression.icon, unselectedIcon: expression.unselectedIcon)
            }
        ),
        QuizQuestion(
            id: "visual_preference",
            question: "What art style resonates with you?",
            answers: VisualPreference.allCases.map { preference in
                QuizOption(id: preference.rawValue, text: preference.displayName, icon: preference.icon, unselectedIcon: preference.unselectedIcon)
            }
        )
    ]

    var currentQuestion: QuizQuestion {
        questions[currentQuestionIndex]
    }

    var canProceed: Bool {
        selectedAnswers.count == questions.count
    }

    var currentQuestionIcon: String {
        switch currentQuestionIndex {
        case 0: return "pencil.and.list.clipboard"
        case 1: return "heart.text.square.fill"
        case 2: return "paintpalette.fill"
        default: return "questionmark.circle.fill"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Personality Discovery")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
            }
            .padding(.top, 8)

            // Question
            Text(currentQuestion.question)
                .font(.system(size: 22))
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 40)
                .padding(.bottom, 32)

            // Answer Options
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(currentQuestion.answers.enumerated()), id: \.element.id) { index, option in
                        QuizOptionCard(
                            option: option,
                            isSelected: selectedAnswers[currentQuestion.id] == option.id,
                            showProgressIndicator: showAutoProgressIndicator && selectedAnswers[currentQuestion.id] == option.id,
                            action: {
                                selectAnswer(option)
                            }
                        )
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1),
                            value: animateCards
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)

            Spacer()

            // Navigation Button (VoiceOver only)
            if voiceOverEnabled {
                Button(action: nextAction) {
                    HStack {
                        Text(currentQuestionIndex < questions.count - 1 ? "Next" : "Continue")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                        if currentQuestionIndex == questions.count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: selectedAnswers[currentQuestion.id] != nil
                                ? themeManager.currentTheme.tabBarSelectionGradient
                                : [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(selectedAnswers[currentQuestion.id] == nil)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onboardingNavigation(
            showBackButton: currentQuestionIndex > 0,
            backAction: previousQuestion
        )
        .heroSymbol(currentQuestionIcon, color: themeManager.currentTheme.accentColor)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                animateCards = true
            }
        }
        .onChange(of: currentQuestionIndex) { _, _ in
            animateCards = false
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                animateCards = true
            }
        }
    }

    // MARK: - Actions

    private func selectAnswer(_ option: QuizOption) {
        cancelAutoProgression()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedAnswers[currentQuestion.id] = option.id
        }

        viewModel.answerQuizQuestion(
            questionId: currentQuestion.id,
            answerId: option.id,
            answerText: option.text
        )

        if !voiceOverEnabled {
            startAutoProgression()
        }
    }

    private func nextAction() {
        if currentQuestionIndex < questions.count - 1 {
            withAnimation {
                currentQuestionIndex += 1
            }
        } else if canProceed {
            viewModel.nextStep()
        }
    }

    private func previousQuestion() {
        cancelAutoProgression()
        withAnimation {
            currentQuestionIndex = max(0, currentQuestionIndex - 1)
        }
    }

    // MARK: - Auto-Progression

    private func startAutoProgression() {
        withAnimation(.easeIn(duration: 0.2)) {
            showAutoProgressIndicator = true
        }

        autoProgressTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
            Task { @MainActor in
                nextAction()
            }
        }

        isAutoProgressing = true
    }

    private func cancelAutoProgression() {
        autoProgressTimer?.invalidate()
        autoProgressTimer = nil

        withAnimation(.easeOut(duration: 0.2)) {
            showAutoProgressIndicator = false
        }

        isAutoProgressing = false
    }
}

// MARK: - Quiz Option Card

struct QuizOptionCard: View {
    let option: QuizOption
    let isSelected: Bool
    let showProgressIndicator: Bool
    let action: () -> Void
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon with morphing animation
                Image(systemName: isSelected ? option.icon : option.unselectedIcon)
                    .font(.system(size: 24))
                    .symbolRenderingMode(.hierarchical)
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundColor(isSelected ? themeManager.currentTheme.gradientOverlayTextColor : themeManager.currentTheme.textPrimaryColor)
                    .frame(width: 40)

                Text(option.text)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? themeManager.currentTheme.gradientOverlayTextColor : themeManager.currentTheme.textPrimaryColor)

                Spacer()

                // Checkmark or progress indicator
                if isSelected {
                    if showProgressIndicator {
                        AutoProgressionIndicator(duration: 0.8) {}
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.currentTheme.gradientOverlayTextColor)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: themeManager.currentTheme.tabBarSelectionGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        themeManager.currentTheme.surfaceColor
                    }
                }
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected
                            ? Color.clear
                            : themeManager.currentTheme.strokeColor.opacity(0.5),
                        lineWidth: 1.5
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        .accessibilityLabel(option.text)
        .accessibilityHint(isSelected ? "Selected" : "Tap to select")
    }
}
