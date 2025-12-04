//
//  CloudKitModels.swift
//  InkFiction
//
//  CloudKit record type constants and conversion utilities
//

import CloudKit
import Foundation

// MARK: - Record Type Constants

extension Constants.iCloud {
    enum RecordFields {

        // MARK: - JournalEntry Fields

        enum JournalEntry {
            static let id = "id"
            static let title = "title"
            static let content = "content"
            static let mood = "mood"
            static let tags = "tags"
            static let createdAt = "createdAt"
            static let updatedAt = "updatedAt"
            static let isArchived = "isArchived"
            static let isPinned = "isPinned"
        }

        // MARK: - JournalImage Fields

        enum JournalImage {
            static let id = "id"
            static let journalEntryId = "journalEntryId"
            static let imageAsset = "imageAsset"
            static let caption = "caption"
            static let isAIGenerated = "isAIGenerated"
            static let createdAt = "createdAt"
        }

        // MARK: - PersonaProfile Fields

        enum PersonaProfile {
            static let id = "id"
            static let name = "name"
            static let bio = "bio"
            static let attributes = "attributes"
            static let createdAt = "createdAt"
            static let updatedAt = "updatedAt"
        }

        // MARK: - PersonaAvatar Fields

        enum PersonaAvatar {
            static let id = "id"
            static let personaId = "personaId"
            static let style = "style"
            static let imageAsset = "imageAsset"
            static let isActive = "isActive"
            static let createdAt = "createdAt"
        }

        // MARK: - AppSettings Fields

        enum AppSettings {
            static let id = "id"
            static let themeId = "themeId"
            static let notificationsEnabled = "notificationsEnabled"
            static let dailyReminderTime = "dailyReminderTime"
            static let aiAutoEnhance = "aiAutoEnhance"
            static let aiAutoTitle = "aiAutoTitle"
            static let onboardingCompleted = "onboardingCompleted"
            static let updatedAt = "updatedAt"
            // Journal Preferences
            static let journalingStyle = "journalingStyle"
            static let emotionalExpression = "emotionalExpression"
            static let visualPreference = "visualPreference"
            static let selectedCompanionId = "selectedCompanionId"
        }
    }
}

// MARK: - CKRecord ID Helpers

extension CKRecord.ID {
    /// Create a record ID from a UUID
    convenience init(uuid: UUID, recordType: String) {
        self.init(recordName: "\(recordType)_\(uuid.uuidString)")
    }

    /// Extract UUID from record name if possible
    var extractedUUID: UUID? {
        // Record name format: "RecordType_UUID"
        let components = recordName.split(separator: "_")
        guard components.count >= 2,
              let uuidString = components.last,
              let uuid = UUID(uuidString: String(uuidString)) else {
            return nil
        }
        return uuid
    }
}

// MARK: - CKRecord Helpers

extension CKRecord {
    /// Create a new CKRecord with a UUID-based record ID
    convenience init(recordType: String, uuid: UUID) {
        let recordID = CKRecord.ID(uuid: uuid, recordType: recordType)
        self.init(recordType: recordType, recordID: recordID)
    }

    /// Get string value safely
    func string(for key: String) -> String? {
        self[key] as? String
    }

    /// Get date value safely
    func date(for key: String) -> Date? {
        self[key] as? Date
    }

    /// Get integer value safely
    func integer(for key: String) -> Int? {
        (self[key] as? NSNumber)?.intValue
    }

    /// Get boolean value safely (stored as Int64 in CloudKit)
    func bool(for key: String) -> Bool {
        (self[key] as? Int64) == 1
    }

    /// Set boolean value (stored as Int64 in CloudKit)
    func setBool(_ value: Bool, for key: String) {
        self[key] = value ? 1 : 0 as Int64
    }

    /// Get string array safely
    func stringArray(for key: String) -> [String] {
        self[key] as? [String] ?? []
    }

    /// Get data value safely
    func data(for key: String) -> Data? {
        self[key] as? Data
    }

    /// Get asset and load data
    func assetData(for key: String) async throws -> Data? {
        guard let asset = self[key] as? CKAsset,
              let fileURL = asset.fileURL else {
            return nil
        }
        return try Data(contentsOf: fileURL)
    }

    /// Create asset from data
    static func createAsset(from data: Data) throws -> CKAsset {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try data.write(to: tempURL)
        return CKAsset(fileURL: tempURL)
    }
}

// MARK: - CloudKit Record Convertible Protocol

protocol CloudKitRecordConvertible {
    /// The CloudKit record type for this model
    static var recordType: String { get }

    /// Convert to a CKRecord
    func toRecord() -> CKRecord

    /// Initialize from a CKRecord
    init?(from record: CKRecord)
}

// MARK: - Sync Metadata

/// Metadata for tracking sync status of local records
struct CloudKitSyncMetadata: Codable {
    let localID: UUID
    var cloudKitRecordName: String?
    var lastSyncedAt: Date?
    var needsSync: Bool
    var syncError: String?

    init(localID: UUID) {
        self.localID = localID
        self.cloudKitRecordName = nil
        self.lastSyncedAt = nil
        self.needsSync = true
        self.syncError = nil
    }

    mutating func markSynced(recordName: String) {
        self.cloudKitRecordName = recordName
        self.lastSyncedAt = Date()
        self.needsSync = false
        self.syncError = nil
    }

    mutating func markNeedsSync() {
        self.needsSync = true
    }

    mutating func markError(_ error: String) {
        self.syncError = error
        self.needsSync = true
    }
}

// MARK: - Reference Helpers

extension CKRecord {
    /// Create a reference to another record
    func setReference(
        to recordID: CKRecord.ID,
        for key: String,
        action: CKRecord.ReferenceAction = .none
    ) {
        self[key] = CKRecord.Reference(recordID: recordID, action: action)
    }

    /// Get referenced record ID
    func referenceID(for key: String) -> CKRecord.ID? {
        (self[key] as? CKRecord.Reference)?.recordID
    }
}
