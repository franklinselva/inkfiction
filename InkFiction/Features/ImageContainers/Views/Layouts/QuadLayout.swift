//
//  QuadLayout.swift
//  InkFiction
//
//  Layout for four images - 2x2 grid with mood pill overlay
//

import SwiftUI

struct QuadLayout: View {
    let imageIds: [UUID]
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
        let imageArray = Array(imageIds.prefix(4))

        return VStack(spacing: CollageDesignTokens.imageSpacing) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: CollageDesignTokens.imageSpacing) {
                    ForEach(0..<2, id: \.self) { col in
                        let index = row * 2 + col
                        if index < imageArray.count {
                            imageView(for: imageArray[index])
                            .frame(maxWidth: .infinity)
                            .frame(height: (CollageDesignTokens.quadHeight - CollageDesignTokens.imageSpacing) / 2)
                            .clipped()
                            .cornerRadius(CollageDesignTokens.imageCornerRadius)
                        }
                    }
                }
            }
        }
        .overlay(alignment: .bottomLeading) {
            MoodPill(mood: mood)
                .padding(CollageDesignTokens.badgePadding)
        }
        .frame(height: CollageDesignTokens.quadHeight)
        .cornerRadius(CollageDesignTokens.cardCornerRadius)
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
