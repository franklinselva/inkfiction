import Foundation

// MARK: - Navigation Destinations

/// All possible navigation destinations in the app
enum Destination: Hashable {

    // MARK: - Onboarding
    case onboarding
    case onboardingStep(OnboardingStep)

    // MARK: - Journal
    case journal
    case journalEntry(id: UUID)
    case journalEditor(entryId: UUID?)

    // MARK: - Timeline
    case timeline
    case timelineDay(date: Date)

    // MARK: - Insights
    case insights
    case insightDetail(type: InsightType)

    // MARK: - Reflect
    case reflect
    case reflectionDetail(id: UUID)

    // MARK: - Settings
    case settings
    case settingsSection(section: SettingsSection)

    // MARK: - Persona
    case persona
    case personaEdit
    case avatarGeneration(style: AvatarStyleType?)

    // MARK: - Subscription
    case subscription
    case paywall
}

// MARK: - Onboarding Steps

enum OnboardingStep: Int, CaseIterable, Hashable {
    case welcome
    case personalityQuiz
    case permissions
    case personaCreation
    case complete

    var title: String {
        switch self {
        case .welcome: "Welcome"
        case .personalityQuiz: "About You"
        case .permissions: "Permissions"
        case .personaCreation: "Create Persona"
        case .complete: "All Set"
        }
    }

    var isSkippable: Bool {
        switch self {
        case .welcome, .complete, .personaCreation: false
        case .personalityQuiz, .permissions: true
        }
    }
}

// MARK: - Insight Types

enum InsightType: String, Hashable {
    case daily
    case weekly
    case monthly
    case moodTrend
    case streak
}

// MARK: - Settings Sections

enum SettingsSection: String, Hashable {
    case notifications
    case theme
    case dataStorage
    case aiFeatures
    case subscription
    case about
    case export
}

// MARK: - Avatar Styles

enum AvatarStyleType: String, CaseIterable, Hashable {
    case artistic
    case cartoon
    case minimalist
    case watercolor
    case sketch

    var displayName: String {
        switch self {
        case .artistic: "Artistic"
        case .cartoon: "Cartoon"
        case .minimalist: "Minimalist"
        case .watercolor: "Watercolor"
        case .sketch: "Sketch"
        }
    }

    var description: String {
        switch self {
        case .artistic: "Rich, painterly style with vibrant colors"
        case .cartoon: "Fun, animated look with bold outlines"
        case .minimalist: "Clean, simple design with minimal details"
        case .watercolor: "Soft, flowing style with gentle gradients"
        case .sketch: "Hand-drawn aesthetic with pencil textures"
        }
    }
}

// MARK: - Sheet Destinations

enum SheetDestination: Identifiable, Hashable {
    case newJournalEntry
    case editJournalEntry(id: UUID)
    case moodSelector
    case imageAttachment
    case avatarGeneration
    case paywall
    case export
    case personaDetail

    var id: String {
        switch self {
        case .newJournalEntry: "newJournalEntry"
        case .editJournalEntry(let id): "editJournalEntry-\(id)"
        case .moodSelector: "moodSelector"
        case .imageAttachment: "imageAttachment"
        case .avatarGeneration: "avatarGeneration"
        case .paywall: "paywall"
        case .export: "export"
        case .personaDetail: "personaDetail"
        }
    }
}

// MARK: - Full Screen Destinations

enum FullScreenDestination: Identifiable, Hashable {
    case onboarding
    case biometricGate
    case imageViewer(imageId: UUID)

    var id: String {
        switch self {
        case .onboarding: "onboarding"
        case .biometricGate: "biometricGate"
        case .imageViewer(let id): "imageViewer-\(id)"
        }
    }
}
