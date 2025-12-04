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

## Phase 1: Data Layer & iCloud Integration ✅ COMPLETED

**Priority:** Critical
**Status:** ✅ Completed on 2025-12-03
**Description:** Set up CloudKit for iCloud sync and SwiftData for local caching.

### Checklist

#### 1.1 CloudKit Setup ✅
- [x] Create `Core/Data/CloudKit/CloudKitManager.swift`
  - [x] Initialize CloudKit container
  - [x] Handle account status changes
  - [x] Implement error handling
- [x] Create `Core/Data/CloudKit/CloudKitModels.swift`
  - [x] Define CKRecord type constants
  - [x] Create record conversion extensions
- [x] Create `Core/Data/CloudKit/SyncMonitor.swift`
  - [x] Track sync status (syncing, synced, error, offline)
  - [x] Publish status via @Observable
  - [x] Handle network reachability

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

#### 1.3 SwiftData Models (Local Cache) ✅
- [x] Create `Core/Data/SwiftData/SwiftDataModels.swift`
- [x] Define `@Model` classes mirroring CloudKit records
- [x] Add `cloudKitRecordName` field for sync tracking
- [x] Configure relationships

#### 1.4 Repository Pattern ✅
- [x] Create `Core/Data/Repository/JournalRepository.swift`
  - [x] CRUD operations
  - [x] Query with filters (mood, date, search)
  - [x] Sync with CloudKit
- [x] Create `Core/Data/Repository/PersonaRepository.swift`
  - [x] Single persona management
  - [x] Multiple avatar variations
- [x] Create `Core/Data/Repository/SettingsRepository.swift`
  - [x] App settings persistence
  - [x] Theme preference
  - [x] Notification settings

#### 1.5 Sync Strategy ✅
- [x] Implement offline-first approach
- [x] Use manual sync with CloudKit private database
- [x] Conflict resolution: last-write-wins
- [x] Background sync support via SyncMonitor

### Files Created
```
InkFiction/
├── Core/
│   └── Data/
│       ├── CloudKit/
│       │   ├── CloudKitManager.swift
│       │   ├── CloudKitModels.swift
│       │   └── SyncMonitor.swift
│       ├── Repository/
│       │   ├── JournalRepository.swift
│       │   ├── PersonaRepository.swift
│       │   └── SettingsRepository.swift
│       └── SwiftData/
│           └── SwiftDataModels.swift
└── App/
    └── InkFictionApp.swift (updated with SwiftData models)
```

### Build Verification
- [x] `fastlane build` - ✅ Build Succeeded

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `JournalRepository.swift` | `ink-snap/InkFiction/Core/Data/Repository/JournalRepository.swift` |
| `PersonaRepository.swift` | `ink-snap/InkFiction/Core/Data/Repository/PersonaRepository.swift` |

---

## Phase 2: Biometric App Protection ✅ COMPLETED

**Priority:** Critical
**Status:** ✅ Completed on 2025-12-03
**Description:** Implement Face ID/Touch ID to protect app access (NOT encryption).

### Checklist

#### 2.1 Biometric Service ✅
- [x] Create `Core/Services/BiometricService.swift`
  ```swift
  final class BiometricService {
      enum BiometricType { case faceID, touchID, none }
      enum AuthResult { case success, failed(Error), notAvailable, notEnrolled }

      func availableBiometricType() -> BiometricType
      func authenticate(reason: String) async -> AuthResult
  }
  ```
- [x] Use LocalAuthentication framework
- [x] Handle all LAError cases gracefully
- [x] Provide appropriate fallback messages

#### 2.2 Biometric Gate View ✅
- [x] Create `Features/Biometric/Views/BiometricGateView.swift`
  - [x] App icon/logo display
  - [x] "Unlock with Face ID" button
  - [x] "Try Again" after failure
  - [x] Error message display
- [x] Create `Features/Biometric/ViewModels/BiometricViewModel.swift`
  - [x] Authentication state management
  - [x] Auto-trigger on appear
  - [x] Track failed attempts

#### 2.3 App State Integration ✅
- [x] Add `isUnlocked` to `AppState` (already existed from Phase 0)
- [x] Lock app on:
  - [x] App launch
  - [x] Return from background
- [x] Skip biometric if:
  - [x] Device doesn't support it (show warning)
  - [x] User has disabled it in settings (future feature)

### Files Created
```
InkFiction/
├── Core/
│   └── Services/
│       └── BiometricService.swift
└── Features/
    └── Biometric/
        ├── Views/
        │   └── BiometricGateView.swift
        └── ViewModels/
            └── BiometricViewModel.swift
```

### Build Verification
- [x] `fastlane build` - ✅ Build Succeeded

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `BiometricService.swift` | `ink-snap/InkFiction/Core/Services/Security/BiometricAuthService.swift` |

---

## Phase 3: Onboarding Flow ✅ COMPLETED

**Priority:** High
**Status:** ✅ Completed on 2025-12-03
**Description:** First-time user experience without account creation.

### Checklist

#### 3.1 Onboarding Models ✅
- [x] Create `Features/Onboarding/Models/OnboardingState.swift`
  - [x] `OnboardingStep` enum (welcome, quiz, companionSelection, permissions)
  - [x] `QuizAnswer` struct for tracking quiz responses
  - [x] `OnboardingState` struct with current step, quiz answers, selected companion
  - [x] `SavedOnboardingData` for persistence
- [x] Create `Features/Onboarding/Models/PersonalityProfile.swift`
  - [x] `JournalingStyle` enum (quickNotes, detailedStories, visualSketches, mixedMedia)
  - [x] `EmotionalExpression` enum (writingFreely, structuredPrompts, moodTracking, creativeExploration)
  - [x] `VisualPreference` enum (abstractDreamy, realisticGrounded, minimalistClean, vibrantExpressive)
  - [x] `PersonalityProfile` with `suggestedCompanions()` method
- [x] Create `Features/Onboarding/Models/AICompanion.swift`
  - [x] 4 predefined companions: Poet, Sage, Dreamer, Realist
  - [x] Companion with id, name, tagline, description, personality traits, gradient colors
- [x] Create `Features/Onboarding/Models/Permission.swift`
  - [x] Permissions enum (notifications, photoLibrary, biometric)
  - [x] Benefits list for each permission

#### 3.2 Onboarding Views ✅
- [x] Create `Features/Onboarding/Views/OnboardingContainerView.swift`
  - [x] Progress indicator (OnboardingNavigationBar)
  - [x] Step navigation with transitions
  - [x] Hero symbol morphing between steps
- [x] Create `Features/Onboarding/Views/WelcomeView.swift`
  - [x] App logo and animated hero symbols
  - [x] "Write. Visualize. Reflect." stacked text with highlighting
  - [x] Swipe-up drawer for "Begin Journey" button
  - [x] Chevron bounce animation
- [x] Create `Features/Onboarding/Views/PersonalityQuizView.swift`
  - [x] 3 quiz questions (journaling style, emotional expression, visual preference)
  - [x] Auto-progression after answer selection (0.8s delay)
  - [x] VoiceOver accessibility support
  - [x] Haptic feedback on selection
- [x] Create `Features/Onboarding/Views/AICompanionSelectionView.swift`
  - [x] CompanionCard for each AI companion
  - [x] "Best Match" badge for recommended companion
  - [x] Auto-progression after selection (1.0s delay)
