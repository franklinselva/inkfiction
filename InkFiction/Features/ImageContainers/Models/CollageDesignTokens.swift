//
//  CollageDesignTokens.swift
//  InkFiction
//
//  Design tokens for contextual collage layouts
//

import Foundation
import SwiftUI

// MARK: - Collage Design Tokens

struct CollageDesignTokens {

    // MARK: - Spacing

    static let imageSpacing: CGFloat = 4
    static let cardPadding: CGFloat = 12
    static let badgePadding: CGFloat = 8

    // MARK: - Heights
    // Unified height for consistent visual rhythm and smooth transitions

    static let moodShowcaseHeight: CGFloat = 200
    static let heroFeaturedHeight: CGFloat = 200
    static let duoFlowHeightSame: CGFloat = 200
    static let duoFlowHeightMixed: CGFloat = 200
    static let storyTriptychHeight: CGFloat = 200
    static let quadHeight: CGFloat = 200
    static let mosaicHeight: CGFloat = 200
    static let galleryHeight: CGFloat = 200
    static let aiMixedHeight: CGFloat = 200
    static let placeholderHeight: CGFloat = 200

    // MARK: - Aspect Ratios

    static let portraitThreshold: CGFloat = 0.9
    static let landscapeThreshold: CGFloat = 1.1
    static let maxTallRatio: CGFloat = 2.0
    static let maxWideRatio: CGFloat = 2.0

    // MARK: - Mood Display

    static let moodIconSizeLarge: CGFloat = 48
    static let moodIconSizeMedium: CGFloat = 32
    static let moodIconSizeSmall: CGFloat = 20

    // MARK: - Corner Radii

    static let cardCornerRadius: CGFloat = 12
    static let imageCornerRadius: CGFloat = 8
    static let thumbnailCornerRadius: CGFloat = 6
    static let badgeCornerRadius: CGFloat = 12

    // MARK: - Shadows

    static let cardShadowRadius: CGFloat = 4
    static let cardShadowOpacity: CGFloat = 0.1

    // MARK: - Animation

    static let shimmerDuration: Double = 1.5
    static let pulseIconDuration: Double = 0.8
    static let layoutTransitionDuration: Double = 0.3
}

// MARK: - Image Orientation Helpers

extension CGFloat {
    var orientation: ImageOrientation {
        if self < CollageDesignTokens.portraitThreshold {
            return .portrait
        } else if self > CollageDesignTokens.landscapeThreshold {
            return .landscape
        } else {
            return .square
        }
    }

    var clamped: CGFloat {
        let max = CollageDesignTokens.maxWideRatio
        let min = 1.0 / CollageDesignTokens.maxTallRatio
        return Swift.max(min, Swift.min(max, self))
    }
}

enum ImageOrientation {
    case portrait
    case landscape
    case square
}

// MARK: - Image Type

enum ImageType: String, CaseIterable {
    case aiGenerated
    case photo
    case drawing

    var sfSymbolName: String {
        switch self {
        case .aiGenerated: return "sparkles"
        case .photo: return "camera.fill"
        case .drawing: return "pencil.tip"
        }
    }

    var displayName: String {
        switch self {
        case .aiGenerated: return "AI"
        case .photo: return "Photo"
        case .drawing: return "Drawing"
        }
    }
}
