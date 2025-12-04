//
//  MoodReflectionView.swift
//  InkFiction
//
//  View for displaying AI-generated mood reflections
//  Ported from old app's MoodReflectionView
//

import SwiftUI

struct MoodReflectionView: View {
    let moodData: OrganicMoodOrbCluster.MoodOrbData
    let timeframe: TimeFrame
    @State private var reflectionService = MoodReflectionService()
    @Environment(\.subscriptionService) private var subscriptionService
    @State private var reflection: MoodReflection?
    @State private var selectedDepth: ReflectionDepth = .standard
    @State private var hasStartedLoading = false
    @State private var showUpgradeSheet = false
    @Environment(\.themeManager) private var themeManager

    // Computed properties for subscription checks
    private var canAccessAIReflections: Bool {
        subscriptionService.limits.hasAIReflections
    }

    private var canAccessAdvancedAI: Bool {
        subscriptionService.limits.hasAdvancedAI
    }

    var body: some View {
        let theme = themeManager.currentTheme

        VStack(spacing: 0) {
            // Key Insight section (above AI Reflection heading)
            if let reflection = reflection, !reflection.keyInsight.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(theme.accentColor)
                            .frame(width: 3)
                            .cornerRadius(1.5)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.accentColor)
                                Text("Key Insight")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(theme.textPrimaryColor.opacity(0.6))
                            }

                            Text(reflection.keyInsight)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.textPrimaryColor.opacity(0.95))
                                .italic()
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(3)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.bottom, 24)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(
                            with: .move(edge: .top).combined(with: .scale(scale: 0.95))),
                        removal: .opacity
                    ))
            }

            // Section header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(theme.textPrimaryColor.opacity(0.6))
                Text("AI Reflection")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(theme.textPrimaryColor.opacity(0.9))
                Spacer()
            }
            .padding(.bottom, 16)

            // Content area with smooth transitions
            ZStack {
                if !canAccessAIReflections {
                    // Upgrade prompt for free tier users
                    UpgradePromptView(
                        currentTier: subscriptionService.currentTier,
                        onUpgrade: { showUpgradeSheet = true }
                    )
                    .transition(.opacity)
                } else if !hasStartedLoading {
                    // Initial state before loading starts
                    ProgressView()
                        .progressViewStyle(
                            CircularProgressViewStyle(
                                tint: theme.textPrimaryColor)
                        )
                        .scaleEffect(1.2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else if reflectionService.isProcessing {
                    ReflectionLoadingView(
                        progress: reflectionService.processingProgress,
                        currentBatch: reflectionService.currentBatch,
                        mood: moodData.mood
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else if let reflection = reflection {
                    VStack(spacing: 24) {
                        // Main reflection content
                        ReflectionContentView(reflection: reflection)

                        // Divider
                        Rectangle()
                            .fill(theme.strokeColor.opacity(0.15))
                            .frame(height: 1)

                        // Themes
                        if !reflection.themes.isEmpty {
                            CleanThemesView(themes: reflection.themes)
                        }

                        // Emotional Progression
                        if !reflection.emotionalProgression.isEmpty {
                            Rectangle()
                                .fill(theme.strokeColor.opacity(0.15))
                                .frame(height: 1)

                            CleanEmotionalProgressionView(
                                progression: reflection.emotionalProgression
                            )
                        }
                    }
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(
                                with: .move(edge: .top).combined(with: .scale(scale: 0.95))),
                            removal: .opacity
                        ))
                } else if let error = reflectionService.error {
                    ErrorView(error: error, onRetry: loadReflection)
                        .transition(.opacity)
                }
            }
            .animation(
                .spring(response: 0.6, dampingFraction: 0.85, blendDuration: 0.3),
                value: reflection != nil
            )
            .animation(
                .spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2),
                value: reflectionService.isProcessing
            )
            .animation(
                .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2),
                value: hasStartedLoading)
        }
        .task {
            // Only generate reflection if user has access to AI reflections
            if canAccessAIReflections {
                hasStartedLoading = true
                await loadReflection()
            }
        }
        .sheet(isPresented: $showUpgradeSheet) {
            PaywallView(context: .featureLimitHit)
        }
    }

    // MARK: - Actions

    @MainActor
    private func loadReflection() async {
        do {
            // Determine appropriate depth based on subscription tier
            let reflectionDepth: ReflectionDepth =
                canAccessAdvancedAI ? selectedDepth : .standard

            let generatedReflection = try await reflectionService.generateMoodReflection(
                mood: Mood(from: moodData.mood),
                entries: moodData.entries,
                timeframe: timeframe,
                depth: reflectionDepth
            )

            withAnimation(.spring(response: 0.6, dampingFraction: 0.85, blendDuration: 0.3)) {
                reflection = generatedReflection
            }
        } catch {
            Log.error("Failed to generate reflection: \(error)", category: .ai)
        }
    }
}

// MARK: - Reflection Content View

