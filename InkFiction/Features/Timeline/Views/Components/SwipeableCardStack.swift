//
//  SwipeableCardStack.swift
//  InkFiction
//
//  Interactive swipeable card stack for Timeline visual memories
//

import SwiftUI

struct SwipeableCardStack: View {
    @Environment(\.themeManager) private var themeManager
    @State private var currentIndex = 0
    @State private var dragOffset = CGSize.zero

    let cards: [ImageContainer]
    let maxVisibleCards: Int

    init(cards: [ImageContainer], maxVisibleCards: Int = 4) {
        self.cards = cards
        self.maxVisibleCards = maxVisibleCards
    }

    var body: some View {
        ZStack {
            if !cards.isEmpty {
                ForEach(0..<min(maxVisibleCards, cards.count), id: \.self) { stackPosition in
                    let cardIndex = (currentIndex + stackPosition) % cards.count
                    CompactCardView(
                        container: cards[cardIndex],
                        stackPosition: stackPosition,
                        dragOffset: stackPosition == 0 ? dragOffset : .zero,
                        onSwipe: handleSwipe,
                        onDragChange: handleDragChange,
                        onDragEnd: handleDragEnd
                    )
                    .zIndex(Double(maxVisibleCards - stackPosition))
                }
            }
        }
        .frame(width: 300, height: 450)
        .contentShape(Rectangle())
    }

    private func handleSwipe(direction: SwipeDirection) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if direction == .left || direction == .right {
                if !cards.isEmpty {
                    currentIndex = (currentIndex + 1) % cards.count
                }
            }
            dragOffset = .zero
        }
    }

    private func handleDragChange(value: DragGesture.Value) {
        if abs(value.translation.width) > abs(value.translation.height) * 0.5 {
            dragOffset = CGSize(width: value.translation.width, height: 0)
        }
    }

    private func handleDragEnd(value: DragGesture.Value) {
        let horizontalThreshold: CGFloat = 80
        let verticalThreshold: CGFloat = 50

        if abs(value.translation.height) < verticalThreshold {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                if abs(value.translation.width) > horizontalThreshold {
                    let direction: SwipeDirection = value.translation.width > 0 ? .right : .left
                    handleSwipe(direction: direction)
                } else {
                    dragOffset = .zero
                }
            }
        } else {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                dragOffset = .zero
            }
        }
    }
}

enum SwipeDirection {
    case left, right, up, down
}

struct CompactCardView: View {
    @Environment(\.themeManager) private var themeManager
    let container: ImageContainer
    let stackPosition: Int
    let dragOffset: CGSize
    let onSwipe: (SwipeDirection) -> Void
    let onDragChange: (DragGesture.Value) -> Void
    let onDragEnd: (DragGesture.Value) -> Void

    @State private var showShareSheet = false

    private let cardWidth: CGFloat = 300
    private let cardHeight: CGFloat = 420

    private var cardOffset: CGSize {
        let verticalOffset = CGFloat(stackPosition) * 30
        return CGSize(
            width: dragOffset.width,
            height: verticalOffset
        )
    }

    private var cardScale: Double {
        let scaleReduction = Double(stackPosition) * 0.08
        return max(0.76, 1.0 - scaleReduction)
    }

    private var cardRotation: Double {
        if stackPosition == 0 {
            return Double(dragOffset.width / 30)
        }
        let rotations = [-2.0, 1.5, -1.0, 2.5]
        return rotations[stackPosition % rotations.count]
    }

    private var cardOpacity: Double {
        return stackPosition < 3 ? 1.0 : 0.7
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentTheme.backgroundColor)
                .frame(width: cardWidth, height: cardHeight)
                .overlay(
                    container.image
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth, height: cardHeight)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                )
                .overlay(
                    VStack(spacing: 0) {
                        Spacer()

                        LinearGradient(
                            colors: [
                                Color.black.opacity(0),
                                Color.black.opacity(0.5),
                                Color.black.opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 140)
                        .overlay(
                            VStack {
                                Spacer()

                                HStack(alignment: .bottom) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        if let caption = container.caption {
                                            Text(caption)
                                                .font(.system(size: 17, weight: .bold))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                        }
                                    }

                                    Spacer()

                                    if stackPosition == 0 {
                                        Button(action: {
                                            showShareSheet = true
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(.ultraThinMaterial)
                                                    .frame(width: 40, height: 40)

                                                Image(systemName: "square.and.arrow.up")
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 25)
                            }
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                )
        }
        .frame(width: cardWidth, height: cardHeight)
        .shadow(color: themeManager.currentTheme.shadowColor, radius: 8, x: 0, y: 4)
        .offset(cardOffset)
        .scaleEffect(cardScale)
        .rotationEffect(.degrees(cardRotation))
        .opacity(cardOpacity)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: stackPosition)
        .simultaneousGesture(
            stackPosition == 0 ?
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onChanged(onDragChange)
                .onEnded(onDragEnd)
            : nil
        )
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [container.extractUIImage()] + (container.caption.map { [$0] } ?? []))
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
