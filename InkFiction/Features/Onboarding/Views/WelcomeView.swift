//
//  WelcomeView.swift
//  InkFiction
//
//  Welcome screen with animated hero - swipe up to continue
//

import SwiftUI
import Combine

struct WelcomeView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.themeManager) private var themeManager

    // MARK: - Animation State

    @State private var animateHero = false
    @State private var animateText = false
    @State private var animateButton = false
    @State private var chevronBounce = false
    @State private var currentSymbolIndex = 0

    // MARK: - Constants

    private let heroSymbols = ["book.fill", "paintbrush.fill", "sparkles"]
    private let symbolToTextMapping = [0, 1, 2]
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    private var highlightedTextIndex: Int {
        symbolToTextMapping[currentSymbolIndex]
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Theme-aware background
            AnimatedGradientBackground()
                .ignoresSafeArea()

            VStack(alignment: .center, spacing: 0) {
                // 1. Logo at top-left
                HStack {
                    Image("inkfiction")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .opacity(animateHero ? 1 : 0)
                        .scaleEffect(animateHero ? 1 : 0.8)
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.leading, 24)

                Spacer()
                    .frame(height: 40)

                // 2. Stacked text (left-aligned)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Write.")
                        .font(.system(size: 46, weight: highlightedTextIndex == 0 ? .bold : .light))
                        .foregroundColor(highlightedTextIndex == 0 ? themeManager.currentTheme.textPrimaryColor : themeManager.currentTheme.textSecondaryColor)
                        .opacity(highlightedTextIndex == 0 ? 1.0 : 0.55)
                        .shadow(color: themeManager.currentTheme.shadowColor, radius: 2, x: 0, y: 1)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: highlightedTextIndex)

                    Text("Visualize.")
                        .font(.system(size: 54, weight: highlightedTextIndex == 1 ? .heavy : .regular, design: .rounded))
                        .foregroundColor(highlightedTextIndex == 1 ? themeManager.currentTheme.textPrimaryColor : themeManager.currentTheme.textSecondaryColor)
                        .opacity(highlightedTextIndex == 1 ? 1.0 : 0.55)
                        .shadow(color: themeManager.currentTheme.shadowColor, radius: 2, x: 0, y: 1)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: highlightedTextIndex)

                    Text("Reflect.")
                        .font(.system(size: 46, weight: highlightedTextIndex == 2 ? .bold : .light))
                        .foregroundColor(highlightedTextIndex == 2 ? themeManager.currentTheme.textPrimaryColor : themeManager.currentTheme.textSecondaryColor)
                        .opacity(highlightedTextIndex == 2 ? 1.0 : 0.55)
                        .shadow(color: themeManager.currentTheme.shadowColor, radius: 2, x: 0, y: 1)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: highlightedTextIndex)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .opacity(animateText ? 1 : 0)
                .offset(y: animateText ? 0 : 20)

                Spacer()
                    .frame(height: 32)

                // 3. Hero Section - Morphing symbol
                MorphSymbolView(
                    symbol: heroSymbols[currentSymbolIndex],
                    config: .init(
                        font: .system(size: 100, weight: .bold),
                        frame: CGSize(width: 280, height: 280),
                        radius: 20,
                        foregroundColor: themeManager.currentTheme.textPrimaryColor,
                        keyFrameDuration: 0.5
                    )
                )
                .scaleEffect(animateHero ? 1 : 0.9)
                .opacity(animateHero ? 1 : 0)
                .onReceive(timer) { _ in
                    currentSymbolIndex = (currentSymbolIndex + 1) % heroSymbols.count
                }

                Spacer()
                    .frame(height: 48)

                // 4. Tagline
                Text("Your journey through thoughts and visuals")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .shadow(color: themeManager.currentTheme.shadowColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 32)
                    .opacity(animateText ? 1 : 0)
                    .offset(y: animateText ? 0 : 20)

                Spacer()

                // 5. Chevron indicator
                VStack(spacing: 12) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor.opacity(chevronBounce ? 0.9 : 0.7))
                        .shadow(color: themeManager.currentTheme.shadowColor, radius: 2, x: 0, y: 1)
                        .offset(y: chevronBounce ? -8 : 0)
                        .animation(
                            .easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                            value: chevronBounce
                        )

                    Text("Swipe up to begin")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor.opacity(chevronBounce ? 0.95 : 0.75))
                        .shadow(color: themeManager.currentTheme.shadowColor, radius: 2, x: 0, y: 1)
                        .animation(
                            .easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                            value: chevronBounce
                        )
                }
                .opacity(animateButton ? 1 : 0)
                .offset(y: animateButton ? 0 : 20)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        chevronBounce = true
                    }
                }

                Spacer()
                    .frame(height: 48)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    // Swipe up to continue
                    if value.translation.height < -50 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            viewModel.nextStep()
                        }
                    }
                }
        )
        .onTapGesture {
            // Tap anywhere to continue as well
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                viewModel.nextStep()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateHero = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                animateText = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                animateButton = true
            }
        }
    }
}
