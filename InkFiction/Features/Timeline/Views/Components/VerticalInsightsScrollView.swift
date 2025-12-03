//
//  VerticalInsightsScrollView.swift
//  InkFiction
//
//  A custom vertical scroll view that implements snap-to-card behavior for insight cards
//

import SwiftUI

/// A custom vertical scroll view that implements snap-to-card behavior for insight cards
struct VerticalInsightsScrollView<Content: View>: View {
    // MARK: - Properties

    /// The content to display (cards)
    let content: Content

    /// Total number of cards
    let cardCount: Int

    /// Height of each card (fixed, including padding)
    let cardHeight: CGFloat

    /// Current card index binding
    @Binding var currentIndex: Int

    /// Callback when card changes
    var onCardChange: ((Int) -> Void)?

    // MARK: - State

    /// Cumulative scroll offset (cards * (cardHeight + spacing))
    @State private var scrollOffset: CGFloat = 0

    /// Current drag translation
    @State private var dragTranslation: CGFloat = 0

    /// Is actively dragging
    @State private var isDragging = false

    /// Haptic feedback generator
    @State private var impactFeedback = UIImpactFeedbackGenerator(style: .medium)

    // MARK: - Constants

    private let snapThreshold: CGFloat = 40 // Snap after 40pt drag
    private let cardSpacing: CGFloat = 12 // Spacing between cards

    // MARK: - Initialization

    init(
        cardCount: Int,
        cardHeight: CGFloat,
        currentIndex: Binding<Int>,
        onCardChange: ((Int) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.cardCount = cardCount
        self.cardHeight = cardHeight
        self._currentIndex = currentIndex
        self.onCardChange = onCardChange
        self.content = content()
    }

    // MARK: - Computed Properties

    /// Total offset = base scroll offset + current drag
    private var totalOffset: CGFloat {
        scrollOffset + dragTranslation
    }

    /// Height of each card including spacing
    private var cardWithSpacing: CGFloat {
        cardHeight + cardSpacing
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            content
                .offset(y: totalOffset)
                .frame(width: geometry.size.width)
                .gesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            handleDragChanged(value)
                        }
                        .onEnded { value in
                            handleDragEnded(value)
                        }
                )
                .onAppear {
                    impactFeedback.prepare()
                    // Initialize scroll offset to show first card (index 0)
                    scrollOffset = 0
                    Log.debug("Initial scroll offset: \(scrollOffset), currentIndex: \(currentIndex)", category: .ui)
                }
                .onChange(of: currentIndex) { _, newIndex in
                    // Snap to new index when changed externally
                    snapToCard(newIndex)
                }
        }
        .frame(height: cardHeight)
        .clipped() // Clip overflow cards
    }

    // MARK: - Gesture Handlers

    private func handleDragChanged(_ value: DragGesture.Value) {
        isDragging = true
        dragTranslation = value.translation.height

        // Clamp drag translation to prevent over-scrolling
        let minOffset = -CGFloat(cardCount - 1) * cardWithSpacing
        let maxOffset: CGFloat = 0

        let tentativeOffset = scrollOffset + dragTranslation
        if tentativeOffset > maxOffset {
            // Add resistance when dragging beyond first card
            let excess = tentativeOffset - maxOffset
            dragTranslation = maxOffset - scrollOffset + excess * 0.3
        } else if tentativeOffset < minOffset {
            // Add resistance when dragging beyond last card
            let excess = minOffset - tentativeOffset
            dragTranslation = minOffset - scrollOffset - excess * 0.3
        }
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        isDragging = false

        let dragDistance = value.translation.height
        let velocity = value.predictedEndTranslation.height - value.translation.height
        var targetIndex = currentIndex

        // Calculate target index based on drag distance and velocity
        if abs(dragDistance) > snapThreshold || abs(velocity) > 100 {
            if dragDistance > 0 || velocity > 100 {
                // Dragged down or fast swipe down = previous card
                targetIndex = max(0, currentIndex - 1)
            } else if dragDistance < 0 || velocity < -100 {
                // Dragged up or fast swipe up = next card
                targetIndex = min(cardCount - 1, currentIndex + 1)
            }
        }

        // Snap to target card
        snapToCard(targetIndex)
        dragTranslation = 0
    }

    // MARK: - Helper Methods

    private func snapToCard(_ index: Int) {
        let didChange = index != currentIndex

        // Calculate target offset (negative because we're offsetting down for higher indices)
        let targetOffset = -CGFloat(index) * cardWithSpacing

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentIndex = index
            scrollOffset = targetOffset
        }

        if didChange {
            // Trigger haptic feedback
            impactFeedback.impactOccurred()
            impactFeedback.prepare()

            // Notify callback
            onCardChange?(index)

            Log.debug("Snapped to card \(index), offset: \(targetOffset)", category: .ui)
        }
    }
}
