//
//  CollageLayoutPattern.swift
//  InkFiction
//
//  Defines layout patterns for contextual journal image collages
//

import Foundation
import SwiftUI

// MARK: - Collage Layout Pattern

enum CollageLayoutPattern: Equatable {
    case moodShowcase
    case heroFeatured
    case duoFlow
    case storyTriptych
    case quad
    case gallery
    case mosaic
    case aiMixed

    var height: CGFloat {
        switch self {
        case .moodShowcase:
            return CollageDesignTokens.moodShowcaseHeight
        case .heroFeatured:
            return CollageDesignTokens.heroFeaturedHeight
        case .duoFlow:
            return CollageDesignTokens.duoFlowHeightSame
        case .storyTriptych:
            return CollageDesignTokens.storyTriptychHeight
        case .quad:
            return CollageDesignTokens.quadHeight
        case .gallery:
            return CollageDesignTokens.galleryHeight
        case .mosaic:
            return CollageDesignTokens.mosaicHeight
        case .aiMixed:
            return CollageDesignTokens.aiMixedHeight
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .moodShowcase:
            return "mood showcase layout"
        case .heroFeatured:
            return "hero featured layout"
        case .duoFlow:
            return "side-by-side flow layout"
        case .storyTriptych:
            return "story layout with featured image"
        case .quad:
            return "four-image grid"
        case .gallery:
            return "gallery grid"
        case .mosaic:
            return "mosaic grid"
        case .aiMixed:
            return "AI and photos mixed layout"
        }
    }
}

// MARK: - Collage Layout Engine

struct CollageLayoutEngine {

    func determineLayout(for entry: JournalEntry) -> CollageLayoutPattern {
        let imageCount = entry.images.count
        let hasAIImages = !entry.generatedImages.isEmpty
        let hasPhotos = !entry.attachedImages.isEmpty

        // No images
        if imageCount == 0 {
            return .moodShowcase
        }

        // Check for AI + Photo mix
        if hasAIImages && hasPhotos {
            return .aiMixed
        }

        // Single image
        if imageCount == 1 {
            return .heroFeatured
        }

        // Two images
        if imageCount == 2 {
            return .duoFlow
        }

        // Three images
        if imageCount == 3 {
            return .storyTriptych
        }

        // Four images
        if imageCount == 4 {
            return .quad
        }

        // 5-6 images - mosaic
        if imageCount >= 5 && imageCount <= 6 {
            return .mosaic
        }

        // 7+ images - gallery
        return .gallery
    }

    func featuredImageId(for entry: JournalEntry) -> UUID? {
        // Prefer AI-generated as featured
        if let firstAI = entry.generatedImages.first {
            return firstAI.id
        }

        // Fallback to first image
        return entry.images.first?.id
    }

    func secondaryImageIds(for entry: JournalEntry, excluding featuredId: UUID?) -> [UUID] {
        entry.images
            .filter { $0.id != featuredId }
            .map(\.id)
    }
}
