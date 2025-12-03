//
//  ImageTypeBadge.swift
//  InkFiction
//
//  Badge showing image type (Photo, AI, Drawing)
//

import SwiftUI

struct ImageTypeBadge: View {
    let type: ImageType
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.sfSymbolName)
                .font(.system(size: scaledIconSize, weight: .semibold))

            Text(type.displayName)
                .font(.system(size: scaledTextSize, weight: .medium))
        }
        .foregroundColor(badgeTextColor)
        .padding(.horizontal, scaledPadding)
        .padding(.vertical, scaledPadding * 0.5)
        .background(badgeBackgroundColor)
        .clipShape(Capsule())
    }

    private var scaledIconSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 14 : 10
    }

    private var scaledTextSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 13 : 10
    }

    private var scaledPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 8 : 6
    }

    private var badgeTextColor: Color {
        switch type {
        case .aiGenerated:
            return .purple
        case .photo:
            return .blue
        case .drawing:
            return .green
        }
    }

    private var badgeBackgroundColor: Color {
        switch type {
        case .aiGenerated:
            return Color.purple.opacity(0.15)
        case .photo:
            return Color.blue.opacity(0.15)
        case .drawing:
            return Color.green.opacity(0.15)
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        ImageTypeBadge(type: .aiGenerated)
        ImageTypeBadge(type: .photo)
        ImageTypeBadge(type: .drawing)
    }
    .padding()
}
