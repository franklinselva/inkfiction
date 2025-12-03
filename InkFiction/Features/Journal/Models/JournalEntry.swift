//
//  JournalEntry.swift
//  InkFiction
//
//  Domain model for journal entries (separate from SwiftData model)
//

import Foundation
import SwiftUI

/// Domain model for journal entries used in the presentation layer
struct JournalEntry: Identifiable, Equatable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var mood: Mood
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
    var isPinned: Bool

    // Image references
    var images: [JournalImage]

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
        images: [JournalImage] = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.mood = mood
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.isPinned = isPinned
        self.images = images
    }

    // MARK: - Computed Properties

    /// Check if entry has any images
    var hasImages: Bool {
        !images.isEmpty
    }

    /// Get all image IDs
    var imageIds: [UUID] {
        images.map(\.id)
    }

    /// Get attached (user-uploaded) images
    var attachedImages: [JournalImage] {
        images.filter { !$0.isAIGenerated }
    }

    /// Get AI-generated images
    var generatedImages: [JournalImage] {
        images.filter(\.isAIGenerated)
    }

    /// Get the featured image (first image if available)
    var featuredImage: JournalImage? {
        images.first
    }

    // MARK: - Conversion from SwiftData Model

    init(from model: JournalEntryModel) {
        self.id = model.id
        self.title = model.title
        self.content = model.content
        self.mood = model.mood
        self.tags = model.tags
        self.createdAt = model.createdAt
        self.updatedAt = model.updatedAt
        self.isArchived = model.isArchived
        self.isPinned = model.isPinned
        self.images = (model.images ?? []).map { JournalImage(from: $0) }
    }

    // MARK: - Equatable & Hashable

    static func == (lhs: JournalEntry, rhs: JournalEntry) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.content == rhs.content &&
        lhs.mood == rhs.mood &&
        lhs.tags == rhs.tags &&
        lhs.createdAt == rhs.createdAt &&
        lhs.updatedAt == rhs.updatedAt &&
        lhs.isArchived == rhs.isArchived &&
        lhs.isPinned == rhs.isPinned &&
        lhs.images == rhs.images
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Journal Image

/// Domain model for journal images
struct JournalImage: Identifiable, Equatable, Hashable {
    let id: UUID
    var imageData: Data?
    var caption: String?
    var isAIGenerated: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        imageData: Data? = nil,
        caption: String? = nil,
        isAIGenerated: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.imageData = imageData
        self.caption = caption
        self.isAIGenerated = isAIGenerated
        self.createdAt = createdAt
    }

    init(from model: JournalImageModel) {
        self.id = model.id
        self.imageData = model.imageData
        self.caption = model.caption
        self.isAIGenerated = model.isAIGenerated
        self.createdAt = model.createdAt
    }

    /// Get UIImage from data
    var uiImage: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
}
