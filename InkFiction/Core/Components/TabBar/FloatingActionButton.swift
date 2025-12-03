//
//  FloatingActionButton.swift
//  InkFiction
//
//  Floating action button for creating new journal entries
//

import SwiftUI
import UIKit

struct FloatingActionButton: View {

    // MARK: - Properties

    let theme: Theme
    let action: () -> Void

    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            ZStack {
                // Gradient background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: theme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                // Glass overlay
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isPressed ? 45 : 0))
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        // Multi-layer shadow for depth
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 20,
            x: 0,
            y: 10
        )
        .shadow(
            color: theme.gradientColors.first?.opacity(0.3) ?? theme.accentColor.opacity(0.3),
            radius: 12,
            x: 0,
            y: 6
        )
        .shadow(
            color: Color.black.opacity(0.12),
            radius: 4,
            x: 0,
            y: 2
        )
        .accessibilityLabel("Add new journal entry")
        .accessibilityHint("Double tap to create a new journal entry")
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        FloatingActionButton(theme: .paper) {
            print("FAB tapped")
        }
    }
}
