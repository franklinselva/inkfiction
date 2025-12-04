//
//  ReflectionLoadingView.swift
//  InkFiction
//
//  Loading view for reflection generation with progress indication
//  Ported from old app's ReflectionLoadingView
//

import SwiftUI

struct ReflectionLoadingView: View {
    let progress: Double
    let currentBatch: String
    let mood: GlassmorphicMoodOrb.MoodType
    @Environment(\.themeManager) private var themeManager
    @State private var isAnimating = false

    private var currentPhrase: String {
        if progress < 0.3 {
            return "Analyzing your entries..."
        } else if progress < 0.7 {
            return "Finding patterns..."
        } else {
            return "Crafting your reflection..."
        }
    }

    var body: some View {
        let theme = themeManager.currentTheme

        VStack(spacing: 32) {
            // Animated mood icon with organic pulse
            Image(systemName: mood.icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [mood.color, mood.color.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(mood.color.opacity(0.1))
                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                        .opacity(isAnimating ? 0.2 : 0.4)
                        .animation(
                            .easeInOut(duration: 2)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                )
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(
                    .easeInOut(duration: 2.5)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )

            VStack(spacing: 20) {
                // Title with wave effect
                Text("Generating Your Reflection")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.textPrimaryColor.opacity(0.9))

                // Progress bar
                ZStack(alignment: .leading) {
                    // Background line
                    Rectangle()
                        .fill(theme.strokeColor.opacity(0.2))
                        .frame(height: 3)
                        .cornerRadius(1.5)

                    // Progress fill with mood color
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        mood.color.opacity(0.8),
                                        mood.color,
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 3)
                            .cornerRadius(1.5)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 40)

                // Dynamic status phrase
                Text(currentPhrase)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(theme.textPrimaryColor.opacity(0.6))
                    .animation(.easeInOut(duration: 0.3), value: currentPhrase)

                // Show batch info only if multiple batches
                if currentBatch.contains("of") && !currentBatch.contains("1 of 1") {
                    Text(currentBatch)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textPrimaryColor.opacity(0.4))
                        .padding(.top, 4)
                }
            }
        }
        .padding(.vertical, 20)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        ReflectionLoadingView(
            progress: 0.45,
            currentBatch: "Processing chunk 2 of 4...",
            mood: .peaceful
        )
        .environment(\.themeManager, ThemeManager())
    }
}
