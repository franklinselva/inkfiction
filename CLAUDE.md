# InkFiction - Claude Session Reference

This file provides context for Claude in future sessions working on the InkFiction app.

## Project Overview

InkFiction is an iOS journaling app being rewritten from a Supabase-backed architecture to an iCloud-only (CloudKit) architecture.

### Key Characteristics
- **iOS 18.0+** target (updated for onScrollGeometryChange API)
- **SwiftUI** with **MVVM** architecture
- **NavigationStack + Router** pattern for navigation
- **CloudKit** for data sync (no Supabase)
- **Biometric protection** (Face ID/Touch ID) for app access
- **Single persona** with multiple avatar style variations
- **No journal encryption** - security via biometric + iCloud
- **Custom floating tab bar** with FAB and glass morphism effects

## Important Files

### Documentation
- **`docs/IMPLEMENTATION_PLAN.md`** - Master plan with all phases and checklists. **ALWAYS check and update this file.**

### Core Architecture
- `App/InkFictionApp.swift` - App entry point
- `App/AppState.swift` - Global state (@Observable)
- `App/RootView.swift` - Root view with app flow
- `Core/Navigation/Router.swift` - Navigation management
- `Core/Navigation/Destination.swift` - Navigation destinations
- `Core/Logging/Logger.swift` - OSLog-based logging
- `Core/Utilities/Constants.swift` - App constants

### Configuration
- `fastlane/Fastfile` - Build automation
- `Info.plist` - App permissions
- `InkFiction.entitlements` - iCloud/CloudKit entitlements

## Development Workflow

### 1. Before Starting Any Work
```
1. Read docs/IMPLEMENTATION_PLAN.md
2. Identify current phase and pending tasks
3. Check build status: fastlane build
```

### 2. During Development
```
1. Use fastlane build to verify changes
2. DO NOT change UI/View designs - only implement backend/logic
3. Follow existing patterns in codebase
```

### 3. After Completing Tasks
```
1. Run: fastlane build (must pass)
2. Update docs/IMPLEMENTATION_PLAN.md:
   - Mark completed items with [x]
   - Add completion date
   - Update revision history
3. List files created/modified
```

## Build Commands

```bash
# Build for simulator (iPhone Air)
fastlane build

# Run tests
fastlane test

# Upload to TestFlight
fastlane beta

# Release to App Store
fastlane release
```

## Project Structure

```
InkFiction/
├── App/                    # App entry, state, root view
├── Core/
│   ├── Navigation/         # Router, Destination
│   ├── Logging/           # OSLog Logger
│   ├── Data/
│   │   ├── CloudKit/      # CloudKit manager, sync
│   │   ├── Repository/    # Data repositories
│   │   └── SwiftData/     # Local models
│   ├── Services/
│   │   └── AI/            # Gemini, image generation
│   ├── Components/        # Reusable UI components
│   ├── Theme/             # Theming system
│   ├── Extensions/        # Swift extensions
│   └── Utilities/         # Constants, helpers
├── Features/
│   ├── Biometric/         # Face ID/Touch ID
│   ├── Onboarding/        # First-time user flow
│   ├── Persona/           # Single persona, multiple avatars
│   ├── Journal/           # Journal entries
│   ├── Timeline/          # Calendar view
│   ├── Insights/          # Analytics
│   ├── Reflect/           # AI reflections
│   ├── Settings/          # App settings
│   └── Subscription/      # StoreKit
├── Resources/             # Assets
├── docs/                  # Documentation
└── fastlane/              # Build automation
```

## Implementation Phases

| Phase | Description | Status |
|-------|-------------|--------|
| 0 | Project Bootstrap & Infrastructure | ✅ Completed |
| 1 | Data Layer & iCloud Integration | Pending |
| 2 | Biometric App Protection | Pending |
| 3 | Onboarding Flow | Pending |
| 4 | Persona Feature | Pending |
| 5 | Journal Feature | Pending |
| 6 | AI Integration | Pending |
| 7 | Timeline & Analytics | Pending |
| 8 | Insights & Reflect | Pending |
| 9 | Settings | Pending |
| 10 | Subscription & StoreKit | Pending |
| 11 | Themes & UI Polish | Pending |
| 12 | Testing & QA | Pending |

## Key Design Decisions

### Single Persona with Multiple Avatars
- One persona per user (name, bio, attributes)
- Multiple avatar styles: Artistic, Cartoon, Minimalist, Watercolor, Sketch
- User can generate avatars in different styles and switch active one

### No Journal Encryption
- Old app had password-based journal encryption
- New app: security via biometric (Face ID) + iCloud encryption
- Simpler user experience, no password to remember

### NavigationStack + Router Pattern
- Centralized `Router` class manages all navigation
- `Destination` enum for type-safe navigation
- Sheets and full-screen covers managed via Router
- Environment injection for access throughout app

### Logging with OSLog
- Categories: app, navigation, data, cloudKit, biometric, ai, subscription, ui, persona, journal, settings
- Levels: debug, info, warning, error
- Signpost support for performance profiling

## Old Project Reference

The old project is at: `/Users/franklinselva/dev/ink-snap/InkFiction`

Use it as reference for:
- UI designs (do not change)
- Feature implementations
- Model structures

Do NOT copy:
- Supabase code
- Encryption code
- Multi-persona management
- Account authentication

## Reminders

1. **Always use `fastlane build`** - Never use xcodebuild directly
2. **Always update IMPLEMENTATION_PLAN.md** after completing tasks
3. **Never change UI designs** - Only implement backend/logic
4. **Check this file** at the start of each session
5. **iPhone Air** is the target simulator device
