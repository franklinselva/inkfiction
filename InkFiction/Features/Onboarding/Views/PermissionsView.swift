//
//  PermissionsView.swift
//  InkFiction
//
//  Final onboarding step for requesting app permissions
//

import SwiftUI
import Combine
import UserNotifications

struct PermissionsView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.themeManager) private var themeManager

    // MARK: - State

    @State private var animatePermissions = false
    @State private var showingSettingsAlert = false
    @State private var deniedPermission: Permission?
    @State private var isRequestingPermissions = false
    @State private var permissionStatuses: [Permission: PermissionStatus] = [
        .notifications: .notDetermined,
        .photoLibrary: .notDetermined,
        .biometric: .notDetermined
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Final Setup")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Text("Enable features for the best experience")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
            .padding(.horizontal, 24)

            // Permissions List
            ScrollView {
                VStack(spacing: 16) {
                    // Enable All Button
                    Button(action: {
                        Task {
                            await requestAllPermissions()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if isRequestingPermissions {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.gradientOverlayTextColor))
                                    .scaleEffect(0.8)
                                Text("Requesting...")
                                    .font(.system(size: 16, weight: .medium))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                Text("Enable All Permissions")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .foregroundColor(themeManager.currentTheme.gradientOverlayTextColor)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .background(
                            LinearGradient(
                                colors: themeManager.currentTheme.tabBarSelectionGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(isRequestingPermissions)
                    .opacity(isRequestingPermissions ? 0.7 : 1.0)
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                    // Permission Cards
                    ForEach(Array(Permission.allCases.enumerated()), id: \.element) { index, permission in
                        PermissionCard(
                            permission: permission,
                            status: permissionStatuses[permission] ?? .notDetermined,
                            action: {
                                Task {
                                    await handlePermissionRequest(permission)
                                }
                            }
                        )
                        .opacity(animatePermissions ? 1 : 0)
                        .offset(y: animatePermissions ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1),
                            value: animatePermissions
                        )
                    }

                    Text("You can change these settings anytime in the app")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)

            // Fixed Bottom Actions
            VStack(spacing: 0) {
                // Gradient fade
                LinearGradient(
                    colors: [themeManager.currentTheme.backgroundColor.opacity(0), themeManager.currentTheme.backgroundColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)

                VStack(spacing: 12) {
                    // Start Journaling Button
                    Button(action: {
                        completeOnboarding()
                    }) {
                        HStack(spacing: 12) {
                            if viewModel.isCompletingOnboarding {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.gradientOverlayTextColor))
                                    .scaleEffect(0.9)
                                Text("Setting up...")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            } else {
                                Text("Start Journaling")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(themeManager.currentTheme.gradientOverlayTextColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: themeManager.currentTheme.tabBarSelectionGradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isCompletingOnboarding || isRequestingPermissions)
                    .opacity(viewModel.isCompletingOnboarding || isRequestingPermissions ? 0.7 : 1.0)

                    // Skip button
                    Button(action: {
                        completeOnboarding(skipped: true)
                    }) {
                        Text("Set up later")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    .disabled(viewModel.isCompletingOnboarding || isRequestingPermissions)
                    .opacity(viewModel.isCompletingOnboarding || isRequestingPermissions ? 0.5 : 1.0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .background(themeManager.currentTheme.backgroundColor)
            }
        }
        .heroSymbol("bell.badge.fill", color: themeManager.currentTheme.accentColor)
        .alert("Permission Required", isPresented: $showingSettingsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            if let permission = deniedPermission {
                Text("You've previously denied \(permission.title) permission. Please enable it in Settings to use this feature.")
            }
        }
        .onAppear {
            Task {
                await checkAllPermissions()
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                animatePermissions = true
            }
        }
    }

    // MARK: - Actions

    private func completeOnboarding(skipped: Bool = false) {
        Task {
            await viewModel.completeOnboarding(skippedPermissions: skipped)
        }
    }

    // MARK: - Permission Handling

    private func checkAllPermissions() async {
        for permission in Permission.allCases {
            permissionStatuses[permission] = await checkPermissionStatus(permission)
        }
    }

    private func checkPermissionStatus(_ permission: Permission) async -> PermissionStatus {
        switch permission {
        case .notifications:
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .authorized: return .authorized
            case .denied: return .denied
            case .notDetermined: return .notDetermined
            default: return .notDetermined
            }

        case .photoLibrary:
            return .notDetermined

        case .biometric:
            return .notDetermined
        }
    }

    private func handlePermissionRequest(_ permission: Permission) async {
        guard !isRequestingPermissions else { return }

        let status = permissionStatuses[permission] ?? .notDetermined

        switch status {
        case .notDetermined:
            isRequestingPermissions = true
            let granted = await requestPermission(permission)
            permissionStatuses[permission] = granted ? .authorized : .denied
            if granted {
                viewModel.grantPermission(permission)
            }
            isRequestingPermissions = false

        case .denied:
            deniedPermission = permission
            showingSettingsAlert = true

        case .authorized:
            // Already authorized, toggle off
            permissionStatuses[permission] = .notDetermined
            viewModel.revokePermission(permission)

        case .notAvailable:
            break
        }
    }

    private func requestPermission(_ permission: Permission) async -> Bool {
        switch permission {
        case .notifications:
            do {
                return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            } catch {
                return false
            }

        case .photoLibrary:
            return true

        case .biometric:
            return true
        }
    }

    private func requestAllPermissions() async {
        guard !isRequestingPermissions else { return }

        isRequestingPermissions = true

        for permission in Permission.allCases {
            if permissionStatuses[permission] == .notDetermined {
                let granted = await requestPermission(permission)
                permissionStatuses[permission] = granted ? .authorized : .denied
                if granted {
                    viewModel.grantPermission(permission)
                }
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
        }

        isRequestingPermissions = false
    }
}

// MARK: - Permission Status

enum PermissionStatus {
    case notDetermined
    case authorized
    case denied
    case notAvailable
}

// MARK: - Permission Card

struct PermissionCard: View {
    let permission: Permission
    let status: PermissionStatus
    let action: () -> Void
    @Environment(\.themeManager) private var themeManager

    private var isGranted: Bool {
        status == .authorized
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            isGranted
                                ? LinearGradient(
                                    colors: themeManager.currentTheme.tabBarSelectionGradient.map { $0.opacity(0.2) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [themeManager.currentTheme.surfaceColor, themeManager.currentTheme.surfaceColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: isGranted ? permission.filledSystemImage : permission.systemImage)
                        .font(.system(size: 22))
                        .foregroundColor(
                            isGranted
                                ? themeManager.currentTheme.accentColor
                                : themeManager.currentTheme.textSecondaryColor
                        )
                        .symbolRenderingMode(.hierarchical)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(permission.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                        if status == .denied {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                        }
                    }

                    Text(permission.description)
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // Toggle indicator
                ZStack {
                    Capsule()
                        .fill(
                            isGranted
                                ? LinearGradient(
                                    colors: themeManager.currentTheme.tabBarSelectionGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [themeManager.currentTheme.strokeColor, themeManager.currentTheme.strokeColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .frame(width: 50, height: 30)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .offset(x: isGranted ? 10 : -10)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isGranted)
                }
            }
            .padding(16)
            .background(themeManager.currentTheme.surfaceColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isGranted
                            ? LinearGradient(
                                colors: themeManager.currentTheme.tabBarSelectionGradient.map { $0.opacity(0.5) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [themeManager.currentTheme.strokeColor.opacity(0.3), themeManager.currentTheme.strokeColor.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
