//
//  PersonaRepository.swift
//  InkFiction
//
//  Repository for single persona management with multiple avatar style variations
//

import CloudKit
import Foundation
import SwiftData

// MARK: - Persona Repository Errors

enum PersonaRepositoryError: LocalizedError {
    case modelContextNotAvailable
    case personaNotFound
    case avatarNotFound(UUID)
    case saveFailed(Error)
    case deleteFailed(Error)
    case syncFailed(Error)
    case avatarLimitReached(AvatarStyle)

    var errorDescription: String? {
        switch self {
        case .modelContextNotAvailable:
            return "Database context is not available."
        case .personaNotFound:
            return "Persona not found."
        case .avatarNotFound(let id):
            return "Avatar not found: \(id)"
        case .saveFailed(let error):
            return "Failed to save persona: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete persona: \(error.localizedDescription)"
        case .syncFailed(let error):
            return "Failed to sync with iCloud: \(error.localizedDescription)"
        case .avatarLimitReached(let style):
            return "Maximum avatars reached for style: \(style.displayName)"
        }
    }
}

// MARK: - Persona Repository

@Observable
@MainActor
final class PersonaRepository {

    // MARK: - Singleton

    static let shared = PersonaRepository()

    // MARK: - Published State

    /// The single persona for this user (nil if not created yet)
    private(set) var currentPersona: PersonaProfileModel?

    /// Whether persona exists
    var hasPersona: Bool { currentPersona != nil }

    /// Loading state
    private(set) var isLoading: Bool = false

    /// Error state
    private(set) var error: PersonaRepositoryError?

    // MARK: - Dependencies

    private var modelContext: ModelContext?
    private let cloudKitManager = CloudKitManager.shared
    private let syncMonitor = SyncMonitor.shared

    // MARK: - Initialization

    private init() {
        Log.info("PersonaRepository initialized", category: .persona)
    }

