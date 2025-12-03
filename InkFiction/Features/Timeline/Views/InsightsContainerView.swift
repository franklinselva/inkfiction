//
//  InsightsContainerView.swift
//  InkFiction
//
//  Container view for scrollable insight cards (Year, Weekly, Monthly)
//

import SwiftUI
import SwiftData

struct InsightsContainerView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<JournalEntryModel> { !$0.isArchived },
           sort: \JournalEntryModel.createdAt, order: .reverse)
    private var entries: [JournalEntryModel]

    @State private var selectedIndex: Int = 0
    @State private var hasAppeared = false

    // MARK: - Computed Properties

    private var yearInsightData: InsightsData {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let entriesThisYear = entries.filter { entry in
            calendar.component(.year, from: entry.createdAt) == currentYear
        }

        let uniqueDays = Set(
            entriesThisYear.map { entry in
                calendar.startOfDay(for: entry.createdAt)
            })

        let currentStreak = calculateCurrentStreak(from: entries, calendar: calendar)

        return InsightsData(
            entriesThisYear: entriesThisYear.count,
            daysJournaled: uniqueDays.count,
            currentStreak: currentStreak
        )
    }

    private var weeklyInsight: WeeklyInsight {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (weekday - calendar.firstWeekday + 7) % 7

        guard let startOfWeek = calendar.date(
            byAdding: .day,
            value: -daysToSubtract,
            to: calendar.startOfDay(for: today)
        ),
              let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)
        else {
            return .empty()
        }

        let dailyEntries = (0..<7).compactMap { offset -> WeeklyInsight.DayEntry? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else {
                return nil
            }
            let dayStart = calendar.startOfDay(for: day)
            let entryCount = entries.filter { entry in
                calendar.isDate(entry.createdAt, inSameDayAs: dayStart)
            }.count

            return WeeklyInsight.DayEntry(
                date: day,
                entryCount: entryCount,
                isToday: calendar.isDateInToday(day)
            )
        }

        return WeeklyInsight(
            startDate: startOfWeek,
            endDate: endOfWeek,
            dailyEntries: dailyEntries
        )
    }

    private var monthlyInsight: MonthlyInsight {
        let calendar = Calendar.current
        let today = Date()

        let components = calendar.dateComponents([.year, .month], from: today)
        guard let firstDayOfMonth = calendar.date(from: components) else {
            return .empty()
        }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysFromPreviousMonth = (firstWeekday - calendar.firstWeekday + 7) % 7

        guard let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count
        else {
            return .empty()
        }

        let totalDays = daysFromPreviousMonth + daysInMonth
        let weeksNeeded = (totalDays + 6) / 7
        let totalCells = weeksNeeded * 7

        var dayInfoArray: [MonthlyInsight.DayInfo] = []

        for offset in 0..<totalCells {
            let adjustedOffset = offset - daysFromPreviousMonth
            guard
                let cellDate = calendar.date(
                    byAdding: .day, value: adjustedOffset, to: firstDayOfMonth)
            else {
                continue
            }

            let isCurrentMonthCell = calendar.isDate(
                cellDate, equalTo: firstDayOfMonth, toGranularity: .month)
            let dayNumber = calendar.component(.day, from: cellDate)

            let entryCount = entries.filter { entry in
                calendar.isDate(entry.createdAt, inSameDayAs: cellDate)
            }.count

            dayInfoArray.append(
                MonthlyInsight.DayInfo(
                    date: cellDate,
                    dayNumber: dayNumber,
                    entryCount: entryCount,
                    isCurrentMonth: isCurrentMonthCell,
                    isToday: calendar.isDateInToday(cellDate)
                ))
        }

        return MonthlyInsight(month: firstDayOfMonth, days: dayInfoArray)
    }

    private func calculateCurrentStreak(from entries: [JournalEntryModel], calendar: Calendar) -> Int {
        guard !entries.isEmpty else { return 0 }

        let uniqueDaysSet = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
        let sortedUniqueDays = uniqueDaysSet.sorted(by: >)

        guard !sortedUniqueDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let mostRecentDate = sortedUniqueDays.first!

        let daysSinceLastEntry =
            calendar.dateComponents([.day], from: mostRecentDate, to: today).day ?? 0

        if daysSinceLastEntry > 1 {
            return 0
        }

        if sortedUniqueDays.count == 1 {
            return 1
        }

        var streak = 1
        for i in 0..<(sortedUniqueDays.count - 1) {
            let currentDay = sortedUniqueDays[i]
            let previousDay = sortedUniqueDays[i + 1]

            let daysDiff =
                calendar.dateComponents([.day], from: previousDay, to: currentDay).day ?? 0

            if daysDiff == 1 {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Body

    var body: some View {
        // Card height calculation:
        // - Card intrinsic height: 120pt
        // - Card internal padding: 20pt (top + bottom = 40pt)
        // - Total per card: 160pt
        VerticalInsightsScrollView(
            cardCount: 3,
            cardHeight: 160, // 120pt content + 40pt padding
            currentIndex: $selectedIndex
        ) {
            VStack(spacing: 12) {
                // Year Stats Insight
                InsightsCard(data: yearInsightData)
                    .id(0)

                // Weekly Insight
                WeeklyInsightCard(insight: weeklyInsight)
                    .id(1)

                // Monthly Insight
                MonthlyInsightCard(insight: monthlyInsight)
                    .id(2)
            }
        }
        .onAppear {
            if !hasAppeared {
                // Set initial card based on day of week/month
                // Default to weekly view in the middle
                selectedIndex = 1

                Log.info("InsightsContainerView appeared, showing card at index \(selectedIndex)", category: .ui)
                hasAppeared = true
            }
        }
    }
}
