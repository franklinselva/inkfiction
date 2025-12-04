//
//  SwiftDataModels.swift
//  InkFiction
//
//  SwiftData models for local persistence with CloudKit sync support
//
//  IMPORTANT: CloudKit integration requires:
//  - All attributes must be optional OR have default values
//  - All relationships must be optional
//  - No unique constraints (@Attribute(.unique) not allowed)
//

import CloudKit
import Foundation
import SwiftData
import SwiftUI

// MARK: - Journal Entry Model

@Model
final class JournalEntryModel {
    // Primary identifier (no unique constraint for CloudKit)
    var id: UUID = UUID()
    var title: String = ""
    var content: String = ""
    var moodRaw: String = "Neutral"
    // Tags stored as comma-separated string for CoreData/CloudKit compatibility
    var tagsRaw: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isArchived: Bool = false
    var isPinned: Bool = false

    // CloudKit sync tracking
    var cloudKitRecordName: String?
    var lastSyncedAt: Date?
    var needsSync: Bool = true

    // Relationships - MUST be optional for CloudKit
    @Relationship(deleteRule: .cascade, inverse: \JournalImageModel.journalEntry)
    var images: [JournalImageModel]?

    var mood: Mood {
        get { Mood(rawValue: moodRaw) ?? .neutral }
        set { moodRaw = newValue.rawValue }
    }

    // Computed property for tags array access
    var tags: [String] {
        get {
            guard !tagsRaw.isEmpty else { return [] }
            return tagsRaw.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            tagsRaw = newValue.joined(separator: ",")
        }
    }

    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        mood: Mood = .neutral,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false,
        isPinned: Bool = false,
        cloudKitRecordName: String? = nil,
        lastSyncedAt: Date? = nil,
        needsSync: Bool = true
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.moodRaw = mood.rawValue
        self.tagsRaw = tags.joined(separator: ",")
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.isPinned = isPinned
        self.cloudKitRecordName = cloudKitRecordName
        self.lastSyncedAt = lastSyncedAt
        self.needsSync = needsSync
        self.images = []
    }
}

// MARK: - Journal Image Model

@Model
final class JournalImageModel {
    var id: UUID = UUID()
    var imageData: Data?
    var caption: String?
    var isAIGenerated: Bool = false
    var createdAt: Date = Date()

    // CloudKit sync tracking
    var cloudKitRecordName: String?
    var lastSyncedAt: Date?
    var needsSync: Bool = true

    // Relationship - optional for CloudKit
    var journalEntry: JournalEntryModel?

    init(
        id: UUID = UUID(),
        imageData: Data? = nil,
        caption: String? = nil,
        isAIGenerated: Bool = false,
        createdAt: Date = Date(),
        cloudKitRecordName: String? = nil,
        lastSyncedAt: Date? = nil,
        needsSync: Bool = true
    ) {
        self.id = id
        self.imageData = imageData
        self.caption = caption
        self.isAIGenerated = isAIGenerated
        self.createdAt = createdAt
        self.cloudKitRecordName = cloudKitRecordName
        self.lastSyncedAt = lastSyncedAt
        self.needsSync = needsSync
    }
}

// MARK: - Persona Profile Model

@Model
final class PersonaProfileModel {
    var id: UUID = UUID()
    var name: String = ""
    var bio: String?
    var attributesData: Data?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // CloudKit sync tracking
    var cloudKitRecordName: String?
    var lastSyncedAt: Date?
    var needsSync: Bool = true

    // Relationships - MUST be optional for CloudKit
    @Relationship(deleteRule: .cascade, inverse: \PersonaAvatarModel.persona)
    var avatars: [PersonaAvatarModel]?

    // Active avatar tracking
    var activeAvatarId: UUID?

    // Computed property for attributes
    var attributes: PersonaAttributes? {
        get {
            guard let data = attributesData else { return nil }
            return try? JSONDecoder().decode(PersonaAttributes.self, from: data)
        }
        set {
            attributesData = try? JSONEncoder().encode(newValue)
        }
    }

