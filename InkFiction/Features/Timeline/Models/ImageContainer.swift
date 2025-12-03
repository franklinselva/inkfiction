//
//  ImageContainer.swift
//  InkFiction
//
//  Image container model for Timeline visual memories
//

import SwiftUI
import UIKit

struct ImageContainer: Identifiable {
    let id: UUID
    let uiImage: UIImage
    let caption: String?
    let date: Date?

    init(
        id: UUID = UUID(),
        uiImage: UIImage,
        caption: String? = nil,
        date: Date? = nil
    ) {
        self.id = id
        self.uiImage = uiImage
        self.caption = caption
        self.date = date
    }

    var image: Image {
        return Image(uiImage: uiImage)
    }

    func extractUIImage() -> UIImage {
        return uiImage
    }

    // Sample data for previews
    static let sampleContainers: [ImageContainer] = [
        ImageContainer(
            uiImage: UIImage(systemName: "photo.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) ?? UIImage(),
            caption: "A peaceful moment",
            date: Date()
        ),
        ImageContainer(
            uiImage: UIImage(systemName: "photo.fill")?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal) ?? UIImage(),
            caption: "Nature walk",
            date: Date().addingTimeInterval(-86400)
        ),
        ImageContainer(
            uiImage: UIImage(systemName: "photo.fill")?.withTintColor(.systemOrange, renderingMode: .alwaysOriginal) ?? UIImage(),
            caption: "Sunset view",
            date: Date().addingTimeInterval(-172800)
        )
    ]
}
