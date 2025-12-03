//
//  FloatingTabBarItem.swift
//  InkFiction
//
//  Individual tab bar item component with expanded/collapsed display modes
//

import SwiftUI

struct FloatingTabBarItem: View {

    // MARK: - Display Mode

    enum DisplayMode {
        case expanded
        case collapsed
    }

    // MARK: - Properties

    let item: TabBarItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let theme: Theme
    var displayMode: DisplayMode = .expanded
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            content
                .frame(
                    minWidth: displayMode == .expanded ? 60 : 0,
                    minHeight: displayMode == .expanded ? 50 : 44
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(scaleEffectValue)
        .animation(
            reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.6),
            value: isPressed
        )
        .animation(
            reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.7),
            value: isSelected
        )
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { isPressing in
                guard displayMode == .expanded else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = isPressing
                }
            },
            perform: {}
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.accessibilityLabel)
        .accessibilityHint(item.accessibilityHint)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    }

    // MARK: - Content Views

    @ViewBuilder
    private var content: some View {
        switch displayMode {
        case .expanded:
            icon
                .scaleEffect(isPressed ? 0.85 : (isSelected ? 1.15 : 1.0))
        case .collapsed:
            icon
                .scaleEffect(1.0)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
        }
    }

    private var icon: some View {
        ZStack {
            // Glow effect for selected state
            if isSelected {
                Image(systemName: symbolName)
                    .font(.system(size: displayMode == .collapsed ? 20 : 24, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: theme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 8)
                    .opacity(0.6)
            }

            // Main icon
            Image(systemName: symbolName)
                .font(.system(size: displayMode == .collapsed ? 20 : 24, weight: isSelected ? .semibold : .regular))
                .symbolRenderingMode(isSelected ? .palette : .hierarchical)
                .foregroundStyle(iconForegroundStyle)
        }
        .matchedGeometryEffect(id: "icon-\(item.destination.rawValue)", in: namespace)
    }

    // MARK: - Computed Properties

    private var symbolName: String {
        if isSelected, let selectedImage = item.selectedImage {
            return selectedImage
        }
        return item.systemImage
    }

    private var iconForegroundStyle: LinearGradient {
        if isSelected {
            return LinearGradient(
                colors: theme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            let opacity = theme.isLight ? 0.4 : 0.35
            return LinearGradient(
                colors: [theme.textSecondaryColor.opacity(opacity)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var scaleEffectValue: CGFloat {
        guard displayMode == .expanded else { return 1.0 }
        return isPressed ? 0.95 : 1.0
    }
}
