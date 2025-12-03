//
//  GridPreviewCard.swift
//  InkFiction
//
//  Horizontal scrollable grid preview for image containers
//

import SwiftUI
import UIKit

// MARK: - Size Variants

enum GridPreviewSize {
    case small   // Compact for lists
    case medium  // Standard view
    case large   // Feature showcase

    var cellWidth: CGFloat {
        switch self {
        case .small: return 110
        case .medium: return 150
        case .large: return 200
        }
    }

    var cellHeight: CGFloat {
        switch self {
        case .small: return 150
        case .medium: return 200
        case .large: return 260
        }
    }

    var captionHeight: CGFloat {
        switch self {
        case .small: return 50
        case .medium: return 60
        case .large: return 70
        }
    }

    var totalHeight: CGFloat {
        cellHeight + captionHeight
    }

    var fontSize: Font {
        switch self {
        case .small: return .caption2
        case .medium: return .caption
        case .large: return .subheadline
        }
    }

    var captionLines: Int {
        switch self {
        case .small: return 2
        case .medium: return 2
        case .large: return 3
        }
    }
}

// MARK: - Grid Preview Card

struct GridPreviewCard: View {
    @Environment(\.themeManager) private var themeManager
    let images: [ImageContainer]
    let maxVisible: Int
    let size: GridPreviewSize
    let onTap: () -> Void

    init(
        images: [ImageContainer],
        maxVisible: Int = 10,
        size: GridPreviewSize = .medium,
        onTap: @escaping () -> Void = {}
    ) {
        self.images = images
        self.maxVisible = maxVisible
        self.size = size
        self.onTap = onTap
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(images.prefix(maxVisible).enumerated()), id: \.element.id) { index, container in
                    if index < maxVisible - 1 || images.count <= maxVisible {
                        ImagePreviewCell(
                            container: container,
                            size: size
                        )
                        .onTapGesture {
                            onTap()
                        }
                    } else {
                        // Show "more" indicator for additional images
                        ZStack {
                            ImagePreviewCell(
                                container: container,
                                size: size
                            )
                            .overlay(
                                themeManager.currentTheme.overlayColor.opacity(0.7)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            )

                            VStack(spacing: 4) {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: size == .large ? 32 : 24, weight: .bold))
                                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                                if images.count > maxVisible {
                                    Text("+\(images.count - maxVisible + 1)")
                                        .font(.system(size: size == .large ? 18 : 14, weight: .semibold))
                                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                                }
                            }
                        }
                        .onTapGesture {
                            onTap()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: size.totalHeight)
    }
}

// MARK: - Image Preview Cell

struct ImagePreviewCell: View {
    @Environment(\.themeManager) private var themeManager
    let container: ImageContainer
    let size: GridPreviewSize
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Image area with fixed size
            ZStack {
                // Fallback gradient if no image
                LinearGradient(
                    colors: [
                        themeManager.currentTheme.surfaceColor.opacity(0.5),
                        themeManager.currentTheme.surfaceColor.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Actual image
                container.image
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.cellWidth, height: size.cellHeight)
                    .clipped()

                // Share button overlay - top right corner
                VStack {
                    HStack {
                        Spacer()

                        Button(action: {
                            showShareSheet = true
                        }) {
                            ZStack {
                                // Glass morphism background
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: size == .small ? 28 : 32, height: size == .small ? 28 : 32)

                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: size == .small ? 12 : 14, weight: .medium))
                                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                            }
                        }
                        .shadow(color: themeManager.currentTheme.shadowColor, radius: 2, x: 0, y: 1)
                        .padding(8)
                    }
                    Spacer()
                }
            }
            .frame(width: size.cellWidth, height: size.cellHeight)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Caption area with better contrast
            if let caption = container.caption {
                VStack(spacing: 2) {
                    Text(caption)
                        .font(size.fontSize)
                        .fontWeight(size == .large ? .medium : .regular)
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        .lineLimit(size.captionLines)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
                .frame(width: size.cellWidth, height: size.captionHeight)
                .background(
                    themeManager.currentTheme.backgroundColor.opacity(0.95)
                )
            }
        }
        .frame(width: size.cellWidth)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: themeManager.currentTheme.shadowColor, radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [container.extractUIImage()] + (container.caption.map { [$0] } ?? []))
        }
    }
}