- [x] Create `Features/Onboarding/Views/PermissionsView.swift`
  - [x] Permission cards with toggle switches
  - [x] "Enable All Permissions" button
  - [x] "Start Journaling" and "Set up later" buttons
  - [x] Settings redirect for denied permissions

#### 3.3 Onboarding Components ✅
- [x] Create `Features/Onboarding/Components/OnboardingNavigationBar.swift`
  - [x] Progress bar with gradient fill
  - [x] Back button with preference key system
  - [x] AutoProgressionIndicator for timed transitions
- [x] Create `Features/Onboarding/Components/CompanionCard.swift`
  - [x] Companion details (name, tagline, description)
  - [x] Personality traits chips
  - [x] Signature style section
  - [x] Selection state with gradient border
- [x] Create `Features/Onboarding/Components/MorphSymbolView.swift`
  - [x] SF Symbol morphing with contentTransition

#### 3.4 Onboarding ViewModel ✅
- [x] Create `Features/Onboarding/ViewModels/OnboardingViewModel.swift`
  - [x] Step progression (nextStep, previousStep)
  - [x] Quiz answer management
  - [x] Companion selection with suggestion logic
  - [x] Permission grant/revoke
  - [x] Complete onboarding with iCloud save
  - [x] Notification posting for state updates

### Onboarding Flow
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Welcome   │────▶│ Personality │────▶│  Companion  │────▶│ Permissions │
│             │     │    Quiz     │     │  Selection  │     │   Request   │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                                                   │
                                                                   ▼
                                                           ┌─────────────┐
                                                           │  Main App   │
                                                           └─────────────┘
```

### Files Created
```
InkFiction/
├── Features/
│   └── Onboarding/
│       ├── Models/
│       │   ├── OnboardingState.swift
│       │   ├── PersonalityProfile.swift
│       │   ├── AICompanion.swift
│       │   └── Permission.swift
│       ├── Views/
│       │   ├── OnboardingContainerView.swift
│       │   ├── WelcomeView.swift
│       │   ├── PersonalityQuizView.swift
│       │   ├── AICompanionSelectionView.swift
│       │   └── PermissionsView.swift
│       ├── ViewModels/
│       │   └── OnboardingViewModel.swift
│       └── Components/
│           ├── OnboardingNavigationBar.swift
│           ├── CompanionCard.swift
│           └── MorphSymbolView.swift
└── App/
    └── RootView.swift (updated for onboarding integration)
```

### Build Verification
- [x] `fastlane build` - ✅ Build Succeeded

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `OnboardingContainerView.swift` | `ink-snap/InkFiction/Features/Onboarding/OnboardingCoordinator.swift` |
| `PersonalityQuizView.swift` | `ink-snap/InkFiction/Features/Onboarding/Views/PersonalityQuizView.swift` |
| `PermissionsView.swift` | `ink-snap/InkFiction/Features/Onboarding/Views/PermissionsView.swift` |
| `AICompanion.swift` | `ink-snap/InkFiction/Features/Onboarding/Models/AICompanion.swift` |
| `CompanionCard.swift` | `ink-snap/InkFiction/Features/Onboarding/Views/CompanionCard.swift` |

---

## Phase 4: Persona Feature ✅ COMPLETED

**Priority:** High
**Status:** ✅ Completed on 2025-12-04
**Description:** Single persona with multiple avatar style variations.

### Key Concept
- **One persona per user** (name, bio, attributes)
- **Multiple avatar styles** for that persona (Artistic, Cartoon, Minimalist, Watercolor, Sketch)
- User can generate avatars in different styles and switch active avatar

### Checklist

#### 4.1 Persona Models ✅
- [x] Create `Features/Persona/Models/PersonaProfile.swift`
  - [x] Rich domain model with all attributes for avatar generation
  - [x] Consistency settings for generation quality
  - [x] Mood tags for persona preferences
  - [x] Base prompt generation for AI services
- [x] Create `Features/Persona/Models/PersonaAvatarStyleMetadata.swift`
  - [x] Favor ratings for user preferences
  - [x] Usage tracking
  - [x] Comparable for sorting
- [x] Create `Features/Persona/Models/EnvironmentPreference.swift`
  - [x] Environment settings (studio, outdoor, urban, etc.)
  - [x] Lighting styles (soft, golden hour, dramatic, etc.)
  - [x] Time of day, weather, season
  - [x] Color palette and background styles
  - [x] Camera angle options
  - [x] Preset environments
- [x] Create `Features/Persona/Models/PersonaType.swift`
  - [x] 14 persona types (professional, creative, fitness, etc.)
  - [x] Preferred moods per type
  - [x] Context keywords for compatibility scoring
- [x] Create `Features/Persona/Models/PersonaUpdatePolicy.swift`
  - [x] Tier-based policies (free, enhanced, premium)
  - [x] Update frequency tracking
  - [x] Generation limits per tier
  - [x] PersonaCreationState enum
- [x] Updated `Core/Data/SwiftData/SwiftDataModels.swift`
  - [x] Added `promptDescription` extension to PersonaAttributes
  - [x] ClothingStyle prompt extension

#### 4.2 Persona Views ✅
- [x] Create `Features/Persona/Views/PersonaCreationSheet.swift`
  - [x] 2-step flow: photo selection → style review
  - [x] Step indicators with progress
  - [x] Photo selection with ImagePicker
  - [x] Style selection grid (up to 3 styles)
  - [x] Generation progress overlay
  - [x] Error handling with retry
  - [x] Save persona with generated avatars
- [x] Create `Features/Persona/Views/PersonaManagementSheet.swift`
  - [x] Free tier showcase view (upgrade CTA)
  - [x] Paid tier management view
  - [x] PersonaHeroSection with avatar display
  - [x] Avatar style horizontal carousel
  - [x] Create/update persona button
  - [x] Tips section
  - [x] Delete avatar style with confirmation
- [x] Create `Features/Persona/Components/ImageCarouselView.swift`
  - [x] Photo library card
  - [x] Selected image card
  - [x] Generation overlay with animated status
- [x] Create `Features/Persona/Components/ImagePicker.swift`
  - [x] PHPickerViewController wrapper
  - [x] CameraView for taking photos
- [x] Uses existing `PolaroidFrameView` from ImageContainers

#### 4.3 Persona ViewModels ✅
- [x] Update `Features/Persona/ViewModels/PersonaViewModel.swift`
  - [x] Load/save persona
  - [x] Update persona details
  - [x] Add/remove avatars
  - [x] Set active avatar
- [x] Create `Features/Persona/ViewModels/PersonaCreationViewModel.swift`
  - [x] Validation (name length)
  - [x] Save persona with photo and generated avatars
  - [x] Update existing persona with new styles
  - [x] Progress tracking
  - [x] Notification posting

#### 4.4 Navigation Integration ✅
- [x] Added `personaCreation` and `personaManagement` sheet destinations
- [x] Added Router convenience methods (`showPersonaCreation`, `showPersonaManagement`)
- [x] Updated RootView with sheet handling for persona sheets

### Files Created
```
InkFiction/
├── Core/
│   └── Data/
│       └── SwiftData/
│           └── SwiftDataModels.swift (updated with prompt extensions)
└── Features/
    └── Persona/
        ├── Models/
        │   ├── PersonaProfile.swift (domain model + extensions)
        │   ├── PersonaAvatarStyleMetadata.swift
        │   ├── EnvironmentPreference.swift
        │   ├── PersonaType.swift
        │   └── PersonaUpdatePolicy.swift
        ├── Views/
        │   ├── PersonaCreationSheet.swift
        │   └── PersonaManagementSheet.swift
        ├── ViewModels/
        │   ├── PersonaViewModel.swift (updated)
        │   └── PersonaCreationViewModel.swift
        └── Components/
            ├── ImageCarouselView.swift
            └── ImagePicker.swift
