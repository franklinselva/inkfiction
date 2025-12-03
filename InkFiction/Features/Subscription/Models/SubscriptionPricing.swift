//
//  SubscriptionPricing.swift
//  InkFiction
//
//  Pricing model for subscription tiers with monthly and yearly options
//

import Foundation

// MARK: - Subscription Pricing

struct SubscriptionPricing {

    // MARK: - Billing Period

    enum BillingPeriod: String, CaseIterable {
        case monthly = "Monthly"
        case yearly = "Yearly"

        var displayName: String {
            rawValue
        }

        var periodSuffix: String {
            switch self {
            case .monthly: "/month"
            case .yearly: "/year"
            }
        }

        var savingsPercentage: Double {
            switch self {
            case .monthly: 0
            case .yearly: 0.20  // 20% discount
            }
        }

        var billingInterval: String {
            switch self {
            case .monthly: "month"
            case .yearly: "year"
            }
        }
    }

    // MARK: - Pricing

    static func price(for tier: SubscriptionTier, period: BillingPeriod) -> Double {
        switch tier {
        case .free:
            return 0
        case .enhanced:
            switch period {
            case .monthly: return 4.99
            case .yearly: return 47.99  // $4.99 * 12 * 0.8 (20% off)
            }
        case .premium:
            switch period {
            case .monthly: return 12.99
            case .yearly: return 124.99  // $12.99 * 12 * 0.8 (20% off)
            }
        }
    }

    static func formattedPrice(for tier: SubscriptionTier, period: BillingPeriod) -> String {
        let price = self.price(for: tier, period: period)
        if price == 0 {
            return "Free"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2

        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }

    static func yearlySavings(for tier: SubscriptionTier) -> Double {
        let monthlyTotal = price(for: tier, period: .monthly) * 12
        let yearlyPrice = price(for: tier, period: .yearly)
        return monthlyTotal - yearlyPrice
    }

    static func formattedSavings(for tier: SubscriptionTier) -> String {
        let savings = yearlySavings(for: tier)

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2

        return formatter.string(from: NSNumber(value: savings)) ?? "$\(savings)"
    }

    static func monthlyEquivalent(for tier: SubscriptionTier) -> Double {
        return price(for: tier, period: .yearly) / 12
    }

    static func formattedMonthlyEquivalent(for tier: SubscriptionTier) -> String {
        let monthly = monthlyEquivalent(for: tier)

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2

        return formatter.string(from: NSNumber(value: monthly)) ?? "$\(monthly)"
    }

    // MARK: - Product IDs

    static func productID(for tier: SubscriptionTier, period: BillingPeriod) -> String {
        switch (tier, period) {
        case (.enhanced, .monthly): return "enhanced_monthly"
        case (.enhanced, .yearly): return "enhanced_yearly"
        case (.premium, .monthly): return "premium_monthly"
        case (.premium, .yearly): return "premium_yearly"
        case (.free, _): return ""
        }
    }

    static func tier(from productID: String) -> SubscriptionTier? {
        if productID.hasPrefix("enhanced") {
            return .enhanced
        } else if productID.hasPrefix("premium") {
            return .premium
        }
        return nil
    }

    static func billingPeriod(from productID: String) -> BillingPeriod {
        if productID.hasSuffix("yearly") {
            return .yearly
        } else if productID.hasSuffix("monthly") {
            return .monthly
        }
        return .monthly
    }

    static var allProductIDs: [String] {
        [
            "enhanced_monthly",
            "enhanced_yearly",
            "premium_monthly",
            "premium_yearly",
        ]
    }
}