    // Get active avatar
    var activeAvatar: PersonaAvatarModel? {
        guard let activeId = activeAvatarId else {
            return avatars?.first
        }
        return avatars?.first { $0.id == activeId }
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        bio: String? = nil,
        attributes: PersonaAttributes? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        activeAvatarId: UUID? = nil,
        cloudKitRecordName: String? = nil,
        lastSyncedAt: Date? = nil,
        needsSync: Bool = true
    ) {
        self.id = id
        self.name = name
        self.bio = bio
        self.attributesData = try? JSONEncoder().encode(attributes)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.activeAvatarId = activeAvatarId
        self.cloudKitRecordName = cloudKitRecordName
        self.lastSyncedAt = lastSyncedAt
        self.needsSync = needsSync
        self.avatars = []
    }
}

// MARK: - Persona Avatar Model

@Model
final class PersonaAvatarModel {
    var id: UUID = UUID()
    var styleRaw: String = "artistic"
    var imageData: Data?
    var createdAt: Date = Date()

    // CloudKit sync tracking
    var cloudKitRecordName: String?
    var lastSyncedAt: Date?
    var needsSync: Bool = true

    // Relationship - optional for CloudKit
    var persona: PersonaProfileModel?

    var style: AvatarStyle {
        get { AvatarStyle(rawValue: styleRaw) ?? .artistic }
        set { styleRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        style: AvatarStyle = .artistic,
        imageData: Data? = nil,
        createdAt: Date = Date(),
        cloudKitRecordName: String? = nil,
        lastSyncedAt: Date? = nil,
        needsSync: Bool = true
    ) {
        self.id = id
        self.styleRaw = style.rawValue
        self.imageData = imageData
        self.createdAt = createdAt
        self.cloudKitRecordName = cloudKitRecordName
        self.lastSyncedAt = lastSyncedAt
        self.needsSync = needsSync
    }
}

// MARK: - App Settings Model

@Model
final class AppSettingsModel {
    var id: UUID = UUID()
    var themeId: String = "paper"
    var notificationsEnabled: Bool = true
    var dailyReminderTime: Date?
    var aiAutoEnhance: Bool = true
    var aiAutoTitle: Bool = true
    var onboardingCompleted: Bool = false
    var updatedAt: Date = Date()

    // Journal Preferences (from onboarding)
    var journalingStyleRaw: String = "quick_notes"
    var emotionalExpressionRaw: String = "writing_freely"
    var visualPreferenceRaw: String = "abstract_dreamy"
    var selectedCompanionId: String = "realist"

    // CloudKit sync tracking
    var cloudKitRecordName: String?
    var lastSyncedAt: Date?
    var needsSync: Bool = true

    // Computed properties for type-safe access
    var journalingStyle: JournalingStyle {
        get { JournalingStyle(rawValue: journalingStyleRaw) ?? .quickNotes }
        set { journalingStyleRaw = newValue.rawValue }
    }

    var emotionalExpression: EmotionalExpression {
        get { EmotionalExpression(rawValue: emotionalExpressionRaw) ?? .writingFreely }
        set { emotionalExpressionRaw = newValue.rawValue }
    }

    var visualPreference: VisualPreference {
        get { VisualPreference(rawValue: visualPreferenceRaw) ?? .abstractDreamy }
        set { visualPreferenceRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        themeId: String = "paper",
        notificationsEnabled: Bool = true,
        dailyReminderTime: Date? = nil,
        aiAutoEnhance: Bool = true,
        aiAutoTitle: Bool = true,
        onboardingCompleted: Bool = false,
        updatedAt: Date = Date(),
        journalingStyleRaw: String = "quick_notes",
        emotionalExpressionRaw: String = "writing_freely",
        visualPreferenceRaw: String = "abstract_dreamy",
        selectedCompanionId: String = "realist",
        cloudKitRecordName: String? = nil,
        lastSyncedAt: Date? = nil,
        needsSync: Bool = true
    ) {
        self.id = id
        self.themeId = themeId
        self.notificationsEnabled = notificationsEnabled
        self.dailyReminderTime = dailyReminderTime
        self.aiAutoEnhance = aiAutoEnhance
        self.aiAutoTitle = aiAutoTitle
        self.onboardingCompleted = onboardingCompleted
        self.updatedAt = updatedAt
        self.journalingStyleRaw = journalingStyleRaw
        self.emotionalExpressionRaw = emotionalExpressionRaw
        self.visualPreferenceRaw = visualPreferenceRaw
        self.selectedCompanionId = selectedCompanionId
        self.cloudKitRecordName = cloudKitRecordName
        self.lastSyncedAt = lastSyncedAt
        self.needsSync = needsSync
    }

    static var `default`: AppSettingsModel {
        AppSettingsModel()
    }
}

// MARK: - Mood Enum

enum Mood: String, CaseIterable, Codable, Sendable {
    case happy = "Happy"
    case excited = "Excited"
    case peaceful = "Peaceful"
    case neutral = "Neutral"
    case thoughtful = "Thoughtful"
    case sad = "Sad"
    case anxious = "Anxious"
    case angry = "Angry"

