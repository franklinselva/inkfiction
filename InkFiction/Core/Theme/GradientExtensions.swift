//
//  GradientExtensions.swift
//  InkFiction
//
//  Helper extensions for commonly used gradients
//

import SwiftUI

// MARK: - Linear Gradient Extensions

extension LinearGradient {

    /// Slate gradient for buttons (used in Paper theme)
    static var slateButton: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.45, green: 0.48, blue: 0.52),  // Medium slate
                Color(red: 0.35, green: 0.38, blue: 0.42),  // Darker slate
                Color(red: 0.28, green: 0.31, blue: 0.35)   // Deep slate
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Paper background gradient for onboarding
    static var paperBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.97, blue: 0.96),
                Color(red: 0.96, green: 0.95, blue: 0.94),
                Color(red: 0.94, green: 0.93, blue: 0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Create a gradient from theme gradient colors
    static func fromTheme(_ theme: Theme, startPoint: UnitPoint = .leading, endPoint: UnitPoint = .trailing) -> LinearGradient {
        LinearGradient(
            colors: theme.gradientColors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    /// Create a gradient from theme tab bar selection colors
    static func tabBarSelection(_ theme: Theme) -> LinearGradient {
        LinearGradient(
            colors: theme.tabBarSelectionGradient,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Create a badge gradient from theme
    static func badge(_ theme: Theme) -> LinearGradient {
        LinearGradient(
            colors: theme.badgeGradient,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Subtle shimmer gradient for loading states
    static var shimmer: LinearGradient {
        LinearGradient(
            colors: [
                Color.gray.opacity(0.2),
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.2)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Angular Gradient Extensions

extension AngularGradient {

    /// Create an angular gradient from theme colors (for circular elements)
    static func fromTheme(_ theme: Theme) -> AngularGradient {
        AngularGradient(
            colors: theme.gradientColors + [theme.gradientColors.first ?? .clear],
            center: .center
        )
    }
}

// MARK: - Radial Gradient Extensions

extension RadialGradient {

    /// Create a glow effect gradient from theme
    static func glow(_ theme: Theme, intensity: Double = 1.0) -> RadialGradient {
        RadialGradient(
            colors: [
                theme.accentColor.opacity(0.6 * intensity),
                theme.accentColor.opacity(0.3 * intensity),
                theme.accentColor.opacity(0.0)
            ],
            center: .center,
            startRadius: 0,
            endRadius: 100
        )
    }

    /// Create a spotlight effect
    static func spotlight(color: Color, intensity: Double = 0.5) -> RadialGradient {
        RadialGradient(
            colors: [
                color.opacity(intensity),
                color.opacity(intensity * 0.5),
                color.opacity(0)
            ],
            center: .center,
            startRadius: 0,
            endRadius: 150
        )
    }
}

// MARK: - Color Extensions for Gradients

extension Color {

    /// Lighten a color by a percentage
    func lighter(by percentage: Double = 0.2) -> Color {
        self.opacity(1.0 - percentage)
    }

    /// Darken a color by a percentage
    func darker(by percentage: Double = 0.2) -> Color {
        // This is a simplified approach - in production you'd convert to HSB
        self.opacity(1.0 + percentage)
    }
}

// MARK: - View Extension for Gradient Backgrounds

extension View {

    /// Apply a theme gradient as background
    func themeGradientBackground(_ theme: Theme, startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> some View {
        self.background(
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: startPoint,
                endPoint: endPoint
            )
        )
    }

    /// Apply a subtle gradient overlay
    func gradientOverlay(_ theme: Theme, opacity: Double = 0.1) -> some View {
        self.overlay(
            LinearGradient(
                colors: theme.gradientColors.map { $0.opacity(opacity) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
