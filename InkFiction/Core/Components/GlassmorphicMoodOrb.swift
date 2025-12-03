//
//  GlassmorphicMoodOrb.swift
//  InkFiction
//
//  Glassmorphic orb component for mood visualization
//

import SwiftUI

// MARK: - Glassmorphic Mood Orb

struct GlassmorphicMoodOrb: View {
    let mood: MoodType
    let size: CGFloat
    let entryCount: Int?
    var onTap: (() -> Void)? = nil

    @Environment(\.themeManager) private var themeManager
    @State private var isFloating = false
    @State private var glowIntensity = 0.5
    @State private var rotationAngle = 0.0
    @State private var isTapped = false

    // MARK: - Mood Type

    enum MoodType: Equatable {
        case peaceful
        case excited
        case reflective
        case anxious
        case grateful
        case happy
        case sad
        case angry
        case neutral

        var color: Color {
            baseColor
        }

        var baseColor: Color {
            switch self {
            case .peaceful: return Color(red: 0.3, green: 0.6, blue: 1.0)
            case .excited: return Color(red: 1.0, green: 0.6, blue: 0.2)
            case .reflective: return Color(red: 0.6, green: 0.4, blue: 1.0)
            case .anxious: return Color(red: 1.0, green: 0.3, blue: 0.3)
            case .grateful: return Color(red: 1.0, green: 0.85, blue: 0.3)
            case .happy: return Color(red: 1.0, green: 0.9, blue: 0.4)
            case .sad: return Color(red: 0.3, green: 0.4, blue: 0.8)
            case .angry: return Color(red: 0.9, green: 0.2, blue: 0.2)
            case .neutral: return Color(red: 0.5, green: 0.5, blue: 0.5)
            }
        }

        var icon: String {
            switch self {
            case .peaceful: return "leaf.fill"
            case .excited: return "sparkles"
            case .reflective: return "moon.stars.fill"
            case .anxious: return "bolt.heart.fill"
            case .grateful: return "heart.fill"
            case .happy: return "face.smiling.fill"
            case .sad: return "cloud.rain.fill"
            case .angry: return "flame.fill"
            case .neutral: return "minus.circle.fill"
            }
        }

        var name: String {
            switch self {
            case .peaceful: return "Peaceful"
            case .excited: return "Excited"
            case .reflective: return "Reflective"
            case .anxious: return "Anxious"
            case .grateful: return "Grateful"
            case .happy: return "Happy"
            case .sad: return "Sad"
            case .angry: return "Angry"
            case .neutral: return "Neutral"
            }
        }
    }

    // MARK: - Color Blending

    private func blendedMoodColor() -> Color {
        let theme = themeManager.currentTheme
        let blendRatio = theme.orbColorBlendRatio
        let themeColor = theme.gradientColors.first ?? theme.accentColor

        return Color(
            red: mood.baseColor.components.red * (1 - blendRatio) + themeColor.components.red * blendRatio,
            green: mood.baseColor.components.green * (1 - blendRatio) + themeColor.components.green * blendRatio,
            blue: mood.baseColor.components.blue * (1 - blendRatio) + themeColor.components.blue * blendRatio
        )
    }

    private func rimGradientColors() -> [Color] {
        let theme = themeManager.currentTheme
        let moodColor = blendedMoodColor()

        if theme.isLight {
            return [
                moodColor.opacity(0.6),
                theme.gradientColors[safe: 1] ?? theme.accentColor.opacity(0.4),
                moodColor.opacity(0.3),
                Color.clear,
                moodColor.opacity(0.6)
            ]
        } else {
            return [
                moodColor.opacity(0.8),
                Color.white.opacity(0.6),
                theme.gradientColors[safe: 1] ?? moodColor.opacity(0.4),
                Color.clear,
                moodColor.opacity(0.8)
            ]
        }
    }

    // MARK: - Body

