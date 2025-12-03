//
//  Theme.swift
//  InkFiction
//
//  Theme definitions with all color and styling properties
//

import SwiftUI

// MARK: - Theme Type

/// Available theme types in the app
enum ThemeType: String, CaseIterable, Codable, Sendable {
    // Light themes
    case paper = "Paper"
    case dawn = "Dawn"
    case bloom = "Bloom"
    case sky = "Sky"
    case pearl = "Pearl"

    // Dark themes
    case sunset = "Sunset"
    case forest = "Forest"
    case aqua = "Aqua"
    case neon = "Neon"

    var isLight: Bool {
        switch self {
        case .paper, .dawn, .bloom, .sky, .pearl:
            return true
        case .sunset, .forest, .aqua, .neon:
            return false
        }
    }

    var displayName: String { rawValue }

    var modeLabel: String {
        isLight ? "Light" : "Dark"
    }
}

// MARK: - Theme

/// Complete theme definition with all colors and styling properties
struct Theme {

    // MARK: - Identity

    let type: ThemeType

    // MARK: - Core Colors

    /// 3-color gradient palette for the theme
    let gradientColors: [Color]

    /// Primary accent color
    let accentColor: Color

    /// Base background color
    let backgroundColor: Color

    // MARK: - Text Colors

    let textPrimaryColor: Color
    let textSecondaryColor: Color

    /// Always white for contrast on gradients
    var gradientOverlayTextColor: Color { .white }

    // MARK: - Glass Morphism

    let glassTint: Color
    let glassOpacity: Double
    let glassMaterial: Material
    let tabBarBackgroundOpacity: Double
    let tabBarSelectionGradient: [Color]

    // MARK: - Surface & Elevation

    let surfaceColor: Color
    let overlayColor: Color
    let shadowColor: Color
    let strokeColor: Color
    let dividerColor: Color
    let placeholderColor: Color

    // MARK: - Semantic Colors

    let successColor: Color
    let warningColor: Color
    let errorColor: Color
    let infoColor: Color
    let linkColor: Color
    let badgeGradient: [Color]

    // MARK: - Orb/3D Effects

    let orbGlowIntensity: Double
    let orbRimOpacity: Double
    let orbShadowIntensity: Double
    let orbColorBlendRatio: Double

    // MARK: - Computed Properties

    var isLight: Bool { type.isLight }

    // MARK: - Theme Factory

    /// Get theme for a specific type
    static func theme(for type: ThemeType) -> Theme {
        switch type {
        case .paper: return .paper
        case .dawn: return .dawn
        case .bloom: return .bloom
        case .sky: return .sky
        case .pearl: return .pearl
        case .sunset: return .sunset
        case .forest: return .forest
        case .aqua: return .aqua
        case .neon: return .neon
        }
    }
}

// MARK: - Light Themes

extension Theme {

