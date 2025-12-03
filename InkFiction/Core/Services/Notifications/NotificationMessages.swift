//
//  NotificationMessages.swift
//  InkFiction
//
//  Time-context-aware notification messages for personalized engagement
//

import Foundation

// MARK: - Notification Message

struct NotificationMessage {
    let title: String
    let body: String

    init(_ title: String, _ body: String) {
        self.title = title
        self.body = body
    }
}

// MARK: - Time of Day

enum TimeOfDay: String, CaseIterable, Codable {
    case morning = "Morning"
    case lunch = "Lunch"
    case evening = "Evening"
    case night = "Night"

    var timeRange: String {
        switch self {
        case .morning: return "6:00 AM - 11:00 AM"
        case .lunch: return "11:00 AM - 2:00 PM"
        case .evening: return "5:00 PM - 9:00 PM"
        case .night: return "9:00 PM - 12:00 AM"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.stars.fill"
        }
    }

    var defaultHour: Int {
        switch self {
        case .morning: return 8
        case .lunch: return 12
        case .evening: return 18
        case .night: return 21
        }
    }

    static func from(hour: Int) -> TimeOfDay {
        switch hour {
        case 6..<11: return .morning
        case 11..<14: return .lunch
        case 17..<21: return .evening
        default: return .night
        }
    }
}

// MARK: - Weekday

enum Weekday: Int, CaseIterable, Codable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

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

    var initial: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }

    var uppercasedShortName: String {
        shortName.uppercased()
    }
}

// MARK: - Notification Message Provider

class NotificationMessageProvider {
    static let shared = NotificationMessageProvider()

    private let lastMessageIndexKey = "lastNotificationMessageIndex"
    private let lastMessageTimeKey = "lastNotificationMessageTime"

    private init() {}

    // MARK: - Morning Messages (6 AM - 11 AM)

    private let morningMessages: [NotificationMessage] = [
        NotificationMessage("Good Morning", "Start your day with a moment of reflection. What are you grateful for?"),
        NotificationMessage("Rise and Reflect", "How are you feeling as this new day begins?"),
        NotificationMessage("Morning Thoughts", "What intentions do you want to set for today?"),
        NotificationMessage("Fresh Start", "A new day, a blank page. What story will you write?"),
        NotificationMessage("Morning Check-In", "Take a breath. What's on your mind this morning?"),
        NotificationMessage("Today's Mindset", "What energy do you want to bring into today?"),
        NotificationMessage("Morning Clarity", "Before the day gets busy, capture your thoughts."),
        NotificationMessage("Dawn Reflection", "The morning is yours. How do you want to use it?"),
        NotificationMessage("New Day, New Entry", "What are you looking forward to today?"),
        NotificationMessage("Morning Moment", "Start with yourself. What do you need today?"),
        NotificationMessage("Sunrise Thoughts", "What dreams or worries are you waking up with?"),
        NotificationMessage("Begin with Reflection", "How can you show up as your best self today?"),
        NotificationMessage("Morning Pause", "Before the world demands your attention, check in with yourself."),
        NotificationMessage("Today Awaits", "What would make today meaningful for you?"),
        NotificationMessage("Peaceful Morning", "In the quiet of morning, what truths emerge?")
    ]

    // MARK: - Lunch Messages (11 AM - 2 PM)

    private let lunchMessages: [NotificationMessage] = [
        NotificationMessage("Midday Check-In", "How's your day unfolding so far?"),
        NotificationMessage("Lunch Break Reflection", "Take a moment to pause. What's been on your mind?"),
        NotificationMessage("Afternoon Thoughts", "Halfway through the day. How are you feeling?"),
        NotificationMessage("Pause and Reflect", "The day's half done. What have you noticed?"),
        NotificationMessage("Midday Moment", "Time for a mental break. What's your energy like?"),
        NotificationMessage("Day's Progress", "How are you moving through today?"),
        NotificationMessage("Quick Check", "What emotions are you carrying right now?"),
        NotificationMessage("Afternoon Pause", "Step away from the busyness. What needs attention?"),
        NotificationMessage("Midpoint Reflection", "What's been surprising about today so far?"),
        NotificationMessage("Lunch Hour Thoughts", "Take a breath. What do you need this afternoon?"),
        NotificationMessage("Day's Journey", "What lessons is today teaching you?"),
        NotificationMessage("Middle Ground", "You're doing great. How can you support yourself?"),
        NotificationMessage("Afternoon Reset", "What would help you feel more balanced?"),
        NotificationMessage("Midday Mindfulness", "What small wins deserve recognition?"),
        NotificationMessage("Lunch Reflection", "What's one thing you want to remember from this morning?")
    ]

    // MARK: - Evening Messages (5 PM - 9 PM)

