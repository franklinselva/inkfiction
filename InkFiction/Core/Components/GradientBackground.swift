//
//  GradientBackground.swift
//  InkFiction
//
//  Animated gradient background components
//

import SwiftUI

// MARK: - Standard Gradient Background

struct GradientBackground: View {
    let colors: [Color]
    var opacity: Double = 0.5
    var startPoint: UnitPoint = .topLeading
    var endPoint: UnitPoint = .bottomTrailing

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: startPoint,
            endPoint: endPoint
        )
        .opacity(opacity)
        .ignoresSafeArea()
    }
}

// MARK: - Animated Gradient Background with Frosted Glass

struct AnimatedGradientBackground: View {
    @Environment(\.themeManager) private var themeManager

    // Animation states for smooth, slow gradient movement
    @State private var gradientOffset: CGFloat = 0
    @State private var gradientRotation: Double = 0
    @State private var pulseOpacity: Double = 0.3

    var body: some View {
        let theme = themeManager.currentTheme

        ZStack {
            // Base background layer
            LinearGradient(
                colors: [
                    theme.backgroundColor,
                    theme.gradientColors.first?.opacity(0.3) ?? theme.backgroundColor,
                    theme.backgroundColor
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Animated gradient layer
            animatedGradientLayer(theme: theme)
                .ignoresSafeArea()
        }
        .onAppear {
            startAnimations(theme: theme)
        }
    }

    // MARK: - Animated Gradient Layer

    private func animatedGradientLayer(theme: Theme) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Primary gradient with slow movement
                LinearGradient(
                    colors: theme.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .scaleEffect(2.2)
                .rotationEffect(.degrees(gradientRotation))
                .offset(x: gradientOffset, y: gradientOffset * 0.5)
                .opacity(theme.isLight ? pulseOpacity * 0.3 : pulseOpacity)

                // Secondary gradient for depth (moves in opposite direction)
                LinearGradient(
                    colors: theme.gradientColors.reversed(),
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
                .scaleEffect(2.2)
                .rotationEffect(.degrees(-gradientRotation * 0.5))
                .offset(x: -gradientOffset * 0.7, y: -gradientOffset * 0.3)
                .opacity(theme.isLight ? pulseOpacity * 0.15 : pulseOpacity * 0.6)
                .blendMode(.softLight)

                // Tertiary gradient for additional complexity
                RadialGradient(
                    colors: [
                        theme.accentColor.opacity(0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: geometry.size.width
                )
                .scaleEffect(1.8)
                .offset(x: gradientOffset * 0.3, y: -gradientOffset * 0.2)
                .opacity(theme.isLight ? pulseOpacity * 0.1 : pulseOpacity * 0.4)
            }
            .padding(-120)
        }
    }

    // MARK: - Animation Control

    private func startAnimations(theme: Theme) {
        // Main gradient movement animation (25 seconds cycle)
        withAnimation(.easeInOut(duration: 25).repeatForever(autoreverses: true)) {
            gradientOffset = 50
        }

        // Rotation animation (30 seconds cycle)
        withAnimation(.easeInOut(duration: 30).repeatForever(autoreverses: true)) {
            gradientRotation = 15
        }

        // Gentle opacity pulse (20 seconds cycle)
        withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
            pulseOpacity = 0.35
        }

        Log.debug("Gradient animations started for theme: \(theme.type.rawValue)", category: .ui)
    }
}

// MARK: - Enhanced Gradient Card with Glass Effect

struct GradientCard: ViewModifier {
    @Environment(\.themeManager) private var themeManager
    var useGlassEffect: Bool = true

    func body(content: Content) -> some View {
        let theme = themeManager.currentTheme

        content
            .background(
                ZStack {
                    // Base gradient fill
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: theme.gradientColors.map { $0.opacity(0.15) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Glass effect overlay if enabled
                    if useGlassEffect {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .opacity(0.3)
                    }

                    // Border with gradient
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: theme.gradientColors.map { $0.opacity(0.3) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
    }
}

// MARK: - Static Glass Overlay Component

struct GlassOverlay: View {
    @Environment(\.themeManager) private var themeManager
    var cornerRadius: CGFloat = 0
    var material: Material? = nil

    var body: some View {
        let theme = themeManager.currentTheme

        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(material ?? theme.glassMaterial)
            .opacity(theme.glassOpacity)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(theme.glassTint)
            )
    }
}

// MARK: - View Extensions

extension View {
    func gradientCard(useGlassEffect: Bool = true) -> some View {
        modifier(GradientCard(useGlassEffect: useGlassEffect))
    }

    func glassOverlay(cornerRadius: CGFloat = 0, material: Material? = nil) -> some View {
        overlay(
            GlassOverlay(cornerRadius: cornerRadius, material: material)
        )
    }
}

// MARK: - Preview

#Preview {
    AnimatedGradientBackground()
        .environment(\.themeManager, ThemeManager())
}