    /// Paper - Default light theme with warm, elegant monochrome tones
    static let paper = Theme(
        type: .paper,
        gradientColors: [
            Color(red: 0.25, green: 0.27, blue: 0.30),  // Dark charcoal
            Color(red: 0.40, green: 0.43, blue: 0.47),  // Medium slate
            Color(red: 0.55, green: 0.58, blue: 0.62)   // Light slate
        ],
        accentColor: Color(red: 0.35, green: 0.38, blue: 0.42),
        backgroundColor: Color(red: 0.988, green: 0.98, blue: 0.96),  // Warm cream paper
        textPrimaryColor: Color(red: 0.12, green: 0.12, blue: 0.12),  // Dark ink
        textSecondaryColor: Color(red: 0.12, green: 0.12, blue: 0.12).opacity(0.6),
        glassTint: Color.gray.opacity(0.1),
        glassOpacity: 0.3,
        glassMaterial: .ultraThinMaterial,
        tabBarBackgroundOpacity: 0.85,
        tabBarSelectionGradient: [
            Color(red: 0.25, green: 0.27, blue: 0.30),
            Color(red: 0.40, green: 0.43, blue: 0.47),
            Color(red: 0.55, green: 0.58, blue: 0.62)
        ],
        surfaceColor: Color.white.opacity(0.9),
        overlayColor: Color.black.opacity(0.3),
        shadowColor: Color.black.opacity(0.1),
        strokeColor: Color.gray.opacity(0.2),
        dividerColor: Color.gray.opacity(0.15),
        placeholderColor: Color.gray.opacity(0.5),
        successColor: Color(red: 0.20, green: 0.60, blue: 0.40),
        warningColor: Color(red: 0.85, green: 0.55, blue: 0.20),
        errorColor: Color(red: 0.80, green: 0.25, blue: 0.25),
        infoColor: Color(red: 0.30, green: 0.50, blue: 0.75),
        linkColor: Color(red: 0.35, green: 0.38, blue: 0.42),
        badgeGradient: [
            Color(red: 0.35, green: 0.38, blue: 0.42),
            Color(red: 0.45, green: 0.48, blue: 0.52)
        ],
        orbGlowIntensity: 0.45,
        orbRimOpacity: 0.55,
        orbShadowIntensity: 0.18,
        orbColorBlendRatio: 0.3
    )

    /// Dawn - Warm pastel sunrise colors
    static let dawn = Theme(
        type: .dawn,
        gradientColors: [
            Color(red: 0.90, green: 0.50, blue: 0.45),  // Rich coral
            Color(red: 0.85, green: 0.40, blue: 0.55),  // Deep rose
            Color(red: 0.70, green: 0.45, blue: 0.75)   // Rich lavender
        ],
        accentColor: Color(red: 0.85, green: 0.45, blue: 0.50),
        backgroundColor: Color(red: 0.988, green: 0.98, blue: 0.97),
        textPrimaryColor: Color(red: 0.10, green: 0.10, blue: 0.10),
        textSecondaryColor: Color(red: 0.10, green: 0.10, blue: 0.10).opacity(0.6),
        glassTint: Color(red: 0.90, green: 0.50, blue: 0.45).opacity(0.1),
        glassOpacity: 0.3,
        glassMaterial: .ultraThinMaterial,
        tabBarBackgroundOpacity: 0.85,
        tabBarSelectionGradient: [
            Color(red: 0.90, green: 0.50, blue: 0.45),
            Color(red: 0.85, green: 0.40, blue: 0.55),
            Color(red: 0.70, green: 0.45, blue: 0.75)
        ],
        surfaceColor: Color.white.opacity(0.9),
        overlayColor: Color.black.opacity(0.3),
        shadowColor: Color.black.opacity(0.1),
        strokeColor: Color(red: 0.85, green: 0.45, blue: 0.50).opacity(0.2),
        dividerColor: Color.gray.opacity(0.15),
        placeholderColor: Color.gray.opacity(0.5),
        successColor: Color(red: 0.20, green: 0.60, blue: 0.40),
        warningColor: Color(red: 0.85, green: 0.55, blue: 0.20),
        errorColor: Color(red: 0.80, green: 0.25, blue: 0.25),
        infoColor: Color(red: 0.30, green: 0.50, blue: 0.75),
        linkColor: Color(red: 0.85, green: 0.45, blue: 0.50),
        badgeGradient: [
            Color(red: 0.90, green: 0.50, blue: 0.45),
            Color(red: 0.85, green: 0.40, blue: 0.55)
        ],
        orbGlowIntensity: 0.6,
        orbRimOpacity: 0.7,
        orbShadowIntensity: 0.2,
        orbColorBlendRatio: 0.35
    )

