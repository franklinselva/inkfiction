//
//  TagChip.swift
//  InkFiction
//
//  Removable tag chip component and flow layout for tags
//

import SwiftUI

// MARK: - Tag Chip

struct TagChip: View {
    let tag: String
    let onRemove: (() -> Void)?

    @Environment(\.themeManager) private var themeManager

    init(tag: String, onRemove: (() -> Void)? = nil) {
        self.tag = tag
        self.onRemove = onRemove
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Tag content
            Text("#\(tag)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeManager.currentTheme.accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(themeManager.currentTheme.accentColor.opacity(0.15))
                )
                .overlay(
                    Capsule()
                        .stroke(themeManager.currentTheme.accentColor.opacity(0.3), lineWidth: 1)
                )

            // X button overlay (only if onRemove is provided)
            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        .background(
                            Circle()
                                .fill(themeManager.currentTheme.backgroundColor)
                                .frame(width: 16, height: 16)
                        )
                }
                .offset(x: 6, y: -6)
            }
        }
        .padding(.top, onRemove != nil ? 6 : 0)
        .padding(.trailing, onRemove != nil ? 6 : 0)
    }
}

// MARK: - Flow Layout

struct TagFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.frames[index].minX,
                    y: bounds.minY + result.frames[index].minY
                ),
                proposal: ProposedViewSize(result.frames[index].size)
            )
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxX: CGFloat = 0

            for subview in subviews {
                let viewSize = subview.sizeThatFits(.unspecified)

                if currentX + viewSize.width > maxWidth, currentX > 0 {
                    currentY += lineHeight + spacing
                    currentX = 0
                    lineHeight = 0
                }

                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: viewSize))
                currentX += viewSize.width + spacing
                lineHeight = max(lineHeight, viewSize.height)
                maxX = max(maxX, currentX - spacing)
            }

            size = CGSize(width: maxX, height: currentY + lineHeight)
        }
    }
}

// MARK: - Tags Section View

struct TagsSectionView: View {
    @Binding var tags: [String]
    @State private var newTagText = ""
    @State private var showAddTagAlert = false

    @Environment(\.themeManager) private var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Tags")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Spacer()

                Button(action: {
                    showAddTagAlert = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }

            if tags.isEmpty {
                Text("No tags yet")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
            } else {
                TagFlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(tag: tag) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                tags.removeAll { $0 == tag }
                            }
                        }
                    }
                }
            }
        }
        .alert("Add Tag", isPresented: $showAddTagAlert) {
            TextField("Enter tag", text: $newTagText)
            Button("Cancel", role: .cancel) {
                newTagText = ""
            }
            Button("Add") {
                addTag()
            }
        } message: {
            Text("Add a tag to categorize your entry")
        }
    }

    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else {
            newTagText = ""
            return
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            tags.append(trimmed)
        }
        newTagText = ""
    }
}
