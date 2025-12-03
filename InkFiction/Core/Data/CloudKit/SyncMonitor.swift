//
//  SyncMonitor.swift
//  InkFiction
//
//  Monitor and track CloudKit sync status with network reachability
//

import Combine
import Foundation
import Network

// MARK: - Sync State

enum SyncState: Equatable {
    case idle
    case syncing(progress: Double)
    case synced(lastSync: Date)
    case error(message: String)
    case offline
    case waitingForNetwork

    var isActive: Bool {
        if case .syncing = self { return true }
        return false
    }

    var displayText: String {
        switch self {
        case .idle:
            return "Ready to sync"
        case .syncing(let progress):
            if progress > 0 {
                return "Syncing \(Int(progress * 100))%..."
            }
            return "Syncing..."
        case .synced(let date):
            return "Synced \(date.formatted(.relative(presentation: .named)))"
        case .error(let message):
            return "Sync error: \(message)"
        case .offline:
            return "Offline - changes saved locally"
        case .waitingForNetwork:
            return "Waiting for network..."
        }
    }

    var icon: String {
        switch self {
        case .idle:
            return "icloud"
        case .syncing:
            return "arrow.triangle.2.circlepath.icloud"
        case .synced:
            return "checkmark.icloud"
        case .error:
            return "exclamationmark.icloud"
        case .offline, .waitingForNetwork:
            return "icloud.slash"
        }
    }

    var color: String {
        switch self {
        case .idle, .synced:
            return "green"
        case .syncing, .waitingForNetwork:
            return "blue"
        case .error:
            return "red"
        case .offline:
            return "gray"
        }
    }
}

// MARK: - Sync Monitor

@Observable
final class SyncMonitor {

    // MARK: - Singleton

    static let shared = SyncMonitor()

    // MARK: - Properties

    private(set) var syncState: SyncState = .idle
    private(set) var isNetworkAvailable: Bool = true
    private(set) var pendingSyncCount: Int = 0
    private(set) var lastSuccessfulSync: Date?

    private let networkMonitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.inkfiction.network.monitor")

    private var syncOperationsInProgress: Int = 0
    private var totalSyncOperations: Int = 0

    // MARK: - Initialization

    private init() {
        self.networkMonitor = NWPathMonitor()
        setupNetworkMonitoring()
        Log.info("SyncMonitor initialized", category: .cloudKit)
    }

    deinit {
        networkMonitor.cancel()
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.handleNetworkChange(path)
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }

    @MainActor
    private func handleNetworkChange(_ path: NWPath) {
        let wasAvailable = isNetworkAvailable
        isNetworkAvailable = path.status == .satisfied

        Log.debug("Network status changed: \(isNetworkAvailable ? "available" : "unavailable")", category: .cloudKit)

        if !isNetworkAvailable {
            syncState = .offline
        } else if !wasAvailable && isNetworkAvailable {
            // Network just became available
            if pendingSyncCount > 0 {
                syncState = .waitingForNetwork
                // Notify that sync can resume
                NotificationCenter.default.post(name: .syncNetworkBecameAvailable, object: nil)
            } else {
                syncState = .idle
            }
        }
    }

    // MARK: - Sync State Management

    /// Call when starting a sync operation
    func beginSync(totalOperations: Int = 1) {
        Task { @MainActor in
            totalSyncOperations = totalOperations
            syncOperationsInProgress = 0
            syncState = .syncing(progress: 0)
            Log.debug("Sync began with \(totalOperations) operations", category: .cloudKit)
        }
    }

    /// Call to update sync progress
    func updateProgress(completed: Int) {
        Task { @MainActor in
            syncOperationsInProgress = completed
            let progress = totalSyncOperations > 0
                ? Double(completed) / Double(totalSyncOperations)
                : 0
            syncState = .syncing(progress: min(progress, 0.99))
        }
    }

    /// Call when sync completes successfully
    func endSync() {
        Task { @MainActor in
            let now = Date()
            lastSuccessfulSync = now
            syncState = .synced(lastSync: now)
            pendingSyncCount = 0

            // Save last sync date
            UserDefaults.standard.set(now, forKey: Constants.UserDefaultsKeys.lastSyncDate)

            Log.info("Sync completed successfully", category: .cloudKit)
        }
    }

    /// Call when sync fails
    func syncFailed(error: Error) {
        Task { @MainActor in
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            syncState = .error(message: message)
            Log.error("Sync failed: \(message)", category: .cloudKit)
        }
    }

    /// Call to reset to idle state
    func resetToIdle() {
        Task { @MainActor in
            if isNetworkAvailable {
                syncState = .idle
            } else {
                syncState = .offline
            }
        }
    }

    /// Increment pending sync count
    func addPendingSync() {
        Task { @MainActor in
            pendingSyncCount += 1
            Log.debug("Pending sync count: \(pendingSyncCount)", category: .cloudKit)
        }
    }

    /// Decrement pending sync count
    func removePendingSync() {
        Task { @MainActor in
            pendingSyncCount = max(0, pendingSyncCount - 1)
        }
    }

    // MARK: - Convenience

    /// Check if sync should be attempted
    var canSync: Bool {
        isNetworkAvailable && CloudKitManager.shared.accountStatus.canSync
    }

    /// Load last sync date from storage
    func loadLastSyncDate() {
        if let date = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.lastSyncDate) as? Date {
            lastSuccessfulSync = date
            syncState = .synced(lastSync: date)
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let syncNetworkBecameAvailable = Notification.Name("syncNetworkBecameAvailable")
    static let syncStatusChanged = Notification.Name("syncStatusChanged")
}

// MARK: - AppState Integration

extension AppState {
    /// Update sync status from SyncMonitor state
    func updateSyncStatus(from state: SyncState) {
        switch state {
        case .idle:
            syncStatus = .idle
        case .syncing:
            syncStatus = .syncing
        case .synced(let date):
            syncStatus = .synced(date)
        case .error(let message):
            syncStatus = .error(message)
        case .offline, .waitingForNetwork:
            syncStatus = .offline
        }
    }
}
