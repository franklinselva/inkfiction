//
//  SettingsRowLabel.swift
//  InkFiction
//
//  Reusable row label component for settings items
//

import SwiftUI

struct SettingsRowLabel: View {
    let icon: String
    let title: String
    let color: Color
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
        }
    }
}

#Preview {
    SettingsRowLabel(icon: "bell.fill", title: "Notifications", color: .orange)
        .environment(\.themeManager, ThemeManager())
}
