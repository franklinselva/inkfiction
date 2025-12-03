import SwiftUI

// MARK: - Root View

/// The root view that handles app flow based on state
struct RootView: View {

    @Environment(AppState.self) private var appState
    @Environment(Router.self) private var router

    var body: some View {
        Group {
            if !appState.isUnlocked {
                // Biometric gate
                BiometricGateView()
            } else if !appState.hasCompletedOnboarding {
                // Onboarding flow (includes companion selection which serves as persona)
                OnboardingContainerView()
            } else {
                // Main app - go directly after onboarding is complete
                MainTabView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
            appState.completeOnboarding()
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isUnlocked)
        .animation(.easeInOut(duration: 0.3), value: appState.hasCompletedOnboarding)
    }
}

// MARK: - Placeholder Views (to be replaced in later phases)

// BiometricGateView is now implemented in Features/Biometric/Views/BiometricGateView.swift
// OnboardingContainerView is now implemented in Features/Onboarding/Views/OnboardingContainerView.swift
// Note: Persona creation is handled during onboarding (companion selection)

// MARK: - Main Tab View

struct MainTabView: View {
    @Environment(Router.self) private var router
    @State private var selectedTab: Tab = .journal

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            TabView(selection: $selectedTab) {
                JournalPlaceholderView()
                    .tag(Tab.journal)
                    .tabItem {
                        Label("Journal", systemImage: "book.closed")
                    }

                TimelinePlaceholderView()
                    .tag(Tab.timeline)
                    .tabItem {
                        Label("Timeline", systemImage: "calendar")
                    }

                InsightsPlaceholderView()
                    .tag(Tab.insights)
                    .tabItem {
                        Label("Insights", systemImage: "lightbulb")
                    }

                SettingsPlaceholderView()
                    .tag(Tab.settings)
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .navigationDestination(for: Destination.self) { destination in
                destinationView(for: destination)
            }
        }
        .sheet(item: $router.presentedSheet) { sheet in
            sheetView(for: sheet)
        }
        .fullScreenCover(item: $router.presentedFullScreenCover) { cover in
            fullScreenCoverView(for: cover)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: Destination) -> some View {
        switch destination {
        case .journalEntry(let id):
            Text("Journal Entry: \(id)")
        case .journalEditor(let entryId):
            Text("Journal Editor: \(entryId?.uuidString ?? "New")")
        case .timelineDay(let date):
            Text("Timeline Day: \(date.formatted())")
        case .insightDetail(let type):
            Text("Insight: \(type.rawValue)")
        case .settingsSection(let section):
            Text("Settings: \(section.rawValue)")
        case .persona:
            Text("Persona Detail")
        case .personaEdit:
            Text("Edit Persona")
        case .avatarGeneration(let style):
            Text("Generate Avatar: \(style?.displayName ?? "Select Style")")
        default:
            Text("Unknown destination")
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: SheetDestination) -> some View {
        switch sheet {
        case .newJournalEntry:
            Text("New Journal Entry")
        case .editJournalEntry(let id):
            Text("Edit Entry: \(id)")
        case .paywall:
            Text("Upgrade to Premium")
        default:
            Text("Sheet: \(sheet.id)")
        }
    }

    @ViewBuilder
    private func fullScreenCoverView(for cover: FullScreenDestination) -> some View {
        switch cover {
        case .onboarding:
            OnboardingContainerView()
        case .biometricGate:
            BiometricGateView()
        case .imageViewer(let imageId):
            Text("Image Viewer: \(imageId)")
        }
    }
}

// MARK: - Tab

enum Tab: String, CaseIterable {
    case journal
    case timeline
    case insights
    case settings
}

// MARK: - Tab Placeholder Views

struct JournalPlaceholderView: View {
    @Environment(Router.self) private var router

    var body: some View {
        VStack {
            Text("Journal")
                .font(.largeTitle)
            Text("Your entries will appear here")
                .foregroundStyle(.secondary)

            Button("Create Entry") {
                router.createNewJournalEntry()
            }
            .padding()
        }
        .navigationTitle("Journal")
    }
}

struct TimelinePlaceholderView: View {
    var body: some View {
        VStack {
            Text("Timeline")
                .font(.largeTitle)
            Text("Calendar view coming soon")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Timeline")
    }
}

struct InsightsPlaceholderView: View {
    var body: some View {
        VStack {
            Text("Insights")
                .font(.largeTitle)
            Text("Analytics coming soon")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Insights")
    }
}

struct SettingsPlaceholderView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            Section("Debug") {
                Button("Reset Onboarding") {
                    appState.hasCompletedOnboarding = false
                }
                Button("Lock App") {
                    appState.lock()
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    RootView()
        .environment(AppState())
        .environment(Router())
}
