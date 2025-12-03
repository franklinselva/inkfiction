//
//  NotificationService.swift
//  InkFiction
//
//  Core notification management service with anti-stacking strategy
//

import Combine
import Foundation
import UIKit
import UserNotifications

// MARK: - Notification Service

@MainActor
@Observable
final class NotificationService: NSObject {
    static let shared = NotificationService()

    let center = UNUserNotificationCenter.current()

    // MARK: - Notification Categories

    enum Category: String, CaseIterable {
        case dailyReminder = "DAILY_REMINDER"
        case streakMotivation = "STREAK_MOTIVATION"
        case moodReflection = "MOOD_REFLECTION"
        case achievement = "ACHIEVEMENT"
        case reEngagement = "RE_ENGAGEMENT"
        case weeklyReflection = "WEEKLY_REFLECTION"
        case monthlyReflection = "MONTHLY_REFLECTION"

        var identifier: String { rawValue }

        var threadIdentifier: String {
            switch self {
            case .dailyReminder, .reEngagement:
                return "DAILY_PROMPTS"
            case .streakMotivation, .achievement:
                return "ACHIEVEMENTS"
            case .moodReflection, .weeklyReflection, .monthlyReflection:
                return "REFLECTIONS"
            }
        }
    }

    // MARK: - Published State

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var isEnabled: Bool = false

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private override init() {
        super.init()
        setupNotificationCategories()
        center.delegate = self

        // Monitor app activation to refresh permission status
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.updateAuthorizationStatus()
                }
            }
            .store(in: &cancellables)

        // Initial status check
        Task {
            await updateAuthorizationStatus()
        }
    }

    // MARK: - Permission Management

    func requestPermission() async -> Bool {
        do {
            Log.info("Requesting notification permission with options: [.alert, .sound, .badge]", category: .notifications)

            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])

            Log.info("Notification permission request completed. Granted: \(granted)", category: .notifications)

            await updateAuthorizationStatus()

            if granted {
                Log.info("Notification permission granted successfully", category: .notifications)

                // Register for remote notifications after successful authorization
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                    Log.info("Registered for remote notifications", category: .notifications)
                }
            } else {
                Log.warning("Notification permission denied by user", category: .notifications)
            }

            return granted
        } catch {
            Log.error("Failed to request notification permission", error: error, category: .notifications)
            await updateAuthorizationStatus()
            return false
        }
    }

    func updateAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isEnabled = settings.authorizationStatus == .authorized
        Log.info("Authorization status updated: \(String(describing: settings.authorizationStatus))", category: .notifications)
    }

    /// Runtime permission check helper
    private func checkNotificationPermission() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Notification Categories Setup

    private func setupNotificationCategories() {
        let categories = Category.allCases.map { category in
            UNNotificationCategory(
                identifier: category.identifier,
                actions: [],
                intentIdentifiers: [],
                options: []
            )
        }

        center.setNotificationCategories(Set(categories))
    }

    // MARK: - Scheduling Methods

    func scheduleDailyReminder(at time: Date, timeOfDay: TimeOfDay? = nil) async {
        // Runtime permission check
        let status = await checkNotificationPermission()
        guard status == .authorized else {
            Log.warning("Cannot schedule daily reminder - permission not granted (status: \(status))", category: .notifications)
            return
        }

        await cancelNotifications(in: .dailyReminder)

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)

        // Determine time of day from the scheduled time if not provided
        let contextTimeOfDay = timeOfDay ?? TimeOfDay.from(hour: hour)

        // Get contextual message based on time of day
        let message = NotificationMessageProvider.shared.getDailyReminderMessage(for: contextTimeOfDay)

        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.categoryIdentifier = Category.dailyReminder.identifier
        content.threadIdentifier = Category.dailyReminder.threadIdentifier
        content.sound = .default

        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            Log.info("Scheduled daily reminder for \(time) (\(contextTimeOfDay.rawValue)): \"\(message.title)\"", category: .notifications)
        } catch {
            Log.error("Failed to schedule daily reminder", error: error, category: .notifications)
        }
    }

    func scheduleStreakMotivation(type: StreakNotificationType, streakCount: Int) async {
        await cancelNotifications(in: .streakMotivation)

        let content = UNMutableNotificationContent()
        content.categoryIdentifier = Category.streakMotivation.identifier
        content.threadIdentifier = Category.streakMotivation.threadIdentifier
        content.sound = .default

        switch type {
        case .milestone:
            content.title = "Streak Milestone"
            content.body = "Amazing! You've journaled for \(streakCount) days in a row. Keep it up!"
        case .risk:
            content.title = "Don't Break Your Streak"
            content.body = "You have a \(streakCount)-day streak going. A quick entry today keeps it alive!"
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_\(type.rawValue)_\(streakCount)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            Log.info("Scheduled streak notification: \(type) for \(streakCount) days", category: .notifications)
        } catch {
            Log.error("Failed to schedule streak notification", error: error, category: .notifications)
        }
    }

    func scheduleAchievement(title: String, description: String) async {
        await cancelNotifications(in: .achievement)

        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked"
        content.body = "\(title): \(description)"
        content.categoryIdentifier = Category.achievement.identifier
        content.threadIdentifier = Category.achievement.threadIdentifier
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "achievement_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            Log.info("Scheduled achievement notification: \(title)", category: .notifications)
        } catch {
            Log.error("Failed to schedule achievement notification", error: error, category: .notifications)
        }
    }

    func scheduleReEngagement(daysSinceLastEntry: Int) async {
        await cancelNotifications(in: .reEngagement)

        // Get contextual re-engagement message
        let message = NotificationMessageProvider.shared.getReEngagementMessage(daysSinceLastEntry: daysSinceLastEntry)

        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.categoryIdentifier = Category.reEngagement.identifier
        content.threadIdentifier = Category.reEngagement.threadIdentifier
        content.sound = .default

        // Schedule for next appropriate time (respecting quiet hours)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false) // 1 hour delay
        let request = UNNotificationRequest(
            identifier: "re_engagement",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            Log.info("Scheduled re-engagement notification after \(daysSinceLastEntry) days: \"\(message.title)\"", category: .notifications)
        } catch {
            Log.error("Failed to schedule re-engagement notification", error: error, category: .notifications)
        }
    }

    func scheduleMoodReflection(prompt: String) async {
        await cancelNotifications(in: .moodReflection)

        let content = UNMutableNotificationContent()
        content.title = "Mood Check-In"
        content.body = prompt
        content.categoryIdentifier = Category.moodReflection.identifier
        content.threadIdentifier = Category.moodReflection.threadIdentifier
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1800, repeats: false) // 30 minutes
        let request = UNNotificationRequest(
            identifier: "mood_reflection",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            Log.info("Scheduled mood reflection notification", category: .notifications)
        } catch {
            Log.error("Failed to schedule mood reflection notification", error: error, category: .notifications)
        }
    }

    func scheduleWeeklyReflection(selectedDay: Int, time: Date) async {
        // Runtime permission check
        let status = await checkNotificationPermission()
        guard status == .authorized else {
            Log.warning("Cannot schedule weekly reflection - permission not granted (status: \(status))", category: .notifications)
            return
        }

        await cancelNotifications(in: .weeklyReflection)

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)

        // Get contextual message
        let message = NotificationMessageProvider.shared.getWeeklyReminderMessage()

        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.categoryIdentifier = Category.weeklyReflection.identifier
        content.threadIdentifier = Category.weeklyReflection.threadIdentifier
        content.sound = .default

        var components = DateComponents()
        components.weekday = selectedDay
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly_reflection",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            Log.info("Scheduled weekly reflection for weekday \(selectedDay) at \(time)", category: .notifications)
        } catch {
            Log.error("Failed to schedule weekly reflection", error: error, category: .notifications)
        }
    }

    func scheduleMonthlyReflection(dayOfMonth: Int, time: Date) async {
        // Runtime permission check
        let status = await checkNotificationPermission()
        guard status == .authorized else {
            Log.warning("Cannot schedule monthly reflection - permission not granted (status: \(status))", category: .notifications)
            return
        }

        await cancelNotifications(in: .monthlyReflection)

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)

        // Get contextual message
        let message = NotificationMessageProvider.shared.getMonthlyReminderMessage()

        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.categoryIdentifier = Category.monthlyReflection.identifier
        content.threadIdentifier = Category.monthlyReflection.threadIdentifier
        content.sound = .default

        var components = DateComponents()
        components.day = dayOfMonth
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "monthly_reflection",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            Log.info("Scheduled monthly reflection for day \(dayOfMonth) at \(time)", category: .notifications)
        } catch {
            Log.error("Failed to schedule monthly reflection", error: error, category: .notifications)
        }
    }

    // MARK: - Management Methods

    func cancelNotifications(in category: Category) async {
        let pendingRequests = await center.pendingNotificationRequests()
        let identifiersToCancel = pendingRequests
            .filter { $0.content.categoryIdentifier == category.identifier }
            .map { $0.identifier }

        center.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        Log.info("Cancelled \(identifiersToCancel.count) notifications in category: \(category)", category: .notifications)
    }

    func cancelAllNotifications() async {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        Log.info("Cancelled all notifications", category: .notifications)
    }

    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }

    func getDeliveredNotifications() async -> [UNNotification] {
        return await center.deliveredNotifications()
    }

    // MARK: - Testing Methods

    func sendTestNotification(category: Category) async {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification for category: \(category.rawValue)"
        content.categoryIdentifier = category.identifier
        content.threadIdentifier = category.threadIdentifier
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_\(category.rawValue)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            Log.info("Sent test notification for category: \(category)", category: .notifications)
        } catch {
            Log.error("Failed to send test notification", error: error, category: .notifications)
        }
    }

    func sendTestNotificationWithDelay(category: Category, delay: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = "InkFiction Test"
        content.body = "Your notification system is working perfectly! Go back to the app to test more features."
        content.categoryIdentifier = category.identifier
        content.threadIdentifier = category.threadIdentifier
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_delay_\(category.rawValue)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            Log.info("Scheduled test notification for category: \(category) with \(delay)s delay", category: .notifications)
        } catch {
            Log.error("Failed to schedule test notification", error: error, category: .notifications)
        }
    }

    func getNotificationDebugInfo() async -> NotificationDebugInfo {
        let pending = await getPendingNotifications()
        let delivered = await getDeliveredNotifications()
        let settings = await center.notificationSettings()

        return NotificationDebugInfo(
            authorizationStatus: settings.authorizationStatus,
            pendingCount: pending.count,
            deliveredCount: delivered.count,
            pendingNotifications: pending.map { request in
                PendingNotificationInfo(
                    identifier: request.identifier,
                    category: request.content.categoryIdentifier,
                    title: request.content.title,
                    body: request.content.body,
                    scheduledDate: extractNextTriggerDate(from: request.trigger)
                )
            }
        )
    }

    // MARK: - Helper Methods

    private func extractNextTriggerDate(from trigger: UNNotificationTrigger?) -> Date? {
        guard let trigger = trigger else { return nil }

        if let calendarTrigger = trigger as? UNCalendarNotificationTrigger {
            return calendarTrigger.nextTriggerDate()
        } else if let intervalTrigger = trigger as? UNTimeIntervalNotificationTrigger {
            return intervalTrigger.nextTriggerDate()
        }

        return nil
    }
}

