//
//  StoryTriptychLayout.swift
//  InkFiction
//
//  Layout for three images - featured left (60%) + 2 stacked right (40%)
//

import SwiftUI

struct StoryTriptychLayout: View {
    let featuredId: UUID
    let secondaryIds: [UUID]
    let images: [UUID: UIImage]
    let mood: Mood

    @Environment(\.themeManager) private var themeManager

    private func imageView(for imageId: UUID) -> some View {
        Group {
            if let image = images[imageId] {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                errorPlaceholder
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: CollageDesignTokens.imageSpacing) {
                // Featured image (60%)
                imageView(for: featuredId)
                    .frame(
                        width: geometry.size.width * 0.6 - CollageDesignTokens.imageSpacing / 2,
                        height: CollageDesignTokens.storyTriptychHeight
                    )
                    .clipped()
                    .cornerRadius(CollageDesignTokens.imageCornerRadius)

                // Stacked images (40%)
                VStack(spacing: CollageDesignTokens.imageSpacing) {
                    ForEach(Array(secondaryIds.prefix(2)), id: \.self) { imageId in
                        imageView(for: imageId)
                            .frame(
                                height: (CollageDesignTokens.storyTriptychHeight - CollageDesignTokens.imageSpacing) / 2
                            )
                            .clipped()
                            .cornerRadius(CollageDesignTokens.imageCornerRadius)
                    }
                }
                .frame(width: geometry.size.width * 0.4 - CollageDesignTokens.imageSpacing / 2)
            }
            .overlay(alignment: .bottomLeading) {
                MoodPill(mood: mood)
                    .padding(CollageDesignTokens.badgePadding)
            }
        }
        .frame(height: CollageDesignTokens.storyTriptychHeight)
    }

    private var errorPlaceholder: some View {
        VStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
            Text("Unable to load")
                .font(.caption2)
        }
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.surfaceColor.opacity(0.3))
    }
}
