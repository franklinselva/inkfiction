//
//  NotificationsViewModel.swift
//  InkFiction
//
//  ViewModel for notifications settings
//

import Combine
import SwiftUI
import UserNotifications

@MainActor
@Observable
final class NotificationsViewModel {

    // MARK: - Published State

    var notificationsEnabled: Bool = false {
        didSet {
            if notificationsEnabled != oldValue {
                handleNotificationToggle()
            }
        }
    }

    var dailyReminderEnabled: Bool = false {
        didSet {
            if dailyReminderEnabled != oldValue {
                handleDailyReminderToggle()
            }
        }
    }

    var reminderTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date() {
        didSet {
            // Auto-sync reminderTimeOfDay based on the time
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: reminderTime)
            reminderTimeOfDay = TimeOfDay.from(hour: hour)

            if dailyReminderEnabled {
                scheduleDailyReminder()
            }
        }
    }

    var reminderTimeOfDay: TimeOfDay = .evening

    var weeklyReminderEnabled: Bool = false {
        didSet {
            if weeklyReminderEnabled != oldValue {
                handleWeeklyReminderToggle()
            }
        }
    }

    var weeklyReminderDay: Int = 1 {
        didSet {
            if weeklyReminderEnabled {
                scheduleWeeklyReminder()
            }
        }
    }

    var weeklyReminderTime: Date = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date() {
        didSet {
            if weeklyReminderEnabled {
                scheduleWeeklyReminder()
            }
        }
    }

    var monthlyReminderEnabled: Bool = false {
        didSet {
            if monthlyReminderEnabled != oldValue {
                handleMonthlyReminderToggle()
            }
        }
    }

    var monthlyReminderDay: Int = 1 {
        didSet {
            if monthlyReminderEnabled {
                scheduleMonthlyReminder()
            }
        }
    }

    var monthlyReminderTime: Date = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date() {
        didSet {
            if monthlyReminderEnabled {
                scheduleMonthlyReminder()
            }
        }
    }

    var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    var showingPermissionDeniedAlert = false
    var isLoading = false

    // MARK: - Private Properties

    private let notificationService = NotificationService.shared
    private let settingsRepository = SettingsRepository.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let dailyReminderEnabled = "notification_dailyReminderEnabled"
        static let reminderTime = "notification_reminderTime"
        static let weeklyReminderEnabled = "notification_weeklyReminderEnabled"
        static let weeklyReminderDay = "notification_weeklyReminderDay"
        static let weeklyReminderTime = "notification_weeklyReminderTime"
        static let monthlyReminderEnabled = "notification_monthlyReminderEnabled"
        static let monthlyReminderDay = "notification_monthlyReminderDay"
        static let monthlyReminderTime = "notification_monthlyReminderTime"
    }

    // MARK: - Initialization

    init() {
        Task {
            await loadInitialState()
        }
    }

    // MARK: - Initial State Loading

    private func loadInitialState() async {
        // Check notification permission status first
        await updateNotificationPermissionStatus()

        // Load settings from UserDefaults
        let defaults = UserDefaults.standard

        dailyReminderEnabled = defaults.bool(forKey: Keys.dailyReminderEnabled)
        if let savedTime = defaults.object(forKey: Keys.reminderTime) as? Date {
            reminderTime = savedTime
        }

        weeklyReminderEnabled = defaults.bool(forKey: Keys.weeklyReminderEnabled)
        weeklyReminderDay = defaults.integer(forKey: Keys.weeklyReminderDay)
        if weeklyReminderDay == 0 { weeklyReminderDay = 1 }
        if let savedWeeklyTime = defaults.object(forKey: Keys.weeklyReminderTime) as? Date {
            weeklyReminderTime = savedWeeklyTime
        }

        monthlyReminderEnabled = defaults.bool(forKey: Keys.monthlyReminderEnabled)
        monthlyReminderDay = defaults.integer(forKey: Keys.monthlyReminderDay)
        if monthlyReminderDay == 0 { monthlyReminderDay = 1 }
        if let savedMonthlyTime = defaults.object(forKey: Keys.monthlyReminderTime) as? Date {
            monthlyReminderTime = savedMonthlyTime
        }

        // Auto-infer time of day from reminder time
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        reminderTimeOfDay = TimeOfDay.from(hour: hour)

        // Sync notificationsEnabled with actual system permission status
        if notificationPermissionStatus == .denied || notificationPermissionStatus == .notDetermined {
            notificationsEnabled = false
            dailyReminderEnabled = false
            weeklyReminderEnabled = false
            monthlyReminderEnabled = false
        } else if notificationPermissionStatus == .authorized || notificationPermissionStatus == .provisional {
            notificationsEnabled = settingsRepository.notificationsEnabled

            // If daily reminder is enabled and permission is granted, schedule it
            if dailyReminderEnabled && notificationsEnabled {
                await notificationService.scheduleDailyReminder(at: reminderTime, timeOfDay: reminderTimeOfDay)
            }

            // If weekly reminder is enabled, schedule it
            if weeklyReminderEnabled && notificationsEnabled {
                await notificationService.scheduleWeeklyReflection(selectedDay: weeklyReminderDay, time: weeklyReminderTime)
            }

            // If monthly reminder is enabled, schedule it
            if monthlyReminderEnabled && notificationsEnabled {
                await notificationService.scheduleMonthlyReflection(dayOfMonth: monthlyReminderDay, time: monthlyReminderTime)
            }
        } else {
            notificationsEnabled = settingsRepository.notificationsEnabled
        }
    }

    // MARK: - Permission Handling

    private func updateNotificationPermissionStatus() async {
        let settings = await notificationService.center.notificationSettings()
        notificationPermissionStatus = settings.authorizationStatus
    }

    // MARK: - Toggle Handlers

    private func handleNotificationToggle() {
        Task {
            if notificationsEnabled {
                // Request permission if needed
                if notificationPermissionStatus == .notDetermined {
                    let granted = await notificationService.requestPermission()
                    await updateNotificationPermissionStatus()

                    if !granted {
                        notificationsEnabled = false
                        showingPermissionDeniedAlert = true
                        return
                    }
                } else if notificationPermissionStatus == .denied {
                    notificationsEnabled = false
                    showingPermissionDeniedAlert = true
                    return
                }

                // Schedule daily reminder if enabled
                if dailyReminderEnabled {
                    await notificationService.scheduleDailyReminder(at: reminderTime, timeOfDay: reminderTimeOfDay)
                }
            } else {
                // Disable all notifications
                await notificationService.cancelAllNotifications()
            }

            // Save to repository
            do {
                try await settingsRepository.toggleNotifications()
            } catch {
                Log.error("Failed to save notification settings", error: error, category: .notifications)
            }
        }
    }

    private func handleDailyReminderToggle() {
        Task {
            if dailyReminderEnabled {
                // Check if notifications are enabled first
                if !notificationsEnabled {
                    notificationsEnabled = true
                    try? await Task.sleep(nanoseconds: 100_000_000)

                    if !notificationsEnabled {
                        dailyReminderEnabled = false
                        return
                    }
                }

                // Schedule daily reminder
                await notificationService.scheduleDailyReminder(at: reminderTime, timeOfDay: reminderTimeOfDay)
            } else {
                await notificationService.cancelNotifications(in: .dailyReminder)
            }

            // Save to UserDefaults
            saveSettings()
        }
    }

    private func scheduleDailyReminder() {
        guard dailyReminderEnabled && notificationsEnabled else { return }

        Task {
            await notificationService.scheduleDailyReminder(at: reminderTime, timeOfDay: reminderTimeOfDay)
            saveSettings()
        }
    }

    private func handleWeeklyReminderToggle() {
        Task {
            if weeklyReminderEnabled {
                if !notificationsEnabled {
                    notificationsEnabled = true
                    try? await Task.sleep(nanoseconds: 100_000_000)

                    if !notificationsEnabled {
                        weeklyReminderEnabled = false
                        return
                    }
                }

                await notificationService.scheduleWeeklyReflection(selectedDay: weeklyReminderDay, time: weeklyReminderTime)
            } else {
                await notificationService.cancelNotifications(in: .weeklyReflection)
            }

            saveSettings()
        }
    }

    private func scheduleWeeklyReminder() {
        guard weeklyReminderEnabled && notificationsEnabled else { return }

        Task {
            await notificationService.scheduleWeeklyReflection(selectedDay: weeklyReminderDay, time: weeklyReminderTime)
            saveSettings()
        }
    }

    private func handleMonthlyReminderToggle() {
        Task {
            if monthlyReminderEnabled {
                if !notificationsEnabled {
                    notificationsEnabled = true
                    try? await Task.sleep(nanoseconds: 100_000_000)

                    if !notificationsEnabled {
                        monthlyReminderEnabled = false
                        return
                    }
                }

                await notificationService.scheduleMonthlyReflection(dayOfMonth: monthlyReminderDay, time: monthlyReminderTime)
            } else {
                await notificationService.cancelNotifications(in: .monthlyReflection)
            }

            saveSettings()
        }
    }

    private func scheduleMonthlyReminder() {
        guard monthlyReminderEnabled && notificationsEnabled else { return }

        Task {
            await notificationService.scheduleMonthlyReflection(dayOfMonth: monthlyReminderDay, time: monthlyReminderTime)
            saveSettings()
        }
    }

    // MARK: - Persistence

    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(dailyReminderEnabled, forKey: Keys.dailyReminderEnabled)
        defaults.set(reminderTime, forKey: Keys.reminderTime)
        defaults.set(weeklyReminderEnabled, forKey: Keys.weeklyReminderEnabled)
        defaults.set(weeklyReminderDay, forKey: Keys.weeklyReminderDay)
        defaults.set(weeklyReminderTime, forKey: Keys.weeklyReminderTime)
        defaults.set(monthlyReminderEnabled, forKey: Keys.monthlyReminderEnabled)
        defaults.set(monthlyReminderDay, forKey: Keys.monthlyReminderDay)
        defaults.set(monthlyReminderTime, forKey: Keys.monthlyReminderTime)
    }

    // MARK: - Public Methods

    func sendTestNotification() async {
        isLoading = true
        defer { isLoading = false }

        // Check permission first
        if notificationPermissionStatus == .notDetermined {
            let granted = await notificationService.requestPermission()
            await updateNotificationPermissionStatus()

            if !granted {
                showingPermissionDeniedAlert = true
                return
            }
        } else if notificationPermissionStatus == .denied {
            showingPermissionDeniedAlert = true
            return
        }

        // Send test notification
        await notificationService.sendTestNotificationWithDelay(category: .dailyReminder, delay: 3.0)
    }

    func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    func refreshPermissionStatus() async {
        await updateNotificationPermissionStatus()
    }
}
