//
//  FloatingTabBar.swift
//  InkFiction
//
//  Custom floating tab bar with glass morphism effect
//

import SwiftUI
import UIKit

struct FloatingTabBar: View {

    // MARK: - Properties

    @Bindable var viewModel: TabBarViewModel
    let theme: Theme

    @Namespace private var tabBarNamespace
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let items = TabDestination.allItems

    // Track container width for smooth animations
    var containerWidth: CGFloat = 0
    var collapseProgress: CGFloat = 0

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .center) {
            glassBackground(width: containerWidth)

            if viewModel.isCollapsed {
                collapsedContent
                    .padding(.horizontal, collapsedHorizontalPadding)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                expandedContent(totalWidth: containerWidth)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .frame(width: containerWidth, height: barHeight)
        .contentShape(Capsule())
        .onTapGesture {
            if viewModel.isCollapsed {
                viewModel.noteUserInteracted()
            }
        }
        .gesture(expandDragGesture)
        .animation(
            reduceMotion ? .none : .spring(response: 0.32, dampingFraction: 0.82),
            value: viewModel.isCollapsed
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tab bar")
    }

    // MARK: - Computed Properties

    private var barHeight: CGFloat {
        viewModel.isCollapsed ? collapsedHeight : tabBarHeight
    }

    private var tabBarHeight: CGFloat {
        verticalSizeClass == .compact ? 60 : 72
    }

    private var collapsedHeight: CGFloat { 56 }

    private var collapsedWidth: CGFloat {
        horizontalSizeClass == .regular ? 180 : 140
    }

    private var collapsedHorizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 18 : 16
    }

    private func itemWidth(for totalWidth: CGFloat) -> CGFloat {
        let padding: CGFloat = 24 // 12 * 2
        let availableWidth = totalWidth - padding
        return availableWidth / CGFloat(items.count)
    }

    // MARK: - Glass Background

    private func glassBackground(width: CGFloat) -> some View {
        let opacityExpanded: Double = 0.9
        let opacityCollapsed: Double = 0.82
        let strokeOpacityExpanded: Double = 0.4
        let strokeOpacityCollapsed: Double = 0.6
        let shadowRadiusExpanded: CGFloat = 15
        let shadowRadiusCollapsed: CGFloat = 8

        let lerpFactor = Double(collapseProgress)
        let backgroundOpacity = opacityExpanded + (opacityCollapsed - opacityExpanded) * lerpFactor
        let strokeOpacity = strokeOpacityExpanded + (strokeOpacityCollapsed - strokeOpacityExpanded) * lerpFactor
        let shadowRadius = shadowRadiusExpanded + (shadowRadiusCollapsed - shadowRadiusExpanded) * CGFloat(lerpFactor)

        let isLightTheme = theme.isLight
        let baseShadowOpacity = isLightTheme ? 0.15 : 0.4
        let shadowOpacityExpanded = baseShadowOpacity
        let shadowOpacityCollapsed = baseShadowOpacity * 0.8
        let shadowOpacity = shadowOpacityExpanded + (shadowOpacityCollapsed - shadowOpacityExpanded) * lerpFactor

        return tabBarBackground
            .frame(width: width, height: barHeight)
            .clipShape(Capsule())
            // Layer 1: Soft ambient shadow
            .shadow(
                color: Color.black.opacity(shadowOpacity * 0.3),
                radius: shadowRadius * 2,
                x: 0,
                y: 12
            )
            // Layer 2: Main shadow with gradient effect
            .shadow(
                color: isLightTheme ?
                    Color.black.opacity(shadowOpacity) :
                    theme.gradientColors.first?.opacity(shadowOpacity * 0.5) ?? Color.black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: 6
            )
            // Layer 3: Sharp close shadow for definition
            .shadow(
                color: Color.black.opacity(shadowOpacity * 0.5),
                radius: shadowRadius * 0.3,
                x: 0,
                y: 2
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                theme.strokeColor.opacity(strokeOpacity),
                                theme.surfaceColor.opacity(strokeOpacity / 2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: isLightTheme ? 1.5 : 1
                    )
            )
            .opacity(backgroundOpacity)
            .matchedGeometryEffect(id: "tabBarBackground", in: tabBarNamespace)
    }

    @ViewBuilder
    private var tabBarBackground: some View {
        ZStack {
            // Clean background
            theme.backgroundColor

            // Subtle material effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(theme.isLight ? 0.4 : 0.25)

            // Enhanced gradient overlay for depth
            LinearGradient(
                colors: [
                    theme.isLight ?
                        Color.white.opacity(0.8) :
                        theme.surfaceColor.opacity(0.6),
                    theme.isLight ?
                        Color.white.opacity(0.2) :
                        Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )

            // Inner glow for light themes
            if theme.isLight {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.6),
                        Color.clear,
                        Color.black.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .compositingGroup()
    }

    // MARK: - Gestures

    private var expandDragGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .onEnded { value in
                guard viewModel.isCollapsed else { return }
                if value.translation.height < -6 {
                    viewModel.noteUserInteracted()
                }
            }
    }

    // MARK: - Content Views

    private func expandedContent(totalWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { _, item in
                FloatingTabBarItem(
                    item: item,
                    isSelected: viewModel.selectedTab == item.destination,
                    namespace: tabBarNamespace,
                    theme: theme,
                    displayMode: .expanded,
                    onTap: {
                        viewModel.selectTab(item.destination)
                        viewModel.noteUserInteracted()
                    }
                )
                .frame(width: itemWidth(for: totalWidth))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, viewModel.isCollapsed ? 8 : 12)
    }

    @ViewBuilder
    private var collapsedContent: some View {
        if let activeItem = items.first(where: { $0.destination == viewModel.selectedTab }) {
            FloatingTabBarItem(
                item: activeItem,
                isSelected: true,
                namespace: tabBarNamespace,
                theme: theme,
                displayMode: .collapsed,
                onTap: {
                    viewModel.noteUserInteracted()
                }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(activeItem.accessibilityLabel)
            .accessibilityHint("Double tap to expand tab bar")
        }
    }
}
