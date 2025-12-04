//
//  ExportService.swift
//  InkFiction
//
//  Service for exporting journal data to a folder structure with CSV, images, and metadata
//

import Foundation
import UIKit

// MARK: - Export Service

@MainActor
final class ExportService {

    // MARK: - Singleton

    static let shared = ExportService()

    // MARK: - Properties

    private let journalRepository = JournalRepository.shared
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    // MARK: - Initialization

    private init() {
        Log.info("ExportService initialized", category: .data)
    }

    // MARK: - Public Methods

    /// Export all journal data to a folder
    /// - Parameter onStageChange: Callback for stage updates
    /// - Returns: URL to the export folder
    func exportData(onStageChange: @escaping (ExportStage) -> Void) async throws -> URL {
        Log.info("Starting journal export", category: .data)

        // Stage 1: Gather entries
        onStageChange(.gatheringEntries)
        let entries = try await gatherEntries()

        guard !entries.isEmpty else {
            throw ExportError.noEntries
        }

        // Stage 2: Collect images
        onStageChange(.collectingImages)
        let exportImages = collectImages(from: entries)

        // Stage 3: Create archive
        onStageChange(.creatingArchive)
        let exportURL = try await createExportFolder(entries: entries, images: exportImages)

        // Complete
        onStageChange(.complete(exportURL))
        Log.info("Export completed: \(exportURL.path)", category: .data)

        return exportURL
    }

    /// Get estimated export size
    func getEstimatedSize() async -> (entryCount: Int, imageCount: Int, estimatedBytes: Int64) {
        do {
            let entries = try await journalRepository.fetchEntries(
                filter: JournalFilter(includeArchived: true)
            )

            var totalBytes: Int64 = 0
            var imageCount = 0

            for entry in entries {
                // Estimate 1KB per entry for CSV
                totalBytes += 1024

                if let images = entry.images {
                    for image in images {
                        imageCount += 1
                        if let data = image.imageData {
                            totalBytes += Int64(data.count)
                        }
                    }
                }
            }

            return (entries.count, imageCount, totalBytes)
        } catch {
            Log.error("Failed to estimate export size", error: error, category: .data)
            return (0, 0, 0)
        }
    }

    // MARK: - Private Methods

    private func gatherEntries() async throws -> [JournalEntryModel] {
        let entries = try await journalRepository.fetchEntries(
            filter: JournalFilter(includeArchived: true),
            sort: .dateAscending
        )
        Log.debug("Gathered \(entries.count) entries for export", category: .data)
        return entries
    }

    private func collectImages(from entries: [JournalEntryModel]) -> [ExportImage] {
        var exportImages: [ExportImage] = []

        for (entryIndex, entry) in entries.enumerated() {
            let entryNumber = entryIndex + 1
            guard let images = entry.images else { continue }

            for (imageIndex, image) in images.enumerated() {
                guard let imageData = image.imageData else { continue }

                let imageNumber = imageIndex + 1
                let type: ExportImageType = image.isAIGenerated ? .aiGenerated : .photo
                let filename = generateFilename(
                    entryNumber: entryNumber,
                    imageNumber: imageNumber,
                    type: type
                )

                exportImages.append(ExportImage(
                    entryId: entry.id,
                    entryNumber: entryNumber,
                    imageId: image.id,
                    imageNumber: imageNumber,
                    type: type,
                    imageData: imageData,
                    filename: filename,
                    caption: image.caption
                ))
            }
        }

        Log.debug("Collected \(exportImages.count) images for export", category: .data)
        return exportImages
    }

    private func generateFilename(entryNumber: Int, imageNumber: Int, type: ExportImageType) -> String {
        return String(format: "entry_%03d_image_%02d%@.jpg", entryNumber, imageNumber, type.fileSuffix)
    }

    private func createExportFolder(entries: [JournalEntryModel], images: [ExportImage]) async throws -> URL {
        let fileManager = FileManager.default

        // Create export directory
        let dateString = dateFormatter.string(from: Date())
        let exportName = "inkfiction_export_\(dateString)_\(UUID().uuidString.prefix(8))"

        let exportDir = fileManager.temporaryDirectory.appendingPathComponent(exportName)

        do {
            try fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true)
        } catch {
            throw ExportError.fileWriteFailed("Failed to create export directory: \(error.localizedDescription)")
        }

        // Create images folder
        let imagesDir = exportDir.appendingPathComponent("images")
        do {
            try fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        } catch {
            throw ExportError.fileWriteFailed("Failed to create images directory: \(error.localizedDescription)")
        }

        // Write images
        for image in images {
            let imageURL = imagesDir.appendingPathComponent(image.filename)
            do {
                try image.imageData.write(to: imageURL)
            } catch {
                Log.warning("Failed to write image \(image.filename): \(error.localizedDescription)", category: .data)
            }
        }

        // Create CSV
        let csvData = createCSV(from: entries, images: images)
        let csvURL = exportDir.appendingPathComponent("journal_entries.csv")
        do {
            try csvData.write(to: csvURL, atomically: true, encoding: .utf8)
        } catch {
            throw ExportError.csvGenerationFailed
        }

