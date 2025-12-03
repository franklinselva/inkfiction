# InkFiction App Rewrite - Implementation Plan

**Version:** 1.1
**Created:** December 3, 2025
**Status:** Planning Phase

---

## Executive Summary

This document outlines the complete implementation plan for rewriting InkFiction from a Supabase-backed application to an iCloud-only architecture. The app will use MVVM architecture with NavigationStack + Router pattern, biometric app protection, and maintain core AI features.

### Key Changes from Old App

| Remove | Add | Keep |
|--------|-----|------|
| Supabase authentication & sync | iCloud-only storage (CloudKit) | All AI features (Gemini) |
| Email/password account management | Biometric app protection (Face ID/Touch ID) | Subscriptions (StoreKit 2) |
| Journal entry encryption | NavigationStack + Router pattern | 8+ themes |
| Multi-persona support | OSLog-based logging | Full analytics |
| Recovery codes | Fastlane CI/CD | Custom floating tab bar |

### Persona Clarification
- **Single persona** per user (not multiple personas)
- **Multiple avatar style variations** for the same persona (Artistic, Cartoon, Minimalist, Watercolor, Sketch)
- User can generate different style variations and switch between them

### Biometric vs Encryption Clarification
- **Biometric protection**: Protects app access (Face ID/Touch ID required to open app)
- **No journal encryption**: Entries are NOT encrypted - security comes from biometric + iCloud
- Old app had both; new app only has biometric app protection

---

## Table of Contents

