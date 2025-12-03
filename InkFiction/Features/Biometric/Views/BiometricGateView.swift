import SwiftUI

// MARK: - Biometric Gate View

/// The lock screen view that requires biometric authentication to access the app
struct BiometricGateView: View {

    // MARK: - Properties

    @Environment(AppState.self) private var appState
    @State private var viewModel = BiometricViewModel()

    // MARK: - Body

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App Icon/Logo
            appIcon

            // App Title
            titleSection

            Spacer()

            // Authentication Section
            authenticationSection

            // Error Message
            if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            }

            // Help Section (after multiple failures)
            if viewModel.shouldShowHelp {
                helpSection
            }

            Spacer()
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            AnimatedGradientBackground()
                .ignoresSafeArea()
        }
        .task {
            await authenticateOnAppear()
        }
        .onChange(of: viewModel.authState) { _, newState in
            if newState == .authenticated {
                appState.unlock()
            }
        }
    }

    // MARK: - Subviews

    private var appIcon: some View {
        Image(systemName: viewModel.biometricType.systemImage)
            .font(.system(size: 80))
            .foregroundStyle(.blue)
            .symbolEffect(.pulse, options: .repeating, value: viewModel.authState == .authenticating)
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("InkFiction")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your personal journal awaits")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var authenticationSection: some View {
        VStack(spacing: 16) {
            // Main unlock button
            Button {
                Task {
                    await viewModel.authenticate()
                }
            } label: {
                HStack(spacing: 12) {
                    if viewModel.authState == .authenticating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: viewModel.unlockButtonIcon)
                    }
                    Text(viewModel.authState == .authenticating ? "Authenticating..." : viewModel.unlockButtonTitle)
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.authState == .authenticating ? Color.blue.opacity(0.7) : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
            }
            .disabled(viewModel.authState == .authenticating)

            // Try again button (shown after failure)
            if viewModel.authState == .failed {
                Button {
                    Task {
                        await viewModel.authenticate()
                    }
                } label: {
                    Text("Try Again")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }

            // Use passcode fallback (shown after multiple failures)
            if viewModel.shouldShowHelp {
                Button {
                    Task {
                        await viewModel.authenticateWithFallback()
                    }
                } label: {
                    Text("Use Passcode Instead")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func errorView(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }

    private var helpSection: some View {
        VStack(spacing: 8) {
            Text("Having trouble?")
                .font(.footnote)
                .fontWeight(.medium)

            Text("Make sure \(viewModel.biometricType.displayName) is set up in your device Settings.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    // MARK: - Methods

    private func authenticateOnAppear() async {
        // Small delay to allow the view to fully appear
        try? await Task.sleep(for: .milliseconds(300))

        // Check availability first
        viewModel.checkAvailability()

        // Auto-trigger authentication if available
        if viewModel.biometricType != .none {
            await viewModel.authenticate()
        }
    }
}

// MARK: - Preview

#Preview {
    BiometricGateView()
        .environment(AppState())
}