    var sfSymbolName: String {
        switch self {
        case .happy: return "face.smiling.fill"
        case .excited: return "star.fill"
        case .peaceful: return "leaf.fill"
        case .neutral: return "minus.circle.fill"
        case .thoughtful: return "bubble.left.and.bubble.right.fill"
        case .sad: return "cloud.rain.fill"
        case .anxious: return "exclamationmark.triangle.fill"
        case .angry: return "flame.fill"
        }
    }

    var color: Color {
        switch self {
        case .happy: return .yellow
        case .excited: return .orange
        case .peaceful: return .green
        case .neutral: return .gray
        case .thoughtful: return .blue
        case .sad: return .indigo
        case .anxious: return .purple
        case .angry: return .red
        }
    }

    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .excited: return "🤩"
        case .peaceful: return "😌"
        case .neutral: return "😐"
        case .thoughtful: return "🤔"
        case .sad: return "😢"
        case .anxious: return "😰"
        case .angry: return "😠"
        }
    }
}

// MARK: - Avatar Style Enum

enum AvatarStyle: String, CaseIterable, Codable, Sendable {
    case artistic
    case cartoon
    case minimalist
    case watercolor
    case sketch

    var displayName: String {
        switch self {
        case .artistic: return "Artistic"
        case .cartoon: return "Cartoon"
        case .minimalist: return "Minimalist"
        case .watercolor: return "Watercolor"
        case .sketch: return "Sketch"
        }
    }

    var description: String {
        switch self {
        case .artistic: return "Creative artistic interpretation"
        case .cartoon: return "Western cartoon character"
        case .minimalist: return "Simple, clean design"
        case .watercolor: return "Soft watercolor painting"
        case .sketch: return "Pencil sketch style"
        }
    }

    var icon: String {
        switch self {
        case .artistic: return "paintpalette.fill"
        case .cartoon: return "face.smiling.fill"
        case .minimalist: return "circle.fill"
        case .watercolor: return "drop.fill"
        case .sketch: return "pencil"
        }
    }

    var previewColor: Color {
        switch self {
        case .artistic: return .purple
        case .cartoon: return .orange
        case .minimalist: return .gray
        case .watercolor: return .teal
        case .sketch: return .secondary
        }
    }
}

// MARK: - Persona Attributes

struct PersonaAttributes: Codable, Equatable, Sendable {
    var gender: Gender
    var ageRange: AgeRange
    var ethnicity: Ethnicity
    var hairStyle: HairStyle
    var hairColor: HairColor
    var eyeColor: EyeColor
    var facialFeatures: [FacialFeature]
    var clothingStyle: ClothingStyle
    var accessories: [Accessory]

    init(
        gender: Gender = .neutral,
        ageRange: AgeRange = .adult,
        ethnicity: Ethnicity = .ambiguous,
        hairStyle: HairStyle = .medium,
        hairColor: HairColor = .brown,
        eyeColor: EyeColor = .brown,
        facialFeatures: [FacialFeature] = [],
        clothingStyle: ClothingStyle = .casual,
        accessories: [Accessory] = []
    ) {
        self.gender = gender
        self.ageRange = ageRange
        self.ethnicity = ethnicity
        self.hairStyle = hairStyle
        self.hairColor = hairColor
        self.eyeColor = eyeColor
        self.facialFeatures = facialFeatures
        self.clothingStyle = clothingStyle
        self.accessories = accessories
    }