        // Create metadata.json
        let metadata = createMetadata(entries: entries, images: images)
        let metadataURL = exportDir.appendingPathComponent("metadata.json")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let metadataData = try encoder.encode(metadata)
            try metadataData.write(to: metadataURL)
        } catch {
            throw ExportError.fileWriteFailed("Failed to write metadata: \(error.localizedDescription)")
        }

        // Create README.txt
        let readme = createReadme(entryCount: entries.count, imageCount: images.count)
        let readmeURL = exportDir.appendingPathComponent("README.txt")
        do {
            try readme.write(to: readmeURL, atomically: true, encoding: .utf8)
        } catch {
            throw ExportError.fileWriteFailed("Failed to write README: \(error.localizedDescription)")
        }

        return exportDir
    }

    // MARK: - CSV Generation

    private func createCSV(from entries: [JournalEntryModel], images: [ExportImage]) -> String {
        var lines: [String] = []

        // Header
        let headers = [
            "entry_number",
            "id",
            "title",
            "content",
            "mood",
            "tags",
            "created_at",
            "updated_at",
            "is_archived",
            "is_pinned",
            "image_filenames",
            "image_count",
            "has_ai_images"
        ]
        lines.append(headers.joined(separator: ","))

        // Rows
        for (index, entry) in entries.enumerated() {
            let entryNumber = index + 1
            let entryImages = images.filter { $0.entryId == entry.id }
            let imageFilenames = entryImages.map { $0.filename }.joined(separator: ";")
            let hasAIImages = entryImages.contains { $0.type == .aiGenerated }

            let row = [
                String(entryNumber),
                escapeCsvField(entry.id.uuidString),
                escapeCsvField(entry.title),
                escapeCsvField(entry.content),
                escapeCsvField(entry.mood.rawValue),
                escapeCsvField(entry.tags.joined(separator: ";")),
                escapeCsvField(iso8601Formatter.string(from: entry.createdAt)),
                escapeCsvField(iso8601Formatter.string(from: entry.updatedAt)),
                entry.isArchived ? "true" : "false",
                entry.isPinned ? "true" : "false",
                escapeCsvField(imageFilenames),
                String(entryImages.count),
                hasAIImages ? "true" : "false"
            ]
            lines.append(row.joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    private func escapeCsvField(_ field: String) -> String {
        // If field contains comma, quote, or newline, wrap in quotes and escape internal quotes
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    // MARK: - Metadata Generation

    private func createMetadata(entries: [JournalEntryModel], images: [ExportImage]) -> ExportMetadata {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        let entryMetadataList: [ExportMetadata.EntryMetadata] = entries.enumerated().map { index, entry in
            let entryNumber = index + 1
            let entryImages = images.filter { $0.entryId == entry.id }

            let imageMetadataList: [ExportMetadata.ImageMetadata] = entryImages.map { image in
                ExportMetadata.ImageMetadata(
                    filename: image.filename,
                    type: image.type.rawValue,
                    originalId: image.imageId.uuidString,
                    caption: image.caption
                )
            }

            return ExportMetadata.EntryMetadata(
                entryNumber: entryNumber,
                id: entry.id.uuidString,
                title: entry.title,
                createdAt: entry.createdAt,
                images: imageMetadataList
            )
        }

        return ExportMetadata(
            exportDate: Date(),
            appVersion: appVersion,
            exportFormat: "InkFiction Export v2.0",
            totalEntries: entries.count,
            totalImages: images.count,
            entries: entryMetadataList
        )
    }

    // MARK: - README Generation

    private func createReadme(entryCount: Int, imageCount: Int) -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let dateString = dateFormatter.string(from: Date())

        return """
        InkFiction Journal Export
        =========================

        Export Date: \(dateString)
        App Version: \(appVersion)
        Total Entries: \(entryCount)
        Total Images: \(imageCount)

        Contents
        --------

        1. journal_entries.csv
           - All journal entries in CSV format
           - Columns: entry_number, id, title, content, mood, tags, created_at,
             updated_at, is_archived, is_pinned, image_filenames, image_count, has_ai_images
           - Tags and image filenames are semicolon-separated within their fields
           - Dates are in ISO 8601 format

        2. images/
           - All images from journal entries
           - Naming convention: entry_XXX_image_YY[_ai].jpg
             - XXX = entry number (001, 002, etc.)
             - YY = image number within entry (01, 02, etc.)
             - _ai suffix indicates AI-generated image

        3. metadata.json
           - Machine-readable export metadata
           - Contains entry-to-image mappings
           - Includes original UUIDs for data integrity

        4. README.txt
           - This file

        Image Types
        -----------
        - Regular images: User-attached photos
        - AI-generated images: Images created by AI within the app (marked with _ai suffix)

        Data Privacy
        ------------
        This export contains your personal journal data. Please handle it securely
        and do not share it with untrusted parties.

        For support, contact: support@inkfiction.app

        """
    }
}
