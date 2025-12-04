//
//  CloudKitManager.swift
//  InkFiction
//
//  CloudKit container management and account status handling
//

import CloudKit
import Foundation

// MARK: - CloudKit Errors

enum CloudKitError: LocalizedError {
    case notAuthenticated
    case accountRestricted
    case accountTemporarilyUnavailable
    case networkUnavailable
    case quotaExceeded
    case serverError(Error)
    case recordNotFound(CKRecord.ID)
    case conflictDetected(serverRecord: CKRecord)
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to iCloud in Settings to sync your data."
        case .accountRestricted:
            return "iCloud access is restricted. Please check parental controls."
        case .accountTemporarilyUnavailable:
            return "iCloud is temporarily unavailable. Please try again later."
        case .networkUnavailable:
            return "No internet connection. Your data will sync when online."
        case .quotaExceeded:
            return "iCloud storage is full. Please free up space to continue syncing."
        case .serverError(let error):
            return "Server error: \(error.localizedDescription)"
        case .recordNotFound(let recordID):
            return "Record not found: \(recordID.recordName)"
        case .conflictDetected:
            return "A newer version exists on iCloud."
        case .unknownError(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}

// MARK: - Account Status

enum CloudKitAccountStatus: Equatable {
    case available
    case noAccount
    case restricted
    case couldNotDetermine
    case temporarilyUnavailable

    var canSync: Bool {
        self == .available
    }

    var statusMessage: String {
        switch self {
        case .available:
            return "iCloud is available"
        case .noAccount:
            return "Sign in to iCloud to sync"
        case .restricted:
            return "iCloud access is restricted"
        case .couldNotDetermine:
            return "Unable to determine iCloud status"
        case .temporarilyUnavailable:
            return "iCloud temporarily unavailable"
        }
    }
}

// MARK: - CloudKit Manager

@Observable
final class CloudKitManager {

    // MARK: - Singleton

    static let shared = CloudKitManager()

    // MARK: - Properties

    private(set) var accountStatus: CloudKitAccountStatus = .couldNotDetermine
    private(set) var isCheckingAccount: Bool = false

    private let container: CKContainer
    private let privateDatabase: CKDatabase

    // MARK: - Initialization

    private init() {
        self.container = CKContainer(identifier: Constants.iCloud.containerIdentifier)
        self.privateDatabase = container.privateCloudDatabase

        Log.info("CloudKitManager initialized with container: \(Constants.iCloud.containerIdentifier)", category: .cloudKit)

        // Setup account change notification
        setupAccountChangeObserver()
    }

    // MARK: - Account Status

    /// Check the current iCloud account status
    @MainActor
    func checkAccountStatus() async {
        guard !isCheckingAccount else { return }

        isCheckingAccount = true
        defer { isCheckingAccount = false }

        Log.debug("Checking iCloud account status...", category: .cloudKit)

        do {
            let status = try await container.accountStatus()
            self.accountStatus = self.mapAccountStatus(status)
            Log.info("iCloud account status: \(self.accountStatus.statusMessage)", category: .cloudKit)
        } catch {
            self.accountStatus = .couldNotDetermine
            Log.error("Failed to check iCloud account status", error: error, category: .cloudKit)
        }
    }

    private func mapAccountStatus(_ status: CKAccountStatus) -> CloudKitAccountStatus {
        switch status {
        case .available:
            return .available
        case .noAccount:
            return .noAccount
        case .restricted:
            return .restricted
        case .couldNotDetermine:
            return .couldNotDetermine
        case .temporarilyUnavailable:
            return .temporarilyUnavailable
        @unknown default:
            return .couldNotDetermine
        }
    }

    private func setupAccountChangeObserver() {
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task {
                await self?.checkAccountStatus()
            }
        }
    }

    // MARK: - Database Access

    var database: CKDatabase {
        privateDatabase
    }

    // MARK: - CRUD Operations

    /// Save a record to CloudKit
    func save(_ record: CKRecord) async throws -> CKRecord {
        guard accountStatus.canSync else {
            throw CloudKitError.notAuthenticated
        }

        Log.debug("Saving record: \(record.recordType) - \(record.recordID.recordName)", category: .cloudKit)

        do {
            let savedRecord = try await privateDatabase.save(record)
            Log.info("Record saved successfully: \(savedRecord.recordID.recordName)", category: .cloudKit)
            return savedRecord
        } catch let error as CKError {
            throw mapCKError(error)
        } catch {
            throw CloudKitError.unknownError(error)
        }
    }

    /// Fetch a record by ID
    func fetch(recordID: CKRecord.ID) async throws -> CKRecord {
        guard accountStatus.canSync else {
            throw CloudKitError.notAuthenticated
        }

        Log.debug("Fetching record: \(recordID.recordName)", category: .cloudKit)

        do {
            let record = try await privateDatabase.record(for: recordID)
            Log.debug("Record fetched successfully: \(recordID.recordName)", category: .cloudKit)
            return record
        } catch let error as CKError {
            throw mapCKError(error)
        } catch {
            throw CloudKitError.unknownError(error)
        }
    }

