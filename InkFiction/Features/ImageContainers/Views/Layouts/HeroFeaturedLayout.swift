//
//  HeroFeaturedLayout.swift
//  InkFiction
//
//  Layout for single image - full-width hero image with mood pill
//

import SwiftUI

struct HeroFeaturedLayout: View {
    let imageId: UUID
    let images: [UUID: UIImage]
    let isAIGenerated: Bool
    let mood: Mood

    @Environment(\.themeManager) private var themeManager

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Full-width hero image
            Group {
                if let image = images[imageId] {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    errorPlaceholder
                }
            }
            .frame(height: CollageDesignTokens.heroFeaturedHeight)
            .clipped()
            .cornerRadius(CollageDesignTokens.imageCornerRadius)

            // Mood pill overlay
            MoodPill(mood: mood)
                .padding(CollageDesignTokens.badgePadding)
        }
        .frame(height: CollageDesignTokens.heroFeaturedHeight)
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
