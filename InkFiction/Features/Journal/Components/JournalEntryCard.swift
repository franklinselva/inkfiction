//
//  JournalEntryCard.swift
//  InkFiction
//
//  Card view for displaying journal entries in a list
//

import SwiftUI

struct JournalEntryCard: View, Equatable {
    let entry: JournalEntry
    var isSelectionMode: Bool = false
    var isSelected: Bool = false

    @Environment(\.themeManager) private var themeManager

    // Equatable conformance for diffing optimization
    static func == (lhs: JournalEntryCard, rhs: JournalEntryCard) -> Bool {
        lhs.entry.id == rhs.entry.id &&
        lhs.entry.updatedAt == rhs.entry.updatedAt &&
        lhs.isSelectionMode == rhs.isSelectionMode &&
        lhs.isSelected == rhs.isSelected
    }

    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(
                        isSelected
                            ? themeManager.currentTheme.accentColor
                            : themeManager.currentTheme.textSecondaryColor
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
            }

            VStack(alignment: .leading, spacing: 12) {
                // Contextual collage view (shows appropriate layout based on image count)
                // Use equatable() to prevent unnecessary re-renders of expensive collage view
                JournalContextualCollageView(entry: entry)
                    .equatable()

                // Header with title, pin icon, date, and chevron
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            if entry.isPinned {
                                Image(systemName: "pin.fill")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                            Text(entry.title.isEmpty ? "Untitled" : entry.title)
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                                .lineLimit(1)
                        }

                        Text(entry.createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }

                    Spacer()

                    // Mood indicator
                    Image(systemName: entry.mood.sfSymbolName)
                        .foregroundColor(entry.mood.color)
                        .font(.body)

                    if !isSelectionMode {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                }

                // Content preview
                if !entry.content.isEmpty {
                    Text(entry.content)
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        .lineLimit(2)
                }

                // Tags
                if !entry.tags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(entry.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(themeManager.currentTheme.accentColor.opacity(0.2))
                                )
                                .lineLimit(1)
                        }

                        if entry.tags.count > 3 {
                            Text("+\(entry.tags.count - 3)")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    themeManager.currentTheme.type.isLight
                        ? Color.white
                        : themeManager.currentTheme.surfaceColor.opacity(0.5)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected
                        ? LinearGradient(
                            colors: themeManager.currentTheme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [
                                themeManager.currentTheme.textSecondaryColor.opacity(
                                    themeManager.currentTheme.type.isLight ? 0.15 : 0.08
                                )
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(
            color: Color.black.opacity(
                themeManager.currentTheme.type.isLight ? 0.05 : 0.2
            ),
            radius: 8,
            x: 0,
            y: 3
        )
        .shadow(
            color: Color.black.opacity(
                themeManager.currentTheme.type.isLight ? 0.03 : 0.1
            ),
            radius: 2,
            x: 0,
            y: 1
        )
    }
}

// MARK: - Card Button Style

struct JournalCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
