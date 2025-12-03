//
//  SettingsView.swift
//  InkFiction
//
//  Main settings view with sections for all app settings
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(Router.self) private var router
    @State private var viewModel = SettingsViewModel()
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack {
            AnimatedGradientBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation header
                NavigationHeaderView(
                    config: NavigationHeaderConfig(
                        title: "Settings",
                        leftButton: .avatar(action: {}),
                        rightButton: .none
                    ),
                    scrollOffset: scrollOffset
                )
                .zIndex(1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // General Section (Account + Appearance)
                        generalSection

                        // Subscription Section
                        subscriptionSection

                        // Settings Section with navigation links
                        settingsSection

                        // Debug Section (DEBUG only)
                        #if DEBUG
                        debugSection
                        #endif

                        // Add bottom spacing to avoid tab bar overlap
                        Color.clear
                            .frame(height: 110)
                    }
                    .padding()
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    scrollOffset = -newValue
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadSettings()
            Task {
                await viewModel.calculateStorageUsage()
            }
        }
        .alert("Authentication", isPresented: $viewModel.showBiometricAlert) {
            Button("OK", role: .cancel) {
                viewModel.clearBiometricAlert()
            }
        } message: {
            Text(viewModel.biometricAlertMessage ?? "An error occurred.")
        }
    }

    // MARK: - General Section (Account + Appearance)

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                // Journal Preferences
                Button {
                    router.push(.settingsSection(section: .account))
                } label: {
                    HStack(spacing: 12) {
                        // Account icon
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(themeManager.currentTheme.accentColor)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Journal Preferences")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                            Text("Journal style, mood, visuals, AI companion")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    .padding()
                }

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                // Theme
                Button {
                    router.push(.settingsSection(section: .theme))
                } label: {
                    HStack {
                        SettingsRowLabel(
                            icon: "paintbrush.fill",
                            title: "Theme",
                            color: .purple
                        )

                        Spacer()

                        HStack(spacing: 4) {
                            ForEach(themeManager.currentTheme.gradientColors.prefix(3), id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 16, height: 16)
                            }
                        }

                        Text(themeManager.currentTheme.type.rawValue)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    .padding()
                }
            }
            .gradientCard()
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subscription")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            Button {
                router.push(.subscription)
            } label: {
                HStack(spacing: 12) {
                    // Subscription icon
                    Image(systemName: StoreKitManager.shared.subscriptionTier.badgeIcon)
                        .font(.system(size: 24))
                        .foregroundStyle(StoreKitManager.shared.subscriptionTier.gradient())
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 8) {
                        // Current tier display
                        HStack(spacing: 6) {
                            Text(StoreKitManager.shared.subscriptionTier.displayName)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                            if StoreKitManager.shared.subscriptionTier != .free {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 255/255, green: 204/255, blue: 0/255))
                            }
                        }

                        // Subscription details
                        if let expiresAt = StoreKitManager.shared.subscriptionExpiresAt {
                            Text("Renews \(expiresAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        } else if StoreKitManager.shared.subscriptionTier == .free {
                            Text("Upgrade for more features")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        }
                    }

                    Spacer()

                    if StoreKitManager.shared.subscriptionTier == .free {
                        Text("Upgrade")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: themeManager.currentTheme.gradientColors,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                }
                .padding()
                .gradientCard()
            }
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                // Notifications
                Button {
                    router.push(.settingsSection(section: .notifications))
                } label: {
                    HStack {
                        SettingsRowLabel(
                            icon: "bell.fill",
                            title: "Notifications",
                            color: .orange
                        )
                        Spacer()

                        if viewModel.notificationsEnabled {
                            Text("On")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    .padding()
                }

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                // Biometric Authentication Toggle
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(
                        isOn: Binding(
                            get: { viewModel.biometricAuthEnabled },
                            set: { viewModel.handleBiometricToggleChange($0) }
                        )
                    ) {
                        HStack(spacing: 12) {
                            Image(systemName: viewModel.biometricIconName)
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                                .frame(width: 28, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.green.opacity(0.15))
                                )

                            Text(viewModel.biometricDisplayName)
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        }
                    }
                    .tint(themeManager.currentTheme.accentColor)
                    .disabled(!viewModel.isBiometricAvailable || viewModel.isProcessingBiometric)

                    // Helper text
                    if !viewModel.isBiometricAvailable {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("Biometric authentication is not available on this device")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        }
                        .padding(.leading, 40)
                    } else if viewModel.biometricAuthEnabled {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text("You'll be asked to authenticate when opening the app")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        }
                        .padding(.leading, 40)
                    }
                }
                .padding()

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                // Data & Storage
                Button {
                    router.push(.settingsSection(section: .dataStorage))
                } label: {
                    HStack {
                        SettingsRowLabel(
                            icon: "internaldrive.fill",
                            title: "Data & Storage",
                            color: .blue
                        )
                        Spacer()

                        Text(viewModel.getStorageUsage())
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    .padding()
                }

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                // About
                Button {
                    router.push(.settingsSection(section: .about))
                } label: {
                    HStack {
                        SettingsRowLabel(
                            icon: "info.circle.fill",
                            title: "About",
                            color: .indigo
                        )
                        Spacer()

                        Text("v\(viewModel.getAppVersion())")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    .padding()
                }
            }
            .gradientCard()
        }
    }

    // MARK: - Debug Section

    #if DEBUG
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Debug")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                Button("Reset Onboarding") {
                    if let appState = getAppState() {
                        appState.hasCompletedOnboarding = false
                    }
                }
                .foregroundColor(themeManager.currentTheme.accentColor)

                Button("Lock App") {
                    if let appState = getAppState() {
                        appState.lock()
                    }
                }
                .foregroundColor(themeManager.currentTheme.accentColor)

                Button("Reset Subscription") {
                    StoreKitManager.shared.resetToFreeTier()
                }
                .foregroundColor(.orange)

                Button("Reset Paywall Tracking") {
                    PaywallDisplayManager.shared.resetForTesting()
                }
                .foregroundColor(.orange)
            }
            .padding()
            .gradientCard()
        }
    }

    private func getAppState() -> AppState? {
        // This is a workaround to get AppState from environment
        // In a real implementation, you'd inject this properly
        return nil
    }
    #endif
}

#Preview {
    SettingsView()
        .environment(\.themeManager, ThemeManager())
        .environment(Router())
}
