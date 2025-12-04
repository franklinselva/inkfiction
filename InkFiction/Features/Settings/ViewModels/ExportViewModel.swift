//
//  ExportViewModel.swift
//  InkFiction
//
//  ViewModel for managing export state and progress
//

import Foundation
import UIKit

@MainActor
@Observable
final class ExportViewModel {

    // MARK: - Published State

    private(set) var stage: ExportStage = .idle
    private(set) var progress: Double = 0.0
    private(set) var entriesCount: Int = 0
    private(set) var imagesCount: Int = 0
    private(set) var estimatedSize: String = "Calculating..."
    private(set) var exportURL: URL?
    private(set) var errorMessage: String?

    var isPreparingShare: Bool = false
    var isPreparingSave: Bool = false

    // MARK: - Dependencies

    private let exportService = ExportService.shared

    // MARK: - Computed Properties

    var canExport: Bool {
        entriesCount > 0 && !stage.isInProgress
    }

    var isExporting: Bool {
        stage.isInProgress
    }

    var isComplete: Bool {
        stage.isComplete
    }

    var isFailed: Bool {
        stage.isFailed
    }

    var exportFolderName: String? {
        exportURL?.lastPathComponent
    }

    var formattedExportSize: String {
        guard let url = exportURL else { return "Unknown" }
        return calculateFolderSize(at: url)
    }

    // MARK: - Initialization

    init() {
        Task {
            await loadEstimatedSize()
        }
    }

    // MARK: - Public Methods

    func loadEstimatedSize() async {
        let (entries, images, bytes) = await exportService.getEstimatedSize()
        entriesCount = entries
        imagesCount = images
        estimatedSize = formatBytes(bytes)
    }

    func startExport() async {
        guard canExport else { return }

        Log.info("Starting export from ViewModel", category: .data)
        errorMessage = nil
        exportURL = nil

        do {
            let url = try await exportService.exportData { [weak self] newStage in
                Task { @MainActor in
                    self?.stage = newStage
                    self?.progress = newStage.progress
                }
            }
            exportURL = url
            Log.info("Export completed successfully", category: .data)
        } catch {
            let message = (error as? ExportError)?.errorDescription ?? error.localizedDescription
            stage = .failed(message)
            errorMessage = message
            Log.error("Export failed", error: error, category: .data)
        }
    }

    func cancelExport() {
        // Currently exports are not cancellable, but we can reset state
        stage = .idle
        progress = 0.0
        errorMessage = nil
    }

    func reset() {
        stage = .idle
        progress = 0.0
        errorMessage = nil
        exportURL = nil

        Task {
            await loadEstimatedSize()
        }
    }

    func prepareForShare() {
        isPreparingShare = true
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isPreparingShare = false
        }
    }

    func prepareForSave() {
        isPreparingSave = true
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isPreparingSave = false
        }
    }

    // MARK: - Private Methods

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func calculateFolderSize(at url: URL) -> String {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0

        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            while let fileURL = enumerator.nextObject() as? URL {
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                    if let size = attributes[.size] as? Int64 {
                        totalSize += size
                    }
                } catch {
                    continue
                }
            }
        }

        return formatBytes(totalSize)
    }
}