    private let eveningMessages: [NotificationMessage] = [
        NotificationMessage("Evening Reflection", "As the day winds down, what stands out?"),
        NotificationMessage("Day's End", "What did today teach you about yourself?"),
        NotificationMessage("Twilight Thoughts", "How are you feeling as evening settles in?"),
        NotificationMessage("Evening Pause", "Before the day ends, what needs to be acknowledged?"),
        NotificationMessage("Sunset Reflection", "What moments from today deserve your attention?"),
        NotificationMessage("End of Day", "What are you carrying from today into tonight?"),
        NotificationMessage("Evening Check-In", "How did today measure up to your hopes?"),
        NotificationMessage("Day's Story", "If today were a chapter, what would it be titled?"),
        NotificationMessage("Evening Gratitude", "What are you thankful for from today?"),
        NotificationMessage("Dusk Reflection", "What emotions are present as the day closes?"),
        NotificationMessage("Today's Journey", "What challenged you? What delighted you?"),
        NotificationMessage("Evening Wind-Down", "Let's process the day together. How are you?"),
        NotificationMessage("Day's Closing", "What deserves to be celebrated or released?"),
        NotificationMessage("Twilight Moment", "How can you honor what today brought?"),
        NotificationMessage("Evening Peace", "As darkness falls, what needs your gentle attention?")
    ]

    // MARK: - Night Messages (9 PM - 12 AM)

    private let nightMessages: [NotificationMessage] = [
        NotificationMessage("Night Reflection", "Before sleep, what's weighing on your heart?"),
        NotificationMessage("Day's End Thoughts", "How do you want to close this day?"),
        NotificationMessage("Bedtime Reflection", "What's one thing you learned about yourself today?"),
        NotificationMessage("Night's Quiet", "In the stillness, what thoughts emerge?"),
        NotificationMessage("Evening's Close", "What do you want to let go of before tomorrow?"),
        NotificationMessage("Late Night Thoughts", "What's keeping your mind active tonight?"),
        NotificationMessage("Rest and Reflect", "Before you rest, what needs expression?"),
        NotificationMessage("Night's Peace", "How can you end today with kindness toward yourself?"),
        NotificationMessage("Moonlight Moment", "What dreams or worries are you taking to bed?"),
        NotificationMessage("Day's Farewell", "What deserves acknowledgment before you sleep?"),
        NotificationMessage("Nighttime Check-In", "How are you truly feeling right now?"),
        NotificationMessage("Before Sleep", "What would help you rest easier tonight?"),
        NotificationMessage("Night's Embrace", "What can you forgive yourself for today?"),
        NotificationMessage("Quiet Reflection", "In today's noise, what truth did you find?"),
        NotificationMessage("Tonight's Thoughts", "What do you want to remember from today?")
    ]

    // MARK: - Weekly Reflection Messages

    private let weeklyMessages: [NotificationMessage] = [
        NotificationMessage("Week in Review", "Take a moment to reflect on the week that's passing. What stood out?"),
        NotificationMessage("Weekly Check-In", "How did this week treat you? Let's capture your thoughts."),
        NotificationMessage("Seven Days, Many Stories", "What patterns did you notice this week?"),
        NotificationMessage("Week's Journey", "From Monday to today, what's changed in you?"),
        NotificationMessage("Pause and Reflect", "This week brought experiences worth remembering. What are they?"),
        NotificationMessage("Weekly Wisdom", "What lessons did this week teach you?"),
        NotificationMessage("Looking Back", "If this week were a chapter, what would you title it?"),
        NotificationMessage("Week's Emotions", "What feelings defined your week?"),
        NotificationMessage("Growth This Week", "How have you grown or changed over these past days?"),
        NotificationMessage("Weekly Gratitude", "What moments from this week deserve appreciation?"),
        NotificationMessage("Week's Highlights", "What made this week unique or memorable?"),
        NotificationMessage("Reflecting Forward", "Looking at this week, what do you want to carry into the next?"),
        NotificationMessage("Seven Days of You", "How did you show up for yourself this week?"),
        NotificationMessage("Week's Balance", "What worked well this week? What didn't?"),
        NotificationMessage("Weekly Perspective", "Stepping back, what does this week reveal about your journey?")
    ]

    // MARK: - Monthly Reflection Messages

