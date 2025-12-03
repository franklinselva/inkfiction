//
//  GalleryLayout.swift
//  InkFiction
//
//  Layout for 5+ images - 1 large left + 2x2 grid right (max 5 images)
//

import SwiftUI

struct GalleryLayout: View {
    let imageIds: [UUID]
    let images: [UUID: UIImage]
    let mood: Mood
    let totalCount: Int

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
        let imageArray = Array(imageIds.prefix(5))

        guard imageArray.count >= 1 else {
            return AnyView(EmptyView())
        }

        return AnyView(
            GeometryReader { geometry in
                let spacing = CollageDesignTokens.imageSpacing
                let totalHeight = CollageDesignTokens.galleryHeight

                // Calculate widths: total width split in half with spacing between
                let availableWidth = geometry.size.width - spacing
                let halfWidth = availableWidth / 2

                // Calculate grid cell dimensions
                let gridCellWidth = (halfWidth - spacing) / 2
                let gridCellHeight = (totalHeight - spacing) / 2

                HStack(spacing: spacing) {
                    // Large featured image (50%)
                    imageView(for: imageArray[0])
                        .frame(
                            width: halfWidth,
                            height: totalHeight
                        )
                        .clipped()
                        .cornerRadius(CollageDesignTokens.imageCornerRadius)

                    // 2x2 Grid (50%)
                    VStack(spacing: spacing) {
                        ForEach(0..<2, id: \.self) { row in
                            HStack(spacing: spacing) {
                                ForEach(0..<2, id: \.self) { col in
                                    let index = 1 + (row * 2 + col)
                                    if index < imageArray.count {
                                        ZStack(alignment: .bottomTrailing) {
                                            imageView(for: imageArray[index])
                                                .frame(width: gridCellWidth, height: gridCellHeight)
                                                .clipped()
                                                .cornerRadius(CollageDesignTokens.imageCornerRadius)

                                            // Show count badge on last image if more images exist
                                            if index == imageArray.count - 1 && totalCount > 5 {
                                                CountBadge(count: totalCount - 5)
                                                    .padding(4)
                                            }
                                        }
                                    } else {
                                        // Empty placeholder for symmetry
                                        Color.clear
                                            .frame(width: gridCellWidth, height: gridCellHeight)
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: halfWidth, height: totalHeight)
                }
                .overlay(alignment: .bottomLeading) {
                    MoodPill(mood: mood)
                        .padding(CollageDesignTokens.badgePadding)
                }
            }
            .frame(height: CollageDesignTokens.galleryHeight)
        )
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