    var body: some View {
        let theme = themeManager.currentTheme
        let moodColor = blendedMoodColor()

        ZStack {
            // Shadow layer for 3D elevation effect
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            theme.shadowColor.opacity(theme.orbShadowIntensity),
                            theme.shadowColor.opacity(theme.orbShadowIntensity * 0.5),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.1,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size * 1.2, height: size * 0.3)
                .offset(y: size * 0.45)
                .blur(radius: 10)
                .scaleEffect(isTapped ? 1.1 : 1.0)

            // Main orb container
            ZStack {
                // Base glass layer with theme material
                Circle()
                    .fill(theme.glassMaterial)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .fill(theme.glassTint)
                            .opacity(theme.glassOpacity * 0.3)
                    )

                // Inner glow with theme-aware intensity
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                moodColor.opacity(0.6),
                                moodColor.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.4
                        )
                    )
                    .frame(width: size * 0.9, height: size * 0.9)
                    .blur(radius: 20)
                    .opacity(glowIntensity * theme.orbGlowIntensity)

                // Reflection highlight
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.isLight ? Color.white.opacity(0.3) : Color.white.opacity(0.4),
                                theme.isLight ? Color.white.opacity(0.05) : Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .frame(width: size * 0.95, height: size * 0.95)

                // Rim light with theme-aware gradient
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: rimGradientColors(),
                            center: .center,
                            startAngle: .degrees(rotationAngle),
                            endAngle: .degrees(rotationAngle + 360)
                        ),
                        lineWidth: 2
                    )
                    .frame(width: size, height: size)
                    .opacity(theme.orbRimOpacity)

                // Content overlay
                ZStack {
                    VStack(spacing: 8) {
                        Image(systemName: mood.icon)
                            .font(.system(size: size * 0.25))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [moodColor, moodColor.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: moodColor.opacity(0.5), radius: theme.isLight ? 5 : 10)

                        Text(mood.name)
                            .font(.system(size: size * 0.08, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.textPrimaryColor.opacity(0.9))
                            .shadow(color: theme.shadowColor, radius: theme.isLight ? 1 : 2)
                    }

                    // Entry count badge
                    if let count = entryCount {
                        Text("\(count)")
                            .font(.system(size: size * 0.09, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimaryColor)
                            .padding(size * 0.05)
                            .frame(minWidth: size * 0.15, minHeight: size * 0.15)
                            .background(
                                Circle()
                                    .fill(moodColor.opacity(0.9))
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                theme.isLight ? theme.strokeColor : Color.white.opacity(0.4),
                                                lineWidth: 1.5
                                            )
                                    )
                            )
                            .offset(x: size * 0.28, y: -size * 0.28)
                    }
                }
            }
            .rotation3DEffect(
                .degrees(5),
                axis: (x: isFloating ? -0.1 : 0.1, y: 0.1, z: 0)
            )
            .offset(y: isFloating ? -10 : 10)
            .scaleEffect(isTapped ? 1.05 : 1.0)
        }
        .onAppear {
            let theme = themeManager.currentTheme
            glowIntensity = theme.orbGlowIntensity * 0.7

            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                isFloating = true
            }

            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowIntensity = theme.orbGlowIntensity
            }

            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isTapped = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isTapped = false
                }
            }

            onTap?()
        }
    }
}

// MARK: - Helper Extensions

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Color {
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        let fallbackColor = UIColor(self).cgColor
        let components = fallbackColor.components ?? [0, 0, 0, 0]

        if components.count == 2 {
            return (components[0], components[0], components[0], components[1])
        } else if components.count >= 3 {
            return (components[0], components[1], components[2], components.count > 3 ? components[3] : 1)
        }

        return (0, 0, 0, 0)
    }
}

// MARK: - Mood Type Conversion

extension GlassmorphicMoodOrb.MoodType {
    init(from mood: Mood) {
        switch mood {
        case .peaceful: self = .peaceful
        case .excited: self = .excited
        case .anxious: self = .anxious
        case .happy: self = .happy
        case .thoughtful: self = .reflective
        case .sad: self = .sad
        case .angry: self = .angry
        case .neutral: self = .neutral
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color.black, Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 40) {
            GlassmorphicMoodOrb(mood: .peaceful, size: 180, entryCount: 5)

            HStack(spacing: 30) {
                GlassmorphicMoodOrb(mood: .excited, size: 100, entryCount: 2)
                GlassmorphicMoodOrb(mood: .reflective, size: 100, entryCount: nil)
            }
        }
    }
    .environment(\.themeManager, ThemeManager())
}
