//
//  AICompanion.swift
//  InkFiction
//
//  AI companion definitions with personality traits and visual styles
//

import Foundation
import SwiftUI

// MARK: - AI Companion

/// An AI companion that guides the user's journaling experience
struct AICompanion: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let tagline: String
    let description: String
    let summaryStyle: String
    let visualStyle: String
    let signatureStyle: String
    let signatureDescription: String
    let personality: [String]
    let gradientColors: [String]
    let iconName: String

    /// Get gradient for the companion
    var gradient: LinearGradient {
        let colors = gradientColors.compactMap { Color(hex: $0) }
        return LinearGradient(
            colors: colors.isEmpty ? [.orange, .pink] : colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Get primary color from gradient
    var primaryColor: Color {
        Color(hex: gradientColors.first ?? "#FF6B6B") ?? .orange
    }

    static func == (lhs: AICompanion, rhs: AICompanion) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Predefined Companions

extension AICompanion {

    /// The Poet - Lyrical and metaphorical companion
    static let poet = AICompanion(
        id: "poet",
        name: "The Poet",
        tagline: "Lyrical & Metaphorical",
        description: "Transforms daily moments into lyrical expressions, finding beauty in the ordinary.",
        summaryStyle: "Lyrical summaries with metaphors and emotional depth",
        visualStyle: "Watercolor and impressionistic art",
        signatureStyle: "POETIC & IMPRESSIONISTIC",
        signatureDescription: "Weaves emotions into watercolor dreams with metaphorical depth",
        personality: ["Thoughtful", "Introspective", "Creative"],
        gradientColors: ["#FF6B6B", "#C06C84", "#6C5B7B"],
        iconName: "text.quote"
    )

    /// The Sage - Insightful and structured companion
    static let sage = AICompanion(
        id: "sage",
        name: "The Sage",
        tagline: "Insightful & Structured",
        description: "Provides wise insights and organized reflections on your daily experiences.",
        summaryStyle: "Clear, structured summaries with key insights",
        visualStyle: "Geometric and abstract art",
        signatureStyle: "STRUCTURED & GEOMETRIC",
        signatureDescription: "Delivers crystal-clear insights with elegant geometric visuals",
        personality: ["Wise", "Analytical", "Balanced"],
        gradientColors: ["#4ECDC4", "#44A08D", "#093637"],
        iconName: "book.closed.fill"
    )

    /// The Dreamer - Creative and imaginative companion
    static let dreamer = AICompanion(
        id: "dreamer",
        name: "The Dreamer",
        tagline: "Creative & Imaginative",
        description: "Adds a touch of wonder and imagination to your journal entries.",
        summaryStyle: "Whimsical summaries with creative interpretations",
        visualStyle: "Surreal and fantastical art",
        signatureStyle: "SURREAL & METAPHORICAL",
        signatureDescription: "Creates emotionally rich narratives with dreamlike visuals",
        personality: ["Playful", "Optimistic", "Imaginative"],
        gradientColors: ["#A8E6CF", "#7FD8BE", "#FD6F96"],
        iconName: "sparkles"
    )

    /// The Realist - Clear and practical companion
    static let realist = AICompanion(
        id: "realist",
        name: "The Realist",
        tagline: "Clear & Practical",
        description: "Keeps your reflections grounded and focused on actionable insights.",
        summaryStyle: "Direct summaries with practical takeaways",
        visualStyle: "Photorealistic and documentary art",
        signatureStyle: "GROUNDED & PHOTOREALISTIC",
        signatureDescription: "Captures authentic moments with documentary-style clarity",
        personality: ["Direct", "Grounded", "Authentic"],
        gradientColors: ["#FF8B94", "#A1A1A1", "#474747"],
        iconName: "camera.fill"
    )

    /// All available companions
    static let all = [poet, sage, dreamer, realist]
}

// MARK: - Color Extension for Hex

extension Color {
    /// Initialize a Color from a hex string
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
