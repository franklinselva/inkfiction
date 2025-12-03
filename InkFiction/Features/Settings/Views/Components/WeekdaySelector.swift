//
//  WeekdaySelector.swift
//  InkFiction
//
//  Visual weekday selector for weekly reminders
//

import SwiftUI

struct WeekdaySelector: View {
    @Binding var selectedDay: Int
    @Environment(\.themeManager) private var themeManager

    private let weekdays: [Weekday] = Weekday.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Day")
                .font(.subheadline.weight(.medium))
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                .padding(.horizontal, 4)

            // Visual day pills in a grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 12
            ) {
                ForEach(weekdays) { day in
                    WeekdayPill(
                        day: day,
                        isSelected: selectedDay == day.rawValue,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDay = day.rawValue
                            }
                        }
                    )
                }
            }
        }
    }
}

struct WeekdayPill: View {
    let day: Weekday
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action()
        }) {
            VStack(spacing: 6) {
                Text(day.uppercasedShortName)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(
                        isSelected ? .white : themeManager.currentTheme.textSecondaryColor)

                Text(day.initial)
                    .font(.title3.weight(.bold))
                    .foregroundColor(
                        isSelected ? .white : themeManager.currentTheme.textPrimaryColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [
                                    themeManager.currentTheme.accentColor,
                                    themeManager.currentTheme.accentColor.opacity(0.8),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    themeManager.currentTheme.surfaceColor,
                                    themeManager.currentTheme.surfaceColor,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected
                                    ? themeManager.currentTheme.accentColor.opacity(0.5)
                                    : themeManager.currentTheme.strokeColor.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected
                            ? themeManager.currentTheme.accentColor.opacity(0.3) : .clear,
                        radius: 8,
                        y: 4
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}
