//
//  ThemeManager.swift
//  InkFiction
//
//  Manages theme state and persistence with caching for instant theme loading
//

import SwiftUI

// MARK: - Theme Manager

/// Manages the current theme and persists theme selection
@Observable
@MainActor
final class ThemeManager {

    // MARK: - Properties

    /// The current active theme
    private(set) var currentTheme: Theme = .paper

    /// Whether we're currently updating from repository
    private var isUpdatingFromRepository = false

    // MARK: - Cache Keys

    private static let cachedThemeKey = "com.inkfiction.cachedTheme"

    // MARK: - Initialization

    init() {
        // Load theme from cache immediately (synchronous)
        loadThemeFromCache()
        Log.debug("ThemeManager initialized with theme: \(currentTheme.type.rawValue)", category: .ui)
    }

    // MARK: - Public Methods

    /// Set the current theme
    /// - Parameter type: The theme type to apply
    func setTheme(_ type: ThemeType) {
        guard !isUpdatingFromRepository else { return }

        Log.info("Setting theme to: \(type.rawValue)", category: .ui)

        currentTheme = Theme.theme(for: type)

        // Cache immediately for fast loading on next launch
        cacheTheme(type)

        // Save to repository (async)
        Task {
            await saveThemeToRepository(type)
        }
    }

    /// Load theme from settings repository (called during app initialization)
    func loadThemeFromRepository() async {
        isUpdatingFromRepository = true
        defer { isUpdatingFromRepository = false }

        let settings = SettingsRepository.shared
        let themeId = settings.currentSettings?.themeId ?? "Paper"

        if let type = ThemeType(rawValue: themeId) {
            if currentTheme.type != type {
                currentTheme = Theme.theme(for: type)
                cacheTheme(type)
                Log.info("Theme loaded from repository: \(type.rawValue)", category: .ui)
            }
        }
    }

    // MARK: - Theme Helpers

    /// Get all available light themes
    var lightThemes: [ThemeType] {
        ThemeType.allCases.filter { $0.isLight }
    }

    /// Get all available dark themes
    var darkThemes: [ThemeType] {
        ThemeType.allCases.filter { !$0.isLight }
    }

    /// The current color scheme based on theme
    var colorScheme: ColorScheme {
        currentTheme.isLight ? .light : .dark
    }

    // MARK: - Private Methods

    /// Load theme from UserDefaults cache (synchronous for instant loading)
    private func loadThemeFromCache() {
        guard let cachedThemeName = UserDefaults.standard.string(forKey: Self.cachedThemeKey),
              let type = ThemeType(rawValue: cachedThemeName) else {
            Log.debug("No cached theme found, using default: Paper", category: .ui)
            return
        }

        currentTheme = Theme.theme(for: type)
        Log.debug("Theme loaded from cache: \(type.rawValue)", category: .ui)
    }

    /// Cache theme to UserDefaults for fast loading on next launch
    private func cacheTheme(_ type: ThemeType) {
        UserDefaults.standard.set(type.rawValue, forKey: Self.cachedThemeKey)
        UserDefaults.standard.synchronize()
        Log.debug("Theme cached: \(type.rawValue)", category: .ui)
    }

    /// Save theme to settings repository
    private func saveThemeToRepository(_ type: ThemeType) async {
        do {
            try await SettingsRepository.shared.setTheme(type.rawValue)
            Log.debug("Theme saved to repository: \(type.rawValue)", category: .ui)
        } catch {
            Log.error("Failed to save theme to repository", error: error, category: .ui)
        }
    }
}

// MARK: - Environment Key

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - View Extension for Theme

extension View {
    /// Apply the current theme's preferred color scheme
    func applyTheme(_ themeManager: ThemeManager) -> some View {
        self.preferredColorScheme(themeManager.colorScheme)
    }
}