    /// Set the model context for SwiftData operations
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Log.debug("Model context set for PersonaRepository", category: .persona)
    }

    // MARK: - Persona CRUD

    /// Load the current persona from storage
    func loadPersona() async throws {
        guard let context = modelContext else {
            throw PersonaRepositoryError.modelContextNotAvailable
        }

        isLoading = true
        defer { isLoading = false }

        Log.debug("Loading persona", category: .persona)

        let descriptor = FetchDescriptor<PersonaProfileModel>()

        do {
            let personas = try context.fetch(descriptor)
            // We only support single persona - take the first one
            currentPersona = personas.first
            Log.info("Persona loaded: \(currentPersona?.name ?? "none")", category: .persona)
        } catch {
            Log.error("Failed to load persona", error: error, category: .persona)
            throw PersonaRepositoryError.saveFailed(error)
        }
    }

    /// Create a new persona (only if none exists)
    func createPersona(
        name: String,
        bio: String? = nil,
        attributes: PersonaAttributes? = nil
    ) async throws -> PersonaProfileModel {
        guard let context = modelContext else {
            throw PersonaRepositoryError.modelContextNotAvailable
        }

        // Check if persona already exists
        if currentPersona != nil {
            Log.warning("Persona already exists, updating instead", category: .persona)
            return try await updatePersona(name: name, bio: bio, attributes: attributes)
        }

        Log.debug("Creating new persona: \(name)", category: .persona)

        let persona = PersonaProfileModel(
            name: name,
            bio: bio,
            attributes: attributes
        )

        context.insert(persona)

        do {
            try context.save()
            currentPersona = persona
            Log.info("Persona created: \(persona.id)", category: .persona)

            // Sync to CloudKit
            syncMonitor.addPendingSync()
            Task {
                await syncPersonaToCloudKit(persona)
            }

            return persona
        } catch {
            Log.error("Failed to create persona", error: error, category: .persona)
            throw PersonaRepositoryError.saveFailed(error)
        }
    }

    /// Update the current persona
    func updatePersona(
        name: String? = nil,
        bio: String? = nil,
        attributes: PersonaAttributes? = nil
    ) async throws -> PersonaProfileModel {
        guard let context = modelContext else {
            throw PersonaRepositoryError.modelContextNotAvailable
        }

        guard let persona = currentPersona else {
            throw PersonaRepositoryError.personaNotFound
        }

        Log.debug("Updating persona: \(persona.id)", category: .persona)

        if let name = name { persona.name = name }
        if let bio = bio { persona.bio = bio }
        if let attributes = attributes { persona.attributes = attributes }
        persona.updatedAt = Date()
        persona.needsSync = true

        do {
            try context.save()
            Log.info("Persona updated: \(persona.id)", category: .persona)

            // Sync to CloudKit
            Task {
                await syncPersonaToCloudKit(persona)
            }

            return persona
        } catch {
            Log.error("Failed to update persona", error: error, category: .persona)
            throw PersonaRepositoryError.saveFailed(error)
        }
    }

    /// Delete the current persona and all avatars
    func deletePersona() async throws {
        guard let context = modelContext else {
            throw PersonaRepositoryError.modelContextNotAvailable
        }

        guard let persona = currentPersona else {
            throw PersonaRepositoryError.personaNotFound
        }

        Log.debug("Deleting persona: \(persona.id)", category: .persona)

        // Delete from CloudKit first if synced
        if let recordName = persona.cloudKitRecordName {
            do {
                let recordID = CKRecord.ID(recordName: recordName)
                try await cloudKitManager.delete(recordID: recordID)
            } catch {
                Log.warning("Failed to delete persona from CloudKit: \(error.localizedDescription)", category: .cloudKit)
            }
        }

        // Delete all avatars from CloudKit
        for avatar in persona.avatars ?? [] {
            if let recordName = avatar.cloudKitRecordName {
                do {
                    let recordID = CKRecord.ID(recordName: recordName)
                    try await cloudKitManager.delete(recordID: recordID)
                } catch {
                    Log.warning("Failed to delete avatar from CloudKit: \(error.localizedDescription)", category: .cloudKit)
                }
            }
        }

        context.delete(persona)

        do {
            try context.save()
            currentPersona = nil
            Log.info("Persona deleted", category: .persona)
        } catch {
            Log.error("Failed to delete persona", error: error, category: .persona)
            throw PersonaRepositoryError.deleteFailed(error)
        }
    }

    // MARK: - Avatar Management

    /// Add a new avatar style variation to the persona
    func addAvatar(
        style: AvatarStyle,
        imageData: Data
    ) async throws -> PersonaAvatarModel {
        guard let context = modelContext else {
            throw PersonaRepositoryError.modelContextNotAvailable
        }

        guard let persona = currentPersona else {
            throw PersonaRepositoryError.personaNotFound
        }

        // Check avatar limit per style
        let existingStyleCount = (persona.avatars ?? []).filter { $0.style == style }.count
        if existingStyleCount >= Constants.Persona.maxAvatarsPerStyle {
            throw PersonaRepositoryError.avatarLimitReached(style)
        }

        Log.debug("Adding avatar with style: \(style.displayName)", category: .persona)

        let avatar = PersonaAvatarModel(
            style: style,
            imageData: imageData
        )

        avatar.persona = persona
        if persona.avatars == nil {
            persona.avatars = []
        }
        persona.avatars?.append(avatar)
        persona.updatedAt = Date()
        persona.needsSync = true

        // Set as active if first avatar
        if persona.activeAvatarId == nil {
            persona.activeAvatarId = avatar.id
        }

        do {
            try context.save()
            Log.info("Avatar added: \(avatar.id) with style \(style.displayName)", category: .persona)

            // Sync to CloudKit
            Task {
                await syncAvatarToCloudKit(avatar, persona: persona)
            }

            return avatar
        } catch {
            Log.error("Failed to add avatar", error: error, category: .persona)
            throw PersonaRepositoryError.saveFailed(error)
        }
    }

    /// Remove an avatar from the persona
    func removeAvatar(_ avatar: PersonaAvatarModel) async throws {
        guard let context = modelContext else {
            throw PersonaRepositoryError.modelContextNotAvailable
        }

        guard let persona = currentPersona else {
            throw PersonaRepositoryError.personaNotFound
        }

        Log.debug("Removing avatar: \(avatar.id)", category: .persona)

        // Delete from CloudKit if synced
        if let recordName = avatar.cloudKitRecordName {
            do {
                let recordID = CKRecord.ID(recordName: recordName)
                try await cloudKitManager.delete(recordID: recordID)
            } catch {
                Log.warning("Failed to delete avatar from CloudKit: \(error.localizedDescription)", category: .cloudKit)
            }
        }

        // If removing active avatar, set another as active
        if persona.activeAvatarId == avatar.id {
            persona.activeAvatarId = (persona.avatars ?? []).first { $0.id != avatar.id }?.id
        }

        persona.avatars?.removeAll { $0.id == avatar.id }
        persona.updatedAt = Date()
        context.delete(avatar)

        do {
            try context.save()
            Log.info("Avatar removed: \(avatar.id)", category: .persona)
        } catch {
            Log.error("Failed to remove avatar", error: error, category: .persona)
            throw PersonaRepositoryError.deleteFailed(error)
        }
    }

    /// Set the active avatar
    func setActiveAvatar(_ avatar: PersonaAvatarModel) async throws {
        guard let context = modelContext else {
            throw PersonaRepositoryError.modelContextNotAvailable
        }

        guard let persona = currentPersona else {
            throw PersonaRepositoryError.personaNotFound
        }

        guard (persona.avatars ?? []).contains(where: { $0.id == avatar.id }) else {
            throw PersonaRepositoryError.avatarNotFound(avatar.id)
        }

        Log.debug("Setting active avatar: \(avatar.id)", category: .persona)

        persona.activeAvatarId = avatar.id
        persona.updatedAt = Date()
        persona.needsSync = true

        do {
            try context.save()
            Log.info("Active avatar set: \(avatar.id)", category: .persona)

            // Sync to CloudKit
            Task {
                await syncPersonaToCloudKit(persona)
            }
        } catch {
            Log.error("Failed to set active avatar", error: error, category: .persona)
            throw PersonaRepositoryError.saveFailed(error)
        }
    }

    /// Get avatars for a specific style
    func getAvatars(for style: AvatarStyle) -> [PersonaAvatarModel] {
        guard let persona = currentPersona else { return [] }
        return (persona.avatars ?? []).filter { $0.style == style }
    }

    /// Get all available avatar styles that have been generated
    var availableStyles: [AvatarStyle] {
        guard let persona = currentPersona else { return [] }
        return Array(Set((persona.avatars ?? []).map { $0.style }))
    }

    // MARK: - CloudKit Sync

    /// Sync persona to CloudKit
    private func syncPersonaToCloudKit(_ persona: PersonaProfileModel) async {
        guard syncMonitor.canSync else {
            Log.debug("Cannot sync - network or account unavailable", category: .cloudKit)
            return
        }

        syncMonitor.beginSync()

        do {
            let record = persona.toRecord()
            let savedRecord = try await cloudKitManager.save(record)

            persona.cloudKitRecordName = savedRecord.recordID.recordName
            persona.lastSyncedAt = Date()
            persona.needsSync = false

            if let context = modelContext {
                try context.save()
            }

            syncMonitor.endSync()
            syncMonitor.removePendingSync()

            Log.info("Persona synced to CloudKit: \(persona.id)", category: .cloudKit)
        } catch {
            syncMonitor.syncFailed(error: error)
            Log.error("Failed to sync persona to CloudKit", error: error, category: .cloudKit)
        }
    }

    /// Sync avatar to CloudKit
    private func syncAvatarToCloudKit(_ avatar: PersonaAvatarModel, persona: PersonaProfileModel) async {
        guard syncMonitor.canSync else { return }

        do {
            let record = CKRecord(recordType: Constants.iCloud.RecordTypes.personaAvatar, uuid: avatar.id)

            record[Constants.iCloud.RecordFields.PersonaAvatar.id] = avatar.id.uuidString
            record[Constants.iCloud.RecordFields.PersonaAvatar.personaId] = persona.id.uuidString
            record[Constants.iCloud.RecordFields.PersonaAvatar.style] = avatar.styleRaw
            record[Constants.iCloud.RecordFields.PersonaAvatar.createdAt] = avatar.createdAt

            // Create reference to persona
            if let personaRecordName = persona.cloudKitRecordName {
                let personaRecordID = CKRecord.ID(recordName: personaRecordName)
                record.setReference(to: personaRecordID, for: Constants.iCloud.RecordFields.PersonaAvatar.personaId)
            }

            // Upload image as asset
            if let imageData = avatar.imageData {
                let asset = try CKRecord.createAsset(from: imageData)
                record[Constants.iCloud.RecordFields.PersonaAvatar.imageAsset] = asset
            }

            let savedRecord = try await cloudKitManager.save(record)

            avatar.cloudKitRecordName = savedRecord.recordID.recordName
            avatar.lastSyncedAt = Date()
            avatar.needsSync = false

            if let context = modelContext {
                try context.save()
            }

            Log.info("Avatar synced to CloudKit: \(avatar.id)", category: .cloudKit)
        } catch {
            Log.error("Failed to sync avatar to CloudKit", error: error, category: .cloudKit)
        }
    }

    /// Pull persona from CloudKit
    func pullFromCloudKit() async throws {
        guard syncMonitor.canSync else {
            throw CloudKitError.networkUnavailable
        }

        guard let context = modelContext else {
            throw PersonaRepositoryError.modelContextNotAvailable
        }

        Log.info("Pulling persona from CloudKit", category: .cloudKit)
        syncMonitor.beginSync()

        do {
            // Fetch persona records
            let personaRecords = try await cloudKitManager.query(
                recordType: Constants.iCloud.RecordTypes.personaProfile,
                sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)]
            )

            // We only support single persona - take the first one
            if let record = personaRecords.first,
               let remotePersona = PersonaProfileModel(from: record) {

                // Check if persona already exists locally
                let remoteId = remotePersona.id
                let descriptor = FetchDescriptor<PersonaProfileModel>(
                    predicate: #Predicate<PersonaProfileModel> { $0.id == remoteId }
                )

                let existingPersonas = try context.fetch(descriptor)

                if let existingPersona = existingPersonas.first {
                    // Update if remote is newer
                    if remotePersona.updatedAt > existingPersona.updatedAt {
                        existingPersona.name = remotePersona.name
                        existingPersona.bio = remotePersona.bio
                        existingPersona.attributesData = remotePersona.attributesData
                        existingPersona.updatedAt = remotePersona.updatedAt
                        existingPersona.cloudKitRecordName = remotePersona.cloudKitRecordName
                        existingPersona.lastSyncedAt = Date()
                        existingPersona.needsSync = false
                    }
                    currentPersona = existingPersona
                } else {
                    // Insert new persona
                    context.insert(remotePersona)
                    currentPersona = remotePersona
                }

                // Fetch avatars for this persona
                await pullAvatarsFromCloudKit(for: currentPersona!)
            }

            try context.save()
            syncMonitor.endSync()

            Log.info("Persona pulled from CloudKit", category: .cloudKit)
        } catch {
            syncMonitor.syncFailed(error: error)
            throw PersonaRepositoryError.syncFailed(error)
        }
    }

    /// Pull avatars from CloudKit for a persona
    private func pullAvatarsFromCloudKit(for persona: PersonaProfileModel) async {
        guard let context = modelContext else { return }

        do {
            let predicate = NSPredicate(format: "personaId == %@", persona.id.uuidString)
            let avatarRecords = try await cloudKitManager.query(
                recordType: Constants.iCloud.RecordTypes.personaAvatar,
                predicate: predicate
            )

            for record in avatarRecords {
                guard let idString = record.string(for: Constants.iCloud.RecordFields.PersonaAvatar.id),
                      let id = UUID(uuidString: idString) else { continue }

                // Check if avatar exists locally
                let existingAvatar = (persona.avatars ?? []).first { $0.id == id }

                if existingAvatar == nil {
                    // Create new avatar
                    let style = AvatarStyle(rawValue: record.string(for: Constants.iCloud.RecordFields.PersonaAvatar.style) ?? "") ?? .artistic
                    let imageData = try? await record.assetData(for: Constants.iCloud.RecordFields.PersonaAvatar.imageAsset)

                    let avatar = PersonaAvatarModel(
                        id: id,
                        style: style,
                        imageData: imageData,
                        createdAt: record.date(for: Constants.iCloud.RecordFields.PersonaAvatar.createdAt) ?? Date(),
                        cloudKitRecordName: record.recordID.recordName,
                        lastSyncedAt: Date(),
                        needsSync: false
                    )

                    avatar.persona = persona
                    if persona.avatars == nil {
                        persona.avatars = []
                    }
                    persona.avatars?.append(avatar)
                }
            }

            try context.save()
            Log.info("Avatars pulled from CloudKit for persona: \(persona.id)", category: .cloudKit)
        } catch {
            Log.error("Failed to pull avatars from CloudKit", error: error, category: .cloudKit)
        }
    }

    /// Full sync (pull then push)
    func performFullSync() async {
        guard syncMonitor.canSync else {
            Log.debug("Cannot perform full sync - network or account unavailable", category: .cloudKit)
            return
        }

        Log.info("Starting full persona sync", category: .cloudKit)

        do {
            // Pull from CloudKit first
            try await pullFromCloudKit()

            // Then push any local changes
            if let persona = currentPersona, persona.needsSync {
                await syncPersonaToCloudKit(persona)
            }

            Log.info("Full persona sync completed", category: .cloudKit)
        } catch {
            Log.error("Full persona sync failed", error: error, category: .cloudKit)
        }
    }

    // MARK: - Cleanup

    /// Clear all persona data
    func clearAllData() async throws {
        guard let context = modelContext else {
            throw PersonaRepositoryError.modelContextNotAvailable
        }

        Log.warning("Clearing all persona data", category: .persona)

        try context.delete(model: PersonaProfileModel.self)
        try context.delete(model: PersonaAvatarModel.self)
        try context.save()

        currentPersona = nil

        Log.info("All persona data cleared", category: .persona)
    }
}
