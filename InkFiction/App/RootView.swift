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

    @State private var isSplashAnimating = true

    var body: some View {
        Group {
            if !appState.hasSplashFinished {
                // Splash screen with warm-up progress
                SplashView(isAnimating: $isSplashAnimating)
            } else if !appState.isUnlocked {
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
        .animation(.easeInOut(duration: 0.3), value: appState.hasSplashFinished)
        .animation(.easeInOut(duration: 0.3), value: appState.isUnlocked)
        .animation(.easeInOut(duration: 0.3), value: appState.hasCompletedOnboarding)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {

    @Environment(Router.self) private var router
    @Environment(\.themeManager) private var themeManager
    @Environment(SubscriptionService.self) private var subscriptionService

    @State private var tabBarViewModel = TabBarViewModel()
    @State private var scrollOffset: CGFloat = 0
    @State private var journalViewModel = JournalListViewModel()
    @State private var showStartupPaywall = false

    // Scroll collapse thresholds
    private let collapseThreshold: CGFloat = 80
    private let expandThreshold: CGFloat = 65

    private let paywallDisplayManager = PaywallDisplayManager.shared

    /// Whether to show the floating tab bar (hide when navigated to a destination)
    private var shouldShowTabBar: Bool {
        router.path.isEmpty
    }

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
                // Reserve space for floating tab bar only when visible
                Color.clear
                    .frame(height: shouldShowTabBar ? metrics.safeAreaHeight : 0)
            }

            // Bottom blur overlay - only show when tab bar is visible
            if shouldShowTabBar {
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
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }

            // Floating UI (tab bar + FAB) - only show when on root tabs
            if shouldShowTabBar {
                GeometryReader { geometry in
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
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, metrics.bottomPadding))
                    }
                }
                .ignoresSafeArea()
                .transition(.move(edge: .bottom).combined(with: .opacity).animation(.easeInOut(duration: 0.25)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: shouldShowTabBar)
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
        .sheet(isPresented: $showStartupPaywall) {
            PaywallView(context: paywallDisplayManager.paywallContext)
                .environment(\.themeManager, themeManager)
                .interactiveDismissDisabled(paywallDisplayManager.paywallContext == .firstLaunch)
        }
        .onAppear {
            checkAndShowPaywall()
        }
    }

    // MARK: - Paywall Check

    private func checkAndShowPaywall() {
        // Check if we should show the paywall on app startup
        paywallDisplayManager.checkShouldShowPaywall()

        if paywallDisplayManager.shouldShowPaywall {
            // Delay slightly to ensure smooth transition after app loads
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showStartupPaywall = true
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch tabBarViewModel.selectedTab {
        case .journal:
            JournalListView(viewModel: journalViewModel, scrollOffset: $scrollOffset)
                .onChange(of: scrollOffset) { _, newValue in
                    handleScrollChange(newValue)
                }
        case .timeline:
            TimelineView(scrollOffset: $scrollOffset)
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    handleScrollChange(newValue)
                }
        case .reflect:
            ReflectView(scrollOffset: $scrollOffset)
                .onChange(of: scrollOffset) { _, newValue in
                    handleScrollChange(newValue)
                }
        case .settings:
            SettingsView()
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
            JournalEditorView(entryId: entryId)
        case .timelineDay(let date):
            Text("Timeline Day: \(date.formatted())")
        case .insightDetail(let type):
            Text("Insight: \(type.rawValue)")
        case .settingsSection(let section):
            settingsDestinationView(for: section)
        case .persona:
            Text("Persona Detail")
        case .personaManagement:
            PersonaManagementView()
                .navigationBarHidden(true)
        case .personaCreation:
            PersonaCreationView()
                .navigationBarHidden(true)
        case .personaEdit:
            Text("Edit Persona")
        case .avatarGeneration(let style):
            Text("Generate Avatar: \(style?.displayName ?? "Select Style")")
        case .subscription:
            SubscriptionStatusView()
        case .paywall:
            PaywallView(context: .manualOpen)
                .environment(\.themeManager, themeManager)
        default:
            Text("Unknown destination")
        }
    }

    @ViewBuilder
    private func settingsDestinationView(for section: SettingsSection) -> some View {
        switch section {
        case .account:
            AccountView()
        case .notifications:
            NotificationsView()
        case .theme:
            ThemeView()
        case .dataStorage:
            DataStorageView()
        case .about:
            AboutView()
        case .subscription:
            SubscriptionStatusView()
        case .aiFeatures:
            AIFeaturesView()
        case .export:
            ExportView()
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: SheetDestination) -> some View {
        switch sheet {
        case .newJournalEntry:
            // Now handled via push navigation
            EmptyView()
        case .editJournalEntry:
            // Now handled via push navigation
            EmptyView()
        case .paywall:
            PaywallView(context: .manualOpen)
                .environment(\.themeManager, themeManager)
        case .personaCreation:
            // Now handled via fullScreenCover
            EmptyView()
        case .personaManagement:
            // Now handled via fullScreenCover
            EmptyView()
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

// ReflectPlaceholderView removed - now using ReflectView
// SettingsPlaceholderView removed - now using SettingsView

// MARK: - Preview

#Preview {
    RootView()
        .environment(AppState())
        .environment(Router())
        .environment(\.themeManager, ThemeManager())
}
