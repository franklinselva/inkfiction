import Foundation

// MARK: - Constants

enum Constants {

    // MARK: - App

    enum App {
        static let name = "InkFiction"
        static let bundleIdentifier = "com.quantumtech.InkFiction"
    }

    // MARK: - iCloud

    enum iCloud {
        static let containerIdentifier = "iCloud.com.quantumtech.InkFiction"

        enum RecordTypes {
            static let journalEntry = "JournalEntry"
            static let journalImage = "JournalImage"
            static let personaProfile = "PersonaProfile"
            static let personaAvatar = "PersonaAvatar"
            static let appSettings = "AppSettings"
        }
    }

    // MARK: - UserDefaults

    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedThemeId = "selectedThemeId"
        static let biometricEnabled = "biometricEnabled"
        static let lastSyncDate = "lastSyncDate"
        static let notificationsEnabled = "notificationsEnabled"
        static let dailyReminderTime = "dailyReminderTime"
        static let aiAutoEnhanceEnabled = "aiAutoEnhanceEnabled"
        static let aiAutoTitleEnabled = "aiAutoTitleEnabled"
        // Journal Preferences
        static let journalingStyle = "journalingStyle"
        static let emotionalExpression = "emotionalExpression"
        static let visualPreference = "visualPreference"
        static let selectedCompanionId = "selectedCompanionId"
    }

    // MARK: - AI

    enum AI {
        /// Base URL for AI API (Cloudflare Workers backend)
        /// Set this to your deployed Cloudflare Worker URL
        static let baseURL = "" // e.g., "https://inkfiction-api.your-subdomain.workers.dev/api"

        /// Gemini model identifier
        static let modelId = "gemini-2.5-flash-preview-05-20"

        enum Timeouts {
            static let `default`: TimeInterval = 30
            static let textGeneration: TimeInterval = 60
            static let imageGeneration: TimeInterval = 120
            static let reflection: TimeInterval = 90
        }

        enum Endpoints {
            static let analyzeMood = "ai/analyze-mood"
            static let generateTitle = "ai/generate-title"
            static let enhanceEntry = "ai/enhance-entry"
            static let generateImage = "ai/generate-image"
            static let generateReflection = "ai/generate-reflection"
            static let processJournal = "ai/process-journal"
            static let generatePersonaBio = "ai/generate-persona-bio"
        }

        enum Limits {
            static let maxContentLength = 50000
            static let maxPromptLength = 10000
            static let maxImagePromptLength = 500
            static let minContentForTitle = 10
            static let minContentForProcessing = 20
        }
    }

    // MARK: - UI

    enum UI {
        static let cornerRadius: CGFloat = 12
        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadiusLarge: CGFloat = 20
        static let padding: CGFloat = 16
        static let paddingSmall: CGFloat = 8
        static let paddingLarge: CGFloat = 24
        static let animationDuration: Double = 0.3

        enum TabBar {
            static let height: CGFloat = 60
            static let bottomPadding: CGFloat = 20
        }
    }

    // MARK: - Journal

    enum Journal {
        static let maxTitleLength = 100
        static let maxContentLength = 50000
        static let maxTagsCount = 10
        static let maxImagesPerEntry = 10
        static let autoSaveInterval: TimeInterval = 5
    }

    // MARK: - Persona

    enum Persona {
        static let maxNameLength = 50
        static let maxBioLength = 500
        static let maxAvatarsPerStyle = 3
    }

    // MARK: - Subscription

    enum Subscription {
        static let freeJournalImagesPerDay = 3
        static let freeAvatarGenerationsPerDay = 1
        static let enhancedJournalImagesPerDay = 10
        static let enhancedAvatarGenerationsPerDay = 5

        enum ProductIds {
            static let enhancedMonthly = "com.quantumtech.inkfiction.enhanced.monthly"
            static let enhancedYearly = "com.quantumtech.inkfiction.enhanced.yearly"
            static let premiumMonthly = "com.quantumtech.inkfiction.premium.monthly"
            static let premiumYearly = "com.quantumtech.inkfiction.premium.yearly"
        }
    }
}
