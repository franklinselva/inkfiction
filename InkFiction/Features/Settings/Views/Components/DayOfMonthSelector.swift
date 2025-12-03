//
//  DayOfMonthSelector.swift
//  InkFiction
//
//  Visual day of month selector for monthly reminders
//

import SwiftUI

struct DayOfMonthSelector: View {
    @Binding var selectedDay: Int
    @Environment(\.themeManager) private var themeManager

    private let days = Array(1...31)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Day of Month")
                .font(.subheadline.weight(.medium))
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                .padding(.horizontal, 4)

            // Calendar-style grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(days, id: \.self) { day in
                    DayCell(
                        day: day,
                        isSelected: selectedDay == day,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDay = day
                            }
                        }
                    )
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.surfaceColor.opacity(0.3))
            )
        }
    }
}

struct DayCell: View {
    let day: Int
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action()
        }) {
            Text("\(day)")
                .font(.body.weight(isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : themeManager.currentTheme.textPrimaryColor)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ?
                              LinearGradient(
                                colors: [
                                    themeManager.currentTheme.accentColor,
                                    themeManager.currentTheme.accentColor.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ) :
                              LinearGradient(
                                colors: [.clear, .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ?
                                        themeManager.currentTheme.accentColor.opacity(0.5) :
                                        themeManager.currentTheme.strokeColor.opacity(0.2),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                        .shadow(
                            color: isSelected ?
                                themeManager.currentTheme.accentColor.opacity(0.3) :
                                .clear,
                            radius: 6,
                            y: 3
                        )
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
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
