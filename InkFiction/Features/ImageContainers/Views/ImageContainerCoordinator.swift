//
//  ImageContainerCoordinator.swift
//  InkFiction
//
//  Coordinator view for switching between different image display modes
//

import SwiftUI

// MARK: - Image Container Mode

enum ImageContainerMode: String, CaseIterable {
    case grid
    case stack
    case polaroid

    var displayName: String {
        switch self {
        case .grid: return "Grid View"
        case .stack: return "Card Stack"
        case .polaroid: return "Polaroid"
        }
    }

    var icon: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .stack: return "square.stack"
        case .polaroid: return "camera"
        }
    }
}

// MARK: - Image Container Coordinator

struct ImageContainerCoordinator: View {
    @Environment(\.themeManager) private var themeManager
    let images: [ImageContainer]
    @State private var displayMode: ImageContainerMode = .grid
    @State private var showFullView = false

    var body: some View {
        ZStack {
            switch displayMode {
            case .grid:
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { _ in
                            GridPreviewCard(
                                images: images,
                                maxVisible: 3,
                                onTap: {
                                    showFullView = true
                                    displayMode = .stack
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }

            case .stack:
                SwipeableCardStack(cards: images)

            case .polaroid:
                PolaroidCarousel(images: images)
            }

            // Mode switcher overlay
            if !showFullView {
                VStack {
                    HStack {
                        Spacer()
                        Menu {
                            ForEach(ImageContainerMode.allCases, id: \.self) { mode in
                                Button(action: { displayMode = mode }) {
                                    Label(mode.displayName, systemImage: mode.icon)
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.title2)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                                .background(themeManager.currentTheme.overlayColor)
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
        }
        .fullScreenCover(isPresented: $showFullView) {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                switch displayMode {
                case .stack:
                    SwipeableCardStack(cards: images)
                case .polaroid:
                    PolaroidCarousel(images: images)
                default:
                    SwipeableCardStack(cards: images)
                }

                // Close button
                VStack {
                    HStack {
                        Button(action: {
                            showFullView = false
                            displayMode = .grid
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                                .background(themeManager.currentTheme.overlayColor)
                                .clipShape(Circle())
                        }
                        .padding()
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ImageContainerCoordinator(images: ImageContainer.sampleContainers)
}
