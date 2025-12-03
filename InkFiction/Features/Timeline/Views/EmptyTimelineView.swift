//
//  EmptyTimelineView.swift
//  InkFiction
//
//  Empty state view for Timeline when no entries exist
//

import SwiftUI

struct EmptyTimelineView: View {
    @Environment(\.themeManager) private var themeManager
    let filter: TimelineFilter

    private var emptyMessage: String {
        switch filter {
        case .day:
            return "No journal entries yet"
        case .week:
            return "No journal entries yet"
        case .month:
            return "No journal entries yet"
        }
    }

    private var suggestionMessage: String {
        "Start journaling to see your timeline"
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: themeManager.currentTheme.gradientColors.map { $0.opacity(0.6) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(emptyMessage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

            Text(suggestionMessage)
                .font(.system(size: 14))
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
