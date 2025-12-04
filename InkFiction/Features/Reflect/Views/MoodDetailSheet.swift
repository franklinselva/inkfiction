//
//  MoodDetailSheet.swift
//  InkFiction
//
//  Native iOS sheet for mood detail display
//

import SwiftUI

// MARK: - Mood Detail Sheet

struct MoodDetailSheet: View {
    let moodData: OrganicMoodOrbCluster.MoodOrbData
    let timeframe: TimeFrame

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        let theme = themeManager.currentTheme

        VStack(spacing: 0) {
            // Header with drag indicator and close button
            VStack(spacing: 0) {
                // Native drag indicator
                Capsule()
                    .fill(theme.textPrimaryColor.opacity(0.2))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // Close button aligned to the right
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.textSecondaryColor)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Clean header
                    MoodDetailHeader(moodData: moodData)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 16)

                    // Subtle divider
                    Rectangle()
                        .fill(theme.strokeColor.opacity(0.15))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // AI Reflection section
                    MoodReflectionView(moodData: moodData, timeframe: timeframe)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // Visual memories section with divider
                    if !moodData.entries.isEmpty {
                        Rectangle()
                            .fill(theme.strokeColor.opacity(0.15))
                            .frame(height: 1)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)

                        VisualMemoriesSection(entries: moodData.entries)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                    }
                }
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
        }
        .background(theme.backgroundColor)
    }
}

// MARK: - Header Component

struct MoodDetailHeader: View {
    let moodData: OrganicMoodOrbCluster.MoodOrbData
    @Environment(\.themeManager) private var themeManager

    private var entryCountText: String {
        let count = moodData.entryCount
        return count == 1 ? "1 journal entry" : "\(count) journal entries"
    }

    var body: some View {
        let theme = themeManager.currentTheme

        HStack(alignment: .top, spacing: 20) {
            // Left side - Clean info layout
            VStack(alignment: .leading, spacing: 8) {
                // Mood type with icon
                HStack(spacing: 10) {
                    Image(systemName: moodData.mood.icon)
                        .font(.title2)
                        .foregroundColor(moodData.mood.color)

                    Text(moodData.mood.name)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.textPrimaryColor)
                }

                // Entry count
                Text(entryCountText)
                    .font(.system(size: 15))
                    .foregroundColor(theme.textPrimaryColor.opacity(0.6))

                // Last captured with cleaner format
                Text("Last captured: \(moodData.lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 13))
                    .foregroundColor(theme.textPrimaryColor.opacity(0.5))
            }

            Spacer()

            // Right side - Simplified orb
            GlassmorphicMoodOrb(
                mood: moodData.mood,
                size: 80,
                entryCount: moodData.entryCount
            )
            .shadow(color: moodData.mood.color.opacity(0.2), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - Mood Stats Section

struct MoodStatsSection: View {
    let moodData: OrganicMoodOrbCluster.MoodOrbData
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        let theme = themeManager.currentTheme

        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                    .foregroundColor(theme.textPrimaryColor.opacity(0.6))
                Text("Statistics")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(theme.textPrimaryColor.opacity(0.9))
            }

            // Stats grid
            HStack(spacing: 16) {
                StatBox(
                    title: "Total Entries",
                    value: "\(moodData.entryCount)",
                    icon: "doc.text.fill",
                    theme: theme
                )

                StatBox(
                    title: "Last Captured",
                    value: moodData.lastUpdated.formatted(.dateTime.month(.abbreviated).day()),
                    icon: "calendar",
                    theme: theme
                )
            }
        }
    }
}

// MARK: - Stat Box

private struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(theme.accentColor)
                Text(title)
                    .font(.caption)
                    .foregroundColor(theme.textSecondaryColor)
            }

            Text(value)
                .font(.title2.bold())
                .foregroundColor(theme.textPrimaryColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surfaceColor)
        )
    }
}

// MARK: - Visual Memories Component

struct VisualMemoriesSection: View {
    let entries: [JournalEntryModel]
    @Environment(\.themeManager) private var themeManager
    @State private var showingGallery = false
    @State private var selectedImageIndex = 0

    private var imageContainers: [ImageContainerData] {
        entries.compactMap { entry -> [ImageContainerData] in
            guard let images = entry.images else { return [] }
            return images.compactMap { image in
                guard let imageData = image.imageData,
                      let uiImage = UIImage(data: imageData) else { return nil }
                return ImageContainerData(
                    id: image.id,
                    uiImage: uiImage,
                    caption: entry.title.isEmpty ? "Memory" : entry.title,
                    date: entry.createdAt
                )
            }
        }.flatMap { $0 }
    }

