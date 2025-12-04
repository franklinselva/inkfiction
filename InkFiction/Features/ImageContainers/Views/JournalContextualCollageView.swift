//
//  JournalContextualCollageView.swift
//  InkFiction
//
//  Master orchestrator view for contextual journal image collages
//  Routes to appropriate layout based on entry state
//

import SwiftUI

struct JournalContextualCollageView: View {
    let entry: JournalEntry
    var preloadedImages: [UUID: UIImage] = [:]

    @Environment(\.themeManager) private var themeManager
    @State private var viewModel: CollageLayoutViewModel

    init(entry: JournalEntry, preloadedImages: [UUID: UIImage] = [:]) {
        self.entry = entry
        self.preloadedImages = preloadedImages
        _viewModel = State(wrappedValue: CollageLayoutViewModel(entry: entry, preloadedImages: preloadedImages))
    }

    var body: some View {
        Group {
            layoutView(for: viewModel)
        }
        .onChange(of: entry) { _, newEntry in
            viewModel.updateEntry(newEntry)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.accessibilityLabel)
    }

    @ViewBuilder
    private func layoutView(for vm: CollageLayoutViewModel) -> some View {
        switch vm.layoutPattern {
        case .moodShowcase:
            MoodShowcaseLayout(
                mood: entry.mood,
                tags: entry.tags,
                content: entry.content
            )

        case .heroFeatured:
            if let featuredId = vm.featuredImageId {
                let isAI = entry.generatedImages.contains { $0.id == featuredId }
                HeroFeaturedLayout(
                    imageId: featuredId,
                    images: vm.images,
                    isAIGenerated: isAI,
                    mood: entry.mood
                )
            }

        case .duoFlow:
            DuoFlowLayout(
                imageIds: entry.imageIds,
                images: vm.images,
                mood: entry.mood
            )

        case .storyTriptych:
            if let featuredId = vm.featuredImageId {
                StoryTriptychLayout(
                    featuredId: featuredId,
                    secondaryIds: vm.secondaryImageIds,
                    images: vm.images,
                    mood: entry.mood
                )
            }

        case .quad:
            QuadLayout(
                imageIds: entry.imageIds,
                images: vm.images,
                mood: entry.mood
            )

        case .gallery:
            GalleryLayout(
                imageIds: entry.imageIds,
                images: vm.images,
                mood: entry.mood,
                totalCount: vm.totalImageCount
            )

        case .mosaic:
            if let featuredId = vm.featuredImageId {
                MosaicLayout(
                    featuredId: featuredId,
                    secondaryIds: vm.secondaryImageIds,
                    images: vm.images,
                    mood: entry.mood,
                    totalCount: vm.totalImageCount
                )
            }

        case .aiMixed:
            if let aiImageId = vm.firstAIImageId {
                AIMixedLayout(
                    aiImageId: aiImageId,
                    photoIds: vm.photoIds,
                    images: vm.images,
                    aiCount: vm.aiImageCount,
                    mood: entry.mood
                )
            }
        }
    }
}

// MARK: - Equatable conformance for performance

extension JournalContextualCollageView: Equatable {
    static func == (lhs: JournalContextualCollageView, rhs: JournalContextualCollageView) -> Bool {
        lhs.entry.id == rhs.entry.id &&
        lhs.entry.images.count == rhs.entry.images.count &&
        lhs.entry.mood == rhs.entry.mood
    }
}
