//
//  ShimmerView.swift
//  InkFiction
//
//  Shimmer effect for loading states
//

import SwiftUI

struct ShimmerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.2),
                        Color.gray.opacity(0.1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .modifier(ConditionalShimmerMask(isEnabled: !reduceMotion, phase: phase))
            .onAppear {
                if !reduceMotion {
                    withAnimation(
                        .linear(duration: CollageDesignTokens.shimmerDuration)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = UIScreen.main.bounds.width
                    }
                }
            }
    }
}

// MARK: - Conditional Shimmer Mask

private struct ConditionalShimmerMask: ViewModifier {
    let isEnabled: Bool
    let phase: CGFloat

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .mask(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: phase)
                )
        } else {
            content
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ShimmerView()
            .frame(height: 200)
            .cornerRadius(12)

        ShimmerView()
            .frame(height: 100)
            .cornerRadius(8)
    }
    .padding()
}
