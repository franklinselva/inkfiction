//
//  FrequencyData.swift
//  InkFiction
//
//  Frequency and statistics data models for Timeline feature
//

import Foundation

// MARK: - Frequency Data Models

struct FrequencyData {
    let totalEntries: Int
    let currentStreak: Int
    let longestStreak: Int
    let weeklyAverage: Double
    let monthlyStats: [MonthStats]
    let dailyPattern: [DayOfWeek: Int]
    let timeOfDayStats: [Hour: Int]
    let wordCountStats: WordCountStats
    let moodDistribution: [String: Int]
    let tagsFrequency: [String: Int]

    static let empty = FrequencyData(
        totalEntries: 0,
        currentStreak: 0,
        longestStreak: 0,
        weeklyAverage: 0.0,
        monthlyStats: [],
        dailyPattern: [:],
        timeOfDayStats: [:],
        wordCountStats: WordCountStats.empty,
        moodDistribution: [:],
        tagsFrequency: [:]
    )
}

struct MonthStats: Identifiable {
    let id = UUID()
    let month: Date
    let entryCount: Int
    let averageWordsPerEntry: Double
    let dominantMood: String
    let streakDays: Int
    let totalWords: Int

    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }

    var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: month)
    }
}

struct WordCountStats {
    let totalWords: Int
    let averageWordsPerEntry: Double
    let longestEntry: Int
    let shortestEntry: Int
    let recentTrend: WordCountTrend

    static let empty = WordCountStats(
        totalWords: 0,
        averageWordsPerEntry: 0.0,
        longestEntry: 0,
        shortestEntry: 0,
        recentTrend: .stable
    )
}

enum WordCountTrend {
    case increasing
    case decreasing
    case stable

    var description: String {
        switch self {
        case .increasing: return "Increasing"
        case .decreasing: return "Decreasing"
        case .stable: return "Stable"
        }
    }

    var systemImage: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
}

// MARK: - Time-based Models

enum DayOfWeek: Int, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    static func from(date: Date) -> DayOfWeek {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return DayOfWeek(rawValue: weekday) ?? .sunday
    }
}

enum Hour: Int, CaseIterable {
    case midnight = 0
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    case eleven = 11
    case noon = 12
    case thirteen = 13
    case fourteen = 14
    case fifteen = 15
    case sixteen = 16
    case seventeen = 17
    case eighteen = 18
    case nineteen = 19
    case twenty = 20
    case twentyOne = 21
    case twentyTwo = 22
    case twentyThree = 23

    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date =
            Calendar.current.date(bySettingHour: rawValue, minute: 0, second: 0, of: Date())
            ?? Date()
        return formatter.string(from: date)
    }

    var timeCategory: TimeCategory {
        switch rawValue {
        case 6..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }

    static func from(date: Date) -> Hour {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        return Hour(rawValue: hour) ?? .midnight
    }
}

enum TimeCategory: String, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case night = "Night"

    var systemImage: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.fill"
        }
    }
}

// MARK: - Goal Tracking Models

struct JournalingGoal {
    let id = UUID()
    let type: GoalType
    let target: Int
    let period: GoalPeriod
    let createdAt: Date
    var isActive: Bool

    static let daily = JournalingGoal(
        type: .entries,
        target: 1,
        period: .daily,
        createdAt: Date(),
        isActive: true
    )

    static let weekly = JournalingGoal(
        type: .entries,
        target: 5,
        period: .weekly,
        createdAt: Date(),
        isActive: true
    )
}

enum GoalType {
    case entries
    case words
    case streak

    var unit: String {
        switch self {
        case .entries: return "entries"
        case .words: return "words"
        case .streak: return "days"
        }
    }
}

enum GoalPeriod {
    case daily
    case weekly
    case monthly

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

// MARK: - Achievement Models

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let systemImage: String
    let unlockedAt: Date?
    let requirement: AchievementRequirement

    var isUnlocked: Bool {
        unlockedAt != nil
    }
}

enum AchievementRequirement {
    case firstEntry
    case streak(days: Int)
    case totalEntries(count: Int)
    case totalWords(count: Int)
    case monthlyGoal
    case perfectWeek
    case nightOwl(entries: Int)
    case earlyBird(entries: Int)

    var description: String {
        switch self {
        case .firstEntry:
            return "Write your first journal entry"
        case .streak(let days):
            return "Write for \(days) consecutive days"
        case .totalEntries(let count):
            return "Write \(count) total entries"
        case .totalWords(let count):
            return "Write \(count) total words"
        case .monthlyGoal:
            return "Complete a monthly writing goal"
        case .perfectWeek:
            return "Write every day for a week"
        case .nightOwl(let entries):
            return "Write \(entries) entries after 10 PM"
        case .earlyBird(let entries):
            return "Write \(entries) entries before 8 AM"
        }
    }
}

// MARK: - Insights Data

struct InsightsData {
    let entriesThisYear: Int
    let daysJournaled: Int
    let currentStreak: Int

    static let empty = InsightsData(
        entriesThisYear: 0,
        daysJournaled: 0,
        currentStreak: 0
    )
}
