//
//  ExportModels.swift
//  InkFiction
//
//  Data models for journal export functionality
//

import Foundation

// MARK: - Export Stage

enum ExportStage: Equatable {
    case idle
    case gatheringEntries
    case collectingImages
    case creatingArchive
    case complete(URL)
    case failed(String)

    var progress: Double {
        switch self {
        case .idle: return 0.0
        case .gatheringEntries: return 0.25
        case .collectingImages: return 0.50
        case .creatingArchive: return 0.75
        case .complete: return 1.0
        case .failed: return 0.0
        }
    }

    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .gatheringEntries: return "Gathering entries..."
        case .collectingImages: return "Collecting images..."
        case .creatingArchive: return "Creating archive..."
        case .complete: return "Export complete"
        case .failed(let message): return "Failed: \(message)"
        }
    }

    var isComplete: Bool {
        if case .complete = self { return true }
        return false
    }

    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    var isInProgress: Bool {
        switch self {
        case .gatheringEntries, .collectingImages, .creatingArchive:
            return true
        default:
            return false
        }
    }
}

// MARK: - Export Image Type

enum ExportImageType: String, Codable {
    case aiGenerated = "ai_generated"
    case photo = "photo"

    var fileSuffix: String {
        switch self {
        case .aiGenerated: return "_ai"
        case .photo: return ""
        }
    }
}

// MARK: - Export Image

struct ExportImage {
    let entryId: UUID
    let entryNumber: Int
    let imageId: UUID
    let imageNumber: Int
    let type: ExportImageType
    let imageData: Data
    let filename: String
    let caption: String?
}

// MARK: - Export Metadata

struct ExportMetadata: Codable {
    let exportDate: Date
    let appVersion: String
    let exportFormat: String
    let totalEntries: Int
    let totalImages: Int
    let entries: [EntryMetadata]

    struct EntryMetadata: Codable {
        let entryNumber: Int
        let id: String
        let title: String
        let createdAt: Date
        let images: [ImageMetadata]
    }

    struct ImageMetadata: Codable {
        let filename: String
        let type: String
        let originalId: String
        let caption: String?
    }
}

// MARK: - Journal Export

struct JournalExport {
    let entries: [JournalEntryModel]
    let images: [ExportImage]
    let metadata: ExportMetadata
}

// MARK: - Export Error

enum ExportError: LocalizedError {
    case noEntries
    case csvGenerationFailed
    case imageCollectionFailed
    case archiveCreationFailed
    case fileWriteFailed(String)
    case repositoryNotAvailable

    var errorDescription: String? {
        switch self {
        case .noEntries:
            return "No journal entries to export."
        case .csvGenerationFailed:
            return "Failed to generate CSV file."
        case .imageCollectionFailed:
            return "Failed to collect images for export."
        case .archiveCreationFailed:
            return "Failed to create export archive."
        case .fileWriteFailed(let detail):
            return "Failed to write file: \(detail)"
        case .repositoryNotAvailable:
            return "Journal repository is not available."
        }
    }
}
