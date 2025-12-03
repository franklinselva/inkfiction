//
//  JournalEditorViewModel.swift
//  InkFiction
//
//  ViewModel for journal entry creation and editing
//

import Combine
import Foundation
import PhotosUI
import SwiftData
import SwiftUI

@MainActor
@Observable
final class JournalEditorViewModel {

    // MARK: - Entry Data

    var id: UUID
    var title: String
    var content: String
    var mood: Mood
    var tags: [String]
    var images: [JournalImage]
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
    var isPinned: Bool

    // MARK: - UI State

    var isProcessing: Bool = false
    var isGeneratingImage: Bool = false
    var showError: Bool = false
    var errorMessage: String = ""
    var showAddTag: Bool = false
    var newTagText: String = ""
    var showPhotoPermissionAlert: Bool = false

    // MARK: - Dependencies

    private var modelContext: ModelContext?
    private let repository = JournalRepository.shared
    private let existingEntryId: UUID?

    // MARK: - Content History (for undo)

    private var contentHistory: [String] = []
    private var originalContent: String = ""

    // MARK: - Initialization

    init(existingEntry: JournalEntry? = nil) {
        if let entry = existingEntry {
            self.existingEntryId = entry.id
            self.id = entry.id
            self.title = entry.title
            self.content = entry.content
            self.mood = entry.mood
            self.tags = entry.tags
            self.images = entry.images
            self.createdAt = entry.createdAt
            self.updatedAt = entry.updatedAt
            self.isArchived = entry.isArchived
            self.isPinned = entry.isPinned
            self.originalContent = entry.content
        } else {
            self.existingEntryId = nil
            self.id = UUID()
            self.title = ""
            self.content = ""
            self.mood = .neutral
            self.tags = []
            self.images = []
            self.createdAt = Date()
            self.updatedAt = Date()
            self.isArchived = false
            self.isPinned = false
            self.originalContent = ""
        }

        Log.debug("JournalEditorViewModel initialized for \(existingEntry == nil ? "new" : "existing") entry", category: .journal)
    }

    /// Set the model context for SwiftData operations
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        repository.setModelContext(context)
    }

    // MARK: - Computed Properties

    var isEditing: Bool {
        existingEntryId != nil
    }

    var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canUndo: Bool {
        !contentHistory.isEmpty
    }

    var hasChanges: Bool {
        content != originalContent || !title.isEmpty || !images.isEmpty || mood != .neutral || !tags.isEmpty
    }

    // MARK: - Entry Operations

    func save() async throws {
        guard modelContext != nil else {
            throw JournalRepositoryError.modelContextNotAvailable
        }

        isProcessing = true
        defer { isProcessing = false }

        let now = Date()
        updatedAt = now

        do {
            if let existingId = existingEntryId,
               let existingModel = try await repository.getEntry(by: existingId) {
                // Update existing entry
                existingModel.title = title
                existingModel.content = content
                existingModel.mood = mood
                existingModel.tags = tags
                existingModel.updatedAt = now
                existingModel.isArchived = isArchived
                existingModel.isPinned = isPinned

                // Handle images - sync images array with model
                await syncImages(to: existingModel)

                try await repository.updateEntry(existingModel)
                Log.info("Journal entry updated: \(existingId)", category: .journal)
            } else {
                // Create new entry
                let newModel = try await repository.createEntry(
                    title: title,
                    content: content,
                    mood: mood,
                    tags: tags
                )

                // Add images to new entry
                for image in images {
                    if let imageData = image.imageData {
                        _ = try await repository.addImage(
                            to: newModel,
                            imageData: imageData,
                            caption: image.caption,
                            isAIGenerated: image.isAIGenerated
                        )
                    }
                }

                Log.info("Journal entry created: \(newModel.id)", category: .journal)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            Log.error("Failed to save journal entry", error: error, category: .journal)
            throw error
        }
    }

    private func syncImages(to model: JournalEntryModel) async {
        guard let context = modelContext else { return }

        // Remove images that are no longer in our array
        let currentImageIds = Set(images.map(\.id))
        let modelImages = model.images ?? []

        for modelImage in modelImages {
            if !currentImageIds.contains(modelImage.id) {
                try? await repository.removeImage(modelImage, from: model)
            }
        }

        // Add new images
        let existingImageIds = Set(modelImages.map(\.id))

        for image in images {
            if !existingImageIds.contains(image.id), let imageData = image.imageData {
                _ = try? await repository.addImage(
                    to: model,
                    imageData: imageData,
                    caption: image.caption,
                    isAIGenerated: image.isAIGenerated
                )
            }
        }
    }

    // MARK: - Image Management

    func addImage(_ uiImage: UIImage) {
        guard let imageData = uiImage.jpegData(compressionQuality: 0.8) else {
            Log.warning("Failed to convert UIImage to JPEG data", category: .journal)
            return
        }

        let newImage = JournalImage(
            imageData: imageData,
            isAIGenerated: false
        )

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            images.append(newImage)
        }

        Log.debug("Image added to entry", category: .journal)
    }

    func removeImage(at index: Int) {
        guard index >= 0 && index < images.count else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            images.remove(at: index)
        }

        Log.debug("Image removed from entry at index \(index)", category: .journal)
    }

    func removeImage(_ image: JournalImage) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            images.removeAll { $0.id == image.id }
        }
    }

    // MARK: - Tag Management

    func addTag(_ tag: String) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else {
            newTagText = ""
            return
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            tags.append(trimmed)
        }
        newTagText = ""

        Log.debug("Tag added: \(trimmed)", category: .journal)
    }

    func removeTag(_ tag: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            tags.removeAll { $0 == tag }
        }

        Log.debug("Tag removed: \(tag)", category: .journal)
    }

    // MARK: - Content Undo

    func pushContentHistory() {
        contentHistory.append(content)
    }

    func undo() {
        guard let previousContent = contentHistory.popLast() else { return }
        content = previousContent
        Log.debug("Undo performed", category: .journal)
    }

    // MARK: - Permissions

    func checkPhotoPermission() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .denied, .restricted:
            await MainActor.run {
                showPhotoPermissionAlert = true
            }
        case .notDetermined:
            let _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        default:
            break
        }
    }

    // MARK: - Validation

    func validate() -> Bool {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter a title or content for your journal entry."
            showError = true
            return false
        }

        if title.count > Constants.Journal.maxTitleLength {
            errorMessage = "Title is too long. Maximum \(Constants.Journal.maxTitleLength) characters allowed."
            showError = true
            return false
        }

        if content.count > Constants.Journal.maxContentLength {
            errorMessage = "Content is too long. Maximum \(Constants.Journal.maxContentLength) characters allowed."
            showError = true
            return false
        }

        return true
    }
}

// MARK: - Photo Picker Helper

extension JournalEditorViewModel {
    func loadImages(from items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                addImage(uiImage)
            }
        }
    }
}
