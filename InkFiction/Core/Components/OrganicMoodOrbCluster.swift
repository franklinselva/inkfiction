//
//  OrganicMoodOrbCluster.swift
//  InkFiction
//
//  Organic clustering layout for glassmorphic mood orbs with physics simulation
//

import SwiftUI

// MARK: - Organic Mood Orb Cluster

/// An organic clustering layout for glassmorphic mood orbs that simulates natural physics
/// with force-directed positioning, collision detection, and gravitational attraction to center
struct OrganicMoodOrbCluster: View {
    let moodData: [MoodOrbData]
    var timeframe: TimeFrame = .thisMonth

    @State private var orbNodes: [OrbNode] = []
    @State private var hasInitialized = false
    @State private var selectedMoodData: MoodOrbData?
    @State private var orbVisibilities: [UUID: Double] = [:]
    @State private var orbScales: [UUID: CGFloat] = [:]
    @State private var isAnimating = false
    @State private var shouldCancelAnimations = false
    @State private var reinitTask: Task<Void, Never>?

    // MARK: - Data Structures

    struct MoodOrbData: Identifiable, Equatable {
        let id: UUID
        let mood: GlassmorphicMoodOrb.MoodType
        let entryCount: Int
        let lastUpdated: Date
        let entries: [JournalEntryModel]

        static func == (lhs: MoodOrbData, rhs: MoodOrbData) -> Bool {
            lhs.id == rhs.id &&
            lhs.entryCount == rhs.entryCount &&
            lhs.lastUpdated == rhs.lastUpdated &&
            lhs.entries.count == rhs.entries.count
        }
    }

    /// Internal node representation for physics simulation
    private struct OrbNode {
        var position: CGPoint
        var velocity: CGPoint
        var radius: CGFloat
        var data: MoodOrbData
        var isSettled: Bool = false

        init(data: MoodOrbData, position: CGPoint) {
            self.data = data
            self.position = position
            self.velocity = CGPoint.zero
            self.radius = 0
        }