// MARK: - Supporting Types

enum StreakNotificationType: String {
    case milestone = "milestone"
    case risk = "risk"
}

struct NotificationDebugInfo {
    let authorizationStatus: UNAuthorizationStatus
    let pendingCount: Int
    let deliveredCount: Int
    let pendingNotifications: [PendingNotificationInfo]
}

struct PendingNotificationInfo {
    let identifier: String
    let category: String
    let title: String
    let body: String
    let scheduledDate: Date?
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Log.info("Will present notification: \(notification.request.identifier)", category: .notifications)

        // Show notification when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Log.info("Received notification response: \(response.notification.request.identifier)", category: .notifications)

        Task { @MainActor in
            await handleNotificationResponse(response: response)
        }

        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        openSettingsFor notification: UNNotification?
    ) {
        Log.info("Open settings for notification", category: .notifications)

        Task { @MainActor in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                await UIApplication.shared.open(url)
            }
        }
    }

    private func handleNotificationResponse(response: UNNotificationResponse) async {
        let categoryIdentifier = response.notification.request.content.categoryIdentifier

        Log.info("Handling notification response for category: \(categoryIdentifier)", category: .notifications)

        // Handle different notification categories
        guard let category = Category.allCases.first(where: { $0.identifier == categoryIdentifier }) else {
            Log.warning("Unknown notification category: \(categoryIdentifier)", category: .notifications)
            return
        }

        switch category {
        case .dailyReminder, .reEngagement:
            // Open journal entry screen
            await openJournalEntry()
        case .streakMotivation, .achievement:
            // Show achievement or streak details
            await showAchievementDetails()
        case .moodReflection, .weeklyReflection, .monthlyReflection:
            // Open reflection screen
            await openReflectionScreen()
        }
    }

    private func openJournalEntry() async {
        // Post notification to open journal entry
        NotificationCenter.default.post(name: Notification.Name("OpenJournalEntry"), object: nil)
    }

    private func showAchievementDetails() async {
        // Post notification to show achievements
        NotificationCenter.default.post(name: Notification.Name("ShowAchievements"), object: nil)
    }

    private func openReflectionScreen() async {
        // Post notification to open reflection screen
        NotificationCenter.default.post(name: Notification.Name("OpenReflection"), object: nil)
    }
}
