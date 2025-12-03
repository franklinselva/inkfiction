//
//  SplashView.swift
//  InkFiction
//
//  Animated splash screen displayed during app launch
//

import SwiftUI

struct SplashView: View {
    @Environment(\.themeManager) private var themeManager
    @Binding var isAnimating: Bool
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Theme-aware gradient background
            LinearGradient(
                colors: themeManager.currentTheme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(0.3)

            VStack(spacing: 24) {
                // Logo with animation
                Image("inkfiction")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .opacity(opacity)

                // App name - theme-aware text color
                Text("InkFiction")
                    .font(.custom("SF Pro Rounded", size: 42).weight(.bold))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                    .opacity(opacity)

                // Tagline - theme-aware secondary text color
                Text("Your thoughts, reimagined")
                    .font(.custom("SF Pro Display", size: 18))
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    .opacity(opacity)
                    .offset(y: opacity == 1 ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                rotation = 5
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView(isAnimating: .constant(true))
        .environment(\.themeManager, ThemeManager())
}
