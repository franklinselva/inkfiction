//
//  MoodShowcaseLayout.swift
//  InkFiction
//
//  Layout for entries with no images - showcases mood with radial gradient
//

import SwiftUI

struct MoodShowcaseLayout: View {
    let mood: Mood
    let tags: [String]
    let content: String

    @Environment(\.themeManager) private var themeManager

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    mood.color.opacity(0.3),
                    mood.color.opacity(0.05),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 120
            )

            VStack(spacing: 8) {
                Image(systemName: mood.sfSymbolName)
                    .font(.system(size: CollageDesignTokens.moodIconSizeLarge))
                    .foregroundColor(mood.color)
                    .symbolEffect(.pulse)

                Text(mood.rawValue)
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                if !tags.isEmpty {
                    Text("\(tags.count) tags \u{00B7} \(readingTime)")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(height: CollageDesignTokens.moodShowcaseHeight)
        .cornerRadius(CollageDesignTokens.cardCornerRadius)
    }

    private var readingTime: String {
        let wordCount = content.split(separator: " ").count
        let minutes = max(1, wordCount / 200)
        return "\(minutes) min read"
    }
}

#Preview {
    VStack(spacing: 16) {
        MoodShowcaseLayout(mood: .happy, tags: ["travel", "adventure"], content: "This is a sample journal entry with some content.")
        MoodShowcaseLayout(mood: .peaceful, tags: [], content: "A short entry.")
    }
    .padding()
}