    /// Delete a record by ID
    func delete(recordID: CKRecord.ID) async throws {
        guard accountStatus.canSync else {
            throw CloudKitError.notAuthenticated
        }

        Log.debug("Deleting record: \(recordID.recordName)", category: .cloudKit)

        do {
            try await privateDatabase.deleteRecord(withID: recordID)
            Log.info("Record deleted successfully: \(recordID.recordName)", category: .cloudKit)
        } catch let error as CKError {
            throw mapCKError(error)
        } catch {
            throw CloudKitError.unknownError(error)
        }
    }

    /// Query records with a predicate
    func query(
        recordType: String,
        predicate: NSPredicate = NSPredicate(value: true),
        sortDescriptors: [NSSortDescriptor]? = nil,
        resultsLimit: Int = 500
    ) async throws -> [CKRecord] {
        guard accountStatus.canSync else {
            throw CloudKitError.notAuthenticated
        }

        Log.debug("Querying records: \(recordType)", category: .cloudKit)

        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = sortDescriptors

        var allRecords: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor?

        do {
            // Initial query
            let (results, nextCursor) = try await privateDatabase.records(
                matching: query,
                inZoneWith: nil,
                desiredKeys: nil,
                resultsLimit: resultsLimit
            )

            for result in results {
                if case .success(let record) = result.1 {
                    allRecords.append(record)
                }
            }
            cursor = nextCursor

            // Continue fetching if there's more data
            while let currentCursor = cursor {
                let (moreResults, nextCursor) = try await privateDatabase.records(
                    continuingMatchFrom: currentCursor,
                    desiredKeys: nil,
                    resultsLimit: resultsLimit
                )

                for result in moreResults {
                    if case .success(let record) = result.1 {
                        allRecords.append(record)
                    }
                }
                cursor = nextCursor
            }

            Log.info("Query returned \(allRecords.count) records of type: \(recordType)", category: .cloudKit)
            return allRecords

        } catch let error as CKError {
            throw mapCKError(error)
        } catch {
            throw CloudKitError.unknownError(error)
        }
    }

    /// Batch save multiple records
    func batchSave(_ records: [CKRecord]) async throws -> [CKRecord] {
        guard accountStatus.canSync else {
            throw CloudKitError.notAuthenticated
        }

        guard !records.isEmpty else { return [] }

        Log.debug("Batch saving \(records.count) records", category: .cloudKit)

        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.isAtomic = false

        return try await withCheckedThrowingContinuation { continuation in
            var savedRecords: [CKRecord] = []

            operation.perRecordSaveBlock = { _, result in
                switch result {
                case .success(let record):
                    savedRecords.append(record)
                case .failure(let error):
                    Log.warning("Failed to save record in batch: \(error.localizedDescription)", category: .cloudKit)
                }
            }

            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    Log.info("Batch save completed: \(savedRecords.count) records saved", category: .cloudKit)
                    continuation.resume(returning: savedRecords)
                case .failure(let error):
                    if let ckError = error as? CKError {
                        continuation.resume(throwing: self.mapCKError(ckError))
                    } else {
                        continuation.resume(throwing: CloudKitError.unknownError(error))
                    }
                }
            }

            privateDatabase.add(operation)
        }
    }

    /// Batch delete multiple records
    func batchDelete(_ recordIDs: [CKRecord.ID]) async throws {
        guard accountStatus.canSync else {
            throw CloudKitError.notAuthenticated
        }

        guard !recordIDs.isEmpty else { return }

        Log.debug("Batch deleting \(recordIDs.count) records", category: .cloudKit)

        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
        operation.isAtomic = false

        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    Log.info("Batch delete completed: \(recordIDs.count) records deleted", category: .cloudKit)
                    continuation.resume()
                case .failure(let error):
                    if let ckError = error as? CKError {
                        continuation.resume(throwing: self.mapCKError(ckError))
                    } else {
                        continuation.resume(throwing: CloudKitError.unknownError(error))
                    }
                }
            }

            privateDatabase.add(operation)
        }
    }

    // MARK: - Error Mapping

    private func mapCKError(_ error: CKError) -> CloudKitError {
        switch error.code {
        case .notAuthenticated:
            return .notAuthenticated
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .quotaExceeded:
            return .quotaExceeded
        case .serverRecordChanged:
            if let serverRecord = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord {
                return .conflictDetected(serverRecord: serverRecord)
            }
            return .serverError(error)
        case .unknownItem:
            if let recordID = error.userInfo[CKRecordChangedErrorAncestorRecordKey] as? CKRecord.ID {
                return .recordNotFound(recordID)
            }
            return .serverError(error)
        case .serviceUnavailable, .requestRateLimited, .zoneBusy:
            return .accountTemporarilyUnavailable
        default:
            return .serverError(error)
        }
    }
}
