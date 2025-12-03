//
//  DateIndicatorView.swift
//  InkFiction
//
//  Reusable date indicator component for Timeline
//

import SwiftUI

struct DateIndicatorView: View {
    @Environment(\.themeManager) private var themeManager
    let date: Date
    let isFirst: Bool
    let scrollOffset: CGFloat

    private var dateHighlight: Double {
        if isFirst {
            return 1.0
        }
        let fadePoint: CGFloat = 200
        let opacity = max(0.6, min(1.0, 1.0 - (abs(scrollOffset) / fadePoint)))
        return opacity
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(DateFormattingUtility.monthAbbreviation(from: date))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(
                    themeManager.currentTheme.textSecondaryColor.opacity(dateHighlight * 0.8))

            Text(DateFormattingUtility.dayNumber(from: date))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(themeManager.currentTheme.textPrimaryColor.opacity(dateHighlight))
                .scaleEffect(isFirst ? 1.1 : 1.0)

            Text(DateFormattingUtility.dayName(from: date))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(
                    themeManager.currentTheme.textSecondaryColor.opacity(dateHighlight * 0.8))
        }
        .animation(.easeInOut(duration: 0.3), value: scrollOffset)
    }
}

struct PeriodIndicatorView: View {
    @Environment(\.themeManager) private var themeManager
    let date: Date
    let filter: TimelineFilter
    let isFirst: Bool
    let scrollOffset: CGFloat

    private var periodHighlight: Double {
        if isFirst {
            return 1.0
        }
        let fadePoint: CGFloat = 200
        let opacity = max(0.6, min(1.0, 1.0 - (abs(scrollOffset) / fadePoint)))
        return opacity
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(PeriodFormatterUtility.periodNumber(for: date, filter: filter))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(
                    themeManager.currentTheme.textPrimaryColor.opacity(periodHighlight)
                )
                .scaleEffect(isFirst ? 1.1 : 1.0)

            Text(PeriodFormatterUtility.periodIndicatorLabel(for: filter))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(
                    themeManager.currentTheme.textSecondaryColor.opacity(periodHighlight * 0.8))
        }
        .animation(.easeInOut(duration: 0.3), value: scrollOffset)
    }
}
