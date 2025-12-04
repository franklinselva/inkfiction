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
    var isGeneratingTitle: Bool = false
    var isEnhancing: Bool = false
    var showError: Bool = false
    var errorMessage: String = ""
    var showAddTag: Bool = false
    var newTagText: String = ""
    var showPhotoPermissionAlert: Bool = false

    // MARK: - AI State

    /// Generated image prompt from AI processing
    var generatedImagePrompt: String = ""

    /// Suggested title alternatives
    var titleAlternatives: [String] = []

    /// Enhancement style for content
    var selectedEnhancementStyle: EnhancementStyle = .refine

    /// Original content before enhancement (for undo)
    private var preEnhancementContent: String = ""

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

// MARK: - AI Features

extension JournalEditorViewModel {

    /// Generate a title for the journal entry using AI
    func generateTitle() async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please write some content first."
            showError = true
            return
        }

        guard content.count >= Constants.AI.Limits.minContentForTitle else {
            errorMessage = "Content is too short to generate a title."
            showError = true
            return
        }

        isGeneratingTitle = true

        do {
            let geminiService = GeminiService.shared
            let result = try await geminiService.generateTitle(content: content, mood: mood)

            await MainActor.run {
                title = result.title
                titleAlternatives = result.alternatives ?? []
                Log.info("Title generated: \(result.title)", category: .journal)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                Log.error("Title generation failed", error: error, category: .journal)
            }
        }

        isGeneratingTitle = false
    }

    /// Enhance the journal entry content using AI
    func enhanceContent(style: EnhancementStyle? = nil) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please write some content first."
            showError = true
            return
        }

        let enhancementStyle = style ?? selectedEnhancementStyle

        // Save original content for undo
        preEnhancementContent = content
        pushContentHistory()

        isEnhancing = true

        do {
            let geminiService = GeminiService.shared

            // Get companion from settings
            let companion = getSelectedCompanion()

            let result = try await geminiService.enhanceEntry(
                content: content,
                style: enhancementStyle,
                companion: companion
            )

            await MainActor.run {
                content = result.enhancedContent
                Log.info("Content enhanced with style: \(enhancementStyle.rawValue)", category: .journal)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                Log.error("Content enhancement failed", error: error, category: .journal)
            }
        }

        isEnhancing = false
    }

    /// Process the entire journal entry (title, mood, tags, image prompt)
    func processJournalEntry() async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please write some content first."
            showError = true
            return
        }

        guard content.count >= Constants.AI.Limits.minContentForProcessing else {
            errorMessage = "Content is too short for full processing."
            showError = true
            return
        }

        isProcessing = true

        do {
            let geminiService = GeminiService.shared

            // Get persona and visual preference from settings
            let visualPreference = getVisualPreference()

            let result = try await geminiService.processJournalEntry(
                content: content,
                persona: nil, // Could be fetched from PersonaRepository if needed
                visualPreference: visualPreference
            )

            await MainActor.run {
                // Update title if empty
                if title.isEmpty {
                    title = result.title
                }

                // Update mood
                if let detectedMood = result.moodEnum {
                    mood = detectedMood
                }

                // Add suggested tags
                for tag in result.tags {
                    if !tags.contains(tag) {
                        tags.append(tag)
                    }
                }

                // Store image prompt for later use
                if let imagePrompt = result.imagePrompt {
                    generatedImagePrompt = imagePrompt
                }

                Log.info("Journal entry processed: title=\(result.title), mood=\(result.mood)", category: .journal)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                Log.error("Journal processing failed", error: error, category: .journal)
            }
        }

        isProcessing = false
    }

    /// Generate an AI image for the journal entry
    func generateAIImage(prompt: String? = nil) async {
        let imagePrompt = prompt ?? generatedImagePrompt

        guard !imagePrompt.isEmpty else {
            // Generate prompt first
            await processJournalEntry()
            guard !generatedImagePrompt.isEmpty else {
                errorMessage = "Could not generate an image prompt."
                showError = true
                return
            }
            // Retry with generated prompt
            await generateAIImage(prompt: generatedImagePrompt)
            return
        }

        isGeneratingImage = true

        do {
            let geminiService = GeminiService.shared
            let visualPreference = getVisualPreference()

            let (imageData, _) = try await geminiService.generateJournalImage(
                sceneDescription: imagePrompt,
                persona: nil,
                mood: mood,
                visualPreference: visualPreference
            )

            // Convert to UIImage
            guard UIImage(data: imageData) != nil else {
                throw AIError.invalidImageData
            }

            await MainActor.run {
                // Add as AI-generated image
                let newImage = JournalImage(
                    imageData: imageData,
                    caption: "AI generated: \(String(imagePrompt.prefix(50)))...",
                    isAIGenerated: true
                )
                images.append(newImage)

                Log.info("AI image generated and added to entry", category: .journal)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                Log.error("AI image generation failed", error: error, category: .journal)
            }
        }

        isGeneratingImage = false
    }

    /// Analyze the mood of the content using AI
    func analyzeMood() async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        do {
            let geminiService = GeminiService.shared
            let result = try await geminiService.analyzeMood(content: content)

            await MainActor.run {
                if let detectedMood = result.moodEnum {
                    mood = detectedMood
                    Log.debug("Mood analyzed: \(detectedMood.rawValue) (confidence: \(result.confidence))", category: .journal)
                }
            }
        } catch {
            // Fallback to local mood detection
            let localMood = detectMoodLocally(from: content)
            await MainActor.run {
                mood = localMood
                Log.debug("Using local mood detection: \(localMood.rawValue)", category: .journal)
            }
        }
    }

    /// Undo content enhancement
    func undoEnhancement() {
        if !preEnhancementContent.isEmpty {
            content = preEnhancementContent
            preEnhancementContent = ""
            Log.debug("Enhancement undone", category: .journal)
        } else {
            undo()
        }
    }

    // MARK: - Private Helpers

    private func getSelectedCompanion() -> AICompanion? {
        guard let companionId = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.selectedCompanionId) else {
            return nil
        }
        return AICompanion.all.first { $0.id == companionId }
    }

    private func getVisualPreference() -> VisualPreference? {
        guard let prefString = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.visualPreference) else {
            return nil
        }
        return VisualPreference(rawValue: prefString)
    }

    private func detectMoodLocally(from text: String) -> Mood {
        let lowercased = text.lowercased()

        // Simple keyword-based detection
        for mood in Mood.allCases {
            let keywords = MoodDetectionKeywords.keywords(for: mood)
            for keyword in keywords {
                if lowercased.contains(keyword) {
                    return mood
                }
            }
        }

        return .neutral
    }
}
