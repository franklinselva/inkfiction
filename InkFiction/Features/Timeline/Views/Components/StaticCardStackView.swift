//
//  StaticCardStackView.swift
//  InkFiction
//
//  View-only card stack for Timeline (no swipe gestures)
//

import SwiftUI

struct StaticCardStackView: View {
    @Environment(\.themeManager) private var themeManager
    let cards: [ImageContainer]
    let maxVisibleCards: Int

    init(cards: [ImageContainer], maxVisibleCards: Int = 3) {
        self.cards = cards
        self.maxVisibleCards = maxVisibleCards
    }

    var body: some View {
        ZStack {
            ForEach(0..<min(maxVisibleCards, cards.count), id: \.self) { index in
                StaticCardView(
                    container: cards[index],
                    stackPosition: index,
                    totalCards: cards.count,
                    maxVisible: maxVisibleCards
                )
                .zIndex(Double(maxVisibleCards - index))
            }
        }
        .frame(height: 420)
    }
}

struct StaticCardView: View {
    @Environment(\.themeManager) private var themeManager
    let container: ImageContainer
    let stackPosition: Int
    let totalCards: Int
    let maxVisible: Int

    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 400

    private var cardOffset: CGSize {
        let verticalOffset = CGFloat(stackPosition) * 25
        let horizontalOffset = CGFloat(stackPosition) * 5
        return CGSize(width: horizontalOffset, height: verticalOffset)
    }

    private var cardScale: Double {
        let scaleReduction = Double(stackPosition) * 0.05
        return max(0.85, 1.0 - scaleReduction)
    }

    private var cardRotation: Double {
        let rotations = [0.0, -1.5, 1.0, -0.5]
        return rotations[stackPosition % rotations.count]
    }

    private var cardOpacity: Double {
        return stackPosition < 2 ? 1.0 : 0.8
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
                    // Gradient overlay for text visibility - ALWAYS dark for contrast
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.clear,
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                )
                .overlay(
                    VStack {
                        Spacer()

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if let caption = container.caption {
                                    Text(caption)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                }

                                if stackPosition == 0 && totalCards > maxVisible {
                                    HStack(spacing: 4) {
                                        Image(systemName: "square.stack.3d.up.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.95))
                                        Text("\(totalCards) memories")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.95))
                                    }
                                    .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                )
        }
        .frame(width: cardWidth, height: cardHeight)
        .shadow(color: themeManager.currentTheme.shadowColor, radius: 10, x: 0, y: 5)
        .offset(cardOffset)
        .scaleEffect(cardScale)
        .rotationEffect(.degrees(cardRotation))
        .opacity(cardOpacity)
    }
}
