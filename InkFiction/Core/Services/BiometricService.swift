import Foundation
import LocalAuthentication

// MARK: - Biometric Type

/// The type of biometric authentication available on the device
enum BiometricType {
    case faceID
    case touchID
    case none

    var displayName: String {
        switch self {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .none: "Passcode"
        }
    }

    var systemImage: String {
        switch self {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .none: "lock"
        }
    }
}

// MARK: - Auth Result

/// The result of a biometric authentication attempt
enum BiometricAuthResult: Equatable {
    case success
    case failed(BiometricError)
    case notAvailable
    case notEnrolled
    case cancelled

    static func == (lhs: BiometricAuthResult, rhs: BiometricAuthResult) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success): true
        case (.notAvailable, .notAvailable): true
        case (.notEnrolled, .notEnrolled): true
        case (.cancelled, .cancelled): true
        case (.failed(let lhsError), .failed(let rhsError)): lhsError == rhsError
        default: false
        }
    }
}

// MARK: - Biometric Error

/// Errors that can occur during biometric authentication
enum BiometricError: Error, Equatable {
    case authenticationFailed
    case userCancel
    case userFallback
    case systemCancel
    case passcodeNotSet
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryLockout
    case unknown(String)

    var localizedDescription: String {
        switch self {
        case .authenticationFailed: "Authentication failed. Please try again."
        case .userCancel: "Authentication was cancelled."
        case .userFallback: "Password authentication requested."
        case .systemCancel: "Authentication was cancelled by the system."
        case .passcodeNotSet: "Please set a device passcode to use this feature."
        case .biometryNotAvailable: "Biometric authentication is not available on this device."
        case .biometryNotEnrolled: "Please enroll in biometric authentication in Settings."
        case .biometryLockout: "Biometric authentication is locked. Please use your passcode."
        case .unknown(let message): message
        }
    }

    static func == (lhs: BiometricError, rhs: BiometricError) -> Bool {
        switch (lhs, rhs) {
        case (.authenticationFailed, .authenticationFailed): true
        case (.userCancel, .userCancel): true
        case (.userFallback, .userFallback): true
        case (.systemCancel, .systemCancel): true
        case (.passcodeNotSet, .passcodeNotSet): true
        case (.biometryNotAvailable, .biometryNotAvailable): true
        case (.biometryNotEnrolled, .biometryNotEnrolled): true
        case (.biometryLockout, .biometryLockout): true
        case (.unknown(let lhsMsg), .unknown(let rhsMsg)): lhsMsg == rhsMsg
        default: false
        }
    }
}

// MARK: - Biometric Service

/// Service for handling biometric authentication (Face ID / Touch ID)
final class BiometricService {

    // MARK: - Properties

    private let context: LAContext

    // MARK: - Initialization

    init() {
        self.context = LAContext()
        Log.debug("BiometricService initialized", category: .biometric)
    }

    // MARK: - Public Methods

    /// Returns the type of biometric authentication available on this device
    func availableBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            Log.debug("Biometric not available: \(error?.localizedDescription ?? "unknown")", category: .biometric)
            return .none
        }

        switch context.biometryType {
        case .faceID:
            Log.debug("Face ID available", category: .biometric)
            return .faceID
        case .touchID:
            Log.debug("Touch ID available", category: .biometric)
            return .touchID
        case .opticID:
            Log.debug("Optic ID available (treating as Face ID)", category: .biometric)
            return .faceID
        case .none:
            Log.debug("No biometry type available", category: .biometric)
            return .none
        @unknown default:
            Log.warning("Unknown biometry type", category: .biometric)
            return .none
        }
    }

    /// Checks if biometric authentication is available on this device
    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if let error = error {
            Log.debug("Biometric availability check failed: \(error.localizedDescription)", category: .biometric)
        }

        return canEvaluate
    }

    /// Checks if device owner authentication (biometric or passcode) is available
    func isDeviceAuthenticationAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)

        if let error = error {
            Log.debug("Device authentication availability check failed: \(error.localizedDescription)", category: .biometric)
        }

        return canEvaluate
    }

    /// Authenticates the user using biometrics
    /// - Parameter reason: The reason displayed to the user for why authentication is needed
    /// - Returns: The result of the authentication attempt
    func authenticate(reason: String = "Unlock InkFiction to access your journal") async -> BiometricAuthResult {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "" // Hide fallback option

        var error: NSError?

        // First check if biometric is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                let result = mapLAError(error)
                Log.warning("Biometric not available: \(error.localizedDescription)", category: .biometric)
                return result
            }
            return .notAvailable
        }

        Log.info("Starting biometric authentication", category: .biometric)
        let signpostID = Log.signpostBegin("BiometricAuth", category: .biometric)

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            Log.signpostEnd("BiometricAuth", signpostID: signpostID, category: .biometric)

            if success {
                Log.info("Biometric authentication successful", category: .biometric)
                return .success
            } else {
                Log.warning("Biometric authentication failed", category: .biometric)
                return .failed(.authenticationFailed)
            }
        } catch let error as NSError {
            Log.signpostEnd("BiometricAuth", signpostID: signpostID, category: .biometric)
            let result = mapLAError(error)
            Log.error("Biometric authentication error: \(error.localizedDescription)", category: .biometric)
            return result
        }
    }

    /// Authenticates using device owner authentication (biometric or passcode)
    /// - Parameter reason: The reason displayed to the user
    /// - Returns: The result of the authentication attempt
    func authenticateWithFallback(reason: String = "Unlock InkFiction to access your journal") async -> BiometricAuthResult {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            if let error = error {
                let result = mapLAError(error)
                Log.warning("Device authentication not available: \(error.localizedDescription)", category: .biometric)
                return result
            }
            return .notAvailable
        }

        Log.info("Starting device owner authentication", category: .biometric)

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )

            if success {
                Log.info("Device owner authentication successful", category: .biometric)
                return .success
            } else {
                Log.warning("Device owner authentication failed", category: .biometric)
                return .failed(.authenticationFailed)
            }
        } catch let error as NSError {
            let result = mapLAError(error)
            Log.error("Device owner authentication error: \(error.localizedDescription)", category: .biometric)
            return result
        }
    }

    // MARK: - Private Methods

    private func mapLAError(_ error: NSError) -> BiometricAuthResult {
        guard error.domain == LAError.errorDomain else {
            return .failed(.unknown(error.localizedDescription))
        }

        switch LAError.Code(rawValue: error.code) {
        case .authenticationFailed:
            return .failed(.authenticationFailed)
        case .userCancel:
            return .cancelled
        case .userFallback:
            return .failed(.userFallback)
        case .systemCancel:
            return .failed(.systemCancel)
        case .passcodeNotSet:
            return .failed(.passcodeNotSet)
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .failed(.biometryLockout)
        default:
            return .failed(.unknown(error.localizedDescription))
        }
    }
}
