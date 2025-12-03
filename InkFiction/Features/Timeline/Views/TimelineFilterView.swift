//
//  TimelineFilterView.swift
//  InkFiction
//
//  Filter tab bar for Timeline (Day/Week/Month)
//

import SwiftUI

struct TimelineFilterView: View {
    @Environment(\.themeManager) private var themeManager
    @Binding var selectedFilter: TimelineFilter
    let namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimelineFilter.allCases, id: \.self) { filter in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFilter = filter
                    }
                }) {
                    Text(filter.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(
                            selectedFilter == filter
                                ? themeManager.currentTheme.textPrimaryColor
                                : themeManager.currentTheme.textSecondaryColor
                        )
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(
                            ZStack {
                                if selectedFilter == filter {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.currentTheme.accentColor.opacity(0.2))
                                        .matchedGeometryEffect(id: "filter", in: namespace)
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentTheme.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.currentTheme.strokeColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
