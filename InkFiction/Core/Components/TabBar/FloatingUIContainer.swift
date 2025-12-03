//
//  FloatingUIContainer.swift
//  InkFiction
//
//  Unified container for floating tab bar and FAB
//

import SwiftUI

struct FloatingUIContainer: View {

    // MARK: - Properties

    @Bindable var viewModel: TabBarViewModel
    let theme: Theme
    let metrics: FloatingContainerMetrics
    let onNewEntry: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showFAB: Bool = false
    @State private var fabOpacity: Double = 0

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // When collapsed, center with spacers
            if viewModel.isCollapsed {
                Spacer()
            }

            // Tab bar
            FloatingTabBar(
                viewModel: viewModel,
                theme: theme,
                containerWidth: tabBarWidth,
                collapseProgress: metrics.progress
            )
            .frame(width: tabBarWidth)
            .animation(
                reduceMotion ? .none : .spring(response: 0.32, dampingFraction: 0.82),
                value: viewModel.isCollapsed
            )
            .animation(
                reduceMotion
                    ? .none
                    : .interpolatingSpring(
                        mass: 1.0,
                        stiffness: 80,
                        damping: 15,
                        initialVelocity: 0
                    ),
                value: showFAB
            )

            // FAB when expanded and on Journal tab
            if showFAB && !viewModel.isCollapsed {
                FloatingActionButton(theme: theme, action: onNewEntry)
                    .opacity(fabOpacity)
                    .scaleEffect(fabOpacity)
                    .animation(
                        .easeOut(duration: 0.25).delay(showFAB ? 0.15 : 0),
                        value: fabOpacity
                    )
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            } else if viewModel.isCollapsed {
                Spacer()
            } else {
                EmptyView()
            }
        }
        .padding(.horizontal, horizontalPadding)
        .frame(height: metrics.containerHeight)
        .scaleEffect(metrics.scale, anchor: .bottom)
        .offset(y: metrics.verticalOffset)
        .animation(
            reduceMotion ? .none : .spring(response: 0.38, dampingFraction: 0.82),
            value: metrics.progress
        )
        .onChange(of: viewModel.selectedTab) { _, newTab in
            Task { @MainActor in
                updateFABVisibility(isTimeline: newTab == .timeline, collapsed: viewModel.isCollapsed)
            }
        }
        .onChange(of: viewModel.isCollapsed) { _, isCollapsed in
            Task { @MainActor in
                updateFABVisibility(
                    isTimeline: viewModel.selectedTab == .timeline,
                    collapsed: isCollapsed
                )
            }
        }
        .onAppear {
            updateFABVisibility(
                isTimeline: viewModel.selectedTab == .timeline,
                collapsed: viewModel.isCollapsed,
                animated: false
            )
        }
    }

    // MARK: - Computed Properties

    private var horizontalPadding: CGFloat {
        if horizontalSizeClass == .regular {
            return 200
        } else {
            return 16
        }
    }

    private var tabBarWidth: CGFloat {
        if viewModel.isCollapsed {
            return horizontalSizeClass == .regular ? 180 : 140
        } else {
            return UIScreen.main.bounds.width - (horizontalPadding * 2) - (showFAB ? 68 : 0)
        }
    }

    // MARK: - Private Methods

    private func updateFABVisibility(isTimeline: Bool, collapsed: Bool, animated: Bool = true) {
        let shouldDisplayFAB = isTimeline && !collapsed
        let shouldAnimate = animated && !reduceMotion

        if shouldDisplayFAB {
            if shouldAnimate {
                withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 80, damping: 15)) {
                    showFAB = true
                }
                withAnimation(.easeOut(duration: 0.3).delay(0.12)) {
                    fabOpacity = 1.0
                }
            } else {
                showFAB = true
                fabOpacity = 1.0
            }
        } else {
            if shouldAnimate {
                withAnimation(.easeIn(duration: 0.2)) {
                    fabOpacity = 0.0
                }
                withAnimation(.easeIn(duration: 0.2).delay(0.1)) {
                    showFAB = false
                }
            } else {
                fabOpacity = 0.0
                showFAB = false
            }
        }
    }
}

// MARK: - Floating Container Metrics

struct FloatingContainerMetrics {
    let progress: CGFloat
    let containerHeight: CGFloat
    let verticalOffset: CGFloat
    let scale: CGFloat
    let bottomPadding: CGFloat
    let safeAreaHeight: CGFloat
    let blurHeight: CGFloat
    let blurOpacity: Double

    init(progress: CGFloat) {
        let clamped = FloatingContainerMetrics.clamp(progress)
        self.progress = clamped

        containerHeight = FloatingContainerMetrics.lerp(72, 56, clamped)
        verticalOffset = FloatingContainerMetrics.lerp(8, 24, clamped)
        scale = FloatingContainerMetrics.lerp(1.0, 0.94, clamped)
        bottomPadding = FloatingContainerMetrics.lerp(36, 28, clamped)  // Increased bottom padding

        let baseSafeArea = FloatingContainerMetrics.lerp(26, 10, clamped)
        safeAreaHeight = containerHeight + bottomPadding + baseSafeArea

        blurHeight = FloatingContainerMetrics.lerp(180, 104, clamped)
        blurOpacity = Double(FloatingContainerMetrics.lerp(0.92, 0.55, clamped))
    }

    private static func lerp(_ expanded: CGFloat, _ collapsed: CGFloat, _ progress: CGFloat) -> CGFloat {
        expanded + (collapsed - expanded) * progress
    }

    private static func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, 0), 1)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()

            FloatingUIContainer(
                viewModel: TabBarViewModel(),
                theme: .paper,
                metrics: FloatingContainerMetrics(progress: 0),
                onNewEntry: {
                    print("New entry tapped")
                }
            )
        }
    }
}
