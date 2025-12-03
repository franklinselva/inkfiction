//
//  DuoFlowLayout.swift
//  InkFiction
//
//  Layout for two images - simple side-by-side split
//

import SwiftUI

struct DuoFlowLayout: View {
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
        guard imageIds.count >= 2 else {
            return AnyView(EmptyView())
        }

        return AnyView(
            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    HStack(spacing: CollageDesignTokens.imageSpacing) {
                        // Simple equal split
                        ForEach(Array(imageIds.prefix(2)), id: \.self) { imageId in
                            imageView(for: imageId)
                                .frame(
                                    width: geometry.size.width / 2 - CollageDesignTokens.imageSpacing / 2,
                                    height: CollageDesignTokens.duoFlowHeightSame
                                )
                                .clipped()
                                .cornerRadius(CollageDesignTokens.imageCornerRadius)
                        }
                    }

                    // Floating mood pill
                    MoodPill(mood: mood)
                        .padding(CollageDesignTokens.badgePadding)
                }
            }
            .frame(height: CollageDesignTokens.duoFlowHeightSame)
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