```

### Build Verification
- [x] `fastlane build` - ✅ Build Succeeded

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `PersonaProfile.swift` | `ink-snap/InkFiction/Features/Persona/Models/PersonaProfile.swift` |
| `PersonaAvatarStyleMetadata.swift` | `ink-snap/InkFiction/Core/Models/PersonaAvatarStyleMetadata.swift` |
| `EnvironmentPreference.swift` | `ink-snap/InkFiction/Features/Persona/Models/EnvironmentPreference.swift` |
| `PersonaCreationSheet.swift` | `ink-snap/InkFiction/Features/Persona/Views/PersonaCreationSheet.swift` |
| `PersonaManagementSheet.swift` | `ink-snap/InkFiction/Features/Persona/Views/PersonaManagementSheet.swift` |
| `ImageCarouselView.swift` | `ink-snap/InkFiction/Features/Persona/Views/ImageCarousel.swift` |
| `ImagePicker.swift` | `ink-snap/InkFiction/Features/Persona/Views/ImagePicker.swift` |

---

## Phase 5: Journal Feature ✅ COMPLETED

**Priority:** Critical
**Status:** ✅ Completed on 2025-12-03
**Description:** Core journaling functionality with mood tracking and images.

### Checklist

#### 5.1 Journal Models ✅
- [x] Create `Features/Journal/Models/JournalEntry.swift`
  - [x] Domain model for journal entries (separate from SwiftData model)
  - [x] JournalImage model for images
  - [x] Conversion from SwiftData JournalEntryModel
  - [x] Computed properties for images, featured image, etc.
- [x] Create `Features/Journal/Models/JournalFilterModels.swift`
  - [x] DateRangeFilter enum (today, yesterday, thisWeek, lastWeek, etc.)
  - [x] JournalFilterState struct with search, date range, archive
  - [x] JournalSortOrder enum
- [x] Mood enum already exists in `Core/Data/SwiftData/SwiftDataModels.swift`

#### 5.2 Journal List ✅
- [x] Create `Features/Journal/Views/JournalListView.swift`
  - [x] Entry cards in list with swipe actions
  - [x] Pull to refresh via loadEntries
  - [x] Sync status indicator
  - [x] Multi-selection mode with bulk actions
  - [x] Archive toggle in header
- [x] Create `Features/Journal/Components/JournalEntryCard.swift`
  - [x] Title, mood icon, date
  - [x] Preview text
  - [x] Image thumbnail carousel
  - [x] Pin indicator
  - [x] Selection mode support
- [x] Create `Features/Journal/Components/ExpandableSearchBar.swift`
  - [x] Debounced text search
  - [x] Date range filter menu
  - [x] Custom date range picker sheet
- [x] Create `Features/Journal/Components/TagChip.swift`
  - [x] Removable tag chips
  - [x] Flow layout for tags

#### 5.3 Journal Editor ✅
- [x] Create `Features/Journal/Views/JournalEditorSheet.swift`
  - [x] Title input
  - [x] TextEditor for content
  - [x] Mood selector
  - [x] Tag management
  - [x] Image attachment via PhotosPicker
  - [x] Keyboard height handling
- [x] Create `Features/Journal/Components/MoodSelectorView.swift`
  - [x] Grid of mood options with animation
  - [x] Visual feedback on selection
  - [x] Auto-collapse after selection
- [x] Create `Features/Journal/Views/JournalEntryDetailView.swift`
  - [x] Full entry display
  - [x] Edit and delete actions

#### 5.4 Journal ViewModels ✅
- [x] Create `Features/Journal/ViewModels/JournalListViewModel.swift`
  - [x] Fetch entries with filtering
  - [x] Incremental search optimization
  - [x] Delete/archive operations
  - [x] Multi-selection and bulk operations
  - [x] Pin toggle
- [x] Create `Features/Journal/ViewModels/JournalEditorViewModel.swift`
  - [x] Create/edit entry
  - [x] Image management
  - [x] Tag management
  - [x] Validation
  - [x] Photo library permission handling

### Files Created
```
InkFiction/
├── Features/
│   └── Journal/
│       ├── Models/
│       │   ├── JournalEntry.swift
│       │   └── JournalFilterModels.swift
│       ├── Views/
│       │   ├── JournalListView.swift
│       │   └── JournalEditorSheet.swift
│       ├── ViewModels/
│       │   ├── JournalListViewModel.swift
│       │   └── JournalEditorViewModel.swift
│       └── Components/
│           ├── JournalEntryCard.swift
│           ├── ExpandableSearchBar.swift
│           ├── MoodSelectorView.swift
│           └── TagChip.swift
└── App/
    └── RootView.swift (updated to use JournalListView)
