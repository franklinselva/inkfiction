//
//  ThemeView.swift
//  InkFiction
//
//  Theme selection view with full navigation and save functionality
//

import SwiftUI

struct ThemeView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTheme: ThemeType = .paper
    @State private var scrollOffset: CGFloat = 0
    @State private var showingSaveSuccess = false
    @State private var hasChanges = false

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                // Navigation header with save button
                NavigationHeaderView(
                    config: NavigationHeaderConfig(
                        title: "Theme",
                        leftButton: .back(action: { dismiss() }),
                        rightButton: hasChanges
                            ? .icon("checkmark.circle.fill", action: { saveTheme() })
                            : (showingSaveSuccess ? .icon("checkmark.circle.fill", action: {}) : .none)
                    ),
                    scrollOffset: scrollOffset
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Current Theme Preview
                        currentThemePreview

                        // Dark Themes Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dark Themes")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                                .padding(.horizontal, 4)

                            ForEach(ThemeType.allCases.filter { !$0.isLight }, id: \.self) { theme in
                                ThemeOptionRow(
                                    themeType: theme,
                                    isSelected: selectedTheme == theme,
                                    onSelect: {
                                        selectTheme(theme)
                                    }
                                )
                            }
                        }

                        // Light Themes Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Light Themes")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                                .padding(.horizontal, 4)

                            ForEach(ThemeType.allCases.filter { $0.isLight }, id: \.self) { theme in
                                ThemeOptionRow(
                                    themeType: theme,
                                    isSelected: selectedTheme == theme,
                                    onSelect: {
                                        selectTheme(theme)
                                    }
                                )
                            }
                        }

                        // Add bottom spacing to avoid tab bar overlap
                        Color.clear
                            .frame(height: 120)
                    }
                    .padding()
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    scrollOffset = -newValue
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            selectedTheme = themeManager.currentTheme.type
        }
    }

    private var currentThemePreview: some View {
        VStack(spacing: 16) {
            Text("Current Theme")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)

            LinearGradient(
                colors: Theme.theme(for: selectedTheme).gradientColors,
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 120)
            .cornerRadius(16)
            .overlay(
                VStack {
                    Text(selectedTheme.rawValue)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text(selectedTheme.isLight ? "Light Mode" : "Dark Mode")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            )
            .shadow(radius: 10)
        }
        .padding()
        .gradientCard()
    }

    private func selectTheme(_ theme: ThemeType) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedTheme = theme
            checkForChanges()
        }
    }

    private func checkForChanges() {
        hasChanges = selectedTheme != themeManager.currentTheme.type
    }

    private func saveTheme() {
        themeManager.setTheme(selectedTheme)
        withAnimation {
            showingSaveSuccess = true
            hasChanges = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingSaveSuccess = false
            }
        }
    }
}

// MARK: - Theme Option Row

struct ThemeOptionRow: View {
    let themeType: ThemeType
    let isSelected: Bool
    let onSelect: () -> Void
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Theme gradient preview
                LinearGradient(
                    colors: Theme.theme(for: themeType).gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 60, height: 40)
                .cornerRadius(8)

                // Theme name and info
                VStack(alignment: .leading, spacing: 4) {
                    Text(themeType.rawValue)
                        .font(.body.weight(.medium))
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    HStack(spacing: 6) {
                        Image(systemName: themeType.isLight ? "sun.max.fill" : "moon.fill")
                            .font(.caption)
                        Text(themeType.isLight ? "Light Mode" : "Dark Mode")
                            .font(.caption)
                    }
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.currentTheme.accentColor)
                        .font(.system(size: 20))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.surfaceColor.opacity(isSelected ? 0.8 : 0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? themeManager.currentTheme.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
    }
}

#Preview {
    ThemeView()
        .environment(\.themeManager, ThemeManager())
}
