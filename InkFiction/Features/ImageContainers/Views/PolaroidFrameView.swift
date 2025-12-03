//
//  PolaroidFrameView.swift
//  InkFiction
//
//  Polaroid-style frame for displaying images
//

import SwiftUI

// MARK: - Polaroid Frame Color

extension Color {
    static let polaroidFrame = Color(red: 0.98, green: 0.98, blue: 0.96)
}

// MARK: - Polaroid Frame View

struct PolaroidFrameView: View {
    @Environment(\.themeManager) private var themeManager
    let container: ImageContainer
    let rotation: Double
    let onDelete: (() -> Void)?

    init(container: ImageContainer, rotation: Double = 0, onDelete: (() -> Void)? = nil) {
        self.container = container
        self.rotation = rotation
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(spacing: 0) {
            // Photo area - fixed square size
            ZStack {
                // Background for photo area
                Rectangle()
                    .fill(themeManager.currentTheme.surfaceColor.opacity(0.2))
                    .frame(width: 256, height: 256)

                // Actual image with fixed size
                container.image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 256, height: 256)
                    .clipped()
            }
            .frame(width: 256, height: 256)
            .padding(12) // White border around photo
            .background(Color.polaroidFrame)

            // Caption area (larger bottom padding for polaroid effect)
            VStack(spacing: 4) {
                if let caption = container.caption {
                    Text(caption)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.black.opacity(0.85))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }

                if let date = container.date {
                    Text(date.formatted(.dateTime.month(.abbreviated).day().year()))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.black.opacity(0.6))
                }
            }
            .frame(width: 280, height: 60)
            .background(Color.polaroidFrame)
        }
        .frame(width: 280, height: 340) // Fixed polaroid size
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.polaroidFrame)
                .shadow(
                    color: themeManager.currentTheme.shadowColor,
                    radius: 10,
                    x: 0,
                    y: 5
                )
        )
        .overlay(
            // Delete button (top-right corner)
            Group {
                if let onDelete = onDelete {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: onDelete) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 26, height: 26)
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                            }
                            .padding(8)
                        }
                        Spacer()
                    }
                }
            }
        )
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Polaroid Carousel

struct PolaroidCarousel: View {
    let images: [ImageContainer]
    let onDelete: ((ImageContainer) -> Void)?
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging = false
    @Environment(\.themeManager) private var themeManager

    private let cardWidth: CGFloat = 280
    private let cardSpacing: CGFloat = 20

    init(images: [ImageContainer], onDelete: ((ImageContainer) -> Void)? = nil) {
        self.images = images
        self.onDelete = onDelete
    }

    var body: some View {
        GeometryReader { geometry in
            // Carousel
            HStack(spacing: cardSpacing) {
                ForEach(Array(images.enumerated()), id: \.element.id) { index, container in
                    PolaroidFrameView(
                        container: container,
                        rotation: randomRotation(for: index),
                        onDelete: onDelete != nil ? { onDelete?(container) } : nil
                    )
                    .frame(width: cardWidth)
                    .scaleEffect(scale(for: index))
                    .opacity(opacity(for: index))
                    .animation(.spring(), value: currentIndex)
                }
            }
            .offset(x: offset(in: geometry))
            .gesture(
                DragGesture()
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        handleDragEnd(value, geometry: geometry)
                    }
            )
        }
    }

    private func offset(in geometry: GeometryProxy) -> CGFloat {
        let baseOffset = -CGFloat(currentIndex) * (cardWidth + cardSpacing)
        let centeringOffset = (geometry.size.width - cardWidth) / 2
        return baseOffset + centeringOffset + dragOffset
    }

    private func scale(for index: Int) -> CGFloat {
        let distance = abs(index - currentIndex)
        return distance == 0 ? 1.0 : 0.9
    }

    private func opacity(for index: Int) -> Double {
        let distance = abs(index - currentIndex)
        return distance <= 1 ? 1.0 : 0.6
    }

    private func randomRotation(for index: Int) -> Double {
        let rotations = [-3.0, 2.0, -4.0, 3.0, -2.0, 4.0]
        return rotations[index % rotations.count]
    }

    private func handleDragEnd(_ value: DragGesture.Value, geometry: GeometryProxy) {
        let threshold: CGFloat = 50
        let dragAmount = value.translation.width

        withAnimation(.spring()) {
            if dragAmount > threshold && currentIndex > 0 {
                currentIndex -= 1
            } else if dragAmount < -threshold && currentIndex < images.count - 1 {
                currentIndex += 1
            }
            dragOffset = 0
        }
    }
}

// MARK: - Page Indicator

struct PageIndicator: View {
    @Environment(\.themeManager) private var themeManager
    let numberOfPages: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { page in
                Circle()
                    .fill(page == currentPage ? themeManager.currentTheme.textPrimaryColor : themeManager.currentTheme.textPrimaryColor.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: currentPage)
            }
        }
    }
}