    // MARK: - Nested Enums

    enum Gender: String, Codable, CaseIterable, Sendable {
        case male, female, neutral
    }

    enum AgeRange: String, Codable, CaseIterable, Sendable {
        case child, teen, youngAdult, adult, middleAge, senior
    }

    enum Ethnicity: String, Codable, CaseIterable, Sendable {
        case ambiguous, caucasian, african, asian, hispanic, middleEastern, southAsian, mixed
    }

    enum HairStyle: String, Codable, CaseIterable, Sendable {
        case bald, short, medium, long, curly, wavy, braided, ponytail, bun
    }

    enum HairColor: String, Codable, CaseIterable, Sendable {
        case black, brown, blonde, red, gray, white, colorful
    }

    enum EyeColor: String, Codable, CaseIterable, Sendable {
        case brown, blue, green, hazel, gray, amber
    }

    enum FacialFeature: String, Codable, CaseIterable, Sendable {
        case glasses, sunglasses, beard, mustache, freckles, dimples, scars
    }

    enum ClothingStyle: String, Codable, CaseIterable, Sendable {
        case casual, business, sporty, elegant, artistic, vintage, streetwear
    }

    enum Accessory: String, Codable, CaseIterable, Sendable {
        case hat, earrings, necklace, watch, headphones, scarf, tie
    }
}

// MARK: - CloudKit Conversion Extensions

extension JournalEntryModel: CloudKitRecordConvertible {
    static var recordType: String { Constants.iCloud.RecordTypes.journalEntry }

    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, uuid: id)

        record[Constants.iCloud.RecordFields.JournalEntry.id] = id.uuidString
        record[Constants.iCloud.RecordFields.JournalEntry.title] = title
        record[Constants.iCloud.RecordFields.JournalEntry.content] = content
        record[Constants.iCloud.RecordFields.JournalEntry.mood] = moodRaw
        record[Constants.iCloud.RecordFields.JournalEntry.tags] = tags
        record[Constants.iCloud.RecordFields.JournalEntry.createdAt] = createdAt
        record[Constants.iCloud.RecordFields.JournalEntry.updatedAt] = updatedAt
        record.setBool(isArchived, for: Constants.iCloud.RecordFields.JournalEntry.isArchived)
        record.setBool(isPinned, for: Constants.iCloud.RecordFields.JournalEntry.isPinned)

        return record
    }

    convenience init?(from record: CKRecord) {
        guard record.recordType == Self.recordType,
              let idString = record.string(for: Constants.iCloud.RecordFields.JournalEntry.id),
              let id = UUID(uuidString: idString) else {
            return nil
        }

        self.init(
            id: id,
            title: record.string(for: Constants.iCloud.RecordFields.JournalEntry.title) ?? "",
            content: record.string(for: Constants.iCloud.RecordFields.JournalEntry.content) ?? "",
            mood: Mood(rawValue: record.string(for: Constants.iCloud.RecordFields.JournalEntry.mood) ?? "") ?? .neutral,
            tags: record.stringArray(for: Constants.iCloud.RecordFields.JournalEntry.tags),
            createdAt: record.date(for: Constants.iCloud.RecordFields.JournalEntry.createdAt) ?? Date(),
            updatedAt: record.date(for: Constants.iCloud.RecordFields.JournalEntry.updatedAt) ?? Date(),
            isArchived: record.bool(for: Constants.iCloud.RecordFields.JournalEntry.isArchived),
            isPinned: record.bool(for: Constants.iCloud.RecordFields.JournalEntry.isPinned),
            cloudKitRecordName: record.recordID.recordName,
            lastSyncedAt: Date(),
            needsSync: false
        )
    }
}

