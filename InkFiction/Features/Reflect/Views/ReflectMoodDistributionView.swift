//
//  ReflectMoodDistributionView.swift
//  InkFiction
//
//  Visualizes mood distribution as a bar chart for Reflect feature
//

import SwiftUI

// MARK: - Reflect Mood Distribution View

struct ReflectMoodDistributionView: View {

    let distribution: [Mood: Int]
    let theme: Theme

    @State private var sortedMoods: [(mood: Mood, count: Int)] = []

    private var totalCount: Int {
        distribution.values.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(sortedMoods.prefix(5), id: \.mood) { item in
                ReflectMoodBarRow(
                    mood: item.mood,
                    count: item.count,
                    total: totalCount,
                    theme: theme
                )
            }
        }
        .onAppear {
            updateSortedMoods()
        }
        .onChange(of: distribution) { _, _ in
            updateSortedMoods()
        }
    }

    private func updateSortedMoods() {
        sortedMoods = distribution.map { ($0.key, $0.value) }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - Reflect Mood Bar Row

struct ReflectMoodBarRow: View {

    let mood: Mood
    let count: Int
    let total: Int
    let theme: Theme

    @State private var animatedWidth: CGFloat = 0

    private var percentage: CGFloat {
        total > 0 ? CGFloat(count) / CGFloat(total) : 0
    }

    var body: some View {
        HStack(spacing: 8) {
            // Mood emoji
            Text(mood.emoji)
                .font(.body)

            // Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.textSecondaryColor.opacity(0.1))

                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(mood.color)
                        .frame(width: geometry.size.width * animatedWidth)
                }
            }
            .frame(height: 12)

            // Count
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(theme.textSecondaryColor)
                .frame(width: 30, alignment: .trailing)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animatedWidth = percentage
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleDistribution: [Mood: Int] = [
        .happy: 15,
        .peaceful: 10,
        .neutral: 8,
        .thoughtful: 5,
        .anxious: 3
    ]

    return ReflectMoodDistributionView(
        distribution: sampleDistribution,
        theme: .paper
    )
    .padding()
}
