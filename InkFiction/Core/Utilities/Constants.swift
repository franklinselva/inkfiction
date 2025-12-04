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
        /// Base URL for AI Text generation API (Cloudflare Workers backend)
        /// For local development: http://localhost:8787
        /// For production: https://inkfiction-ai-text.your-subdomain.workers.dev
        static var textBaseURL: String {
            #if DEBUG
            return UserDefaults.standard.string(forKey: "ai_text_base_url") ?? "http://localhost:8787"
            #else
            return UserDefaults.standard.string(forKey: "ai_text_base_url") ?? ""
            #endif
        }

        /// Base URL for AI Image generation API (Cloudflare Workers backend)
        /// For local development: http://localhost:8788
        /// For production: https://inkfiction-ai-image.your-subdomain.workers.dev
        static var imageBaseURL: String {
            #if DEBUG
            return UserDefaults.standard.string(forKey: "ai_image_base_url") ?? "http://localhost:8788"
            #else
            return UserDefaults.standard.string(forKey: "ai_image_base_url") ?? ""
            #endif
        }

        /// Gemini model identifiers
        static let textModelId = "gemini-2.5-flash"
        static let imageModelId = "gemini-2.5-flash-preview-05-20"

        enum Timeouts {
            static let `default`: TimeInterval = 30
            static let textGeneration: TimeInterval = 60
            static let imageGeneration: TimeInterval = 120
            static let reflection: TimeInterval = 90
        }

        /// Operations recognized by Cloudflare Workers
        enum Operations {
            // Text operations
            static let journalProcessing = "journal_processing"
            static let weeklyMonthlySummary = "weekly_monthly_summary"
            static let personaCreation = "persona_creation"
            static let chat = "chat"

            // Image operations
            static let journalImage = "journal_image"
            static let personaAvatar = "persona_avatar"
        }

        enum Limits {
            static let maxContentLength = 50000
            static let maxPromptLength = 10000
            static let maxImagePromptLength = 500
            static let minContentForTitle = 10
            static let minContentForProcessing = 20
            static let maxReferenceImages = 3
        }

        /// Generation config defaults
        enum GenerationConfig {
            static let defaultTemperature: Double = 0.7
            static let defaultMaxOutputTokens: Int = 2048
            static let imageTemperature: Double = 0.8
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