extension PersonaProfileModel: CloudKitRecordConvertible {
    static var recordType: String { Constants.iCloud.RecordTypes.personaProfile }

    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, uuid: id)

        record[Constants.iCloud.RecordFields.PersonaProfile.id] = id.uuidString
        record[Constants.iCloud.RecordFields.PersonaProfile.name] = name
        record[Constants.iCloud.RecordFields.PersonaProfile.bio] = bio
        record[Constants.iCloud.RecordFields.PersonaProfile.attributes] = attributesData
        record[Constants.iCloud.RecordFields.PersonaProfile.createdAt] = createdAt
        record[Constants.iCloud.RecordFields.PersonaProfile.updatedAt] = updatedAt

        return record
    }

    convenience init?(from record: CKRecord) {
        guard record.recordType == Self.recordType,
              let idString = record.string(for: Constants.iCloud.RecordFields.PersonaProfile.id),
              let id = UUID(uuidString: idString) else {
            return nil
        }

        let attributesData = record.data(for: Constants.iCloud.RecordFields.PersonaProfile.attributes)
        let attributes = attributesData.flatMap {
            try? JSONDecoder().decode(PersonaAttributes.self, from: $0)
        }

        self.init(
            id: id,
            name: record.string(for: Constants.iCloud.RecordFields.PersonaProfile.name) ?? "",
            bio: record.string(for: Constants.iCloud.RecordFields.PersonaProfile.bio),
            attributes: attributes,
            createdAt: record.date(for: Constants.iCloud.RecordFields.PersonaProfile.createdAt) ?? Date(),
            updatedAt: record.date(for: Constants.iCloud.RecordFields.PersonaProfile.updatedAt) ?? Date(),
            cloudKitRecordName: record.recordID.recordName,
            lastSyncedAt: Date(),
            needsSync: false
        )
    }
}

extension AppSettingsModel: CloudKitRecordConvertible {
    static var recordType: String { Constants.iCloud.RecordTypes.appSettings }

    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, uuid: id)

        record[Constants.iCloud.RecordFields.AppSettings.id] = id.uuidString
        record[Constants.iCloud.RecordFields.AppSettings.themeId] = themeId
        record.setBool(notificationsEnabled, for: Constants.iCloud.RecordFields.AppSettings.notificationsEnabled)
        record[Constants.iCloud.RecordFields.AppSettings.dailyReminderTime] = dailyReminderTime
        record.setBool(aiAutoEnhance, for: Constants.iCloud.RecordFields.AppSettings.aiAutoEnhance)
        record.setBool(aiAutoTitle, for: Constants.iCloud.RecordFields.AppSettings.aiAutoTitle)
        record.setBool(onboardingCompleted, for: Constants.iCloud.RecordFields.AppSettings.onboardingCompleted)
        record[Constants.iCloud.RecordFields.AppSettings.updatedAt] = updatedAt
        // Journal Preferences
        record[Constants.iCloud.RecordFields.AppSettings.journalingStyle] = journalingStyleRaw
        record[Constants.iCloud.RecordFields.AppSettings.emotionalExpression] = emotionalExpressionRaw
        record[Constants.iCloud.RecordFields.AppSettings.visualPreference] = visualPreferenceRaw
        record[Constants.iCloud.RecordFields.AppSettings.selectedCompanionId] = selectedCompanionId

        return record
    }

    convenience init?(from record: CKRecord) {
        guard record.recordType == Self.recordType,
              let idString = record.string(for: Constants.iCloud.RecordFields.AppSettings.id),
              let id = UUID(uuidString: idString) else {
            return nil
        }

        self.init(
            id: id,
            themeId: record.string(for: Constants.iCloud.RecordFields.AppSettings.themeId) ?? "paper",
            notificationsEnabled: record.bool(for: Constants.iCloud.RecordFields.AppSettings.notificationsEnabled),
            dailyReminderTime: record.date(for: Constants.iCloud.RecordFields.AppSettings.dailyReminderTime),
            aiAutoEnhance: record.bool(for: Constants.iCloud.RecordFields.AppSettings.aiAutoEnhance),
            aiAutoTitle: record.bool(for: Constants.iCloud.RecordFields.AppSettings.aiAutoTitle),
            onboardingCompleted: record.bool(for: Constants.iCloud.RecordFields.AppSettings.onboardingCompleted),
            updatedAt: record.date(for: Constants.iCloud.RecordFields.AppSettings.updatedAt) ?? Date(),
            journalingStyleRaw: record.string(for: Constants.iCloud.RecordFields.AppSettings.journalingStyle) ?? "quick_notes",
            emotionalExpressionRaw: record.string(for: Constants.iCloud.RecordFields.AppSettings.emotionalExpression) ?? "writing_freely",
            visualPreferenceRaw: record.string(for: Constants.iCloud.RecordFields.AppSettings.visualPreference) ?? "abstract_dreamy",
            selectedCompanionId: record.string(for: Constants.iCloud.RecordFields.AppSettings.selectedCompanionId) ?? "realist",
            cloudKitRecordName: record.recordID.recordName,
            lastSyncedAt: Date(),
            needsSync: false
        )
    }
}