    /// Bloom - Natural botanical colors
    static let bloom = Theme(
        type: .bloom,
        gradientColors: [
            Color(red: 0.45, green: 0.65, blue: 0.50),  // Rich sage green
            Color(red: 0.85, green: 0.45, blue: 0.55),  // Deep pink
            Color(red: 0.95, green: 0.60, blue: 0.45)   // Rich apricot
        ],
        accentColor: Color(red: 0.45, green: 0.65, blue: 0.50),
        backgroundColor: Color(red: 0.988, green: 0.98, blue: 0.97),
        textPrimaryColor: Color(red: 0.08, green: 0.08, blue: 0.08),
        textSecondaryColor: Color(red: 0.08, green: 0.08, blue: 0.08).opacity(0.6),
        glassTint: Color(red: 0.45, green: 0.65, blue: 0.50).opacity(0.1),
        glassOpacity: 0.3,
        glassMaterial: .ultraThinMaterial,
        tabBarBackgroundOpacity: 0.85,
        tabBarSelectionGradient: [
            Color(red: 0.45, green: 0.65, blue: 0.50),
            Color(red: 0.85, green: 0.45, blue: 0.55),
            Color(red: 0.95, green: 0.60, blue: 0.45)
        ],
        surfaceColor: Color.white.opacity(0.9),
        overlayColor: Color.black.opacity(0.3),
        shadowColor: Color.black.opacity(0.1),
        strokeColor: Color(red: 0.45, green: 0.65, blue: 0.50).opacity(0.2),
        dividerColor: Color.gray.opacity(0.15),
        placeholderColor: Color.gray.opacity(0.5),
        successColor: Color(red: 0.20, green: 0.60, blue: 0.40),
        warningColor: Color(red: 0.85, green: 0.55, blue: 0.20),
        errorColor: Color(red: 0.80, green: 0.25, blue: 0.25),
        infoColor: Color(red: 0.30, green: 0.50, blue: 0.75),
        linkColor: Color(red: 0.45, green: 0.65, blue: 0.50),
        badgeGradient: [
            Color(red: 0.45, green: 0.65, blue: 0.50),
            Color(red: 0.85, green: 0.45, blue: 0.55)
        ],
        orbGlowIntensity: 0.6,
        orbRimOpacity: 0.7,
        orbShadowIntensity: 0.2,
        orbColorBlendRatio: 0.35
    )

    /// Sky - Fresh blue sky colors
    static let sky = Theme(
        type: .sky,
        gradientColors: [
            Color(red: 0.35, green: 0.60, blue: 0.90),  // Rich sky blue
            Color(red: 0.30, green: 0.55, blue: 0.95),  // Bright blue
            Color(red: 0.25, green: 0.65, blue: 0.85)   // Azure
        ],
        accentColor: Color(red: 0.30, green: 0.55, blue: 0.90),
        backgroundColor: Color.white,
        textPrimaryColor: Color(red: 0.10, green: 0.10, blue: 0.10),
        textSecondaryColor: Color(red: 0.10, green: 0.10, blue: 0.10).opacity(0.6),
        glassTint: Color(red: 0.30, green: 0.55, blue: 0.90).opacity(0.1),
        glassOpacity: 0.3,
        glassMaterial: .ultraThinMaterial,
        tabBarBackgroundOpacity: 0.85,
        tabBarSelectionGradient: [
            Color(red: 0.35, green: 0.60, blue: 0.90),
            Color(red: 0.30, green: 0.55, blue: 0.95),
            Color(red: 0.25, green: 0.65, blue: 0.85)
        ],
        surfaceColor: Color.white.opacity(0.9),
        overlayColor: Color.black.opacity(0.3),
        shadowColor: Color.black.opacity(0.1),
        strokeColor: Color(red: 0.30, green: 0.55, blue: 0.90).opacity(0.2),
        dividerColor: Color.gray.opacity(0.15),
        placeholderColor: Color.gray.opacity(0.5),
        successColor: Color(red: 0.20, green: 0.60, blue: 0.40),
        warningColor: Color(red: 0.85, green: 0.55, blue: 0.20),
        errorColor: Color(red: 0.80, green: 0.25, blue: 0.25),
        infoColor: Color(red: 0.30, green: 0.55, blue: 0.90),
        linkColor: Color(red: 0.30, green: 0.55, blue: 0.90),
        badgeGradient: [
            Color(red: 0.35, green: 0.60, blue: 0.90),
            Color(red: 0.30, green: 0.55, blue: 0.95)
        ],
        orbGlowIntensity: 0.6,
        orbRimOpacity: 0.7,
        orbShadowIntensity: 0.2,
        orbColorBlendRatio: 0.35
    )

