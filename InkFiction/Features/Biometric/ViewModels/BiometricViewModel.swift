import Foundation
import SwiftUI

// MARK: - Biometric View Model

/// ViewModel for managing biometric authentication state and logic
@Observable
final class BiometricViewModel {

    // MARK: - Properties

    /// The biometric service for authentication
    private let biometricService: BiometricService

    /// Current authentication state
    private(set) var authState: AuthState = .idle

    /// The type of biometric available on this device
    private(set) var biometricType: BiometricType = .none

    /// Error message to display to the user
    private(set) var errorMessage: String?

    /// Number of failed authentication attempts
    private(set) var failedAttempts: Int = 0

    /// Maximum failed attempts before showing additional help
    private let maxFailedAttempts = 3

    // MARK: - Auth State

    enum AuthState: Equatable {
        case idle
        case authenticating
        case authenticated
        case failed
        case unavailable
    }

    // MARK: - Initialization

    init(biometricService: BiometricService = BiometricService()) {
        self.biometricService = biometricService
        self.biometricType = biometricService.availableBiometricType()
        Log.debug("BiometricViewModel initialized with biometric type: \(biometricType.displayName)", category: .biometric)
    }

    // MARK: - Public Methods

    /// Triggers biometric authentication
    @MainActor
    func authenticate() async {
        guard authState != .authenticating else {
            Log.debug("Authentication already in progress", category: .biometric)
            return
        }

        authState = .authenticating
        errorMessage = nil
        Log.info("Starting authentication attempt", category: .biometric)

        let result = await biometricService.authenticate()

        switch result {
        case .success:
            authState = .authenticated
            failedAttempts = 0
            Log.info("Authentication successful", category: .biometric)

        case .cancelled:
            authState = .idle
            Log.debug("Authentication cancelled by user", category: .biometric)

        case .failed(let error):
            handleAuthenticationFailure(error: error)

        case .notAvailable:
            authState = .unavailable
            errorMessage = "Biometric authentication is not available on this device."
            Log.warning("Biometric not available", category: .biometric)

        case .notEnrolled:
            authState = .unavailable
            errorMessage = "Please set up \(biometricType.displayName) in Settings to use this feature."
            Log.warning("Biometric not enrolled", category: .biometric)
        }
    }

    /// Authenticates with fallback to device passcode
    @MainActor
    func authenticateWithFallback() async {
        guard authState != .authenticating else { return }

        authState = .authenticating
        errorMessage = nil
        Log.info("Starting authentication with fallback", category: .biometric)

        let result = await biometricService.authenticateWithFallback()

        switch result {
        case .success:
            authState = .authenticated
            failedAttempts = 0
            Log.info("Authentication with fallback successful", category: .biometric)

        case .cancelled:
            authState = .idle
            Log.debug("Authentication cancelled", category: .biometric)

        case .failed(let error):
            handleAuthenticationFailure(error: error)

        case .notAvailable, .notEnrolled:
            authState = .unavailable
            errorMessage = "Device authentication is not available."
            Log.warning("Device authentication not available", category: .biometric)
        }
    }

    /// Resets the authentication state to idle
    @MainActor
    func resetState() {
        authState = .idle
        errorMessage = nil
        Log.debug("Authentication state reset", category: .biometric)
    }

    /// Checks if biometric is available and updates state accordingly
    @MainActor
    func checkAvailability() {
        biometricType = biometricService.availableBiometricType()

        if biometricType == .none && !biometricService.isDeviceAuthenticationAvailable() {
            authState = .unavailable
            errorMessage = "No authentication method available on this device."
            Log.warning("No authentication method available", category: .biometric)
        }
    }

    /// Returns whether the user should see additional help after multiple failures
    var shouldShowHelp: Bool {
        failedAttempts >= maxFailedAttempts
    }

    /// Returns the appropriate button title based on biometric type
    var unlockButtonTitle: String {
        switch biometricType {
        case .faceID: "Unlock with Face ID"
        case .touchID: "Unlock with Touch ID"
        case .none: "Unlock"
        }
    }

    /// Returns the appropriate system image for the biometric type
    var unlockButtonIcon: String {
        biometricType.systemImage
    }

    // MARK: - Private Methods

    @MainActor
    private func handleAuthenticationFailure(error: BiometricError) {
        authState = .failed
        failedAttempts += 1
        errorMessage = error.localizedDescription

        Log.warning("Authentication failed (attempt \(failedAttempts)): \(error.localizedDescription)", category: .biometric)

        if failedAttempts >= maxFailedAttempts {
            Log.info("Max failed attempts reached, showing help", category: .biometric)
        }
    }
}