private struct ReflectionContentView: View {
    let reflection: MoodReflection
    @Environment(\.themeManager) private var themeManager
    @State private var showFullText = false

    var body: some View {
        let theme = themeManager.currentTheme

        VStack(alignment: .leading, spacing: 16) {
            Text(reflection.summary)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(theme.textPrimaryColor.opacity(0.9))
                .lineLimit(showFullText ? nil : 8)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showFullText)

            if reflection.summary.count > 300 {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showFullText.toggle()
                    }
                }) {
                    Text(showFullText ? "Show Less" : "Read More")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.accentColor)
                }
            }
        }
    }
}

// MARK: - Clean Themes View

private struct CleanThemesView: View {
    let themes: [String]
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        let theme = themeManager.currentTheme

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "tag")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textPrimaryColor.opacity(0.6))
                Text("Key Themes")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textPrimaryColor.opacity(0.9))
            }

            FlowLayout(spacing: 10) {
                ForEach(themes, id: \.self) { themeText in
                    Text(themeText)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.textPrimaryColor.opacity(0.9))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(theme.surfaceColor)
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            theme.accentColor.opacity(0.3),
                                            theme.accentColor.opacity(0.1),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(
                            color: theme.shadowColor.opacity(0.2),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                }
            }
        }
    }
}

// MARK: - Clean Emotional Progression View

private struct CleanEmotionalProgressionView: View {
    let progression: String
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        let theme = themeManager.currentTheme

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textPrimaryColor.opacity(0.6))
                Text("Emotional Journey")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textPrimaryColor.opacity(0.9))
            }

            Text(progression)
                .font(.system(size: 16))
                .foregroundColor(theme.textPrimaryColor.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let error: ReflectionError
    let onRetry: () async -> Void
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        let theme = themeManager.currentTheme

        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text(error.localizedDescription)
                .font(.headline)
                .foregroundColor(theme.textPrimaryColor)
                .multilineTextAlignment(.center)

            Text(error.fallbackStrategy)
                .font(.subheadline)
                .foregroundColor(theme.textSecondaryColor)
                .multilineTextAlignment(.center)

            Button(action: {
                Task {
                    await onRetry()
                }
            }) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(theme.accentColor)
                    )
            }
        }
        .padding(24)
    }
}

// MARK: - Upgrade Prompt View

private struct UpgradePromptView: View {
    let currentTier: SubscriptionTier
    let onUpgrade: () -> Void
    @Environment(\.themeManager) private var themeManager

    // Get Enhanced tier data from SubscriptionPolicy
    private var enhancedTier: SubscriptionTier { .enhanced }
    private var enhancedLimits: SubscriptionPolicy.TierLimits { enhancedTier.limits }

    var body: some View {
        let theme = themeManager.currentTheme

        VStack(spacing: 20) {
            // Lock icon
            ZStack {
                Circle()
                    .fill(theme.accentColor.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "lock.fill")
                    .font(.system(size: 36))
                    .foregroundColor(theme.accentColor)
            }

            // Title and description
            VStack(spacing: 8) {
                Text("AI Reflections Locked")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(theme.textPrimaryColor)

                Text(SubscriptionPolicy.upgradeMessage(from: currentTier, context: .generic))
                    .font(.system(size: 15))
                    .foregroundColor(theme.textSecondaryColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)

            // Upgrade button with Enhanced tier branding
            Button(action: onUpgrade) {
                HStack(spacing: 8) {
                    Image(systemName: enhancedLimits.badgeIcon)
                        .font(.system(size: 14))
                    Text("Upgrade to \(enhancedLimits.displayName)")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    enhancedTier.gradient()
                        .clipShape(Capsule())
                )
                .shadow(
                    color: enhancedTier.primaryGradientColor.opacity(0.3),
                    radius: 10,
                    y: 5
                )
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Flow Layout Helper

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (subview, frame) in zip(subviews, result.frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.origin.x, y: bounds.minY + frame.origin.y),
                proposal: .init(frame.size)
            )
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let viewSize = subview.sizeThatFits(.unspecified)

                if currentX + viewSize.width > maxWidth, currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: viewSize))
                lineHeight = max(lineHeight, viewSize.height)
                currentX += viewSize.width + spacing
            }

            size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Helper Extensions

extension Mood {
    init(from orbMood: GlassmorphicMoodOrb.MoodType) {
        switch orbMood {
        case .peaceful: self = .peaceful
        case .excited: self = .excited
        case .anxious: self = .anxious
        case .happy: self = .happy
        case .reflective: self = .thoughtful
        case .grateful: self = .happy
        case .sad: self = .sad
        case .angry: self = .angry
        case .neutral: self = .neutral
        }
    }
}

// MARK: - Preview

#Preview {
    MoodReflectionView(
        moodData: OrganicMoodOrbCluster.MoodOrbData(
            id: UUID(),
            mood: .peaceful,
            entryCount: 5,
            lastUpdated: Date(),
            entries: []
        ),
        timeframe: .thisWeek
    )
    .environment(\.themeManager, ThemeManager())
}