    /// Pearl - Warm elegant earthy metallics
    static let pearl = Theme(
        type: .pearl,
        gradientColors: [
            Color(red: 0.55, green: 0.45, blue: 0.35),  // Rich warm brown
            Color(red: 0.75, green: 0.65, blue: 0.50),  // Golden pearl
            Color(red: 0.85, green: 0.75, blue: 0.60)   // Warm champagne
        ],
        accentColor: Color(red: 0.65, green: 0.55, blue: 0.42),
        backgroundColor: Color(red: 0.988, green: 0.98, blue: 0.97),
        textPrimaryColor: Color(red: 0.08, green: 0.08, blue: 0.08),
        textSecondaryColor: Color(red: 0.08, green: 0.08, blue: 0.08).opacity(0.6),
        glassTint: Color(red: 0.65, green: 0.55, blue: 0.42).opacity(0.1),
        glassOpacity: 0.25,
        glassMaterial: .ultraThinMaterial,
        tabBarBackgroundOpacity: 0.85,
        tabBarSelectionGradient: [
            Color(red: 0.55, green: 0.45, blue: 0.35),
            Color(red: 0.75, green: 0.65, blue: 0.50),
            Color(red: 0.85, green: 0.75, blue: 0.60)
        ],
        surfaceColor: Color.white.opacity(0.9),
        overlayColor: Color.black.opacity(0.3),
        shadowColor: Color.black.opacity(0.1),
        strokeColor: Color(red: 0.65, green: 0.55, blue: 0.42).opacity(0.2),
        dividerColor: Color.gray.opacity(0.15),
        placeholderColor: Color.gray.opacity(0.5),
        successColor: Color(red: 0.20, green: 0.60, blue: 0.40),
        warningColor: Color(red: 0.85, green: 0.55, blue: 0.20),
        errorColor: Color(red: 0.80, green: 0.25, blue: 0.25),
        infoColor: Color(red: 0.30, green: 0.50, blue: 0.75),
        linkColor: Color(red: 0.65, green: 0.55, blue: 0.42),
        badgeGradient: [
            Color(red: 0.55, green: 0.45, blue: 0.35),
            Color(red: 0.75, green: 0.65, blue: 0.50)
        ],
        orbGlowIntensity: 0.5,
        orbRimOpacity: 0.6,
        orbShadowIntensity: 0.15,
        orbColorBlendRatio: 0.3
    )
}

// MARK: - Dark Themes

extension Theme {

