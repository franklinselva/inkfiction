import SwiftUI

// MARK: - Router

/// Centralized navigation router using NavigationStack
@Observable
final class Router {

    // MARK: - State

    var path = NavigationPath()
    var presentedSheet: SheetDestination?
    var presentedFullScreenCover: FullScreenDestination?
    var alert: AlertState?

    // MARK: - Navigation

    func push(_ destination: Destination) {
        Log.debug("Push: \(destination)", category: .navigation)
        path.append(destination)
    }

    func pop() {
        guard !path.isEmpty else { return }
        Log.debug("Pop", category: .navigation)
        path.removeLast()
    }

    func popToRoot() {
        Log.debug("Pop to root", category: .navigation)
        path = NavigationPath()
    }

    func pop(_ count: Int) {
        let removeCount = min(count, path.count)
        guard removeCount > 0 else { return }
        path.removeLast(removeCount)
    }

    func replace(with destination: Destination) {
        Log.debug("Replace with: \(destination)", category: .navigation)
        path = NavigationPath()
        path.append(destination)
    }

    // MARK: - Sheets

    func present(sheet: SheetDestination) {
        Log.debug("Present sheet: \(sheet)", category: .navigation)
        presentedSheet = sheet
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    // MARK: - Full Screen Covers

    func present(fullScreenCover: FullScreenDestination) {
        Log.debug("Present cover: \(fullScreenCover)", category: .navigation)
        presentedFullScreenCover = fullScreenCover
    }

    func dismissFullScreenCover() {
        presentedFullScreenCover = nil
    }

    // MARK: - Alerts

    func showAlert(_ alert: AlertState) {
        self.alert = alert
    }

    func dismissAlert() {
        alert = nil
    }

    // MARK: - Convenience

    func createNewJournalEntry() {
        present(sheet: .newJournalEntry)
    }

    func editJournalEntry(id: UUID) {
        present(sheet: .editJournalEntry(id: id))
    }

    func viewJournalEntry(id: UUID) {
        push(.journalEntry(id: id))
    }

    func showPaywall() {
        present(sheet: .paywall)
    }

    func showOnboarding() {
        present(fullScreenCover: .onboarding)
    }

    func showBiometricGate() {
        present(fullScreenCover: .biometricGate)
    }
}

// MARK: - Alert State

struct AlertState: Identifiable {
    let id = UUID()
    let title: String
    let message: String?
    let primaryButton: AlertButton
    let secondaryButton: AlertButton?

    struct AlertButton {
        let title: String
        let role: ButtonRole?
        let action: () -> Void

        init(title: String, role: ButtonRole? = nil, action: @escaping () -> Void = {}) {
            self.title = title
            self.role = role
            self.action = action
        }

        static func `default`(_ title: String, action: @escaping () -> Void = {}) -> AlertButton {
            AlertButton(title: title, action: action)
        }

        static func cancel(_ title: String = "Cancel") -> AlertButton {
            AlertButton(title: title, role: .cancel)
        }

        static func destructive(_ title: String, action: @escaping () -> Void) -> AlertButton {
            AlertButton(title: title, role: .destructive, action: action)
        }
    }

    init(title: String, message: String? = nil, primaryButton: AlertButton = .default("OK"), secondaryButton: AlertButton? = nil) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }
}

// MARK: - Environment

private struct RouterKey: EnvironmentKey {
    static let defaultValue = Router()
}

extension EnvironmentValues {
    var router: Router {
        get { self[RouterKey.self] }
        set { self[RouterKey.self] = newValue }
    }
}
