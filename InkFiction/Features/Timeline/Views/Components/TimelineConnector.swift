//
//  TimelineConnector.swift
//  InkFiction
//
//  Vertical connector line for Timeline entries
//

import SwiftUI

struct TimelineConnector: View {
    @Environment(\.themeManager) private var themeManager
    let isFirst: Bool
    let isLast: Bool
    let scrollOffset: CGFloat

    private var lineOpacity: Double {
        isFirst ? 0.35 : 0.22
    }

    var body: some View {
        VStack(spacing: 0) {
            // Line extending downward
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            themeManager.currentTheme.strokeColor.opacity(lineOpacity * 1.2),
                            themeManager.currentTheme.strokeColor.opacity(lineOpacity * 0.6),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2)
                .frame(height: isLast ? 60 : nil)

            if isLast {
                Spacer()
            }
        }
    }
}