    /// Sunset - Warm vibrant sunset colors (default dark)
    static let sunset = Theme(
        type: .sunset,
        gradientColors: [
            Color(red: 0.95, green: 0.55, blue: 0.30),  // Orange
            Color(red: 0.90, green: 0.40, blue: 0.50),  // Pink
            Color(red: 0.65, green: 0.35, blue: 0.70)   // Purple
        ],
        accentColor: Color(red: 0.95, green: 0.55, blue: 0.40),
        backgroundColor: Color(red: 0.05, green: 0.05, blue: 0.05),
        textPrimaryColor: Color.white,
        textSecondaryColor: Color.white.opacity(0.7),
        glassTint: Color(red: 0.95, green: 0.55, blue: 0.40).opacity(0.15),
        glassOpacity: 0.7,
        glassMaterial: .regularMaterial,
        tabBarBackgroundOpacity: 0.9,
        tabBarSelectionGradient: [
            Color(red: 0.95, green: 0.55, blue: 0.30),
            Color(red: 0.90, green: 0.40, blue: 0.50),
            Color(red: 0.65, green: 0.35, blue: 0.70)
        ],
        surfaceColor: Color.white.opacity(0.08),
        overlayColor: Color.black.opacity(0.5),
        shadowColor: Color.black.opacity(0.3),
        strokeColor: Color.white.opacity(0.15),
        dividerColor: Color.white.opacity(0.1),
        placeholderColor: Color.white.opacity(0.4),
        successColor: Color(red: 0.30, green: 0.75, blue: 0.50),
        warningColor: Color(red: 0.95, green: 0.70, blue: 0.30),
        errorColor: Color(red: 0.95, green: 0.40, blue: 0.40),
        infoColor: Color(red: 0.45, green: 0.65, blue: 0.90),
        linkColor: Color(red: 0.95, green: 0.55, blue: 0.40),
        badgeGradient: [
            Color(red: 0.95, green: 0.55, blue: 0.30),
            Color(red: 0.90, green: 0.40, blue: 0.50)
        ],
        orbGlowIntensity: 0.7,
        orbRimOpacity: 0.8,
        orbShadowIntensity: 0.4,
        orbColorBlendRatio: 0.4
    )

    /// Forest - Natural calming green tones
    static let forest = Theme(
        type: .forest,
        gradientColors: [
            Color(red: 0.25, green: 0.45, blue: 0.30),  // Deep sage green
            Color(red: 0.35, green: 0.55, blue: 0.40),  // Medium sage
            Color(red: 0.45, green: 0.65, blue: 0.50)   // Light sage
        ],
        accentColor: Color(red: 0.40, green: 0.60, blue: 0.45),
        backgroundColor: Color(red: 0.02, green: 0.03, blue: 0.02),
        textPrimaryColor: Color.white,
        textSecondaryColor: Color.white.opacity(0.7),
        glassTint: Color(red: 0.35, green: 0.55, blue: 0.40).opacity(0.15),
        glassOpacity: 0.75,
        glassMaterial: .regularMaterial,
        tabBarBackgroundOpacity: 0.9,
        tabBarSelectionGradient: [
            Color(red: 0.25, green: 0.45, blue: 0.30),
            Color(red: 0.35, green: 0.55, blue: 0.40),
            Color(red: 0.45, green: 0.65, blue: 0.50)
        ],
        surfaceColor: Color.white.opacity(0.08),
        overlayColor: Color.black.opacity(0.5),
        shadowColor: Color.black.opacity(0.3),
        strokeColor: Color.white.opacity(0.15),
        dividerColor: Color.white.opacity(0.1),
        placeholderColor: Color.white.opacity(0.4),
        successColor: Color(red: 0.40, green: 0.75, blue: 0.50),
        warningColor: Color(red: 0.95, green: 0.70, blue: 0.30),
        errorColor: Color(red: 0.95, green: 0.40, blue: 0.40),
        infoColor: Color(red: 0.45, green: 0.65, blue: 0.90),
        linkColor: Color(red: 0.40, green: 0.60, blue: 0.45),
        badgeGradient: [
            Color(red: 0.25, green: 0.45, blue: 0.30),
            Color(red: 0.35, green: 0.55, blue: 0.40)
        ],
        orbGlowIntensity: 0.8,
        orbRimOpacity: 0.9,
        orbShadowIntensity: 0.5,
        orbColorBlendRatio: 0.45
    )

