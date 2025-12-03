//
//  MoodDistributionView.swift
//  InkFiction
//
//  Reusable mood distribution component for Timeline
//

import SwiftUI

struct MoodDistributionView: View {
    @Environment(\.themeManager) private var themeManager
    let moodDistribution: [(mood: Mood, count: Int)]
    let maxVisible: Int

    init(moodDistribution: [(mood: Mood, count: Int)], maxVisible: Int = 5) {
        self.moodDistribution = moodDistribution
        self.maxVisible = maxVisible
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(moodDistribution.prefix(maxVisible), id: \.mood) { item in
                HStack(spacing: 4) {
                    Image(systemName: item.mood.sfSymbolName)
                        .font(.system(size: 14))
                        .foregroundColor(item.mood.color)
                    Text("\(item.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
            }

            if moodDistribution.count > maxVisible {
                Text("+\(moodDistribution.count - maxVisible)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
            }
        }
    }
}

struct MoodDistributionSimpleView: View {
    @Environment(\.themeManager) private var themeManager
    let moodDistribution: [(mood: Mood, count: Int)]
    let maxVisible: Int

    init(moodDistribution: [(mood: Mood, count: Int)], maxVisible: Int = 5) {
        self.moodDistribution = moodDistribution
        self.maxVisible = maxVisible
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(moodDistribution.prefix(maxVisible), id: \.mood) { item in
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.mood.color)
                        .frame(width: 8, height: 8)
                    Text("\(item.count)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
            }
        }
    }
}
