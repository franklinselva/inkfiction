//
//  CountBadge.swift
//  InkFiction
//
//  Badge showing count of additional images
//

import SwiftUI

struct CountBadge: View {
    let count: Int
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Text("+\(count)")
            .font(.system(size: scaledFontSize, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, scaledPadding)
            .padding(.vertical, scaledPadding * 0.5)
            .background(Capsule().fill(.black.opacity(0.6)))
    }

    private var scaledFontSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 14 : 12
    }

    private var scaledPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 10 : 8
    }
}

#Preview {
    HStack(spacing: 16) {
        CountBadge(count: 3)
        CountBadge(count: 10)
        CountBadge(count: 99)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