```

### Build Verification
- [x] `fastlane build` - ✅ Build Succeeded

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `JournalEntry.swift` | `ink-snap/InkFiction/Features/Journal/Models/JournalEntry.swift` |
| `JournalFilterModels.swift` | `ink-snap/InkFiction/Features/Journal/Models/JournalFilterModels.swift` |
| `JournalListView.swift` | `ink-snap/InkFiction/Features/Journal/Views/JournalView.swift` |
| `JournalEditorSheet.swift` | `ink-snap/InkFiction/Features/Journal/Views/JournalEntrySheetView.swift` |
| `ExpandableSearchBar.swift` | `ink-snap/InkFiction/Features/Journal/Views/ExpandableSearchBar.swift` |
| `JournalEntryCard.swift` | Adapted from journal view patterns |

---

## Phase 6: AI Integration ✅ COMPLETED

**Priority:** High
**Status:** ✅ Completed on 2025-12-04
**Description:** Gemini 2.5 Flash API for text analysis and image generation via Vercel backend.

### Architecture
- All AI calls go through Vercel serverless functions (backend to be implemented separately)
- iOS client includes complete prompt policies and service layer
- Designed for single AI provider (Gemini 2.5 Flash) for both text and images

### Checklist

#### 6.1 AI Models ✅
- [x] Create `Core/Services/AI/Models/AIModels.swift`
  - [x] AIConfiguration, AIRequest, AIResponse types
  - [x] AIOperation enum for all operation types
  - [x] AIContext for personalization
  - [x] PersonaAttributesDTO for API serialization
  - [x] MoodAnalysisResult, TitleGenerationResult
  - [x] EntryEnhancementResult, JournalProcessingResult
  - [x] ImageGenerationResult, ReflectionResult
  - [x] EnhancedJournalContext for rich prompting
- [x] Create `Core/Services/AI/Models/AIError.swift`
  - [x] Comprehensive error types (network, API, request, response, image, subscription)
  - [x] isRetryable and shouldShowAlert helpers
  - [x] Conversion from API error responses

#### 6.2 Prompt System ✅
- [x] Create `Core/Services/AI/Prompts/PromptPolicy.swift`
  - [x] PromptPolicy protocol
  - [x] ModelRequirements struct
  - [x] GeminiModel enum
  - [x] ContextAllocation ratios
  - [x] PromptContext for building prompts
  - [x] PromptComponents output
  - [x] ResponseFormat (JSON, plain text)
- [x] Create `Core/Services/AI/Prompts/PromptManager.swift`
  - [x] Central coordinator for all prompt generation
  - [x] Policy registration
  - [x] Convenience methods for common operations
  - [x] Token estimation

#### 6.3 Prompt Policies ✅
- [x] Create `Core/Services/AI/Prompts/Policies/MoodAnalysisPolicy.swift`
  - [x] Mood detection from journal text
  - [x] JSON response schema with confidence
  - [x] Client-side fallback via MoodDetectionKeywords extension
- [x] Create `Core/Services/AI/Prompts/Policies/TitleGenerationPolicy.swift`
  - [x] Evocative title generation (3-7 words)
  - [x] Alternative suggestions
- [x] Create `Core/Services/AI/Prompts/Policies/JournalEnhancementPolicy.swift`
  - [x] 4 enhancement styles (expand, refine, poetic, concise)
  - [x] AI companion voice integration
- [x] Create `Core/Services/AI/Prompts/Policies/JournalImagePolicy.swift`
  - [x] Visual style based on VisualPreference
  - [x] Mood-specific atmosphere
  - [x] Persona element integration
- [x] Create `Core/Services/AI/Prompts/Policies/PersonaAvatarPolicy.swift`
  - [x] 5 avatar styles (artistic, cartoon, minimalist, watercolor, sketch)
  - [x] Persona attributes to prompt conversion
  - [x] Style-specific modifiers
- [x] Create `Core/Services/AI/Prompts/Policies/ReflectionPolicy.swift`
  - [x] Timeframe-based reflections
  - [x] AI companion voice
  - [x] Mood trend analysis
  - [x] Insights and suggestions
- [x] Create `Core/Services/AI/Prompts/Policies/JournalProcessingPolicy.swift`
  - [x] Full entry processing (title, mood, tags, image prompt)
  - [x] Persona-aware prompting
  - [x] Visual preference integration
  - [x] Avatar style suggestion

#### 6.4 GeminiService ✅
- [x] Create `Core/Services/AI/GeminiService.swift`
  - [x] Core API client for Vercel backend
  - [x] Request/response handling with Codable
  - [x] Retry logic with exponential backoff
  - [x] Error mapping from HTTP status codes
  - [x] Convenience methods: analyzeMood, generateTitle, enhanceEntry
  - [x] processJournalEntry, generateImage, generateReflection
  - [x] Environment key for SwiftUI injection

#### 6.5 Services ✅
- [x] Create `Core/Services/AI/ImageGenerationService.swift`
  - [x] Persona avatar generation by style
  - [x] Journal entry image generation
  - [x] Progress tracking
  - [x] Image caching (NSCache)
  - [x] Subscription quota integration
- [x] Create `Core/Services/AI/MoodAnalysisService.swift`
  - [x] AI mood analysis
  - [x] Local fallback detection
  - [x] Batch analysis for multiple entries
  - [x] Mood distribution calculation
  - [x] Analysis caching
- [x] Create `Core/Services/AI/ReflectionService.swift`
  - [x] Timeframe-based reflections
  - [x] Daily insight generation
  - [x] Weekly/monthly summaries
  - [x] Streak calculation
  - [x] Mood trend analysis
  - [x] Reflection caching
- [x] Create `Core/Services/AI/TitleGenerationService.swift`
  - [x] AI title generation
  - [x] Local fallback title generation
  - [x] Entry enhancement
  - [x] Full journal processing

#### 6.6 Constants Update ✅
- [x] Update `Core/Utilities/Constants.swift`
  - [x] AI.baseURL placeholder for Vercel backend
  - [x] AI.modelId for Gemini 2.5 Flash
  - [x] AI.Timeouts (default, textGeneration, imageGeneration, reflection)
  - [x] AI.Endpoints for all API routes
  - [x] AI.Limits (content lengths, prompt lengths)

### Files Created
```
InkFiction/
├── Core/
│   ├── Services/
│   │   └── AI/
│   │       ├── GeminiService.swift
│   │       ├── ImageGenerationService.swift
│   │       ├── MoodAnalysisService.swift
│   │       ├── ReflectionService.swift
│   │       ├── TitleGenerationService.swift
│   │       ├── Models/
│   │       │   ├── AIModels.swift
│   │       │   └── AIError.swift
│   │       └── Prompts/
│   │           ├── PromptPolicy.swift
│   │           ├── PromptManager.swift
│   │           └── Policies/
│   │               ├── MoodAnalysisPolicy.swift
│   │               ├── TitleGenerationPolicy.swift
│   │               ├── JournalEnhancementPolicy.swift
│   │               ├── JournalImagePolicy.swift
│   │               ├── PersonaAvatarPolicy.swift
│   │               ├── ReflectionPolicy.swift
│   │               └── JournalProcessingPolicy.swift
│   └── Utilities/
│       └── Constants.swift (updated)
└── Features/
    └── Subscription/
        └── ... (SubscriptionService updated with AI quota methods)
