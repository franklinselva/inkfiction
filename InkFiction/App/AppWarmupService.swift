//
//  AppWarmupService.swift
//  InkFiction
//
//  Centralized service for app warm-up operations during splash screen
//

import Foundation
import SwiftData

// MARK: - Warm-up Phase

enum WarmupPhase: String, CaseIterable {
    case initializing = "Initializing"
    case loadingSettings = "Loading settings"
    case loadingPersona = "Loading persona"
    case loadingJournals = "Loading journals"
    case completed = "Ready"

    var progress: Double {
        switch self {
        case .initializing: return 0.0
        case .loadingSettings: return 0.25
        case .loadingPersona: return 0.50
        case .loadingJournals: return 0.75
        case .completed: return 1.0
        }
    }
}

// MARK: - Warm-up Result

struct WarmupResult {
    let hasCompletedOnboarding: Bool
    let hasPersona: Bool
    let journalCount: Int
    let success: Bool
    let error: Error?

    static let empty = WarmupResult(
        hasCompletedOnboarding: false,
        hasPersona: false,
        journalCount: 0,
        success: false,
        error: nil
    )
}

// MARK: - App Warmup Service

@Observable
@MainActor
final class AppWarmupService {

    // MARK: - Singleton

    static let shared = AppWarmupService()

    // MARK: - State

    private(set) var currentPhase: WarmupPhase = .initializing
    private(set) var isComplete: Bool = false
    private(set) var result: WarmupResult = .empty

    // MARK: - Configuration

    /// Maximum number of journal entries to preload during warm-up
    static let journalPreloadLimit = 50

    /// Minimum splash duration in seconds
    static let minimumSplashDuration: TimeInterval = 1.5

    // MARK: - Dependencies

    private var modelContext: ModelContext?
    private var themeManager: ThemeManager?

    // MARK: - Initialization

    private init() {
        Log.info("AppWarmupService initialized", category: .app)
    }

    // MARK: - Configuration

    func configure(modelContext: ModelContext, themeManager: ThemeManager) {
        self.modelContext = modelContext
        self.themeManager = themeManager
    }

    // MARK: - Warm-up

    /// Perform the complete warm-up sequence
    /// Returns the warm-up result with onboarding and data status
    func performWarmup() async -> WarmupResult {
        let startTime = Date()

        Log.info("Starting app warm-up", category: .app)

        guard let context = modelContext else {
            Log.error("Model context not configured for warm-up", category: .app)
            return WarmupResult(
                hasCompletedOnboarding: false,
                hasPersona: false,
                journalCount: 0,
                success: false,
                error: nil
            )
        }

        // Initialize repositories with model context
        setPhase(.initializing)
        JournalRepository.shared.setModelContext(context)
        PersonaRepository.shared.setModelContext(context)
        SettingsRepository.shared.setModelContext(context)

        // Check iCloud account status
        await CloudKitManager.shared.checkAccountStatus()
        SyncMonitor.shared.loadLastSyncDate()

        // Load settings
        setPhase(.loadingSettings)
        await SettingsRepository.shared.warmup()

        // Load theme
        if let themeManager = themeManager {
            await themeManager.loadThemeFromRepository()
        }

        let hasCompletedOnboarding = SettingsRepository.shared.hasCompletedOnboarding

        // Load persona
        setPhase(.loadingPersona)
        var hasPersona = false
        do {
            try await PersonaRepository.shared.warmup()
            hasPersona = PersonaRepository.shared.hasPersona
        } catch {
            Log.error("Failed to warm up persona", error: error, category: .persona)
        }

        // Load journals (only if onboarding completed)
        setPhase(.loadingJournals)
        var journalCount = 0
        if hasCompletedOnboarding {
            do {
                journalCount = try await JournalRepository.shared.warmup(limit: Self.journalPreloadLimit)
            } catch {
                Log.error("Failed to warm up journals", error: error, category: .journal)
            }
        }

        // Ensure minimum splash duration
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < Self.minimumSplashDuration {
            let remaining = Self.minimumSplashDuration - elapsed
            try? await Task.sleep(for: .seconds(remaining))
        }

        // Complete warm-up
        setPhase(.completed)
        isComplete = true

        let warmupResult = WarmupResult(
            hasCompletedOnboarding: hasCompletedOnboarding,
            hasPersona: hasPersona,
            journalCount: journalCount,
            success: true,
            error: nil
        )

        result = warmupResult

        Log.info("App warm-up completed - onboarding: \(hasCompletedOnboarding), persona: \(hasPersona), journals: \(journalCount)", category: .app)

        return warmupResult
    }

    // MARK: - Reset

    /// Reset the warm-up service state (for testing/debugging)
    func reset() {
        currentPhase = .initializing
        isComplete = false
        result = .empty
        Log.debug("AppWarmupService reset", category: .app)
    }

    // MARK: - Private

    private func setPhase(_ phase: WarmupPhase) {
        currentPhase = phase
        Log.debug("Warm-up phase: \(phase.rawValue)", category: .app)
    }
}
