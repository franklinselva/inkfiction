//
//  MoodSelectorView.swift
//  InkFiction
//
//  Grid view for selecting mood with visual feedback
//

import SwiftUI

struct MoodSelectorView: View {
    @Binding var selectedMood: Mood
    @Binding var isExpanded: Bool

    @Environment(\.themeManager) private var themeManager

    @State private var selectedMoodIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with current mood badge
            HStack {
                Text("Mood")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Spacer()

                // Selected mood badge
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: selectedMood.sfSymbolName)
                            .font(.system(size: 14, weight: .medium))
                        Text(selectedMood.rawValue)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(selectedMood.color)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(
                        color: selectedMood.color.opacity(0.3),
                        radius: 6,
                        y: 2
                    )
                }
            }

            // Mood picker grid with staggered animation
            if isExpanded {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                    ForEach(Array(Mood.allCases.enumerated()), id: \.element) { index, mood in
                        moodButton(for: mood, index: index)
                            .opacity(isExpanded ? 1 : 0)
                            .scaleEffect(isExpanded ? 1 : 0.8)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.8)
                                    .delay(isExpanded ? Double(index) * 0.03 : 0),
                                value: isExpanded
                            )
                    }
                }
                .transition(
                    .asymmetric(
                        insertion: .opacity.animation(.easeIn(duration: 0.2)),
                        removal: .opacity.animation(.easeOut(duration: 0.2))
                    )
                )
            }
        }
    }

    @ViewBuilder
    private func moodButton(for mood: Mood, index: Int) -> some View {
        let isSelected = selectedMood == mood

        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedMoodIndex = index
                selectedMood = mood

                // Auto-hide picker after selection
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                }
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: mood.sfSymbolName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        isSelected
                            ? LinearGradient(colors: [.white], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [mood.color], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )

                Text(mood.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : mood.color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? mood.color : mood.color.opacity(0.15))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color.white.opacity(0.3) : mood.color.opacity(0.3),
                        lineWidth: isSelected ? 1.5 : 1
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
            )
            .shadow(
                color: isSelected ? mood.color.opacity(0.4) : .clear,
                radius: isSelected ? 8 : 0,
                y: isSelected ? 2 : 0
            )
        }
        .scaleEffect(selectedMoodIndex == index ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedMoodIndex)
    }
}

// MARK: - Compact Mood Selector (for filter)

struct CompactMoodSelector: View {
    @Binding var selectedMood: Mood?

    @Environment(\.themeManager) private var themeManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All moods option
                moodChip(mood: nil, label: "All")

                ForEach(Mood.allCases, id: \.self) { mood in
                    moodChip(mood: mood, label: mood.rawValue)
                }
            }
        }
    }

    @ViewBuilder
    private func moodChip(mood: Mood?, label: String) -> some View {
        let isSelected = selectedMood == mood

        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedMood = mood
            }
        }) {
            HStack(spacing: 4) {
                if let mood = mood {
                    Image(systemName: mood.sfSymbolName)
                        .font(.system(size: 12))
                }
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(
                isSelected
                    ? .white
                    : (mood?.color ?? themeManager.currentTheme.textPrimaryColor)
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        isSelected
                            ? (mood?.color ?? themeManager.currentTheme.accentColor)
                            : (mood?.color.opacity(0.15) ?? themeManager.currentTheme.surfaceColor)
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected
                            ? Color.clear
                            : (mood?.color.opacity(0.3) ?? themeManager.currentTheme.textSecondaryColor.opacity(0.3)),
                        lineWidth: 1
                    )
            )
        }
    }
}
