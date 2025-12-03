//
//  ImageThumbnailView.swift
//  InkFiction
//
//  Thumbnail view for displaying journal images with remove button
//

import SwiftUI

struct ImageThumbnailView: View {
    let image: JournalImage
    let onRemove: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Image
            if let uiImage = image.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.currentTheme.surfaceColor, lineWidth: 2)
                    )
                    .overlay(
                        // AI badge if AI generated
                        Group {
                            if image.isAIGenerated {
                                VStack {
                                    Spacer()
                                    HStack {
                                        ImageTypeBadge(type: .aiGenerated)
                                            .scaleEffect(0.8)
                                        Spacer()
                                    }
                                    .padding(4)
                                }
                            }
                        }
                    )
                    .scaleEffect(isPressed ? 0.95 : 1.0)
            } else {
                // Placeholder for missing image
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.surfaceColor.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    )
            }

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 22, height: 22)
                    )
            }
            .offset(x: 8, y: -8)
        }
        .onTapGesture {
            // Could open full screen preview here
        }
        .onLongPressGesture(
            minimumDuration: 0.1,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: { }
        )
    }
}

// MARK: - UIImage variant for compatibility

struct UIImageThumbnailView: View {
    let image: UIImage
    let onRemove: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Image
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.currentTheme.surfaceColor, lineWidth: 2)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 22, height: 22)
                    )
            }
            .offset(x: 8, y: -8)
        }
        .onTapGesture {
            // Could open full screen preview here
        }
        .onLongPressGesture(
            minimumDuration: 0.1,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: { }
        )
    }
}