    private let monthlyMessages: [NotificationMessage] = [
        NotificationMessage("Month in Review", "A new month approaches. What defined this one?"),
        NotificationMessage("Monthly Milestone", "Thirty days of experiences. What stands out most?"),
        NotificationMessage("Month's Journey", "How have you evolved over these past weeks?"),
        NotificationMessage("Looking Back", "What themes emerged in your life this month?"),
        NotificationMessage("Monthly Reflection", "Take a breath and review your month. What surprised you?"),
        NotificationMessage("One Month, Many Moments", "Which memories from this month deserve to be cherished?"),
        NotificationMessage("Month's Growth", "How are you different now than you were 30 days ago?"),
        NotificationMessage("Patterns and Progress", "What patterns did you notice repeating this month?"),
        NotificationMessage("Monthly Check-In", "What accomplishments or challenges marked this month?"),
        NotificationMessage("Month's Lessons", "What did this month teach you about yourself?"),
        NotificationMessage("Gratitude and Growth", "What are you grateful for from this past month?"),
        NotificationMessage("Monthly Perspective", "From this distance, how do you see your month?"),
        NotificationMessage("Thirty Days", "What would you want to remember about this month a year from now?"),
        NotificationMessage("Month's Balance", "What brought you joy? What brought you stress?"),
        NotificationMessage("Forward and Back", "Looking at this month, what do you want for the next?")
    ]

    // MARK: - Message Selection

    func getDailyReminderMessage(for timeOfDay: TimeOfDay) -> NotificationMessage {
        let messages = getMessages(for: timeOfDay)
        return selectRandomMessage(from: messages, for: timeOfDay)
    }

    private func getMessages(for timeOfDay: TimeOfDay) -> [NotificationMessage] {
        switch timeOfDay {
        case .morning: return morningMessages
        case .lunch: return lunchMessages
        case .evening: return eveningMessages
        case .night: return nightMessages
        }
    }

    private func selectRandomMessage(from messages: [NotificationMessage], for timeOfDay: TimeOfDay) -> NotificationMessage {
        let key = "\(lastMessageIndexKey)_\(timeOfDay.rawValue)"
        return selectRandomMessageInternal(from: messages, key: key, context: timeOfDay.rawValue)
    }

    private func selectRandomMessage(from messages: [NotificationMessage], for context: String) -> NotificationMessage {
        let key = "\(lastMessageIndexKey)_\(context)"
        return selectRandomMessageInternal(from: messages, key: key, context: context)
    }

    private func selectRandomMessageInternal(from messages: [NotificationMessage], key: String, context: String) -> NotificationMessage {
        let lastIndex = UserDefaults.standard.integer(forKey: key)
        let lastTime = UserDefaults.standard.double(forKey: lastMessageTimeKey)

        // Check if last message was sent within the last 12 hours
        let timeSinceLastMessage = Date().timeIntervalSince1970 - lastTime
        let shouldAvoidRepeat = timeSinceLastMessage < 12 * 3600

        var availableIndices = Array(0..<messages.count)

        // Remove last used index if we should avoid repetition
        if shouldAvoidRepeat, lastIndex < messages.count {
            availableIndices.removeAll { $0 == lastIndex }
        }

        // If we've removed all indices (shouldn't happen), just use all
        if availableIndices.isEmpty {
            availableIndices = Array(0..<messages.count)
        }

        // Select random index
        let selectedIndex = availableIndices.randomElement() ?? 0

        // Store for next time
        UserDefaults.standard.set(selectedIndex, forKey: key)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastMessageTimeKey)

        Log.info("Selected notification message \(selectedIndex) for \(context)", category: .notifications)

        return messages[selectedIndex]
    }

    // MARK: - Re-engagement Messages

    func getReEngagementMessage(daysSinceLastEntry: Int) -> NotificationMessage {
        let messages: [NotificationMessage] = [
            NotificationMessage("We're Here", "No pressure. Your journal is here whenever you're ready."),
            NotificationMessage("Welcome Back", "It's been \(daysSinceLastEntry) days. How have you been?"),
            NotificationMessage("Gentle Reminder", "Sometimes the best entries come after a break."),
            NotificationMessage("Your Space Awaits", "No judgment, just space for whatever you're feeling."),
            NotificationMessage("Thinking of You", "Your thoughts matter. Want to share what's been happening?"),
            NotificationMessage("No Rush", "Journaling at your own pace is perfectly okay."),
            NotificationMessage("Open Pages", "Your journal misses your voice. What's new?"),
            NotificationMessage("Check-In", "Life gets busy. How are you doing, really?")
        ]

        return messages.randomElement() ?? messages[0]
    }

    // MARK: - Weekly Reflection Message Selection

    func getWeeklyReminderMessage() -> NotificationMessage {
        return selectRandomMessage(from: weeklyMessages, for: "weekly")
    }

    // MARK: - Monthly Reflection Message Selection

    func getMonthlyReminderMessage() -> NotificationMessage {
        return selectRandomMessage(from: monthlyMessages, for: "monthly")
    }

    // MARK: - Helper Methods

    func resetMessageHistory() {
        TimeOfDay.allCases.forEach { timeOfDay in
            let key = "\(lastMessageIndexKey)_\(timeOfDay.rawValue)"
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.removeObject(forKey: lastMessageTimeKey)
        Log.info("Reset notification message history", category: .notifications)
    }
}
