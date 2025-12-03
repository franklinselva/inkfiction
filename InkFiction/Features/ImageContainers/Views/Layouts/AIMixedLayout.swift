//
//  AIMixedLayout.swift
//  InkFiction
//
//  Layout for AI + Photos mixed - AI featured with gradient border
//

import SwiftUI

struct AIMixedLayout: View {
    let aiImageId: UUID
    let photoIds: [UUID]
    let images: [UUID: UIImage]
    let aiCount: Int
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
        VStack(spacing: CollageDesignTokens.imageSpacing) {
            // Featured AI image with gradient border
            imageView(for: aiImageId)
                .frame(height: CollageDesignTokens.aiMixedHeight * 0.6)
                .clipped()
                .cornerRadius(CollageDesignTokens.imageCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: CollageDesignTokens.imageCornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .pink, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )

            // Photo thumbnails + AI badge
            HStack(spacing: CollageDesignTokens.imageSpacing) {
                ForEach(Array(photoIds.prefix(2)), id: \.self) { photoId in
                    imageView(for: photoId)
                        .frame(maxWidth: .infinity)
                        .frame(height: CollageDesignTokens.aiMixedHeight * 0.4 - CollageDesignTokens.imageSpacing)
                        .clipped()
                        .cornerRadius(CollageDesignTokens.thumbnailCornerRadius)
                }

                // AI count badge
                VStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("\(aiCount) AI")
                        .font(.caption2.bold())
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: CollageDesignTokens.aiMixedHeight * 0.4 - CollageDesignTokens.imageSpacing)
                .background(
                    RoundedRectangle(cornerRadius: CollageDesignTokens.thumbnailCornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.15), .pink.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
        }
        .frame(height: CollageDesignTokens.aiMixedHeight)
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
