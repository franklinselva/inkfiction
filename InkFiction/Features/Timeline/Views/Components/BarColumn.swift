//
//  BarColumn.swift
//  InkFiction
//
//  Bar column component for weekly insight chart
//

import SwiftUI

struct BarColumn: View {
    let dayLabel: String
    let entryCount: Int
    let isToday: Bool
    let maxHeight: CGFloat = 80
    let maxEntries: Int  // For scaling
    @Environment(\.themeManager) private var themeManager
    @State private var animatedHeight: CGFloat = 0

    private var barHeight: CGFloat {
        guard maxEntries > 0 else { return 0 }
        let ratio = CGFloat(entryCount) / CGFloat(maxEntries)
        return max(ratio * maxHeight, entryCount > 0 ? 20 : 0)  // Minimum 20pt if has entries
    }

    private var hasEntry: Bool {
        entryCount > 0
    }

    var body: some View {
        VStack(spacing: 6) {
            // Bar
            ZStack(alignment: .bottom) {
                // Empty bar background
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        themeManager.currentTheme.strokeColor,
                        lineWidth: 1.5
                    )
                    .frame(height: maxHeight)

                // Filled bar
                if hasEntry {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: themeManager.currentTheme.gradientColors.map {
                                    $0.opacity(0.7)
                                },
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: animatedHeight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    themeManager.currentTheme.accentColor.opacity(0.5),
                                    lineWidth: isToday ? 2 : 0
                                )
                        )
                }
            }
            .frame(maxWidth: .infinity)

            // Day label
            Text(dayLabel)
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(
                    isToday
                        ? themeManager.currentTheme.accentColor
                        : themeManager.currentTheme.textSecondaryColor
                )
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animatedHeight = barHeight
            }
        }
        .onChange(of: entryCount) { _, _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                animatedHeight = barHeight
            }
        }
    }
}