```

### Build Verification
- [x] `fastlane build` - ✅ Build Succeeded

### Backend Required (Vercel)
The iOS client is ready. Backend implementation needed:
- `/api/ai/analyze-mood` - Mood analysis endpoint
- `/api/ai/generate-title` - Title generation endpoint
- `/api/ai/enhance-entry` - Entry enhancement endpoint
- `/api/ai/generate-image` - Image generation endpoint
- `/api/ai/generate-reflection` - Reflection generation endpoint
- `/api/ai/process-journal` - Full journal processing endpoint
- `/api/ai/generate-persona-bio` - Persona bio generation endpoint

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `GeminiService.swift` | `ink-snap/InkFiction/Core/Services/Gemini/GeminiAPIService.swift` |
| `ImageGenerationService.swift` | `ink-snap/InkFiction/Core/Services/AI/AIImageService.swift` |
| `MoodAnalysisService.swift` | `ink-snap/InkFiction/Features/Reflect/ViewModels/ReflectViewModel.swift` |
| `PromptManager.swift` | `ink-snap/InkFiction/Core/Services/Prompts/PromptManager.swift` |
| `PromptPolicy.swift` | `ink-snap/InkFiction/Core/Services/Prompts/Policies/` |

---

## Phase 7: Timeline & Analytics ✅ COMPLETED

**Priority:** Medium
**Status:** ✅ Completed on 2025-12-03
**Description:** Calendar view and journaling statistics with visual memory cards.

### Checklist

#### 7.1 Timeline Models ✅
- [x] Create `Features/Timeline/Models/CalendarModels.swift`
  - [x] CalendarEntry, CalendarMonth, CalendarDay structures
  - [x] EntryIndicator enum with dot counts
  - [x] MonthlyStats with completion rate and mood distribution
  - [x] CalendarViewMode (month/year)
  - [x] CalendarGridConfiguration presets
  - [x] CalendarNavigation for month traversal
  - [x] CalendarImageCache for image management
- [x] Create `Features/Timeline/Models/FrequencyData.swift`
  - [x] FrequencyData with comprehensive stats
  - [x] MonthStats with month-specific metrics
  - [x] WordCountStats and WordCountTrend
  - [x] DayOfWeek enum with day patterns
  - [x] Hour enum with time categories
  - [x] JournalingGoal (daily/weekly/monthly targets)
  - [x] Achievement with unlock tracking
  - [x] InsightsData for quick stats
- [x] Create `Features/Timeline/Models/TimelineFilter.swift`
  - [x] TimelineFilter enum (day, week, month)
- [x] Create `Features/Timeline/Models/DayGroupedEntry.swift`
  - [x] Entry grouping with image containers
  - [x] Dominant mood calculation with tiebreaker
  - [x] Mood distribution calculation
- [x] Create `Features/Timeline/Models/ImageContainer.swift`
  - [x] Image container for visual memories
  - [x] UIImage to SwiftUI Image conversion

#### 7.2 Timeline Views ✅
- [x] Create `Features/Timeline/Views/TimelineView.swift`
  - [x] Day/Week/Month filter tabs with animation
  - [x] Insights card with entries, days journaled, streak
  - [x] Timeline content with grouped entries
  - [x] Image extraction from journal entries
  - [x] SwiftData integration with @Query
- [x] Create `Features/Timeline/Views/TimelineFilterView.swift`
  - [x] Animated tab bar with matchedGeometryEffect
- [x] Create `Features/Timeline/Views/VisualMemoryPeriodCard.swift`
  - [x] Period header with stats
  - [x] Static card stack for images
  - [x] Mood distribution display
  - [x] PeriodSummaryHeader component
- [x] Create `Features/Timeline/Views/EntriesDetailSheet.swift`
  - [x] Visual memories section with swipeable cards
  - [x] Journal entries grouped by day
  - [x] Fullscreen gallery support
  - [x] TimelineJournalEntryCard component
  - [x] FullScreenImageGallery component
- [x] Create `Features/Timeline/Views/EmptyTimelineView.swift`
  - [x] Empty state with suggestions

#### 7.3 Timeline Components ✅
- [x] Create `Features/Timeline/Views/Components/DateIndicatorView.swift`
  - [x] Date indicator with month, day, weekday
  - [x] PeriodIndicatorView for week/month
  - [x] Fade animation based on scroll offset
- [x] Create `Features/Timeline/Views/Components/MoodDistributionView.swift`
  - [x] Mood icons with counts
  - [x] MoodDistributionSimpleView variant
- [x] Create `Features/Timeline/Views/Components/TimelineConnector.swift`
  - [x] Vertical connector line with gradient
- [x] Create `Features/Timeline/Views/Components/StaticCardStackView.swift`
  - [x] View-only card stack (no gestures)
  - [x] Offset, scale, rotation effects
  - [x] Caption and memory count display
- [x] Create `Features/Timeline/Views/Components/SwipeableCardStack.swift`
  - [x] Interactive swipeable cards
  - [x] Share functionality
  - [x] Drag gestures with thresholds

#### 7.4 Timeline Utilities ✅
- [x] Create `Features/Timeline/Utilities/DateFormattingUtility.swift`
  - [x] Centralized date formatting
  - [x] Smart labels (Today/Yesterday)
  - [x] Date range formatting
- [x] Create `Features/Timeline/Utilities/PeriodFormatterUtility.swift`
  - [x] Period number, label, sublabel formatting
  - [x] Period title for detail sheets

#### 7.5 Timeline ViewModel ✅
- [x] Create `Features/Timeline/ViewModels/TimelineViewModel.swift`
  - [x] Insights calculation
  - [x] Current and longest streak calculation
  - [x] Mood distribution calculation
  - [x] Entry grouping (by day, week, month)
  - [x] Word count statistics
  - [x] Daily pattern analysis
  - [x] Calendar navigation

### Files Created
```
InkFiction/
├── Features/
│   └── Timeline/
│       ├── Models/
│       │   ├── CalendarModels.swift
│       │   ├── FrequencyData.swift
│       │   ├── TimelineFilter.swift
│       │   ├── DayGroupedEntry.swift
│       │   └── ImageContainer.swift
│       ├── Views/
│       │   ├── TimelineView.swift
│       │   ├── TimelineFilterView.swift
│       │   ├── VisualMemoryPeriodCard.swift
│       │   ├── EntriesDetailSheet.swift
│       │   ├── EmptyTimelineView.swift
│       │   └── Components/
│       │       ├── DateIndicatorView.swift
│       │       ├── MoodDistributionView.swift
│       │       ├── TimelineConnector.swift
│       │       ├── StaticCardStackView.swift
│       │       └── SwipeableCardStack.swift
│       ├── ViewModels/
│       │   └── TimelineViewModel.swift
│       └── Utilities/
│           ├── DateFormattingUtility.swift
│           └── PeriodFormatterUtility.swift
└── App/
    └── RootView.swift (updated to use TimelineView)