    /// Aqua - Cool calming water/ocean colors
    static let aqua = Theme(
        type: .aqua,
        gradientColors: [
            Color(red: 0.20, green: 0.80, blue: 0.85),  // Cyan
            Color(red: 0.25, green: 0.55, blue: 0.90),  // Blue
            Color(red: 0.30, green: 0.40, blue: 0.80)   // Deep blue
        ],
        accentColor: Color(red: 0.25, green: 0.70, blue: 0.85),
        backgroundColor: Color(red: 0.02, green: 0.05, blue: 0.08),
        textPrimaryColor: Color.white,
        textSecondaryColor: Color.white.opacity(0.7),
        glassTint: Color(red: 0.20, green: 0.70, blue: 0.80).opacity(0.15),
        glassOpacity: 0.65,
        glassMaterial: .ultraThinMaterial,
        tabBarBackgroundOpacity: 0.9,
        tabBarSelectionGradient: [
            Color(red: 0.20, green: 0.80, blue: 0.85),
            Color(red: 0.25, green: 0.55, blue: 0.90),
            Color(red: 0.30, green: 0.40, blue: 0.80)
        ],
        surfaceColor: Color.white.opacity(0.08),
        overlayColor: Color.black.opacity(0.5),
        shadowColor: Color.black.opacity(0.3),
        strokeColor: Color.white.opacity(0.15),
        dividerColor: Color.white.opacity(0.1),
        placeholderColor: Color.white.opacity(0.4),
        successColor: Color(red: 0.30, green: 0.80, blue: 0.60),
        warningColor: Color(red: 0.95, green: 0.70, blue: 0.30),
        errorColor: Color(red: 0.95, green: 0.40, blue: 0.40),
        infoColor: Color(red: 0.25, green: 0.70, blue: 0.85),
        linkColor: Color(red: 0.25, green: 0.70, blue: 0.85),
        badgeGradient: [
            Color(red: 0.20, green: 0.80, blue: 0.85),
            Color(red: 0.25, green: 0.55, blue: 0.90)
        ],
        orbGlowIntensity: 0.75,
        orbRimOpacity: 0.85,
        orbShadowIntensity: 0.35,
        orbColorBlendRatio: 0.4
    )

    /// Neon - Vibrant high-contrast electric colors
    static let neon = Theme(
        type: .neon,
        gradientColors: [
            Color(red: 1.0, green: 0.20, blue: 0.60),   // Hot pink
            Color(red: 0.70, green: 0.20, blue: 0.90),  // Electric purple
            Color(red: 0.20, green: 0.90, blue: 0.90)   // Neon cyan
        ],
        accentColor: Color(red: 1.0, green: 0.30, blue: 0.65),
        backgroundColor: Color.black,
        textPrimaryColor: Color.white,
        textSecondaryColor: Color.white.opacity(0.8),
        glassTint: Color(red: 0.70, green: 0.20, blue: 0.70).opacity(0.2),
        glassOpacity: 0.8,
        glassMaterial: .thickMaterial,
        tabBarBackgroundOpacity: 0.95,
        tabBarSelectionGradient: [
            Color(red: 1.0, green: 0.20, blue: 0.60),
            Color(red: 0.70, green: 0.20, blue: 0.90),
            Color(red: 0.20, green: 0.90, blue: 0.90)
        ],
        surfaceColor: Color.white.opacity(0.1),
        overlayColor: Color.black.opacity(0.6),
        shadowColor: Color.black.opacity(0.4),
        strokeColor: Color.white.opacity(0.2),
        dividerColor: Color.white.opacity(0.15),
        placeholderColor: Color.white.opacity(0.5),
        successColor: Color(red: 0.20, green: 0.95, blue: 0.60),
        warningColor: Color(red: 1.0, green: 0.80, blue: 0.20),
        errorColor: Color(red: 1.0, green: 0.30, blue: 0.30),
        infoColor: Color(red: 0.20, green: 0.90, blue: 0.90),
        linkColor: Color(red: 1.0, green: 0.30, blue: 0.65),
        badgeGradient: [
            Color(red: 1.0, green: 0.20, blue: 0.60),
            Color(red: 0.70, green: 0.20, blue: 0.90)
        ],
        orbGlowIntensity: 0.9,
        orbRimOpacity: 1.0,
        orbShadowIntensity: 0.6,
        orbColorBlendRatio: 0.5
    )
}