    var body: some View {
        let theme = themeManager.currentTheme

        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 16))
                    .foregroundColor(theme.textPrimaryColor.opacity(0.6))
                Text("Visual Memories")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(theme.textPrimaryColor.opacity(0.9))

                Spacer()

                if !imageContainers.isEmpty {
                    Text("\(imageContainers.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textPrimaryColor.opacity(0.5))
                }
            }

            if imageContainers.isEmpty {
                EmptyVisualMemoriesView()
            } else {
                // Image grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(imageContainers.prefix(6)) { container in
                        Image(uiImage: container.uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture {
                                if let index = imageContainers.firstIndex(where: { $0.id == container.id }) {
                                    selectedImageIndex = index
                                    showingGallery = true
                                }
                            }
                    }
                }
            }
        }
        .sheet(isPresented: $showingGallery) {
            ImageGalleryView(images: imageContainers, selectedIndex: selectedImageIndex)
        }
    }
}

// MARK: - Image Container Data

struct ImageContainerData: Identifiable {
    let id: UUID
    let uiImage: UIImage
    let caption: String
    let date: Date
}

// MARK: - Empty Visual Memories View

struct EmptyVisualMemoriesView: View {
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        let theme = themeManager.currentTheme

        VStack(spacing: 12) {
            Image(systemName: "photo.stack")
                .font(.system(size: 32))
                .foregroundColor(theme.textPrimaryColor.opacity(0.3))

            Text("No visual memories yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.textPrimaryColor.opacity(0.5))

            Text("Journal entries with images will appear here")
                .font(.system(size: 12))
                .foregroundColor(theme.textPrimaryColor.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.textPrimaryColor.opacity(0.05))
        )
    }
}

// MARK: - Recent Entries Section

struct RecentEntriesSection: View {
    let entries: [JournalEntryModel]
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        let theme = themeManager.currentTheme

        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundColor(theme.textPrimaryColor.opacity(0.6))
                Text("Recent Entries")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(theme.textPrimaryColor.opacity(0.9))
            }

            // Entry list
            ForEach(entries.prefix(5)) { entry in
                RecentEntryRow(entry: entry)
            }
        }
    }
}

// MARK: - Recent Entry Row

struct RecentEntryRow: View {
    let entry: JournalEntryModel
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        let theme = themeManager.currentTheme

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.title.isEmpty ? "Untitled" : entry.title)
                    .font(.subheadline.bold())
                    .foregroundColor(theme.textPrimaryColor)
                    .lineLimit(1)

                Spacer()

                Text(entry.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption)
                    .foregroundColor(theme.textSecondaryColor)
            }

            Text(entry.content)
                .font(.caption)
                .foregroundColor(theme.textSecondaryColor)
                .lineLimit(2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surfaceColor.opacity(0.5))
        )
    }
}

// MARK: - Image Gallery View

struct ImageGalleryView: View {
    let images: [ImageContainerData]
    @State var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager

    var body: some View {
        let theme = themeManager.currentTheme

        ZStack {
            theme.backgroundColor.ignoresSafeArea()

            TabView(selection: $selectedIndex) {
                ForEach(Array(images.enumerated()), id: \.element.id) { index, container in
                    Image(uiImage: container.uiImage)
                        .resizable()
                        .scaledToFit()
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))

            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(theme.textPrimaryColor.opacity(0.7))
                            .background(Circle().fill(theme.overlayColor))
                    }
                    .padding()

                    Spacer()
                }

                Spacer()

                if let caption = images[safe: selectedIndex]?.caption {
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [
                                theme.backgroundColor.opacity(0),
                                theme.backgroundColor.opacity(0.6),
                                theme.backgroundColor.opacity(0.85)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                        .allowsHitTesting(false)

                        Text(caption)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.textPrimaryColor)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .padding(.bottom, 40)
                            .frame(maxWidth: .infinity)
                            .background(theme.backgroundColor.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MoodDetailSheet(
        moodData: OrganicMoodOrbCluster.MoodOrbData(
            id: UUID(),
            mood: .peaceful,
            entryCount: 5,
            lastUpdated: Date(),
            entries: []
        ),
        timeframe: .thisWeek
    )
    .environment(\.themeManager, ThemeManager())
}