```

### Build Verification
- [x] `fastlane build` - ✅ Build Succeeded

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `TimelineView.swift` | `ink-snap/InkFiction/Features/Timeline/Views/TimelineView.swift` |
| `CalendarModels.swift` | `ink-snap/InkFiction/Features/Timeline/Models/CalendarModels.swift` |
| `FrequencyData.swift` | `ink-snap/InkFiction/Features/Timeline/Models/FrequencyData.swift` |
| `DateFormattingUtility.swift` | `ink-snap/InkFiction/Features/Timeline/Utilities/DateFormattingUtility.swift` |
| `PeriodFormatterUtility.swift` | `ink-snap/InkFiction/Features/Timeline/Utilities/PeriodFormatterUtility.swift` |
| `StaticCardStackView.swift` | `ink-snap/InkFiction/Features/Timeline/Views/StaticCardStackView.swift` |
| `SwipeableCardStack.swift` | `ink-snap/InkFiction/Features/ImageContainers/Views/SwipeableCardStack.swift` |
| `ImageContainer.swift` | `ink-snap/InkFiction/Features/ImageContainers/Models/ImageContainer.swift` |

---

## Phase 8: Insights & Reflect ✅ COMPLETED

**Priority:** Medium
**Status:** ✅ Completed on 2025-12-03
**Description:** AI-powered insights and mood reflections with organic mood orb visualization.

### Checklist

#### 8.1 Reflect Feature ✅
- [x] Create `Features/Reflect/Models/ReflectModels.swift`
  - [x] MoodData struct with mood, intensity, entryCount, position, lastEntryDate
  - [x] MoodReflection struct for AI-generated reflections
  - [x] ReflectionConfig for reflection settings
  - [x] TimeFrame enum (today, thisWeek, thisMonth, thisYear, lastYear, allTime)
  - [x] MoodDetectionKeywords for keyword-based mood analysis
  - [x] SentimentAnalysis for intensity calculation
- [x] Create `Features/Reflect/Views/ReflectView.swift`
  - [x] AnimatedGradientBackground for visual appeal
  - [x] NavigationHeaderView with timeframe filter menu
  - [x] OrganicMoodOrbCluster for mood visualization
  - [x] Empty state view when no entries
  - [x] SwiftData integration with @Query
- [x] Create `Features/Reflect/Views/MoodDetailSheet.swift`
  - [x] MoodDetailHeader with orb and entry count
  - [x] MoodStatsSection with statistics boxes
  - [x] VisualMemoriesSection with image grid and gallery
  - [x] RecentEntriesSection with entry rows
  - [x] ImageGalleryView for fullscreen image viewing
- [x] Create `Features/Reflect/Views/ReflectMoodDistributionView.swift`
  - [x] Bar-based mood distribution visualization
- [x] Create `Features/Reflect/ViewModels/ReflectViewModel.swift`
  - [x] Mood analysis with keyword scoring
  - [x] Sentiment-based intensity calculation
  - [x] Timeframe filtering
  - [x] Mood insights generation
  - [x] Entry grouping by mood

#### 8.2 Core Components ✅
- [x] Create `Core/Components/GlassmorphicMoodOrb.swift`
  - [x] Glassmorphic orb with floating animation
  - [x] Glow effects with theme-aware intensity
  - [x] Rim rotation animation
  - [x] MoodType enum with color, icon, name
  - [x] Color blending with theme colors
- [x] Create `Core/Components/OrganicMoodOrbCluster.swift`
  - [x] Force-directed physics simulation
  - [x] Collision detection and resolution
  - [x] Golden angle distribution for initial positioning
  - [x] Staggered reveal animation from center
  - [x] MoodOrbData struct for orb data
- [x] Create `Core/Components/GradientBackground.swift`
  - [x] AnimatedGradientBackground with layered animations
  - [x] GradientCard view modifier
  - [x] GlassOverlay component
- [x] Update `Core/Components/NavigationHeaderView.swift`
  - [x] Added menu right button type
  - [x] Added toggle right button type
- [x] Update `Core/Logging/Logger.swift`
  - [x] Added analytics log category
  - [x] Added moodAnalysis log category

### Files Created
```
InkFiction/
├── Core/
│   ├── Components/
│   │   ├── GlassmorphicMoodOrb.swift
│   │   ├── GradientBackground.swift
│   │   ├── OrganicMoodOrbCluster.swift
│   │   └── NavigationHeaderView.swift (updated)
│   └── Logging/
│       └── Logger.swift (updated)
└── Features/
    └── Reflect/
        ├── Models/
        │   └── ReflectModels.swift
        ├── Views/
        │   ├── ReflectView.swift
        │   ├── MoodDetailSheet.swift
        │   └── ReflectMoodDistributionView.swift
        └── ViewModels/
            └── ReflectViewModel.swift
```

### Build Verification
- [x] `fastlane build` - ✅ Build Succeeded

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `ReflectView.swift` | `ink-snap/InkFiction/Features/Reflect/Views/ReflectView.swift` |
| `ReflectViewModel.swift` | `ink-snap/InkFiction/Features/Reflect/ViewModels/ReflectViewModel.swift` |
| `GlassmorphicMoodOrb.swift` | `ink-snap/InkFiction/Core/Components/GlassmorphicMoodOrb.swift` |
| `OrganicMoodOrbCluster.swift` | `ink-snap/InkFiction/Core/Components/OrganicMoodOrbCluster.swift` |
| `GradientBackground.swift` | `ink-snap/InkFiction/Core/Components/GradientBackground.swift` |
| `MoodDetailSheet.swift` | `ink-snap/InkFiction/Features/Reflect/Views/MoodDetailSheet.swift` |
| `NavigationHeaderView.swift` | `ink-snap/InkFiction/Core/Components/NavigationHeaderView.swift` |

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

## Phase 10: Subscription & StoreKit ✅ COMPLETED

**Priority:** High
**Status:** ✅ Completed on 2025-12-04
**Description:** In-app purchases with StoreKit 2.

### Checklist

#### 10.1 StoreKit Configuration ✅
- [x] Create `InkFictionSubscriptions.storekit` - StoreKit 2 configuration file
  - [x] 4 subscription products (Enhanced Monthly/Yearly, Premium Monthly/Yearly)
  - [x] 7-day free trial for Enhanced tier
  - [x] Subscription group: "InkFiction Subscriptions"
  - [x] Pricing: Enhanced $4.99/mo or $47.99/yr, Premium $12.99/mo or $124.99/yr

#### 10.2 Subscription Models ✅
- [x] Create `Features/Subscription/Models/SubscriptionTier.swift`
  - [x] SubscriptionTier enum (free, enhanced, premium)
  - [x] Display properties (displayName, badgeIcon, gradientColors)
  - [x] Priority for upgrade comparisons
  - [x] Color/gradient helpers
- [x] Create `Features/Subscription/Models/SubscriptionPolicy.swift`
  - [x] TierLimits struct with comprehensive limits
  - [x] Daily AI image generations (0/4/20)
  - [x] Persona styles (0/3/5)
  - [x] Storage quotas (100MB/2GB/10GB)
  - [x] AI feature flags (reflections, summaries, advanced AI)
  - [x] PaywallFeature struct for paywall display
  - [x] RetentionOffer configuration
  - [x] UpgradeContext enum for context-aware messaging
- [x] Create `Features/Subscription/Models/SubscriptionPricing.swift`
  - [x] BillingPeriod enum (monthly/yearly)
  - [x] Price lookup and formatting
  - [x] Product ID mapping
  - [x] Yearly savings calculation

#### 10.3 StoreKit Manager ✅
- [x] Create `Core/Services/StoreKit/StoreKitManager.swift`
  - [x] StoreKit 2 integration with async/await
  - [x] Product loading
  - [x] Purchase flow with transaction verification
  - [x] Restore purchases via AppStore.sync()
  - [x] Transaction listener for real-time updates
  - [x] Subscription state persistence

#### 10.4 Subscription Service ✅
- [x] Create `Core/Services/StoreKit/SubscriptionService.swift`
  - [x] Entitlement checking
  - [x] Usage tracking (daily AI images, persona generations)
  - [x] Validation methods (canGenerateJournalImage, canCreatePersona)
  - [x] Paywall state management
  - [x] Daily usage reset logic
  - [x] Environment key for SwiftUI injection

#### 10.5 Paywall Display Manager ✅
- [x] Create `Core/Services/StoreKit/PaywallDisplayManager.swift`
  - [x] Paywall context (firstLaunch, periodicReminder, featureLimitHit, manualOpen)
  - [x] Exponential backoff for periodic reminders
  - [x] Monthly reset of dismiss count
  - [x] Analytics event tracking
  - [x] Debug info for testing

#### 10.6 Subscription Views ✅
- [x] Create `Features/Subscription/Views/PaywallView.swift`
  - [x] Hero section with contextual messaging
  - [x] Mood orb showcase with sample data
  - [x] Feature showcase with PaywallFeature list
  - [x] Pricing toggle (monthly/yearly)
  - [x] Plan cards (Enhanced/Premium)
  - [x] CTA button with purchase flow
  - [x] Trial offer banner
  - [x] Trust badges
  - [x] Footer with Terms/Privacy, restore purchases
- [x] Create `Features/Subscription/ViewModels/PaywallViewModel.swift`
  - [x] Product loading
  - [x] Purchase subscription flow
  - [x] Restore purchases flow
  - [x] Error handling
  - [x] Trial eligibility check

#### 10.7 Subscription Components ✅
- [x] Create `Features/Subscription/Components/PlanCard.swift`
  - [x] Multiple styles (selection, upgrade, currentPlan, full)
  - [x] Tier-specific styling and gradients
  - [x] Recommended badge
  - [x] Price display with savings
- [x] Create `Features/Subscription/Components/FeatureRow.swift`
  - [x] Card, list, and compact styles
  - [x] Icon with gradient
- [x] Create `Features/Subscription/Components/PricingToggleView.swift`
  - [x] Monthly/Yearly toggle with animation
  - [x] "Save 20%" badge for yearly
- [x] Create `Features/Subscription/Components/UpgradeButton.swift`
  - [x] Large, medium, small styles
  - [x] Processing state
  - [x] Tier-specific gradient
- [x] Create `Features/Subscription/Components/RestorePurchasesButton.swift`
  - [x] Footer and card styles
  - [x] Processing state
- [x] Create `Features/Subscription/Components/TrialOfferBanner.swift`
  - [x] Hero, compact, and card styles
  - [x] 7-day free trial messaging

#### 10.8 App Integration ✅
- [x] Update `RootView.swift` - Paywall sheet handling
- [x] Update `SettingsPlaceholderView` - Subscription section with upgrade button and usage stats
- [x] Debug controls for subscription/paywall reset

### Files Created
```
InkFiction/
├── InkFictionSubscriptions.storekit
├── Core/
│   └── Services/
│       └── StoreKit/
│           ├── StoreKitManager.swift
│           ├── SubscriptionService.swift
│           └── PaywallDisplayManager.swift
└── Features/
    └── Subscription/
        ├── Models/
        │   ├── SubscriptionTier.swift
        │   ├── SubscriptionPolicy.swift
        │   └── SubscriptionPricing.swift
        ├── Views/
        │   └── PaywallView.swift
        ├── ViewModels/
        │   └── PaywallViewModel.swift
        └── Components/
            ├── PlanCard.swift
            ├── FeatureRow.swift
            ├── PricingToggleView.swift
            ├── UpgradeButton.swift
            ├── RestorePurchasesButton.swift
            └── TrialOfferBanner.swift
