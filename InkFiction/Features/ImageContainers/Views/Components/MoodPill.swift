//
//  MoodPill.swift
//  InkFiction
//
//  Floating mood indicator pill for collage layouts
//

import SwiftUI

struct MoodPill: View {
    let mood: Mood
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: scaledSpacing) {
            Image(systemName: mood.sfSymbolName)
                .font(.caption)
                .imageScale(imageScale)

            Text(mood.rawValue)
                .font(.caption2)
        }
        .padding(.horizontal, scaledPadding)
        .padding(.vertical, scaledPadding * 0.5)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .foregroundColor(mood.color)
    }

    private var scaledSpacing: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 6 : 4
    }

    private var scaledPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 10 : 8
    }

    private var imageScale: Image.Scale {
        dynamicTypeSize.isAccessibilitySize ? .medium : .small
    }
}

#Preview {
    VStack(spacing: 16) {
        ForEach(Mood.allCases, id: \.self) { mood in
            MoodPill(mood: mood)
        }
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
