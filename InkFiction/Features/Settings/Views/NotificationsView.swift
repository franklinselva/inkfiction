//
//  NotificationsView.swift
//  InkFiction
//
//  Notifications settings view with reminders and preferences
//

import SwiftUI

struct NotificationsView: View {
    @State private var viewModel = NotificationsViewModel()
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0
    @State private var animateToggle = false

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                // Navigation header
                NavigationHeaderView(
                    config: NavigationHeaderConfig(
                        title: "Notifications",
                        leftButton: .back(action: { dismiss() }),
                        rightButton: .none
                    ),
                    scrollOffset: scrollOffset
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Permission Status Card
                        if viewModel.notificationPermissionStatus == .denied {
                            permissionDeniedCard
                        }

                        // General Notifications
                        generalNotificationsSection

                        // Daily Reminders
                        dailyRemindersSection

                        // Weekly Reminders
                        weeklyRemindersSection

                        // Monthly Reminders
                        monthlyRemindersSection

                        // Add bottom spacing to avoid tab bar overlap
                        Color.clear
                            .frame(height: 120)
                    }
                    .padding()
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    scrollOffset = -newValue
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.refreshPermissionStatus()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
        ) { _ in
            Task {
                await viewModel.refreshPermissionStatus()
                Log.info("NotificationsView refreshed permission status on app activation", category: .notifications)
            }
        }
        .alert("Notifications Disabled", isPresented: $viewModel.showingPermissionDeniedAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Open Settings") {
                viewModel.openNotificationSettings()
            }
        } message: {
            Text("Please enable notifications in Settings to receive journal reminders and updates.")
        }
        .overlay {
            if viewModel.isLoading {
                themeManager.currentTheme.overlayColor
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .progressViewStyle(
                                CircularProgressViewStyle(
                                    tint: themeManager.currentTheme.textPrimaryColor
                                )
                            )
                            .scaleEffect(1.5)
                    }
            }
        }
    }

    // MARK: - Permission Denied Card

    private var permissionDeniedCard: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.warningColor)

            VStack(alignment: .leading, spacing: 4) {
                Text("Notifications Disabled")
                    .font(.body.weight(.medium))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                Text("Enable in Settings to receive reminders")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
            }

            Spacer()

            Button("Settings") {
                viewModel.openNotificationSettings()
            }
            .font(.caption.weight(.medium))
            .foregroundColor(themeManager.currentTheme.accentColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.warningColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.currentTheme.warningColor.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.bottom, 8)
    }

    // MARK: - General Notifications Section

    private var generalNotificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(spacing: 16) {
                Toggle(isOn: $viewModel.notificationsEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Notifications")
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                            Text("Receive journal reminders and updates")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        }
                    }
                }
                .tint(themeManager.currentTheme.accentColor)
                .scaleEffect(animateToggle && viewModel.notificationsEnabled ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: animateToggle)
                .onChange(of: viewModel.notificationsEnabled) { _, newValue in
                    if newValue {
                        withAnimation {
                            animateToggle = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            animateToggle = false
                        }
                    }
                }
            }
            .padding()
            .gradientCard()
        }
    }

    // MARK: - Daily Reminders Section

    private var dailyRemindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Reminders")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(spacing: 16) {
                Toggle(isOn: $viewModel.dailyReminderEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily Journal Reminder")
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                            Text("Get reminded to write in your journal")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        }
                    }
                }
                .tint(themeManager.currentTheme.accentColor)
                .disabled(!viewModel.notificationsEnabled)

                if viewModel.dailyReminderEnabled {
                    VStack(spacing: 12) {
                        DatePicker(
                            selection: $viewModel.reminderTime,
                            displayedComponents: .hourAndMinute
                        ) {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .font(.body)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                                    .frame(width: 24)

                                Text("Reminder Time")
                                    .font(.body)
                                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                            }
                        }
                        .datePickerStyle(.compact)
                        .tint(themeManager.currentTheme.accentColor)

                        // Show scheduled time
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.successColor)
                            Text("Reminder set for \(viewModel.reminderTime.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                            Spacer()
                        }
                        .padding(.horizontal, 24 + 12)
                        .transition(.opacity)
                    }
                }
            }
            .padding()
            .gradientCard()
        }
    }

    // MARK: - Weekly Reminders Section

    private var weeklyRemindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.accentColor)

                Text("Weekly Reminders")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 16) {
                Toggle(isOn: $viewModel.weeklyReminderEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weekly Journal Reminder")
                            .font(.body.weight(.medium))
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        Text("Get reminded to reflect on your week")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                }
                .tint(themeManager.currentTheme.accentColor)
                .disabled(!viewModel.notificationsEnabled)

                if viewModel.weeklyReminderEnabled {
                    VStack(spacing: 16) {
                        Divider()
                            .background(themeManager.currentTheme.dividerColor)

                        // Time Picker
                        DatePicker(
                            selection: $viewModel.weeklyReminderTime,
                            displayedComponents: .hourAndMinute
                        ) {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .font(.body)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                                    .frame(width: 24)

                                Text("Reminder Time")
                                    .font(.body)
                                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                            }
                        }
                        .datePickerStyle(.compact)
                        .tint(themeManager.currentTheme.accentColor)

                        // Visual Weekday Selector
                        WeekdaySelector(selectedDay: $viewModel.weeklyReminderDay)

                        // Next Occurrence Preview
                        NextOccurrenceView(
                            reminderType: .weekly,
                            time: viewModel.weeklyReminderTime,
                            weekday: viewModel.weeklyReminderDay,
                            dayOfMonth: nil
                        )
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .padding()
            .gradientCard()
        }
    }

    // MARK: - Monthly Reminders Section

    private var monthlyRemindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.circle.fill")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.accentColor)

                Text("Monthly Reminders")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 16) {
                Toggle(isOn: $viewModel.monthlyReminderEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monthly Journal Reminder")
                            .font(.body.weight(.medium))
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        Text("Get reminded to reflect on your month")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                }
                .tint(themeManager.currentTheme.accentColor)
                .disabled(!viewModel.notificationsEnabled)

                if viewModel.monthlyReminderEnabled {
                    VStack(spacing: 16) {
                        Divider()
                            .background(themeManager.currentTheme.dividerColor)

                        // Time Picker
                        DatePicker(
                            selection: $viewModel.monthlyReminderTime,
                            displayedComponents: .hourAndMinute
                        ) {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .font(.body)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                                    .frame(width: 24)

                                Text("Reminder Time")
                                    .font(.body)
                                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                            }
                        }
                        .datePickerStyle(.compact)
                        .tint(themeManager.currentTheme.accentColor)

                        // Visual Day of Month Selector
                        DayOfMonthSelector(selectedDay: $viewModel.monthlyReminderDay)

                        // Next Occurrence Preview
                        NextOccurrenceView(
                            reminderType: .monthly,
                            time: viewModel.monthlyReminderTime,
                            weekday: nil,
                            dayOfMonth: viewModel.monthlyReminderDay
                        )
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .padding()
            .gradientCard()
        }
    }
}

#Preview {
    NotificationsView()
        .environment(\.themeManager, ThemeManager())
}