```

### Build Verification
- [x] `fastlane build` - ✅ Build Succeeded

### Subscription Tiers

| Tier | Monthly | Yearly | AI Images/Day | Persona Styles | Storage |
|------|---------|--------|---------------|----------------|---------|
| Free | $0 | $0 | 0 | 0 | 100 MB |
| Enhanced | $4.99 | $47.99 | 4 | 3 | 2 GB |
| Premium | $12.99 | $124.99 | 20 | 5 | 10 GB |

### Reference Files (Old Project)
| New File | Reference From |
|----------|---------------|
| `SubscriptionTier.swift` | `ink-snap/InkFiction/Core/Subscription/SubscriptionPolicy.swift` |
| `SubscriptionPolicy.swift` | `ink-snap/InkFiction/Core/Subscription/SubscriptionPolicy.swift` |
| `SubscriptionPricing.swift` | `ink-snap/InkFiction/Core/Models/SubscriptionPricing.swift` |
| `StoreKitManager.swift` | `ink-snap/InkFiction/Core/Services/Payment/StoreKitManager.swift` |
| `PaywallView.swift` | `ink-snap/InkFiction/Features/Subscription/Views/PremiumPaywallView.swift` |
| `PaywallViewModel.swift` | `ink-snap/InkFiction/Features/Subscription/ViewModels/PaywallViewModel.swift` |
| `PaywallDisplayManager.swift` | `ink-snap/InkFiction/Core/Subscription/PaywallDisplayManager.swift` |
| `PlanCard.swift` | `ink-snap/InkFiction/Core/Components/Subscription/PlanCard.swift` |

---

## Phase 11: Themes & UI Polish

**Priority:** Medium
**Status:** Partially Complete (Tab Bar & FAB done)
**Description:** Visual theming and core UI components.

### Checklist

#### 11.1 Theme System ✅
- [x] Create `Core/Theme/Theme.swift` - Theme protocol
- [x] Create `Core/Theme/ThemeManager.swift` - Observable theme state
- [x] Implement 9 themes:
  - [x] Paper (default)
  - [x] Dawn
  - [x] Bloom
  - [x] Sky
  - [x] Pearl
  - [x] Sunset
  - [x] Forest
  - [x] Aqua
  - [x] Neon

#### 11.2 Core Components (Partial) ✅
- [x] Create `Core/Components/TabBar/FloatingTabBar.swift` - Custom floating tab bar
- [x] Create `Core/Components/TabBar/FloatingTabBarItem.swift` - Tab item component
- [x] Create `Core/Components/TabBar/TabBarConfiguration.swift` - Tab destinations
- [x] Create `Core/Components/TabBar/TabBarViewModel.swift` - Tab state management
- [x] Create `Core/Components/TabBar/FloatingActionButton.swift`
- [x] Create `Core/Components/TabBar/FloatingUIContainer.swift` - Container with metrics
- [ ] Create `Core/Components/AsyncImageView.swift`
- [ ] Create `Core/Components/LoadingView.swift`
- [ ] Create `Core/Components/EmptyStateView.swift`
- [ ] Create `Core/Components/SyncStatusView.swift`

#### 11.3 Main App Shell ✅
- [x] Create main `MainTabView` in `RootView.swift` with:
  - [x] Custom floating tab bar (4 tabs)
  - [x] Tab destinations: Journal, Timeline, Insights, Settings
  - [x] Floating action button for new entry (on Journal tab)
  - [x] Smooth tab transitions
  - [x] Scroll-based collapse/expand (iOS 18+)
  - [x] Glass morphism effects
  - [x] Theme integration

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

| Phase | Description | Priority | Status |
|-------|-------------|----------|--------|
| **0** | **Project Bootstrap & Infrastructure** | **Critical** | ✅ Completed |
| **1** | **Data Layer & iCloud Integration** | **Critical** | ✅ Completed |
| **2** | **Biometric App Protection** | **Critical** | ✅ Completed |
| **3** | **Onboarding Flow** | **High** | ✅ Completed |
| **4** | **Persona Feature** | **High** | ✅ Completed |
| **5** | **Journal Feature** | **Critical** | ✅ Completed |
| **6** | **AI Integration** | **High** | ✅ Completed |
| **7** | **Timeline & Analytics** | **Medium** | ✅ Completed |
| **8** | **Insights & Reflect** | **Medium** | ✅ Completed |
| **9** | Settings | Medium | Pending |
| **10** | **Subscription & StoreKit** | **High** | ✅ Completed |
| **11** | **Themes & UI Polish** | **Medium** | ⏳ Partial (Tab Bar + FAB) |
| **12** | Testing & QA | Critical | Pending |

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-03 | Initial plan |
| 1.1 | 2025-12-03 | Added Phase 0 (Fastlane, OSLog, Router), clarified single persona with multiple avatar styles, clarified biometric vs encryption, updated navigation to NavigationStack + Router |
| 1.2 | 2025-12-03 | **Phase 0 Completed** - Project bootstrap, Fastlane setup, OSLog logging, NavigationStack+Router, base app files, Info.plist permissions. Simplified to single build configuration. Build verified with `fastlane build`. |
| 1.3 | 2025-12-03 | **Phase 1 Completed** - CloudKit integration (CloudKitManager, CloudKitModels, SyncMonitor), SwiftData models for all entities, Repository pattern (JournalRepository, PersonaRepository, SettingsRepository). Offline-first approach with network reachability. Build verified. |
| 1.4 | 2025-12-03 | **Phase 2 Completed** - Biometric app protection (BiometricService, BiometricGateView, BiometricViewModel). Face ID/Touch ID authentication with LocalAuthentication framework, error handling, failed attempt tracking, passcode fallback. App locks on background/launch. Build verified. |
| 1.5 | 2025-12-03 | **Phase 3 Completed** - Full onboarding flow with 4 screens: Welcome (animated hero, swipe drawer), Personality Quiz (3 questions with auto-progression), AI Companion Selection (4 companions: Poet, Sage, Dreamer, Realist), Permissions (notifications, photos, biometric). Includes OnboardingViewModel, reusable components (NavigationBar, CompanionCard, MorphSymbolView). Theme-aware with Paper theme integration. Build verified. |
| 1.6 | 2025-12-03 | **Phase 11 Partial** - Custom floating tab bar with FAB implemented. Includes: FloatingTabBar (glass morphism, collapse/expand), FloatingTabBarItem (expanded/collapsed modes), FloatingActionButton (gradient + shadows), FloatingUIContainer (metrics-based layout), TabBarViewModel (state management), TabBarConfiguration (4 tabs: Journal, Timeline, Insights, Settings). Scroll-based collapse using iOS 18 onScrollGeometryChange. Updated iOS deployment target to 18.0. Theme system already complete with 9 themes. Build verified. |
| 1.7 | 2025-12-03 | **Phase 7 Completed** - Full Timeline feature with visual memory cards. Includes: CalendarModels (CalendarEntry, CalendarMonth, CalendarDay, MonthlyStats, CalendarNavigation), FrequencyData (stats, streaks, word count, achievements), DayGroupedEntry for entry grouping with mood distribution. Views: TimelineView (day/week/month filtering, insights card, SwiftData integration), VisualMemoryPeriodCard, EntriesDetailSheet, TimelineFilterView, EmptyTimelineView. Components: DateIndicatorView, PeriodIndicatorView, MoodDistributionView, TimelineConnector, StaticCardStackView, SwipeableCardStack with share functionality. Utilities: DateFormattingUtility (smart labels), PeriodFormatterUtility. TimelineViewModel with streak calculation, mood analysis, entry grouping. ImageContainer model for visual memories. RootView updated to use TimelineView. Build verified. |
| 1.8 | 2025-12-03 | **Phase 5 Completed** - Full Journal feature implementation. Models: JournalEntry (domain model), JournalImage, JournalFilterModels (DateRangeFilter, JournalFilterState, JournalSortOrder). Views: JournalListView (list with swipe actions, multi-selection, archive toggle), JournalEditorSheet (entry creation/editing), JournalEntryDetailView. ViewModels: JournalListViewModel (filtering, sorting, bulk operations, incremental search), JournalEditorViewModel (CRUD, image/tag management). Components: JournalEntryCard, ExpandableSearchBar (debounced, date filter), MoodSelectorView (animated grid), TagChip (flow layout), CustomDateRangePickerView. RootView updated to use JournalListView with proper editor sheet handling. Build verified. |
| 1.9 | 2025-12-03 | **Phase 8 Completed** - Full Reflect feature with organic mood orb visualization. Components: GlassmorphicMoodOrb (floating animation, glow effects, rim rotation), OrganicMoodOrbCluster (force-directed physics, collision detection, golden angle distribution), GradientBackground (animated layers, glass overlay). Views: ReflectView (AnimatedGradientBackground, NavigationHeaderView with menu, OrganicMoodOrbCluster, empty state), MoodDetailSheet (stats, visual memories, recent entries, image gallery), ReflectMoodDistributionView. Models: MoodData, MoodReflection, ReflectionConfig, TimeFrame, MoodDetectionKeywords, SentimentAnalysis. ViewModel: ReflectViewModel (mood analysis, keyword scoring, sentiment intensity, timeframe filtering). Updated NavigationHeaderView with menu/toggle button types. Added analytics and moodAnalysis log categories. Build verified. |
| 2.0 | 2025-12-04 | **Phase 10 Completed** - Full Subscription & StoreKit implementation. StoreKit Config: InkFictionSubscriptions.storekit with 4 products (Enhanced/Premium × Monthly/Yearly), 7-day trial for Enhanced. Models: SubscriptionTier (free/enhanced/premium with gradients), SubscriptionPolicy (tier limits, feature flags, retention offers), SubscriptionPricing (pricing, product IDs). Services: StoreKitManager (StoreKit 2, purchase/restore, transaction listener), SubscriptionService (entitlements, usage tracking, daily reset), PaywallDisplayManager (exponential backoff, context-aware). Views: PaywallView (hero, mood orb showcase, features, plan cards, trial banner, trust badges), PaywallViewModel (purchase flow, restore). Components: PlanCard (4 styles), FeatureRow, PricingToggleView, UpgradeButton, RestorePurchasesButton, TrialOfferBanner. App integration: RootView paywall sheet, Settings subscription section with debug controls. Build verified. |
| 2.1 | 2025-12-04 | **Phase 6 Completed** - Full AI Integration for Gemini 2.5 Flash via Vercel backend. Models: AIModels (request/response types, operation enums, context), AIError (comprehensive error handling). Prompt System: PromptPolicy protocol, PromptManager coordinator, 7 prompt policies (MoodAnalysis, TitleGeneration, JournalEnhancement, JournalImage, PersonaAvatar, Reflection, JournalProcessing). Services: GeminiService (core API client, retry logic), ImageGenerationService (avatar/journal images, caching, quota), MoodAnalysisService (AI + local fallback, batch analysis), ReflectionService (timeframe reflections, streak calculation), TitleGenerationService (titles, enhancement, full processing). Updated Constants with AI configuration, SubscriptionService with AI quota methods. iOS client ready; Vercel backend to be implemented separately. Build verified. |
| 2.2 | 2025-12-04 | **Phase 4 Completed** - Full Persona Feature implementation ported from old app. Models: PersonaProfile (domain model with consistency settings, mood tags, base prompt generation), PersonaAvatarStyleMetadata (favor ratings, usage tracking), EnvironmentPreference (15+ enums for environment/lighting/weather/season/color/background/camera settings), PersonaType (14 types with context keywords), PersonaUpdatePolicy (tier-based limits). Views: PersonaCreationSheet (2-step flow: photo → style review, step indicators, generation overlay), PersonaManagementSheet (free tier showcase, paid tier management, hero section, avatar carousel). Components: ImageCarouselView (photo library/selected cards, generation overlay), ImagePicker (PHPicker + Camera). ViewModels: PersonaCreationViewModel (validation, save with avatars, progress), PersonaViewModel (CRUD, active avatar). Navigation: Added sheet destinations and Router methods. Uses existing PolaroidFrameView from ImageContainers. Build verified. |
