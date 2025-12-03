//
//  SecurityAndPrivacyView.swift
//  InkFiction
//
//  Security and privacy settings view with biometric auth and iCloud status
//

import SwiftUI

struct SecurityAndPrivacyView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SecurityAndPrivacyViewModel()
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                // Navigation header
                NavigationHeaderView(
                    config: NavigationHeaderConfig(
                        title: "Security",
                        leftButton: .back(action: { dismiss() }),
                        rightButton: viewModel.showingSaveSuccess
                            ? .icon("checkmark.circle.fill", action: {})
                            : .none
                    ),
                    scrollOffset: scrollOffset
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Authentication Section
                        authenticationSection

                        // iCloud Sync Section
                        iCloudSection

                        // Privacy Information
                        privacyInfoSection

                        // Add bottom spacing
                        Color.clear.frame(height: 120)
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
            viewModel.onAppear()
        }
        .alert("Biometric Authentication", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {
                viewModel.clearAlert()
            }
        } message: {
            Text(viewModel.alertMessage ?? "An error occurred.")
        }
    }

    // MARK: - Authentication Section

    private var authenticationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Authentication")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(spacing: 16) {
                Toggle(
                    isOn: Binding(
                        get: { viewModel.biometricAuthEnabled },
                        set: { viewModel.handleBiometricToggleChange($0) }
                    )
                ) {
                    HStack(spacing: 12) {
                        Image(systemName: viewModel.biometricIconName)
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.currentTheme.accentColor)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.biometricDisplayName)
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                            Text(viewModel.biometricDescription)
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        }
                    }
                }
                .tint(themeManager.currentTheme.accentColor)
                .disabled(!viewModel.isBiometricAvailable || viewModel.isProcessing)

                if viewModel.isProcessing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("Authenticating...")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    .padding(.horizontal, 4)
                } else if !viewModel.isBiometricAvailable {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)

                        Text("Biometric authentication is not available on this device.")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 4)
                } else if viewModel.biometricAuthEnabled {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)

                        Text("You'll be asked to authenticate when opening the app.")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding()
            .gradientCard()
        }
    }

    // MARK: - iCloud Section

    private var iCloudSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Sync")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                // iCloud Sync Status
                HStack(spacing: 12) {
                    Image(systemName: "icloud.fill")
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.currentTheme.accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("iCloud Sync")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                        Text("Your journal entries are automatically synced with iCloud")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.successColor)
                }
                .padding()

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                // Data Protection Info
                HStack(spacing: 12) {
                    Image(systemName: "lock.icloud.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Data Protection")
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                        Text("Your data is encrypted end-to-end with your Apple ID")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }

                    Spacer()
                }
                .padding()
            }
            .gradientCard()
        }
    }

    // MARK: - Privacy Info Section

    private var privacyInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(themeManager.currentTheme.accentColor)
                Text("Your Privacy")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 16) {
                privacyFeature(
                    icon: "lock.shield.fill",
                    color: .blue,
                    title: "Secure Storage",
                    description: "All journal entries are stored securely in iCloud"
                )

                privacyFeature(
                    icon: "eye.slash.fill",
                    color: .purple,
                    title: "Private by Default",
                    description: "Your data never leaves your Apple ID account"
                )

                privacyFeature(
                    icon: "key.fill",
                    color: .green,
                    title: "Only You Have Access",
                    description: "Your journal is protected by your device authentication"
                )
            }
            .padding()
            .gradientCard()
        }
    }

    private func privacyFeature(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundColor(.green)
        }
    }
}

// MARK: - View Model

@MainActor
@Observable
final class SecurityAndPrivacyViewModel {
    var biometricAuthEnabled: Bool = false
    var showingSaveSuccess: Bool = false
    var isProcessing: Bool = false
    var showAlert: Bool = false
    var alertMessage: String?
    var isBiometricAvailable: Bool = false
    private var biometricType: BiometricType = .none

    private let biometricService = BiometricService.shared

    var biometricIconName: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .none:
            return "lock.shield.fill"
        }
    }

    var biometricDisplayName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "Face ID / Touch ID"
        }
    }

    var biometricDescription: String {
        if isBiometricAvailable {
            return "Protect your journal with biometric authentication"
        } else {
            return "Biometric authentication is unavailable on this device"
        }
    }

    func onAppear() {
        biometricType = biometricService.availableBiometricType()
        isBiometricAvailable = biometricService.isBiometricAvailable()
        biometricAuthEnabled = biometricService.isEnabled
    }

    func handleBiometricToggleChange(_ newValue: Bool) {
        guard !isProcessing else { return }

        Task {
            await processToggleChange(to: newValue)
        }
    }

    private func processToggleChange(to newValue: Bool) async {
        guard newValue != biometricService.isEnabled else {
            biometricAuthEnabled = biometricService.isEnabled
            return
        }

        isProcessing = true
        alertMessage = nil
        showAlert = false

        if newValue {
            // Enabling biometric - verify user can authenticate
            guard isBiometricAvailable else {
                presentError("Biometric authentication is not available.")
                isProcessing = false
                return
            }

            let result = await biometricService.authenticate(reason: "Enable \(biometricDisplayName)")

            switch result {
            case .success:
                biometricService.isEnabled = true
                biometricAuthEnabled = true
                showSuccessIndicator()
            case .cancelled:
                biometricAuthEnabled = false
            case .failed(let error):
                presentError(error.localizedDescription)
                biometricAuthEnabled = false
            case .notAvailable, .notEnrolled:
                presentError("Biometric authentication is not available on this device.")
                biometricAuthEnabled = false
            }
        } else {
            // Disabling biometric
            biometricService.isEnabled = false
            biometricAuthEnabled = false
            showSuccessIndicator()
        }

        isProcessing = false
    }

    private func presentError(_ message: String) {
        alertMessage = message
        showAlert = true
    }

    private func showSuccessIndicator() {
        showingSaveSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showingSaveSuccess = false
        }
    }

    func clearAlert() {
        alertMessage = nil
        showAlert = false
    }
}

#Preview {
    SecurityAndPrivacyView()
        .environment(\.themeManager, ThemeManager())
}
