//
//  TabBarConfiguration.swift
//  InkFiction
//
//  Tab bar configuration with destinations and items
//

import SwiftUI

// MARK: - Tab Bar Item

struct TabBarItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let systemImage: String
    let selectedImage: String?
    let destination: TabDestination
    let accessibilityLabel: String
    let accessibilityHint: String

    init(
        title: String,
        systemImage: String,
        selectedImage: String? = nil,
        destination: TabDestination
    ) {
        self.title = title
        self.systemImage = systemImage
        self.selectedImage = selectedImage
        self.destination = destination
        self.accessibilityLabel = "\(title) tab"
        self.accessibilityHint = "Double tap to switch to \(title)"
    }
}

// MARK: - Tab Destination

enum TabDestination: String, CaseIterable {
    case timeline = "Timeline"
    case reflect = "Reflect"
    case journal = "Journal"
    case settings = "Settings"

    var defaultItem: TabBarItem {
        switch self {
        case .timeline:
            return TabBarItem(
                title: "Timeline",
                systemImage: "timeline.selection",
                selectedImage: "timeline.selection",
                destination: self
            )
        case .reflect:
            return TabBarItem(
                title: "Reflect",
                systemImage: "sparkles",
                selectedImage: "sparkles",
                destination: self
            )
        case .journal:
            return TabBarItem(
                title: "Journal",
                systemImage: "book.closed",
                selectedImage: "book.closed.fill",
                destination: self
            )
        case .settings:
            return TabBarItem(
                title: "Settings",
                systemImage: "gearshape",
                selectedImage: "gearshape.fill",
                destination: self
            )
        }
    }

    static var allItems: [TabBarItem] {
        Self.allCases.map { $0.defaultItem }
    }
}
