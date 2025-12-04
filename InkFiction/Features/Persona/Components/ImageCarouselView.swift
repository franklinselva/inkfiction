//
//  ImageCarouselView.swift
//  InkFiction
//
//  Carousel component for image selection and preview during persona creation
//

import Combine
import PhotosUI
import SwiftUI

struct ImageCarouselView: View {
    @Binding var selectedImage: UIImage?
    @Binding var showImagePicker: Bool
    @Binding var isGenerating: Bool
    @Binding var generationProgress: Double
    var selectedStyles: Set<AvatarStyle>
    let themeManager: ThemeManager

    @State private var currentIndex = 0

    private var imageAspectRatio: CGFloat {
        guard let image = selectedImage else { return 1.0 }
        return image.size.width / image.size.height
    }

    private var carouselHeight: CGFloat {
        guard selectedImage != nil else { return 280 }
        let width = UIScreen.main.bounds.width - 40
        let calculatedHeight = width / imageAspectRatio
        return min(400, max(200, calculatedHeight))
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                TabView(selection: $currentIndex) {
                    if let image = selectedImage {
                        SelectedImageCard(
                            image: image,
                            themeManager: themeManager,
                            onRemove: { selectedImage = nil }
                        )
                        .tag(0)
                    } else {
                        PhotoLibraryCard(
                            themeManager: themeManager,
                            action: { showImagePicker = true }
                        )
                        .tag(0)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: carouselHeight)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: carouselHeight)

                if isGenerating && selectedImage != nil {
                    GenerationOverlayCompact(
                        progress: generationProgress,
                        selectedStyles: Array(selectedStyles),
                        themeManager: themeManager
                    )
                }
            }

            if selectedImage != nil && !isGenerating {
                Button(action: { selectedImage = nil }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                        Text("Change Photo")
                            .font(.caption)
                    }
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
            }
        }
    }
}

// MARK: - Photo Library Card

struct PhotoLibraryCard: View {
    let themeManager: ThemeManager
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    themeManager.currentTheme.accentColor.opacity(0.2),
                                    themeManager.currentTheme.accentColor.opacity(0.05)
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: isHovered ? 20 : 15)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeManager.currentTheme.accentColor.opacity(0.15),
                                    themeManager.currentTheme.accentColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "photo.fill")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.accentColor)
                        .symbolRenderingMode(.hierarchical)
                }
                .scaleEffect(isHovered ? 1.05 : 1.0)

                VStack(spacing: 8) {
                    Text("Choose from Library")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    Text("Select a photo for your persona")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.currentTheme.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                themeManager.currentTheme.accentColor.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: themeManager.currentTheme.accentColor.opacity(0.1),
                radius: 10,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Selected Image Card

struct SelectedImageCard: View {
    let image: UIImage
    let themeManager: ThemeManager
    let onRemove: () -> Void
    @State private var showRemoveButton = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.currentTheme.backgroundColor.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: themeManager.currentTheme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )

            VStack {
                Spacer()
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Photo Selected")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.9))
                    )
                    .shadow(radius: 4)

                    Spacer()
                }
                .padding(16)
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showRemoveButton.toggle()
            }
        }
    }
}

// MARK: - Generation Overlay Compact

struct GenerationOverlayCompact: View {
    let progress: Double
    let selectedStyles: [AvatarStyle]
    let themeManager: ThemeManager
    @State private var currentStyleIndex = 0
    @State private var currentText = ""
    @State private var timer: AnyCancellable?

    private var stylesToAnimate: [String] {
        selectedStyles.isEmpty
            ? ["Dynamic", "Creative", "Artistic"]
            : selectedStyles.map { $0.displayName }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.85))

            VStack(spacing: 20) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: themeManager.currentTheme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse)

                Text("Creating \(currentText) variations")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                    .frame(width: 150)
            }
            .padding(30)
        }
        .onAppear {
            currentText = stylesToAnimate[currentStyleIndex]

            // Start timer
            timer = Timer.publish(every: 2.0, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStyleIndex = (currentStyleIndex + 1) % stylesToAnimate.count
                        currentText = stylesToAnimate[currentStyleIndex]
                    }
                }
        }
        .onDisappear {
            // Cancel timer to prevent memory leak
            timer?.cancel()
            timer = nil
        }
    }
}
