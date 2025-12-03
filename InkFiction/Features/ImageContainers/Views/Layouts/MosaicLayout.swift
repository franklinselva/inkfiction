//
//  MosaicLayout.swift
//  InkFiction
//
//  Layout for 5-6 images - featured (50%) + mini grid (50%)
//

import SwiftUI

struct MosaicLayout: View {
    let featuredId: UUID
    let secondaryIds: [UUID]
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
        let secondaryArray = Array(secondaryIds.prefix(4))

        return GeometryReader { geometry in
            HStack(spacing: CollageDesignTokens.imageSpacing) {
                // Featured (50%)
                imageView(for: featuredId)
                    .frame(
                        width: geometry.size.width * 0.5 - CollageDesignTokens.imageSpacing / 2,
                        height: CollageDesignTokens.mosaicHeight
                    )
                    .clipped()
                    .cornerRadius(CollageDesignTokens.imageCornerRadius)

                // Mini grid (50%)
                VStack(spacing: CollageDesignTokens.imageSpacing) {
                    // Top row - 2 images
                    HStack(spacing: CollageDesignTokens.imageSpacing) {
                        ForEach(Array(secondaryArray.prefix(2)), id: \.self) { imageId in
                            imageView(for: imageId)
                                .frame(
                                    height: (CollageDesignTokens.mosaicHeight - CollageDesignTokens.imageSpacing * 2) / 3
                                )
                                .clipped()
                                .cornerRadius(CollageDesignTokens.thumbnailCornerRadius)
                        }
                    }

                    // Middle row - 2 images
                    HStack(spacing: CollageDesignTokens.imageSpacing) {
                        ForEach(Array(secondaryArray.dropFirst(2).prefix(2)), id: \.self) { imageId in
                            imageView(for: imageId)
                                .frame(
                                    height: (CollageDesignTokens.mosaicHeight - CollageDesignTokens.imageSpacing * 2) / 3
                                )
                                .clipped()
                                .cornerRadius(CollageDesignTokens.thumbnailCornerRadius)
                        }
                    }

                    // Bottom - mood + count
                    HStack {
                        MoodPill(mood: mood)
                        Spacer()
                        if totalCount > 5 {
                            CountBadge(count: totalCount - 5)
                        }
                    }
                    .frame(
                        height: (CollageDesignTokens.mosaicHeight - CollageDesignTokens.imageSpacing * 2) / 3
                    )
                    .padding(.horizontal, CollageDesignTokens.badgePadding)
                }
                .frame(width: geometry.size.width * 0.5 - CollageDesignTokens.imageSpacing / 2)
            }
        }
        .frame(height: CollageDesignTokens.mosaicHeight)
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