0. [Phase 0: Project Bootstrap & Infrastructure](#phase-0-project-bootstrap--infrastructure)
1. [Phase 1: Data Layer & iCloud Integration](#phase-1-data-layer--icloud-integration)
2. [Phase 2: Biometric App Protection](#phase-2-biometric-app-protection)
3. [Phase 3: Onboarding Flow](#phase-3-onboarding-flow)
4. [Phase 4: Persona Feature](#phase-4-persona-feature)
5. [Phase 5: Journal Feature](#phase-5-journal-feature)
6. [Phase 6: AI Integration](#phase-6-ai-integration)
7. [Phase 7: Timeline & Analytics](#phase-7-timeline--analytics)
8. [Phase 8: Insights & Reflect](#phase-8-insights--reflect)
9. [Phase 9: Settings](#phase-9-settings)
10. [Phase 10: Subscription & StoreKit](#phase-10-subscription--storekit)
11. [Phase 11: Themes & UI Polish](#phase-11-themes--ui-polish)
12. [Phase 12: Testing & QA](#phase-12-testing--qa)
13. [Architecture Overview](#architecture-overview)
14. [Project Structure](#project-structure)
15. [File Migration Reference](#file-migration-reference)
16. [Dependencies](#dependencies)

---

## Phase 0: Project Bootstrap & Infrastructure ✅ COMPLETED

**Priority:** Critical
**Status:** ✅ Completed on 2025-12-03
**Description:** Set up project foundation, Fastlane, logging, and navigation routing before any feature development.

### Checklist

#### 0.1 Xcode Project Configuration ✅
- [x] Set iOS deployment target to **iOS 17.0**
- [x] Update bundle identifier: `com.quantumtech.InkFiction`
- [x] Configure iCloud capability in Xcode
  - [x] Enable CloudKit
  - [x] Create/select iCloud container: `iCloud.com.quantumtech.InkFiction`
- [x] Add entitlements:
  - [x] iCloud (CloudKit)
  - [x] Push Notifications
  - [x] Face ID (`NSFaceIDUsageDescription`)
- [x] Single build configuration (simplified from Debug/Release/Staging)

#### 0.2 Fastlane Setup ✅
- [x] Create `fastlane/Appfile` with team ID
- [x] Create `fastlane/Fastfile` with lanes:
  - [x] `build` - Build for iPhone Air simulator
  - [x] `test` - Run unit tests
  - [x] `beta` - Build and upload to TestFlight
  - [x] `release` - Build and upload to App Store
  - [x] `certificates` - Manage code signing
- [x] Create `fastlane/Matchfile` for code signing
- [x] Create `.gitignore` with proper exclusions

#### 0.3 Logging Infrastructure (OSLog) ✅
- [x] Create `Core/Logging/Logger.swift`
- [x] Implement category-based logging (app, navigation, data, cloudKit, biometric, ai, subscription, ui, persona, journal, settings)
- [x] Add log levels: debug, info, warning, error
- [x] Add signpost support for performance profiling

#### 0.4 Navigation Router (NavigationStack + Router) ✅
- [x] Create `Core/Navigation/Router.swift` with @Observable
- [x] Create `Core/Navigation/Destination.swift` with all navigation destinations
- [x] Implement push, pop, popToRoot, replace methods
- [x] Add sheet/fullScreenCover management in Router
- [x] Create SheetDestination and FullScreenDestination enums
- [x] Add AlertState for alert management
- [x] Add Environment key for router access

#### 0.5 Project Folder Structure ✅
- [x] Created complete directory structure:
  - `App/` - InkFictionApp.swift, AppState.swift, RootView.swift
  - `Core/Navigation/` - Router.swift, Destination.swift
  - `Core/Logging/` - Logger.swift
  - `Core/Utilities/` - Constants.swift
  - `Core/Data/CloudKit/`, `Core/Data/Repository/`, `Core/Data/SwiftData/`
  - `Core/Services/AI/Prompts/`
  - `Core/Components/`, `Core/Theme/Themes/`, `Core/Extensions/`
  - `Features/` - Biometric, Onboarding, Persona, Journal, Timeline, Insights, Reflect, Settings, Subscription (each with Models/, Views/, ViewModels/)
  - `fastlane/`

#### 0.6 Base App Files ✅
- [x] Create `App/InkFictionApp.swift` - App entry point with SwiftData container
- [x] Create `App/AppState.swift` - Global app state (isUnlocked, hasCompletedOnboarding, hasPersona, syncStatus)
- [x] Create `App/RootView.swift` - Root view with flow management and placeholder views
- [x] Create `Core/Utilities/Constants.swift` - App-wide constants (iCloud, UserDefaults, API, UI, Journal, Persona, Subscription)

#### 0.7 Info.plist Configuration ✅
- [x] Add `NSFaceIDUsageDescription`
- [x] Add `NSPhotoLibraryUsageDescription`
- [x] Add `NSCameraUsageDescription`
- [x] Add `NSPhotoLibraryAddUsageDescription`
- [x] Configure background modes (remote-notification)

### Files Created
```
InkFiction/
├── App/
│   ├── InkFictionApp.swift
│   ├── AppState.swift
│   └── RootView.swift
├── Core/
│   ├── Navigation/
│   │   ├── Router.swift
│   │   └── Destination.swift
│   ├── Logging/
│   │   └── Logger.swift
│   └── Utilities/
│       └── Constants.swift
├── fastlane/
│   ├── Fastfile
│   ├── Appfile
│   └── Matchfile
├── Info.plist (updated)
├── InkFiction.entitlements (updated)
└── .gitignore
```

### Build Verification
- [x] `fastlane build` - ✅ Build Succeeded

### Fastfile Template

```ruby
default_platform(:ios)

platform :ios do
  desc "Run all unit tests"
  lane :test do
    run_tests(
      scheme: "InkFiction",
      device: "iPhone 15 Pro",
      clean: true
    )
  end

  desc "Push a new beta build to TestFlight"
  lane :beta do
    ensure_git_status_clean
    increment_build_number(xcodeproj: "InkFiction.xcodeproj")
    build_app(
      scheme: "InkFiction",
      export_method: "app-store"
    )
    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
    commit_version_bump(
      xcodeproj: "InkFiction.xcodeproj",
      message: "Bump build number for TestFlight"
    )
    push_to_git_remote
  end

  desc "Push a new release build to the App Store"
  lane :release do
    ensure_git_status_clean
    increment_version_number(
      xcodeproj: "InkFiction.xcodeproj",
      bump_type: "patch"
    )
    increment_build_number(xcodeproj: "InkFiction.xcodeproj")
    build_app(
      scheme: "InkFiction",
      export_method: "app-store"
    )
    upload_to_app_store(
      skip_screenshots: true,
      skip_metadata: false,
      submit_for_review: false
    )
    commit_version_bump(
      xcodeproj: "InkFiction.xcodeproj",
      message: "Release version bump"
    )
    push_to_git_remote
    add_git_tag
  end

  desc "Sync certificates and profiles"
  lane :certificates do
    match(type: "development")
    match(type: "appstore")
  end
end
```

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `Logger.swift` | `ink-snap/InkFiction/Core/Services/Logging/Logger.swift` (rewrite for OSLog) |

---

## Phase 1: Data Layer & iCloud Integration

**Priority:** Critical
**Description:** Set up CloudKit for iCloud sync and SwiftData for local caching.

### Checklist

#### 1.1 CloudKit Setup
- [ ] Create `Core/Data/CloudKit/CloudKitManager.swift`
  - [ ] Initialize CloudKit container
  - [ ] Handle account status changes
  - [ ] Implement error handling
- [ ] Create `Core/Data/CloudKit/CloudKitModels.swift`
  - [ ] Define CKRecord type constants
  - [ ] Create record conversion extensions
- [ ] Create `Core/Data/CloudKit/SyncMonitor.swift`
  - [ ] Track sync status (syncing, synced, error, offline)
  - [ ] Publish status via Combine/Observable
  - [ ] Handle network reachability

#### 1.2 CloudKit Record Types
Define these record types in CloudKit Dashboard:

**JournalEntry**
```
- id: String (UUID)
- title: String
- content: String
- mood: String
- tags: List<String>
- createdAt: Date/Time
- updatedAt: Date/Time
- isArchived: Int64
- isPinned: Int64
```

**JournalImage**
```
- id: String (UUID)
- journalEntryId: String (reference)
- imageAsset: Asset
- caption: String?
- isAIGenerated: Int64
- createdAt: Date/Time
```

**PersonaProfile**
```
- id: String (UUID)
- name: String
- bio: String?
- attributes: Bytes (JSON)
- createdAt: Date/Time
- updatedAt: Date/Time
```

**PersonaAvatar**
```
- id: String (UUID)
- personaId: String (reference)
- style: String (artistic/cartoon/minimalist/watercolor/sketch)
- imageAsset: Asset
- isActive: Int64
- createdAt: Date/Time
```

**AppSettings**
```
- id: String (UUID)
- themeId: String
- notificationsEnabled: Int64
- dailyReminderTime: Date/Time?
- aiAutoEnhance: Int64
- aiAutoTitle: Int64
- onboardingCompleted: Int64
- updatedAt: Date/Time
```

#### 1.3 SwiftData Models (Local Cache)
- [ ] Create `Core/Data/SwiftData/SwiftDataModels.swift`
- [ ] Define `@Model` classes mirroring CloudKit records
- [ ] Add `cloudKitRecordID` field for sync tracking
- [ ] Configure relationships

#### 1.4 Repository Pattern
- [ ] Create `Core/Data/Repository/JournalRepository.swift`
  - [ ] CRUD operations
  - [ ] Query with filters (mood, date, search)
  - [ ] Sync with CloudKit
- [ ] Create `Core/Data/Repository/PersonaRepository.swift`
  - [ ] Single persona management
  - [ ] Multiple avatar variations
- [ ] Create `Core/Data/Repository/SettingsRepository.swift`
  - [ ] App settings persistence
  - [ ] Theme preference
  - [ ] Notification settings

#### 1.5 Sync Strategy
- [ ] Implement offline-first approach
- [ ] Use `CKSyncEngine` (iOS 17+) or manual sync
- [ ] Conflict resolution: last-write-wins
- [ ] Background sync scheduling

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `JournalRepository.swift` | `ink-snap/InkFiction/Core/Data/Repository/JournalRepository.swift` |
| `PersonaRepository.swift` | `ink-snap/InkFiction/Core/Data/Repository/PersonaRepository.swift` |

---

## Phase 2: Biometric App Protection

**Priority:** Critical
**Description:** Implement Face ID/Touch ID to protect app access (NOT encryption).

### Checklist

#### 2.1 Biometric Service
- [ ] Create `Core/Services/BiometricService.swift`
  ```swift
  final class BiometricService {
      enum BiometricType { case faceID, touchID, none }
      enum AuthResult { case success, failed(Error), notAvailable, notEnrolled }

      func availableBiometricType() -> BiometricType
      func authenticate(reason: String) async -> AuthResult
  }
  ```
- [ ] Use LocalAuthentication framework
- [ ] Handle all LAError cases gracefully
- [ ] Provide appropriate fallback messages

#### 2.2 Biometric Gate View
- [ ] Create `Features/Biometric/Views/BiometricGateView.swift`
  - [ ] App icon/logo display
  - [ ] "Unlock with Face ID" button
  - [ ] "Try Again" after failure
  - [ ] Error message display
- [ ] Create `Features/Biometric/ViewModels/BiometricViewModel.swift`
  - [ ] Authentication state management
  - [ ] Auto-trigger on appear
  - [ ] Track failed attempts

#### 2.3 App State Integration
- [ ] Add `isUnlocked` to `AppState`
- [ ] Lock app on:
  - [ ] App launch
  - [ ] Return from background
- [ ] Skip biometric if:
  - [ ] Device doesn't support it (show warning)
  - [ ] User has disabled it in settings (future feature)

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `BiometricService.swift` | `ink-snap/InkFiction/Core/Services/Security/BiometricAuthService.swift` |

---

## Phase 3: Onboarding Flow

**Priority:** High
**Description:** First-time user experience without account creation.

### Checklist

#### 3.1 Onboarding Models
- [ ] Create `Features/Onboarding/Models/OnboardingStep.swift`
  ```swift
  enum OnboardingStep: Int, CaseIterable {
      case welcome
      case personalityQuiz
      case permissions
      case complete
  }
  ```
- [ ] Create `Features/Onboarding/Models/OnboardingState.swift`
  - [ ] Current step tracking
  - [ ] Quiz answers
  - [ ] Permissions granted

#### 3.2 Onboarding Views
- [ ] Create `Features/Onboarding/Views/OnboardingContainerView.swift`
  - [ ] Progress indicator
  - [ ] Step navigation
  - [ ] Skip functionality
- [ ] Create `Features/Onboarding/Views/WelcomeView.swift`
  - [ ] App introduction
  - [ ] Key features highlight
  - [ ] "Get Started" CTA
- [ ] Create `Features/Onboarding/Views/PersonalityQuizView.swift`
  - [ ] Journal preference questions
  - [ ] AI companion style selection
- [ ] Create `Features/Onboarding/Views/PermissionsView.swift`
  - [ ] Notifications permission
  - [ ] Photo library permission
  - [ ] Camera permission
- [ ] Create `Features/Onboarding/Views/OnboardingCompleteView.swift`
  - [ ] Success animation
  - [ ] Transition to main app

#### 3.3 Onboarding ViewModel
- [ ] Create `Features/Onboarding/ViewModels/OnboardingViewModel.swift`
  - [ ] Step progression
  - [ ] Quiz logic
  - [ ] Permission requests
  - [ ] Save to iCloud on completion

### Onboarding Flow
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Welcome   │────▶│ Personality │────▶│ Permissions │────▶│  Complete   │
│             │     │    Quiz     │     │   Request   │     │  → Persona  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                                                   │
                                                                   ▼
                                                           ┌─────────────┐
                                                           │   Create    │
                                                           │   Persona   │
                                                           └─────────────┘
```

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `OnboardingContainerView.swift` | `ink-snap/InkFiction/Features/Onboarding/Views/OnboardingContainerView.swift` |
| `PersonalityQuizView.swift` | `ink-snap/InkFiction/Features/Onboarding/Views/PersonalityQuizView.swift` |
| `PermissionsView.swift` | `ink-snap/InkFiction/Features/Onboarding/Views/PermissionsView.swift` |

---

## Phase 4: Persona Feature

**Priority:** High
**Description:** Single persona with multiple avatar style variations.

### Key Concept
- **One persona per user** (name, bio, attributes)
- **Multiple avatar styles** for that persona (Artistic, Cartoon, Minimalist, Watercolor, Sketch)
- User can generate avatars in different styles and switch active avatar

### Checklist

#### 4.1 Persona Models
- [ ] Create `Features/Persona/Models/PersonaProfile.swift`
  ```swift
  struct PersonaProfile: Identifiable {
      let id: UUID
      var name: String
      var bio: String?
      var attributes: PersonaAttributes
      var avatars: [PersonaAvatar]  // Multiple style variations
      var activeAvatarId: UUID?
      let createdAt: Date
      var updatedAt: Date
  }
  ```
- [ ] Create `Features/Persona/Models/PersonaAvatar.swift`
  ```swift
  struct PersonaAvatar: Identifiable {
      let id: UUID
      let style: AvatarStyle
      let imageData: Data
      let createdAt: Date
  }
  ```
- [ ] Create `Features/Persona/Models/AvatarStyle.swift`
  ```swift
  enum AvatarStyle: String, CaseIterable {
      case artistic
      case cartoon
      case minimalist
      case watercolor
      case sketch

      var displayName: String { ... }
      var description: String { ... }
  }
  ```
- [ ] Create `Features/Persona/Models/PersonaAttributes.swift`
  - [ ] Environment preference
  - [ ] Preferred moods
  - [ ] Activity keywords

#### 4.2 Persona Views
- [ ] Create `Features/Persona/Views/PersonaCreationView.swift`
  - [ ] Name input
  - [ ] Bio input (optional)
  - [ ] Attribute selection
- [ ] Create `Features/Persona/Views/PersonaDetailView.swift`
  - [ ] Display persona info
  - [ ] Avatar carousel (all styles)
  - [ ] Edit button
  - [ ] Generate new avatar button
- [ ] Create `Features/Persona/Views/AvatarStyleCarousel.swift`
  - [ ] Horizontal scroll of avatar styles
  - [ ] Active indicator
  - [ ] Tap to switch active
- [ ] Create `Features/Persona/Views/AvatarGenerationView.swift`
  - [ ] Style picker
  - [ ] Generation progress
  - [ ] Preview and save

#### 4.3 Persona ViewModel
- [ ] Create `Features/Persona/ViewModels/PersonaViewModel.swift`
  - [ ] Load/save persona
  - [ ] Update persona details
  - [ ] Generate avatar in style
  - [ ] Switch active avatar
  - [ ] Sync to iCloud

### Avatar Style Variations Diagram
```
┌─────────────────────────────────────────────────────────────┐
│                     SINGLE PERSONA                           │
│  Name: "Alex"                                                │
│  Bio: "A creative soul who loves nature"                    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              AVATAR STYLE VARIATIONS                 │    │
│  │                                                      │    │
│  │  [Artistic]  [Cartoon]  [Minimalist]  [Watercolor]  │    │
│  │      ✓                                               │    │
│  │   (active)                                           │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `PersonaProfile.swift` | `ink-snap/InkFiction/Features/Persona/Models/PersonaProfile.swift` (simplify to single) |
| `AvatarStyle.swift` | `ink-snap/InkFiction/Features/Persona/Models/AvatarStyle.swift` |
| `PersonaCreationView.swift` | `ink-snap/InkFiction/Features/Persona/Views/PersonaCreationSheet.swift` |

---

## Phase 5: Journal Feature

**Priority:** Critical
**Description:** Core journaling functionality with mood tracking and images.

### Checklist

#### 5.1 Journal Models
- [ ] Create `Features/Journal/Models/JournalEntry.swift`
  ```swift
  struct JournalEntry: Identifiable {
      let id: UUID
      var title: String
      var content: String
      var mood: Mood
      var tags: [String]
      var images: [JournalImage]
      var isArchived: Bool
      var isPinned: Bool
      let createdAt: Date
      var updatedAt: Date
  }
  ```
- [ ] Create `Features/Journal/Models/Mood.swift`
  ```swift
  enum Mood: String, CaseIterable {
      case happy, excited, peaceful, neutral
      case thoughtful, sad, anxious, angry

      var emoji: String { ... }
      var color: Color { ... }
  }
  ```
- [ ] Create `Features/Journal/Models/JournalImage.swift`
  - [ ] ID, image data, caption
  - [ ] isAIGenerated flag

#### 5.2 Journal List
- [ ] Create `Features/Journal/Views/JournalListView.swift`
  - [ ] Entry cards in list/grid
  - [ ] Pull to refresh
  - [ ] Sync status indicator
- [ ] Create `Features/Journal/Components/JournalCard.swift`
  - [ ] Title, mood icon, date
  - [ ] Preview text
  - [ ] Image thumbnail
- [ ] Create `Features/Journal/Components/FilterBar.swift`
  - [ ] Mood filter
  - [ ] Date range
  - [ ] Archive toggle
- [ ] Create `Features/Journal/Components/SearchBar.swift`
  - [ ] Text search
  - [ ] Search suggestions

#### 5.3 Journal Editor
- [ ] Create `Features/Journal/Views/JournalEditorView.swift`
  - [ ] Title input
  - [ ] Rich text content
  - [ ] Mood selector
  - [ ] Tag input
  - [ ] Image attachment
  - [ ] Auto-save
- [ ] Create `Features/Journal/Views/MoodSelectorView.swift`
  - [ ] Grid of mood options
  - [ ] Visual feedback
- [ ] Create `Features/Journal/Views/ImageAttachmentView.swift`
  - [ ] Camera capture
  - [ ] Photo library picker
  - [ ] AI generation trigger

#### 5.4 Journal ViewModels
- [ ] Create `Features/Journal/ViewModels/JournalListViewModel.swift`
  - [ ] Fetch entries
  - [ ] Filter/search
  - [ ] Delete/archive
- [ ] Create `Features/Journal/ViewModels/JournalEditorViewModel.swift`
  - [ ] Create/edit entry
  - [ ] Auto-save timer
  - [ ] Image management
  - [ ] AI title generation

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `JournalEntry.swift` | `ink-snap/InkFiction/Features/Journal/Models/JournalEntry.swift` |
| `Mood.swift` | `ink-snap/InkFiction/Features/Journal/Models/Mood.swift` |
| `JournalListView.swift` | `ink-snap/InkFiction/Features/Journal/Views/JournalView.swift` |
| `JournalEditorView.swift` | `ink-snap/InkFiction/Features/Journal/Views/JournalEntrySheetView.swift` |

---

## Phase 6: AI Integration

**Priority:** High
**Description:** Gemini API for text analysis and image generation.

### Checklist

#### 6.1 Gemini Service
- [ ] Create `Core/Services/AI/GeminiService.swift`
  - [ ] API client with async/await
  - [ ] Request/response models
  - [ ] Rate limiting handling
  - [ ] Error handling
- [ ] Create `Core/Services/AI/GeminiModels.swift`
  - [ ] Request/response types
  - [ ] Token counting

#### 6.2 Image Generation
- [ ] Create `Core/Services/AI/ImageGenerationService.swift`
  - [ ] Persona avatar generation (by style)
  - [ ] Journal entry image generation
  - [ ] Generation queue management
  - [ ] Progress tracking

#### 6.3 Text Analysis
- [ ] Create `Core/Services/AI/MoodAnalysisService.swift`
  - [ ] Detect mood from text
  - [ ] Generate title suggestions
  - [ ] Entry enhancement
- [ ] Create `Core/Services/AI/ReflectionService.swift`
  - [ ] Generate mood reflections
  - [ ] Pattern analysis

#### 6.4 Prompt Templates
- [ ] Create `Core/Services/AI/Prompts/`
  - [ ] `PersonaAvatarPrompt.swift`
  - [ ] `JournalImagePrompt.swift`
  - [ ] `MoodAnalysisPrompt.swift`
  - [ ] `TitleGenerationPrompt.swift`
  - [ ] `ReflectionPrompt.swift`

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `GeminiService.swift` | `ink-snap/InkFiction/Core/Services/Gemini/` |
| `ImageGenerationService.swift` | `ink-snap/InkFiction/Core/Services/AI/` |
| `MoodAnalysisService.swift` | `ink-snap/InkFiction/Features/Reflect/Services/MoodAnalysisService.swift` |

---

## Phase 7: Timeline & Analytics

**Priority:** Medium
**Description:** Calendar view and journaling statistics.

### Checklist

#### 7.1 Timeline Models
- [ ] Create `Features/Timeline/Models/CalendarData.swift`
- [ ] Create `Features/Timeline/Models/FrequencyData.swift`
- [ ] Create `Features/Timeline/Models/StreakData.swift`

#### 7.2 Timeline Views
- [ ] Create `Features/Timeline/Views/TimelineView.swift`
  - [ ] Monthly calendar grid
  - [ ] Entry indicators per day
  - [ ] Mood color coding
- [ ] Create `Features/Timeline/Views/CalendarDayView.swift`
  - [ ] Day detail with entries
- [ ] Create `Features/Timeline/Views/MoodTrendView.swift`
  - [ ] Mood over time chart
  - [ ] Distribution pie chart
- [ ] Create `Features/Timeline/Views/StreakView.swift`
  - [ ] Current streak display
  - [ ] Best streak

#### 7.3 Timeline ViewModel
- [ ] Create `Features/Timeline/ViewModels/TimelineViewModel.swift`
  - [ ] Calendar data aggregation
  - [ ] Streak calculation
  - [ ] Mood trend analysis

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `TimelineView.swift` | `ink-snap/InkFiction/Features/Timeline/Views/TimelineView.swift` |
| `CalendarData.swift` | `ink-snap/InkFiction/Features/Timeline/Models/CalendarModels.swift` |

---

## Phase 8: Insights & Reflect

**Priority:** Medium
**Description:** AI-powered insights and mood reflections.

### Checklist

#### 8.1 Insights Feature
- [ ] Create `Features/Insights/Models/` (Daily, Weekly, Monthly insights)
- [ ] Create `Features/Insights/Views/InsightsContainerView.swift`
- [ ] Create `Features/Insights/Views/InsightCardView.swift`
- [ ] Create `Features/Insights/Views/MoodDistributionView.swift`
- [ ] Create `Features/Insights/ViewModels/InsightsViewModel.swift`

#### 8.2 Reflect Feature
- [ ] Create `Features/Reflect/Models/MoodReflection.swift`
- [ ] Create `Features/Reflect/Models/ReflectionConfig.swift`
- [ ] Create `Features/Reflect/Views/ReflectView.swift`
- [ ] Create `Features/Reflect/Views/ReflectionCardView.swift`
- [ ] Create `Features/Reflect/ViewModels/ReflectViewModel.swift`

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `InsightsContainerView.swift` | `ink-snap/InkFiction/Features/Insights/Views/InsightsContainerView.swift` |
| `ReflectView.swift` | `ink-snap/InkFiction/Features/Reflect/Views/ReflectView.swift` |

---

## Phase 9: Settings

**Priority:** Medium
**Description:** App configuration and preferences.

### Checklist

#### 9.1 Settings Model
- [ ] Create `Features/Settings/Models/AppSettings.swift`
  - [ ] Theme preference
  - [ ] Notification settings
  - [ ] AI feature toggles
  - [ ] Export preferences

#### 9.2 Settings Views
- [ ] Create `Features/Settings/Views/SettingsView.swift` - Main settings list
- [ ] Create `Features/Settings/Views/NotificationsSettingsView.swift`
- [ ] Create `Features/Settings/Views/ThemeSettingsView.swift`
- [ ] Create `Features/Settings/Views/DataStorageView.swift` - iCloud status, export
- [ ] Create `Features/Settings/Views/AISettingsView.swift`
- [ ] Create `Features/Settings/Views/AboutView.swift`

#### 9.3 Settings ViewModel
- [ ] Create `Features/Settings/ViewModels/SettingsViewModel.swift`
- [ ] Create `Core/Services/ExportService.swift` - JSON/Markdown/PDF export

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `SettingsView.swift` | `ink-snap/InkFiction/Features/Settings/Views/SettingsView.swift` |
| `AppSettings.swift` | `ink-snap/InkFiction/Features/Settings/Models/AppSettings.swift` |

---

## Phase 10: Subscription & StoreKit

**Priority:** High
**Description:** In-app purchases with StoreKit 2.

### Checklist

#### 10.1 Subscription Models
- [ ] Create `Features/Subscription/Models/SubscriptionTier.swift`
  ```swift
  enum SubscriptionTier: String {
      case free
      case enhanced
      case premium
  }
  ```
- [ ] Create `Features/Subscription/Models/UsageTracking.swift`
- [ ] Create `Features/Subscription/Models/FeatureLimits.swift`

#### 10.2 Subscription Views
- [ ] Create `Features/Subscription/Views/PaywallView.swift`
- [ ] Create `Features/Subscription/Views/SubscriptionStatusView.swift`
- [ ] Create `Features/Subscription/Views/PlanComparisonView.swift`

#### 10.3 Subscription Service
- [ ] Create `Core/Services/SubscriptionService.swift`
  - [ ] StoreKit 2 integration
  - [ ] Purchase flow
  - [ ] Restore purchases
  - [ ] Entitlement checking
- [ ] Create StoreKit configuration file for testing

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `SubscriptionTier.swift` | `ink-snap/InkFiction/Features/Subscription/Models/SubscriptionTier.swift` |
| `PaywallView.swift` | `ink-snap/InkFiction/Features/Subscription/Views/PremiumPaywallView.swift` |

---

## Phase 11: Themes & UI Polish

**Priority:** Medium
**Description:** Visual theming and core UI components.

### Checklist

#### 11.1 Theme System
- [ ] Create `Core/Theme/Theme.swift` - Theme protocol
- [ ] Create `Core/Theme/ThemeManager.swift` - Observable theme state
- [ ] Implement 8 themes:
  - [ ] Paper (default)
  - [ ] Dawn
  - [ ] Bloom
  - [ ] Sky
  - [ ] Pearl
  - [ ] Sunset
  - [ ] Forest
  - [ ] Aqua

#### 11.2 Core Components
- [ ] Create `Core/Components/FloatingTabBar.swift` - Custom floating tab bar
- [ ] Create `Core/Components/FloatingActionButton.swift`
- [ ] Create `Core/Components/AsyncImageView.swift`
- [ ] Create `Core/Components/LoadingView.swift`
- [ ] Create `Core/Components/EmptyStateView.swift`
- [ ] Create `Core/Components/SyncStatusView.swift`

#### 11.3 Main App Shell
- [ ] Create main `ContentView.swift` with:
  - [ ] Custom floating tab bar (4 tabs)
  - [ ] Tab destinations: Journal, Timeline, Insights, Settings
  - [ ] Floating action button for new entry
  - [ ] Smooth tab transitions

### Tab Bar Design
```
┌─────────────────────────────────────────────────────────────┐
│                                                              │
│                      [App Content]                           │
│                                                              │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│              ┌─────────────────────────┐                     │
│              │  📓   📅   💡   ⚙️  │     ← Floating Tab Bar │
│              └─────────────────────────┘                     │
│                         [+]              ← FAB (new entry)   │
└─────────────────────────────────────────────────────────────┘
```

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `Theme.swift` | `ink-snap/InkFiction/Core/Theme/Theme.swift` |
| `FloatingTabBar.swift` | `ink-snap/InkFiction/Core/Components/FloatingTabBar.swift` |
| `FloatingActionButton.swift` | `ink-snap/InkFiction/Core/Components/FloatingActionButton.swift` |

---

## Phase 12: Testing & QA

**Priority:** Critical
**Description:** Comprehensive testing before release.

### Checklist

#### 12.1 Unit Tests
- [ ] Test all ViewModels
- [ ] Test Repositories
- [ ] Test Services (mock network)
- [ ] Test CloudKit sync logic (mock)

#### 12.2 UI Tests
- [ ] Test onboarding flow
- [ ] Test biometric gate (simulator limitation)
- [ ] Test journal CRUD
- [ ] Test persona creation
- [ ] Test navigation flows

#### 12.3 Integration Tests
- [ ] Test CloudKit sync end-to-end
- [ ] Test subscription flow (sandbox)
- [ ] Test data persistence

#### 12.4 Manual QA
- [ ] Test on physical devices (iPhone, iPad)
- [ ] Test offline mode
- [ ] Test sync across multiple devices
- [ ] Test app state restoration
- [ ] Test edge cases (empty states, errors)

---

## Architecture Overview

### MVVM + Router Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                        PRESENTATION                          │
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │    Views    │◄───│  ViewModels │    │   Router    │     │
│  │  (SwiftUI)  │    │ (@Observable)│◄───│ (Navigation)│     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│         │                  │                                 │
│         └──────────────────┴─────────────┐                  │
│                                          ▼                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         DOMAIN                               │
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Models    │    │  Services   │    │ Repositories│     │
│  │  (Structs)  │    │  (AI, etc)  │    │(Data Access)│     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                          DATA                                │
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │  CloudKit   │    │  SwiftData  │    │ UserDefaults│     │
│  │  (Remote)   │    │  (Local)    │    │  (Prefs)    │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Navigation Flow

```
App Launch
    │
    ▼
┌─────────────┐     No      ┌─────────────┐
│  Biometric  │────────────▶│   Locked    │
│   Check     │             │    View     │
└─────────────┘             └─────────────┘
    │ Yes
    ▼
┌─────────────┐     No      ┌─────────────┐
│ Onboarding  │────────────▶│  Onboarding │
│  Complete?  │             │    Flow     │
└─────────────┘             └─────────────┘
    │ Yes                          │
    ▼                              ▼
┌─────────────┐             ┌─────────────┐
│   Has       │     No      │   Persona   │
│  Persona?   │────────────▶│  Creation   │
└─────────────┘             └─────────────┘
    │ Yes                          │
    ▼                              ▼
┌─────────────────────────────────────────┐
│              MAIN APP                    │
│  ┌─────────┬─────────┬────────┬──────┐ │
│  │ Journal │Timeline │Insights│ Settings│
│  └─────────┴─────────┴────────┴──────┘ │
└─────────────────────────────────────────┘
```

---

## Project Structure

```
InkFiction/
├── App/
│   ├── InkFictionApp.swift
│   └── AppState.swift
│
├── Core/
│   ├── Navigation/
│   │   ├── Router.swift
│   │   ├── Destination.swift
│   │   └── NavigationContainer.swift
│   │
│   ├── Logging/
│   │   └── Logger.swift
│   │
│   ├── Data/
│   │   ├── CloudKit/
│   │   │   ├── CloudKitManager.swift
│   │   │   ├── CloudKitModels.swift
│   │   │   └── SyncMonitor.swift
│   │   ├── Repository/
│   │   │   ├── JournalRepository.swift
│   │   │   ├── PersonaRepository.swift
│   │   │   └── SettingsRepository.swift
│   │   └── SwiftData/
│   │       └── SwiftDataModels.swift
│   │
│   ├── Services/
│   │   ├── AI/
│   │   │   ├── GeminiService.swift
│   │   │   ├── ImageGenerationService.swift
│   │   │   ├── MoodAnalysisService.swift
│   │   │   └── Prompts/
│   │   ├── BiometricService.swift
│   │   ├── NotificationService.swift
│   │   ├── ExportService.swift
│   │   └── SubscriptionService.swift
│   │
│   ├── Components/
│   │   ├── FloatingTabBar.swift
│   │   ├── FloatingActionButton.swift
│   │   ├── AsyncImageView.swift
│   │   ├── LoadingView.swift
│   │   ├── EmptyStateView.swift
│   │   └── SyncStatusView.swift
│   │
│   ├── Theme/
│   │   ├── Theme.swift
│   │   ├── ThemeManager.swift
│   │   └── Themes/
│   │       ├── PaperTheme.swift
│   │       ├── DawnTheme.swift
│   │       └── ...
│   │
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   ├── View+Extensions.swift
│   │   └── ...
│   │
│   └── Utilities/
│       └── Constants.swift
│
├── Features/
│   ├── Biometric/
│   │   ├── Views/
│   │   │   └── BiometricGateView.swift
│   │   └── ViewModels/
│   │       └── BiometricViewModel.swift
│   │
│   ├── Onboarding/
│   │   ├── Models/
│   │   ├── Views/
│   │   └── ViewModels/
│   │
│   ├── Persona/
│   │   ├── Models/
│   │   │   ├── PersonaProfile.swift
│   │   │   ├── PersonaAvatar.swift
│   │   │   ├── AvatarStyle.swift
│   │   │   └── PersonaAttributes.swift
│   │   ├── Views/
│   │   │   ├── PersonaCreationView.swift
│   │   │   ├── PersonaDetailView.swift
│   │   │   ├── AvatarStyleCarousel.swift
│   │   │   └── AvatarGenerationView.swift
│   │   └── ViewModels/
│   │       └── PersonaViewModel.swift
│   │
│   ├── Journal/
│   │   ├── Models/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Components/
│   │
│   ├── Timeline/
│   │   ├── Models/
│   │   ├── Views/
│   │   └── ViewModels/
│   │
│   ├── Insights/
│   │   ├── Models/
│   │   ├── Views/
│   │   └── ViewModels/
│   │
│   ├── Reflect/
│   │   ├── Models/
│   │   ├── Views/
│   │   └── ViewModels/
│   │
│   ├── Settings/
│   │   ├── Models/
│   │   ├── Views/
│   │   └── ViewModels/
│   │
│   └── Subscription/
│       ├── Models/
│       ├── Views/
│       └── ViewModels/
│
├── Resources/
│   ├── Assets.xcassets/
│   ├── Localizable.strings
│   └── Info.plist
│
├── Configuration/
│   ├── Debug.xcconfig
│   ├── Release.xcconfig
│   └── Staging.xcconfig
│
└── fastlane/
    ├── Fastfile
    ├── Appfile
    ├── Matchfile
    └── .env (gitignored)
```

---

## File Migration Reference

### Files to Rewrite (Fresh Implementation)
These should be written fresh using old code as reference only:

| Category | Old Reference | Notes |
|----------|--------------|-------|
| Navigation | `AppLaunchCoordinator.swift` | Complete rewrite with NavigationStack + Router |
| Logging | `Logger.swift` | Rewrite using OSLog |
| CloudKit | (none) | New implementation |
| Repositories | `*Repository.swift` | Rewrite for CloudKit instead of Supabase |

### Files to Adapt (Significant Changes)
| New File | Old Reference | Changes |
|----------|--------------|---------|
| `PersonaProfile.swift` | `PersonaProfile.swift` | Single persona, multiple avatar styles |
| `JournalEntry.swift` | `JournalEntry.swift` | Remove encryption fields |
| `SettingsViewModel.swift` | `SettingsViewModel.swift` | Remove account management |

### Files to Port (Minor Changes)
| New File | Old Reference | Changes |
|----------|--------------|---------|
| `Mood.swift` | `Mood.swift` | Minimal |
| `AvatarStyle.swift` | `AvatarStyle.swift` | Minimal |
| `Theme.swift` | `Theme.swift` | Minimal |
| `FloatingTabBar.swift` | `FloatingTabBar.swift` | Adapt to new navigation |
| UI Components | `Core/Components/*` | Style updates |

### Do NOT Migrate
- `Core/Services/Supabase/*` - All Supabase code
- `Core/Services/Encryption/*` - All encryption code
- `Features/Authentication/*` - Account auth views
- Multi-persona management files
- Recovery code views

---

## Dependencies

### Native Frameworks (Required)
- SwiftUI
- SwiftData
- CloudKit
- StoreKit 2
- LocalAuthentication
- UserNotifications
- OSLog

### Third-Party (Optional)
- None required initially
- Consider Kingfisher for image caching if CloudKit performance is an issue

### API Keys Required
- Google Gemini API Key
- Image Generation API Key (Replicate or similar)

### Configuration
```
Configuration/
├── Debug.xcconfig
│   └── GEMINI_API_KEY = debug_key
│   └── IMAGE_GEN_API_KEY = debug_key
├── Release.xcconfig
│   └── GEMINI_API_KEY = $(GEMINI_API_KEY)
│   └── IMAGE_GEN_API_KEY = $(IMAGE_GEN_API_KEY)
└── Staging.xcconfig
    └── GEMINI_API_KEY = staging_key
    └── IMAGE_GEN_API_KEY = staging_key
```

---

## Implementation Priority Summary

| Phase | Description | Priority |
|-------|-------------|----------|
| **0** | **Project Bootstrap & Infrastructure** | **Critical** |
| **1** | Data Layer & iCloud Integration | Critical |
| **2** | Biometric App Protection | Critical |
| **3** | Onboarding Flow | High |
| **4** | Persona Feature | High |
| **5** | Journal Feature | Critical |
| **6** | AI Integration | High |
| **7** | Timeline & Analytics | Medium |
| **8** | Insights & Reflect | Medium |
| **9** | Settings | Medium |
| **10** | Subscription & StoreKit | High |
| **11** | Themes & UI Polish | Medium |
| **12** | Testing & QA | Critical |

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-03 | Initial plan |
| 1.1 | 2025-12-03 | Added Phase 0 (Fastlane, OSLog, Router), clarified single persona with multiple avatar styles, clarified biometric vs encryption, updated navigation to NavigationStack + Router |
| 1.2 | 2025-12-03 | **Phase 0 Completed** - Project bootstrap, Fastlane setup, OSLog logging, NavigationStack+Router, base app files, Info.plist permissions. Simplified to single build configuration. Build verified with `fastlane build`. |
