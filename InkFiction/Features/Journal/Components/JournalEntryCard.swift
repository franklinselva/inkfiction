//
//  JournalEntryCard.swift
//  InkFiction
//
//  Card view for displaying journal entries in a list
//

import SwiftUI

struct JournalEntryCard: View {
    let entry: JournalEntry
    var isSelectionMode: Bool = false
    var isSelected: Bool = false

    @Environment(\.themeManager) private var themeManager

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
                // Image preview (if has images)
                if entry.hasImages {
                    JournalImagePreview(images: entry.images)
                }

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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(entry.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(themeManager.currentTheme.accentColor.opacity(0.2))
                                    )
                            }
                        }
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

// MARK: - Journal Image Preview

struct JournalImagePreview: View {
    let images: [JournalImage]

    @Environment(\.themeManager) private var themeManager

    var body: some View {
        if images.count == 1, let image = images.first?.uiImage {
            // Single image
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if images.count > 1 {
            // Multiple images grid
            HStack(spacing: 8) {
                ForEach(images.prefix(3)) { journalImage in
                    if let uiImage = journalImage.uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                if images.count > 3 {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(themeManager.currentTheme.surfaceColor)
                            .frame(height: 100)

                        Text("+\(images.count - 3)")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                }
            }
        }
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
