//
//  PersonaUpdatePolicy.swift
//  InkFiction
//
//  Tier-based policies for persona creation and update management
//

import Foundation

// MARK: - PersonaUpdatePolicy

struct PersonaUpdatePolicy {

    // MARK: - Update Record

    struct UpdateRecord: Codable, Identifiable {
        let id: UUID
        let personaId: UUID
        let updateType: UpdateType
        let newStyle: AvatarStyle
        let tier: SubscriptionTier
        let timestamp: Date

        enum UpdateType: String, Codable {
            case creation
            case styleAddition
            case styleRegeneration
            case fullUpdate
        }

        init(
            id: UUID = UUID(),
            personaId: UUID,
            updateType: UpdateType,
            newStyle: AvatarStyle,
            tier: SubscriptionTier,
            timestamp: Date = Date()
        ) {
            self.id = id
            self.personaId = personaId
            self.updateType = updateType
            self.newStyle = newStyle
            self.tier = tier
            self.timestamp = timestamp
        }
    }

    // MARK: - Tier Policy

    struct TierPolicy {
        let tier: SubscriptionTier
        let maxPersonaStyles: Int
        let updateFrequencyDays: Int
        let maxGenerationsPerPeriod: Int
        let canCreateNew: Bool
        let canUpdate: Bool
        let canRegenerate: Bool

        /// Check if user can add more styles
        func canAddMoreStyles(currentCount: Int) -> Bool {
            canCreateNew && currentCount < maxPersonaStyles
        }

        /// Check if user can update (based on cooldown)
        func canUpdatePersona(lastUpdateDate: Date?) -> (canUpdate: Bool, daysRemaining: Int?) {
            guard canUpdate else { return (false, nil) }
            guard let lastUpdate = lastUpdateDate else { return (true, nil) }

            let daysSinceUpdate = Calendar.current.dateComponents([.day], from: lastUpdate, to: Date()).day ?? 0
            let daysRemaining = updateFrequencyDays - daysSinceUpdate

            if daysRemaining <= 0 {
                return (true, nil)
            } else {
                return (false, daysRemaining)
            }
        }

        /// Check remaining generations for period
        func remainingGenerations(usedThisPeriod: Int) -> Int {
            max(0, maxGenerationsPerPeriod - usedThisPeriod)
        }
    }

    // MARK: - Get Policy for Tier

    static func policy(for tier: SubscriptionTier) -> TierPolicy {
        switch tier {
        case .free:
            return TierPolicy(
                tier: .free,
                maxPersonaStyles: 0,
                updateFrequencyDays: 0,
                maxGenerationsPerPeriod: 0,
                canCreateNew: false,
                canUpdate: false,
                canRegenerate: false
            )
        case .enhanced:
            return TierPolicy(
                tier: .enhanced,
                maxPersonaStyles: 3,
                updateFrequencyDays: 30,  // Monthly updates
                maxGenerationsPerPeriod: 5,
                canCreateNew: true,
                canUpdate: true,
                canRegenerate: true
            )
        case .premium:
            return TierPolicy(
                tier: .premium,
                maxPersonaStyles: 5,
                updateFrequencyDays: 14,  // Bi-weekly updates
                maxGenerationsPerPeriod: 20,
                canCreateNew: true,
                canUpdate: true,
                canRegenerate: true
            )
        }
    }

    // MARK: - Convenience Methods

    static func canCreatePersona(tier: SubscriptionTier) -> Bool {
        policy(for: tier).canCreateNew
    }

    static func maxStyles(for tier: SubscriptionTier) -> Int {
        policy(for: tier).maxPersonaStyles
    }

    static func updateCooldown(for tier: SubscriptionTier) -> Int {
        policy(for: tier).updateFrequencyDays
    }

    static func formatCooldownRemaining(days: Int) -> String {
        if days == 0 {
            return "Available now"
        } else if days == 1 {
            return "1 day remaining"
        } else {
            return "\(days) days remaining"
        }
    }

    static func formatUpdateFrequency(for tier: SubscriptionTier) -> String {
        let days = policy(for: tier).updateFrequencyDays
        switch days {
        case 0: return "Not available"
        case 1...7: return "Weekly"
        case 8...14: return "Bi-weekly"
        case 15...30: return "Monthly"
        default: return "Every \(days) days"
        }
    }
}

// MARK: - PersonaCreationState

enum PersonaCreationState {
    case canCreate
    case canUpdate
    case updateLocked(daysRemaining: Int, frequencyDays: Int)
    case limitReached
    case upgrade

    var canProceed: Bool {
        switch self {
        case .canCreate, .canUpdate:
            return true
        case .updateLocked, .limitReached, .upgrade:
            return false
        }
    }

    var message: String {
        switch self {
        case .canCreate:
            return "Create your persona"
        case .canUpdate:
            return "Update available"
        case .updateLocked(let days, let frequency):
            return "Next update in \(days) day\(days == 1 ? "" : "s") (every \(frequency) days)"
        case .limitReached:
            return "Style limit reached"
        case .upgrade:
            return "Upgrade to unlock personas"
        }
    }

    var icon: String {
        switch self {
        case .canCreate: return "plus.circle.fill"
        case .canUpdate: return "arrow.clockwise.circle.fill"
        case .updateLocked: return "lock.circle.fill"
        case .limitReached: return "exclamationmark.circle.fill"
        case .upgrade: return "crown.fill"
        }
    }
}
