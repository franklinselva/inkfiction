//
//  RootView.swift
//  InkFiction
//
//  Root view that handles app flow and main tab navigation
//

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
                // Main app with custom floating tab bar
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

// MARK: - Main Tab View

struct MainTabView: View {

    @Environment(Router.self) private var router
    @Environment(\.themeManager) private var themeManager

    @State private var tabBarViewModel = TabBarViewModel()
    @State private var scrollOffset: CGFloat = 0

    // Scroll collapse thresholds
    private let collapseThreshold: CGFloat = 80
    private let expandThreshold: CGFloat = 65

    var body: some View {
        @Bindable var router = router

        let metrics = FloatingContainerMetrics(progress: tabBarViewModel.isCollapsed ? 1 : 0)

        ZStack(alignment: .bottom) {
            // Background
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()

            // Main content with NavigationStack
            NavigationStack(path: $router.path) {
                tabContent
                    .navigationDestination(for: Destination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Reserve space for floating tab bar
                Color.clear
                    .frame(height: metrics.safeAreaHeight)
            }

            // Bottom blur overlay
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: metrics.blurHeight)
                    .opacity(metrics.blurOpacity)
                    .mask(
                        LinearGradient(
                            colors: [.clear, .black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea()
            }
            .allowsHitTesting(false)

            // Floating UI (tab bar + FAB)
            VStack {
                Spacer()
                FloatingUIContainer(
                    viewModel: tabBarViewModel,
                    theme: themeManager.currentTheme,
                    metrics: metrics,
                    onNewEntry: {
                        router.createNewJournalEntry()
                    }
                )
                .padding(.bottom, metrics.bottomPadding)
            }
        }
        .sheet(item: $router.presentedSheet) { sheet in
            sheetView(for: sheet)
        }
        .fullScreenCover(item: $router.presentedFullScreenCover) { cover in
            fullScreenCoverView(for: cover)
        }
        .alert(
            router.alert?.title ?? "",
            isPresented: .init(
                get: { router.alert != nil },
                set: { if !$0 { router.dismissAlert() } }
            ),
            presenting: router.alert
        ) { alert in
            Button(alert.primaryButton.title, role: alert.primaryButton.role) {
                alert.primaryButton.action()
            }
            if let secondary = alert.secondaryButton {
                Button(secondary.title, role: secondary.role) {
                    secondary.action()
                }
            }
        } message: { alert in
            if let message = alert.message {
                Text(message)
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch tabBarViewModel.selectedTab {
        case .journal:
            JournalPlaceholderView()
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    handleScrollChange(newValue)
                }
        case .timeline:
            TimelinePlaceholderView()
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    handleScrollChange(newValue)
                }
        case .reflect:
            ReflectPlaceholderView()
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    handleScrollChange(newValue)
                }
        case .settings:
            SettingsPlaceholderView()
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    handleScrollChange(newValue)
                }
        }
    }

    // MARK: - Scroll Handling

    private func handleScrollChange(_ offset: CGFloat) {
        scrollOffset = offset

        // Collapse when scrolling down past threshold
        if offset > collapseThreshold && !tabBarViewModel.isCollapsed {
            tabBarViewModel.setCollapsedState(true)
        }
        // Expand when scrolling up past threshold (hysteresis for smoother behavior)
        else if offset < expandThreshold && tabBarViewModel.isCollapsed {
            tabBarViewModel.setCollapsedState(false)
        }
    }

    // MARK: - Destination Views

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
                .presentationDetents([.large])
        case .editJournalEntry(let id):
            Text("Edit Entry: \(id)")
                .presentationDetents([.large])
        case .paywall:
            Text("Upgrade to Premium")
                .presentationDetents([.medium, .large])
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

// MARK: - Tab Placeholder Views

struct JournalPlaceholderView: View {
    @Environment(Router.self) private var router
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)

                Image(systemName: "book.closed.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: themeManager.currentTheme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Journal")
                    .font(.largeTitle.bold())
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Text("Your entries will appear here")
                    .foregroundStyle(themeManager.currentTheme.textSecondaryColor)

                // Placeholder content for scroll testing
                ForEach(0..<10, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.currentTheme.surfaceColor)
                        .frame(height: 120)
                        .overlay(
                            Text("Entry \(index + 1)")
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        )
                }
            }
            .padding(.horizontal)
        }
        .background(themeManager.currentTheme.backgroundColor)
        .navigationTitle("Journal")
    }
}

struct TimelinePlaceholderView: View {
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: themeManager.currentTheme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Timeline")
                    .font(.largeTitle.bold())
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Text("Calendar view coming soon")
                    .foregroundStyle(themeManager.currentTheme.textSecondaryColor)

                // Placeholder for scroll
                ForEach(0..<8, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.currentTheme.surfaceColor)
                        .frame(height: 80)
                        .overlay(
                            Text("Day \(index + 1)")
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        )
                }
            }
            .padding(.horizontal)
        }
        .background(themeManager.currentTheme.backgroundColor)
        .navigationTitle("Timeline")
    }
}

struct ReflectPlaceholderView: View {
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)

                Image(systemName: "rainbow")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: themeManager.currentTheme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Reflect")
                    .font(.largeTitle.bold())
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Text("AI reflections coming soon")
                    .foregroundStyle(themeManager.currentTheme.textSecondaryColor)

                // Placeholder for scroll
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.currentTheme.surfaceColor)
                        .frame(height: 150)
                        .overlay(
                            Text("Reflection \(index + 1)")
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        )
                }
            }
            .padding(.horizontal)
        }
        .background(themeManager.currentTheme.backgroundColor)
        .navigationTitle("Reflect")
    }
}

struct SettingsPlaceholderView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Theme Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Theme")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(ThemeType.allCases, id: \.rawValue) { type in
                            ThemePreviewButton(
                                type: type,
                                isSelected: themeManager.currentTheme.type == type
                            ) {
                                themeManager.setTheme(type)
                            }
                        }
                    }
                }
                .padding()
                .background(themeManager.currentTheme.surfaceColor)
                .cornerRadius(16)

                // Debug Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Debug")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    Button("Reset Onboarding") {
                        appState.hasCompletedOnboarding = false
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)

                    Button("Lock App") {
                        appState.lock()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
                .padding()
                .background(themeManager.currentTheme.surfaceColor)
                .cornerRadius(16)

                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .background(themeManager.currentTheme.backgroundColor)
        .navigationTitle("Settings")
    }
}

// MARK: - Theme Preview Button

struct ThemePreviewButton: View {
    let type: ThemeType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                let theme = Theme.theme(for: type)

                // Theme preview circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: theme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected ? Color.white : Color.clear,
                                lineWidth: 3
                            )
                    )
                    .shadow(
                        color: isSelected ? theme.accentColor.opacity(0.5) : .clear,
                        radius: 8
                    )

                Text(type.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? theme.accentColor : .secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .environment(AppState())
        .environment(Router())
        .environment(\.themeManager, ThemeManager())
}