        var size: CGFloat { radius * 2 }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(orbNodes.enumerated()), id: \.offset) { index, node in
                    OrganicMicroMovingOrb(
                        mood: node.data.mood,
                        size: node.size,
                        entryCount: node.data.entryCount,
                        index: index,
                        isSettled: node.isSettled,
                        onTap: {
                            selectedMoodData = node.data
                        }
                    )
                    .position(node.position)
                    .opacity(opacity(for: node.data))
                    .scaleEffect(scale(for: node.data))
                    .zIndex(Double(node.size))
                }
            }
            .clipped()
            .allowsHitTesting(!isAnimating)
            .onAppear {
                initializeOrganicLayout(in: geometry.size)
            }
            .onDisappear {
                cleanupAnimationState()
                reinitTask?.cancel()
                reinitTask = nil
            }
            .onChange(of: moodData) { _, newData in
                if !newData.isEmpty {
                    scheduleReinitializeLayout(in: geometry.size)
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                scheduleReinitializeLayout(in: newSize)
            }
        }
        .sheet(item: $selectedMoodData) { moodData in
            MoodDetailSheet(
                moodData: moodData,
                timeframe: timeframe
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
            .presentationBackground(.ultraThinMaterial)
        }
    }

    // MARK: - Physics Simulation

    /// Initialize bubble chart layout with proper packing algorithm
    private func initializeOrganicLayout(in size: CGSize) {
        guard !hasInitialized else { return }
        guard !moodData.isEmpty else { return }

        shouldCancelAnimations = false
        isAnimating = true

        let centerYOffset = size.height * 0.06
        let center = CGPoint(x: size.width / 2, y: size.height / 2 - centerYOffset)
        let containerRadius = min(size.width * 0.46, size.height * 0.5)

        let preparedNodes = prepareNodes(center: center, containerRadius: containerRadius)
        let resolvedNodes = runForceDirectedLayout(
            nodes: preparedNodes,
            center: center,
            containerRadius: containerRadius
        )

        orbNodes = resolvedNodes

        // Set initial states
        let initialVisibilities: [UUID: Double] = resolvedNodes.reduce(into: [:]) { result, node in
            result[node.data.id] = 0.0
        }
        let initialScales: [UUID: CGFloat] = resolvedNodes.reduce(into: [:]) { result, node in
            result[node.data.id] = 0.3
        }

        orbVisibilities = initialVisibilities
        orbScales = initialScales

        // Staggered reveal animation
        for (index, node) in resolvedNodes.enumerated() {
            let distanceFromCenter = sqrt(pow(node.position.x - center.x, 2) + pow(node.position.y - center.y, 2))
            let normalizedDistance = distanceFromCenter / containerRadius
            let delay = Double(normalizedDistance) * 0.3

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard !shouldCancelAnimations else { return }

                withAnimation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0.2)) {
                    orbVisibilities[node.data.id] = 1.0
                    orbScales[node.data.id] = 1.0
                }

                if index == resolvedNodes.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        isAnimating = false
                    }
                }
            }
        }

        hasInitialized = true
    }

    /// Schedules layout reinitialization with debouncing to prevent simultaneous physics simulations
    private func scheduleReinitializeLayout(in size: CGSize) {
        // Cancel any pending reinit task
        reinitTask?.cancel()

        // Schedule new reinit with 200ms debounce
        reinitTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

            guard !Task.isCancelled else { return }

            await MainActor.run {
                reinitializeLayout(in: size)
            }
        }
    }

    private func reinitializeLayout(in size: CGSize) {
        shouldCancelAnimations = true
        hasInitialized = false
        initializeOrganicLayout(in: size)
    }

    private func cleanupAnimationState() {
        shouldCancelAnimations = true
        isAnimating = false
        orbVisibilities.removeAll()
        orbScales.removeAll()
        hasInitialized = false
    }

    // MARK: - Utility Functions

    private func opacity(for data: MoodOrbData) -> Double {
        orbVisibilities[data.id] ?? 1.0
    }

    private func scale(for data: MoodOrbData) -> CGFloat {
        orbScales[data.id] ?? 1.0
    }

    // MARK: - Bubble Chart Functions

    private func clampPosition(_ position: CGPoint, radius: CGFloat, center: CGPoint, containerRadius: CGFloat) -> CGPoint {
        let toCenter = CGPoint(x: position.x - center.x, y: position.y - center.y)
        let distanceFromCenter = max(0.0001, sqrt(toCenter.x * toCenter.x + toCenter.y * toCenter.y))

        if distanceFromCenter + radius <= containerRadius {
            return position
        }

        let allowedDistance = containerRadius - radius
        let scale = allowedDistance / distanceFromCenter
        return CGPoint(
            x: center.x + toCenter.x * scale,
            y: center.y + toCenter.y * scale
        )
    }

    private func prepareNodes(center: CGPoint, containerRadius: CGFloat) -> [OrbNode] {
        let fillRatio: CGFloat = 0.75
        let minimumRadius = max(22, containerRadius * 0.065)

        let totalValue = max(CGFloat(moodData.reduce(0) { $0 + max($1.entryCount, 1) }), CGFloat(moodData.count))
        let scale = containerRadius * sqrt(fillRatio / totalValue) * 0.9

        let sortedData = moodData.sorted { $0.entryCount > $1.entryCount }

        var nodes: [OrbNode] = []
        let goldenAngle: CGFloat = .pi * (3 - sqrt(5))

        for (index, data) in sortedData.enumerated() {
            let value = data.entryCount == 0 ? 0.5 : max(CGFloat(data.entryCount), 1)
            let radius = max(value.squareRoot() * scale, minimumRadius)

            let distance: CGFloat
            let angle: CGFloat

            if index == 0 {
                distance = 0
                angle = 0
            } else {
                let normalizedIndex = CGFloat(index)
                distance = min(containerRadius * 0.4, sqrt(normalizedIndex) * radius * 1.8)
                angle = goldenAngle * normalizedIndex
            }

            let position = CGPoint(
                x: center.x + cos(angle) * distance,
                y: center.y + sin(angle) * distance
            )

            var node = OrbNode(data: data, position: position)
            node.radius = radius
            node.velocity = CGPoint.zero
            nodes.append(node)
        }

        return nodes
    }

    private func runForceDirectedLayout(nodes initialNodes: [OrbNode], center: CGPoint, containerRadius: CGFloat) -> [OrbNode] {
        var nodes = initialNodes
        let padding: CGFloat = 6
        let repulsionStrength: CGFloat = 0.018
        let centerStrength: CGFloat = 0.02
        let boundaryStrength: CGFloat = 0.08
        let damping: CGFloat = 0.87
        let timeStep: CGFloat = 16
        let maxIterations = 520
        let settleThreshold: CGFloat = 0.08

        guard nodes.count > 1 else {
            if var first = nodes.first {
                first.position = center
                first.isSettled = true
                return [first]
            }
            return nodes
        }

        for _ in 0..<maxIterations {
            var maxVelocity: CGFloat = 0

            for i in nodes.indices {
                var force = CGPoint.zero

                // Attraction to center
                let toCenter = CGPoint(
                    x: center.x - nodes[i].position.x,
                    y: center.y - nodes[i].position.y
                )
                let massScale = max(min(nodes[i].radius / max(containerRadius * 0.4, 1), 1.15), 0.45)
                force.x += toCenter.x * centerStrength * massScale
                force.y += toCenter.y * centerStrength * massScale

                // Repulsion between overlapping nodes
                for j in nodes.indices where j != i {
                    let dx = nodes[i].position.x - nodes[j].position.x
                    let dy = nodes[i].position.y - nodes[j].position.y
                    var distanceSquared = dx * dx + dy * dy
                    distanceSquared = max(distanceSquared, 0.0001)
                    let distance = sqrt(distanceSquared)
                    let requiredDistance = nodes[i].radius + nodes[j].radius + padding

                    if distance < requiredDistance {
                        let overlap = requiredDistance - distance
                        let normalizedX = dx / distance
                        let normalizedY = dy / distance
                        let strength = repulsionStrength * overlap * overlap
                        force.x += normalizedX * strength
                        force.y += normalizedY * strength
                    }
                }

                // Boundary push
                let fromCenter = CGPoint(
                    x: nodes[i].position.x - center.x,
                    y: nodes[i].position.y - center.y
                )
                let distanceFromCenter = max(0.0001, sqrt(fromCenter.x * fromCenter.x + fromCenter.y * fromCenter.y))
                let allowedDistance = containerRadius - nodes[i].radius - padding

                if distanceFromCenter > allowedDistance {
                    let overflow = distanceFromCenter - allowedDistance
                    let normalizedX = fromCenter.x / distanceFromCenter
                    let normalizedY = fromCenter.y / distanceFromCenter
                    force.x -= normalizedX * overflow * boundaryStrength
                    force.y -= normalizedY * overflow * boundaryStrength
                }

                nodes[i].velocity.x = (nodes[i].velocity.x + force.x * timeStep) * damping
                nodes[i].velocity.y = (nodes[i].velocity.y + force.y * timeStep) * damping
                maxVelocity = max(maxVelocity, sqrt(nodes[i].velocity.x * nodes[i].velocity.x + nodes[i].velocity.y * nodes[i].velocity.y))
            }

            for idx in nodes.indices {
                nodes[idx].position.x += nodes[idx].velocity.x
                nodes[idx].position.y += nodes[idx].velocity.y
                nodes[idx].position = clampPosition(
                    nodes[idx].position,
                    radius: nodes[idx].radius,
                    center: center,
                    containerRadius: containerRadius - padding
                )
            }

            if maxVelocity < settleThreshold {
                break
            }
        }

        resolveResidualOverlaps(&nodes, center: center, containerRadius: containerRadius, padding: padding)

        let sorted = nodes.sorted { lhs, rhs in
            if abs(lhs.position.y - rhs.position.y) > 1 {
                return lhs.position.y > rhs.position.y
            }
            return lhs.radius < rhs.radius
        }

        return sorted.enumerated().map { _, node in
            var mutableNode = node
            mutableNode.isSettled = true
            return mutableNode
        }
    }

    private func resolveResidualOverlaps(
        _ nodes: inout [OrbNode],
        center: CGPoint,
        containerRadius: CGFloat,
        padding: CGFloat
    ) {
        guard nodes.count > 1 else { return }

        let iterations = 10

        for _ in 0..<iterations {
            var adjusted = false

            for i in 0..<nodes.count {
                for j in (i + 1)..<nodes.count {
                    var dx = nodes[j].position.x - nodes[i].position.x
                    var dy = nodes[j].position.y - nodes[i].position.y
                    var distance = sqrt(dx * dx + dy * dy)
                    let minDistance = nodes[i].radius + nodes[j].radius + padding

                    if distance < 0.0001 {
                        let jitterAngle = CGFloat(i + j) * (.pi * 0.61803398875)
                        dx = cos(jitterAngle) * 0.001
                        dy = sin(jitterAngle) * 0.001
                        distance = 0.001
                    }

                    guard distance < minDistance else { continue }

                    adjusted = true
                    let overlap = minDistance - distance
                    let shift = overlap * 0.55
                    let nx = dx / distance
                    let ny = dy / distance

                    nodes[i].position.x -= nx * shift
                    nodes[i].position.y -= ny * shift
                    nodes[j].position.x += nx * shift
                    nodes[j].position.y += ny * shift

                    nodes[i].position = clampPosition(
                        nodes[i].position,
                        radius: nodes[i].radius,
                        center: center,
                        containerRadius: containerRadius - padding
                    )
                    nodes[j].position = clampPosition(
                        nodes[j].position,
                        radius: nodes[j].radius,
                        center: center,
                        containerRadius: containerRadius - padding
                    )
                }
            }

            if !adjusted { break }
        }
    }
}

// MARK: - Organic Micro Moving Orb

/// Enhanced orb component with organic micro-movements and settlement behavior
struct OrganicMicroMovingOrb: View {
    let mood: GlassmorphicMoodOrb.MoodType
    let size: CGFloat
    let entryCount: Int
    let index: Int
    let isSettled: Bool
    var onTap: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Dynamic shadow that responds to settlement
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(isSettled ? 0.4 : 0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.2,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size * 1.3, height: size * 0.4)
                .offset(y: size * 0.5)
                .blur(radius: isSettled ? 15 : 10)

            GlassmorphicMoodOrb(mood: mood, size: size, entryCount: entryCount, onTap: onTap)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color.black, Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        OrganicMoodOrbCluster(
            moodData: [
                .init(id: UUID(), mood: .peaceful, entryCount: 4, lastUpdated: Date(), entries: []),
                .init(id: UUID(), mood: .excited, entryCount: 3, lastUpdated: Date().addingTimeInterval(-3600), entries: []),
                .init(id: UUID(), mood: .reflective, entryCount: 2, lastUpdated: Date().addingTimeInterval(-7200), entries: [])
            ]
        )
        .padding()
    }
    .environment(\.themeManager, ThemeManager())
}
