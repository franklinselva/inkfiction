//
//  DayGroupedEntry.swift
//  InkFiction
//
//  Model for grouping journal entries by day with image containers
//

import SwiftUI
import UIKit

struct DayGroupedEntry {
    let date: Date
    let entries: [JournalEntryModel]

    // Store loaded images from entries
    private var loadedImages: [UUID: UIImage]

    // Cached stable values (calculated once during init)
    let imageContainers: [ImageContainer]
    let dominantMood: Mood
    let moodDistribution: [(mood: Mood, count: Int)]

    // Initialize with pre-loaded images
    init(date: Date, entries: [JournalEntryModel], loadedImages: [UUID: UIImage] = [:]) {
        self.date = date
        self.entries = entries
        self.loadedImages = loadedImages

        // Get image containers from loaded images with stable ordering
        var containers: [(container: ImageContainer, index: Int)] = []
        var currentIndex = 0

        for entry in entries {
            // Get images from entry
            if let images = entry.images {
                for image in images {
                    if let imageData = image.imageData,
                       let uiImage = UIImage(data: imageData) {
                        containers.append((
                            container: ImageContainer(
                                id: image.id,
                                uiImage: uiImage,
                                caption: entry.title.isEmpty ? nil : entry.title,
                                date: entry.createdAt
                            ),
                            index: currentIndex
                        ))
                        currentIndex += 1
                    }
                }
            }

            // Also check loaded images from external sources
            for (imageId, uiImage) in loadedImages {
                // Only add if not already added from entry.images
                if !containers.contains(where: { $0.container.id == imageId }) {
                    containers.append((
                        container: ImageContainer(
                            id: imageId,
                            uiImage: uiImage,
                            caption: entry.title.isEmpty ? nil : entry.title,
                            date: entry.createdAt
                        ),
                        index: currentIndex
                    ))
                    currentIndex += 1
                }
            }
        }

        // Sort containers by date (newest first), then by original index for stable ordering
        self.imageContainers = containers.sorted {
            guard let date1 = $0.container.date, let date2 = $1.container.date else {
                return $0.container.date != nil
            }
            if date1 != date2 {
                return date1 > date2
            }
            return $0.index < $1.index
        }.map { $0.container }

        // Calculate dominant mood with stable tiebreaker
        let moodCounts = entries.reduce(into: [:]) { counts, entry in
            counts[entry.mood, default: 0] += 1
        }

        // If there's a tie, use the most recent entry's mood as tiebreaker
        if let maxCount = moodCounts.values.max() {
            let tiedMoods = moodCounts.filter { $0.value == maxCount }.map { $0.key }

            if tiedMoods.count == 1 {
                self.dominantMood = tiedMoods[0]
            } else {
                // Multiple moods tied - use most recent entry's mood
                let sortedEntries = entries.sorted { $0.createdAt > $1.createdAt }
                self.dominantMood = sortedEntries.first?.mood ?? .neutral
            }
        } else {
            self.dominantMood = .neutral
        }

        // Calculate mood distribution with stable sorting
        self.moodDistribution = moodCounts.map { (mood: $0.key, count: $0.value) }
            .sorted {
                // Primary sort: count (descending)
                if $0.count != $1.count {
                    return $0.count > $1.count
                }
                // Secondary sort: mood raw value (alphabetical) for stability
                return $0.mood.rawValue < $1.mood.rawValue
            }
    }
}
