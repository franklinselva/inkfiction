//
//  CollageLayoutViewModel.swift
//  InkFiction
//
//  ViewModel for contextual collage layout logic
//  Optimized with layout computation caching
//

import Foundation
import SwiftUI

@MainActor
@Observable
class CollageLayoutViewModel {
    private(set) var layoutPattern: CollageLayoutPattern
    private(set) var entry: JournalEntry
    private(set) var featuredImageId: UUID?
    private(set) var secondaryImageIds: [UUID]
    private(set) var firstAIImageId: UUID?
    private(set) var photoIds: [UUID]
    private(set) var images: [UUID: UIImage]

    private let engine = CollageLayoutEngine()

    // Cache key for layout computations to avoid redundant work
    private struct LayoutCacheKey: Hashable {
        let entryId: UUID
        let imageCount: Int
        let hasAIImages: Bool
        let hasPhotos: Bool
        let updatedAt: Date
    }

    private var cachedLayoutKey: LayoutCacheKey?

    init(entry: JournalEntry, preloadedImages: [UUID: UIImage] = [:]) {
        self.entry = entry
        self.images = preloadedImages

        // Compute layout decisions (cached)
        let cacheKey = LayoutCacheKey(
            entryId: entry.id,
            imageCount: entry.images.count,
            hasAIImages: !entry.generatedImages.isEmpty,
            hasPhotos: !entry.attachedImages.isEmpty,
            updatedAt: entry.updatedAt
        )

        let pattern = engine.determineLayout(for: entry)
        let featured = engine.featuredImageId(for: entry)

        // Initialize stored properties
        self.layoutPattern = pattern
        self.featuredImageId = featured
        self.cachedLayoutKey = cacheKey

        // Secondary images (all except featured)
        if let featured = featured {
            self.secondaryImageIds = entry.images.filter { $0.id != featured }.map(\.id)
        } else {
            self.secondaryImageIds = entry.images.map(\.id)
        }

        // Separate AI and photos
        self.firstAIImageId = entry.generatedImages.first?.id
        self.photoIds = entry.attachedImages.map(\.id)

        // Load images from entry if not preloaded
        loadImagesFromEntry()
    }

    private func loadImagesFromEntry() {
        for journalImage in entry.images {
            if images[journalImage.id] == nil, let uiImage = journalImage.uiImage {
                images[journalImage.id] = uiImage
            }
        }
    }

    func updateEntry(_ newEntry: JournalEntry) {
        // Check if layout needs recomputation
        let newCacheKey = LayoutCacheKey(
            entryId: newEntry.id,
            imageCount: newEntry.images.count,
            hasAIImages: !newEntry.generatedImages.isEmpty,
            hasPhotos: !newEntry.attachedImages.isEmpty,
            updatedAt: newEntry.updatedAt
        )

        // Only recompute layout if cache key changed
        if cachedLayoutKey != newCacheKey {
            let pattern = engine.determineLayout(for: newEntry)
            let featured = engine.featuredImageId(for: newEntry)

            self.layoutPattern = pattern
            self.featuredImageId = featured
            self.cachedLayoutKey = newCacheKey

            if let featured = featured {
                self.secondaryImageIds = newEntry.images.filter { $0.id != featured }.map(\.id)
            } else {
                self.secondaryImageIds = newEntry.images.map(\.id)
            }

            self.firstAIImageId = newEntry.generatedImages.first?.id
            self.photoIds = newEntry.attachedImages.map(\.id)
        }

        self.entry = newEntry
        loadImagesFromEntry()
    }

    var accessibilityLabel: String {
        let imageCount = entry.images.count
        let aiCount = entry.generatedImages.count
        let photoCount = entry.attachedImages.count

        var components: [String] = []

        // Mood
        components.append("\(entry.mood.rawValue) mood")

        // Image count and types
        if imageCount == 0 {
            components.append("No images")
        } else if imageCount == 1 {
            let firstImage = entry.images[0]
            let type = firstImage.isAIGenerated ? "AI-generated image" : "photo"
            components.append("One \(type)")
        } else {
            var imageDesc = "\(imageCount) images"
            if aiCount > 0 && photoCount > 0 {
                imageDesc += ": \(aiCount) AI-generated, \(photoCount) photos"
            } else if aiCount > 0 {
                imageDesc += ": all AI-generated"
            } else {
                imageDesc += ": all photos"
            }
            components.append(imageDesc)
        }

        // Layout description
        components.append("Displayed in \(layoutPattern.accessibilityDescription)")

        return components.joined(separator: ". ")
    }

    var totalImageCount: Int {
        entry.images.count
    }

    var aiImageCount: Int {
        entry.generatedImages.count
    }
}
