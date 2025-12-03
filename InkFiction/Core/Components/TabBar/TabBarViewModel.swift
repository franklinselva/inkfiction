//
//  TabBarViewModel.swift
//  InkFiction
//
//  View model for managing floating tab bar state
//

import SwiftUI
import Combine
import UIKit

@MainActor
@Observable
final class TabBarViewModel {

    // MARK: - Presentation Change Reason

    enum PresentationChangeReason {
        case scroll
        case tap
        case tabChange
        case tabReselected
        case contentAppeared
        case programmatic
    }

    // MARK: - Published Properties

    var selectedTab: TabDestination = .timeline
    var isCollapsed: Bool = false

    var selectionAnimation: Animation = .interactiveSpring(
        response: 0.35,
        dampingFraction: 0.8,
        blendDuration: 0.25
    )

    // MARK: - Private Properties

    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)

    // MARK: - Initialization

    init() {
        // Always start from Timeline on app launch
        selectedTab = .timeline
    }

    // MARK: - Public Methods

    /// Select a tab destination
    func selectTab(_ destination: TabDestination) {
        guard selectedTab != destination else {
            // Tab reselected - expand if collapsed
            setCollapsedState(false)
            return
        }

        withAnimation(selectionAnimation) {
            selectedTab = destination
        }

        triggerHapticFeedback()

        // Tab changed - expand if needed
        setCollapsedState(false)
    }

    /// Set the collapsed state with animation
    func setCollapsedState(_ collapsed: Bool) {
        guard isCollapsed != collapsed else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            isCollapsed = collapsed
        }
    }

    /// Note that user interacted - expands the tab bar
    func noteUserInteracted() {
        setCollapsedState(false)
    }

    // MARK: - Private Methods

    private func triggerHapticFeedback() {
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
}
