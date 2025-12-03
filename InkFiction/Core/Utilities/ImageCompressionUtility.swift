//
//  ImageCompressionUtility.swift
//  InkFiction
//
//  Utility for optimizing images for CloudKit storage
//  Uses HEIC format when available for better compression without quality loss
//

import UIKit
import UniformTypeIdentifiers

/// Image compression settings for different use cases
enum ImageCompressionQuality {
    /// High quality for user-uploaded photos (0.8 HEIC / 0.85 JPEG)
    case high
    /// Medium quality for AI-generated images (0.7 HEIC / 0.75 JPEG)
    case medium
    /// Thumbnail quality for previews (0.5 HEIC / 0.6 JPEG)
    case thumbnail

    var heicQuality: CGFloat {
        switch self {
        case .high: return 0.8
        case .medium: return 0.7
        case .thumbnail: return 0.5
        }
    }

    var jpegQuality: CGFloat {
        switch self {
        case .high: return 0.85
        case .medium: return 0.75
        case .thumbnail: return 0.6
        }
    }
}

/// Target dimensions for resizing images
enum ImageTargetSize {
    /// Full resolution (max 2048px on longest side)
    case full
    /// Large preview (max 1024px)
    case large
    /// Medium preview (max 512px)
    case medium
    /// Thumbnail (max 256px)
    case thumbnail
    /// Custom max dimension
    case custom(maxDimension: CGFloat)

    var maxDimension: CGFloat {
        switch self {
        case .full: return 2048
        case .large: return 1024
        case .medium: return 512
        case .thumbnail: return 256
        case .custom(let maxDimension): return maxDimension
        }
    }
}

/// Utility for compressing and optimizing images for CloudKit storage
enum ImageCompressionUtility {

    // MARK: - Public Methods

    /// Compress image data for CloudKit upload
    /// Uses HEIC format when available (better compression, same quality)
    /// Falls back to JPEG on older devices
    ///
    /// - Parameters:
    ///   - imageData: Original image data
    ///   - quality: Compression quality level
    ///   - targetSize: Target size for resizing
    /// - Returns: Compressed image data, or nil if compression fails
    static func compress(
        imageData: Data,
        quality: ImageCompressionQuality = .high,
        targetSize: ImageTargetSize = .full
    ) -> Data? {
        guard let image = UIImage(data: imageData) else {
            Log.warning("Failed to create UIImage from data for compression", category: .data)
            return nil
        }

        return compress(image: image, quality: quality, targetSize: targetSize)
    }

    /// Compress UIImage for CloudKit upload
    ///
    /// - Parameters:
    ///   - image: Original UIImage
    ///   - quality: Compression quality level
    ///   - targetSize: Target size for resizing
    /// - Returns: Compressed image data, or nil if compression fails
    static func compress(
        image: UIImage,
        quality: ImageCompressionQuality = .high,
        targetSize: ImageTargetSize = .full
    ) -> Data? {
        // Resize image if needed
        let resizedImage = resize(image: image, targetSize: targetSize)

        // Try HEIC first (better compression, same quality)
        if let heicData = compressToHEIC(image: resizedImage, quality: quality.heicQuality) {
            Log.debug("Compressed image to HEIC: \(formatBytes(heicData.count))", category: .data)
            return heicData
        }

        // Fall back to JPEG
        if let jpegData = resizedImage.jpegData(compressionQuality: quality.jpegQuality) {
            Log.debug("Compressed image to JPEG: \(formatBytes(jpegData.count))", category: .data)
            return jpegData
        }

        Log.warning("Failed to compress image", category: .data)
        return nil
    }

    /// Compress image specifically for CloudKit sync (optimized settings)
    /// - Parameters:
    ///   - imageData: Original image data
    ///   - isAIGenerated: Whether the image is AI-generated (can use lower quality)
    /// - Returns: Compressed data optimized for CloudKit
    static func compressForCloudKit(imageData: Data, isAIGenerated: Bool) -> Data? {
        let quality: ImageCompressionQuality = isAIGenerated ? .medium : .high
        return compress(imageData: imageData, quality: quality, targetSize: .full)
    }

    /// Calculate compression ratio
    static func compressionRatio(original: Data, compressed: Data) -> Double {
        guard original.count > 0 else { return 0 }
        return Double(compressed.count) / Double(original.count)
    }

    /// Format bytes into human-readable string
    static func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    // MARK: - Private Methods

    /// Resize image to fit within target dimensions while maintaining aspect ratio
    private static func resize(image: UIImage, targetSize: ImageTargetSize) -> UIImage {
        let maxDimension = targetSize.maxDimension
        let size = image.size

        // Check if resizing is needed
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        let newSize: CGSize

        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        // Resize using UIGraphicsImageRenderer for better quality
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        Log.debug("Resized image from \(Int(size.width))x\(Int(size.height)) to \(Int(newSize.width))x\(Int(newSize.height))", category: .data)

        return resizedImage
    }

    /// Compress image to HEIC format
    private static func compressToHEIC(image: UIImage, quality: CGFloat) -> Data? {
        guard let cgImage = image.cgImage else { return nil }

        let data = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.heic.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality,
            kCGImageDestinationOptimizeColorForSharing: true
        ]

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return data as Data
    }
}

// MARK: - Image Data Statistics

extension ImageCompressionUtility {

    /// Get statistics about image data
    struct ImageStats {
        let originalSize: Int
        let compressedSize: Int
        let compressionRatio: Double
        let format: String
        let dimensions: CGSize?

        var savedBytes: Int {
            originalSize - compressedSize
        }

        var savedPercentage: Double {
            guard originalSize > 0 else { return 0 }
            return Double(savedBytes) / Double(originalSize) * 100
        }
    }

    /// Analyze and compress image, returning statistics
    static func analyzeAndCompress(
        imageData: Data,
        quality: ImageCompressionQuality = .high,
        targetSize: ImageTargetSize = .full
    ) -> (data: Data?, stats: ImageStats) {
        let originalSize = imageData.count
        let originalImage = UIImage(data: imageData)
        let dimensions = originalImage?.size

        guard let compressed = compress(imageData: imageData, quality: quality, targetSize: targetSize) else {
            let stats = ImageStats(
                originalSize: originalSize,
                compressedSize: originalSize,
                compressionRatio: 1.0,
                format: "unknown",
                dimensions: dimensions
            )
            return (nil, stats)
        }

        // Detect format from compressed data
        let format = detectFormat(data: compressed)

        let stats = ImageStats(
            originalSize: originalSize,
            compressedSize: compressed.count,
            compressionRatio: Double(compressed.count) / Double(originalSize),
            format: format,
            dimensions: dimensions
        )

        Log.info("Image compression: \(formatBytes(originalSize)) → \(formatBytes(compressed.count)) (\(String(format: "%.1f", stats.savedPercentage))% saved)", category: .data)

        return (compressed, stats)
    }

    /// Detect image format from data header
    private static func detectFormat(data: Data) -> String {
        guard data.count >= 12 else { return "unknown" }

        let bytes = [UInt8](data.prefix(12))

        // HEIC/HEIF: starts with ftyp followed by heic/mif1/etc
        if bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70 {
            return "HEIC"
        }

        // JPEG: starts with FF D8 FF
        if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
            return "JPEG"
        }

        // PNG: starts with 89 50 4E 47
        if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
            return "PNG"
        }

        return "unknown"
    }
}