// MARK: - JournalImageModel CloudKit Conversion

extension JournalImageModel {
    static var recordType: String { Constants.iCloud.RecordTypes.journalImage }

    /// Convert to CloudKit record with compressed image asset
    /// - Parameter entryId: The parent journal entry ID for reference
    /// - Returns: CKRecord with image asset, or nil if compression fails
    func toRecord(entryId: UUID) -> CKRecord? {
        let record = CKRecord(recordType: Self.recordType, uuid: id)

        record[Constants.iCloud.RecordFields.JournalImage.id] = id.uuidString
        record[Constants.iCloud.RecordFields.JournalImage.journalEntryId] = entryId.uuidString
        record[Constants.iCloud.RecordFields.JournalImage.caption] = caption
        record.setBool(isAIGenerated, for: Constants.iCloud.RecordFields.JournalImage.isAIGenerated)
        record[Constants.iCloud.RecordFields.JournalImage.createdAt] = createdAt

        // Set reference to parent journal entry
        let entryRecordID = CKRecord.ID(uuid: entryId, recordType: Constants.iCloud.RecordTypes.journalEntry)
        record.setReference(to: entryRecordID, for: Constants.iCloud.RecordFields.JournalImage.journalEntryId, action: .deleteSelf)

        // Compress and add image asset
        if let originalData = imageData {
            // Use optimal compression based on image type
            if let compressedData = ImageCompressionUtility.compressForCloudKit(
                imageData: originalData,
                isAIGenerated: isAIGenerated
            ) {
                do {
                    let asset = try CKRecord.createAsset(from: compressedData)
                    record[Constants.iCloud.RecordFields.JournalImage.imageAsset] = asset

                    let ratio = ImageCompressionUtility.compressionRatio(original: originalData, compressed: compressedData)
                    Log.debug("Image \(id) compressed for CloudKit: \(ImageCompressionUtility.formatBytes(originalData.count)) → \(ImageCompressionUtility.formatBytes(compressedData.count)) (ratio: \(String(format: "%.2f", ratio)))", category: .cloudKit)
                } catch {
                    Log.error("Failed to create CKAsset for image \(id)", error: error, category: .cloudKit)
                    return nil
                }
            } else {
                Log.warning("Failed to compress image \(id) for CloudKit", category: .cloudKit)
                return nil
            }
        }

        return record
    }

    /// Initialize from CloudKit record (without image data - loaded separately)
    convenience init?(from record: CKRecord) {
        guard record.recordType == Self.recordType,
              let idString = record.string(for: Constants.iCloud.RecordFields.JournalImage.id),
              let id = UUID(uuidString: idString) else {
            return nil
        }

        self.init(
            id: id,
            imageData: nil, // Image data loaded separately via asset
            caption: record.string(for: Constants.iCloud.RecordFields.JournalImage.caption),
            isAIGenerated: record.bool(for: Constants.iCloud.RecordFields.JournalImage.isAIGenerated),
            createdAt: record.date(for: Constants.iCloud.RecordFields.JournalImage.createdAt) ?? Date(),
            cloudKitRecordName: record.recordID.recordName,
            lastSyncedAt: Date(),
            needsSync: false
        )
    }

    /// Load image data from CloudKit record asset
    /// Call this after initializing from record to populate imageData
    func loadImageData(from record: CKRecord) async {
        do {
            if let data = try await record.assetData(for: Constants.iCloud.RecordFields.JournalImage.imageAsset) {
                self.imageData = data
                Log.debug("Loaded image data from CloudKit: \(ImageCompressionUtility.formatBytes(data.count))", category: .cloudKit)
            }
        } catch {
            Log.error("Failed to load image data from CloudKit for image \(id)", error: error, category: .cloudKit)
        }
    }
}
