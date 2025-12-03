//
//  ExpandableSearchBar.swift
//  InkFiction
//
//  Expandable search bar with debounced input and date filter
//

import Combine
import SwiftUI

struct ExpandableSearchBar: View {
    @Binding var filterState: JournalFilterState

    @Environment(\.themeManager) private var themeManager

    @FocusState private var isSearchFocused: Bool
    @State private var showDateRangePopover = false
    @State private var debounceTask: Task<Void, Never>?
    @State private var localSearchText: String = ""

    init(filterState: Binding<JournalFilterState>) {
        self._filterState = filterState
        self._localSearchText = State(initialValue: filterState.wrappedValue.searchText)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Search field with expandable behavior
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    .transition(.opacity)

                TextField("Search entries...", text: $localSearchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onChange(of: localSearchText) { _, newValue in
                        debounceTask?.cancel()
                        debounceTask = Task {
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            if !Task.isCancelled {
                                filterState.searchText = newValue
                            }
                        }
                    }

                if !localSearchText.isEmpty {
                    Button(action: {
                        localSearchText = ""
                        filterState.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        themeManager.currentTheme.type.isLight
                            ? Color.white
                            : themeManager.currentTheme.surfaceColor.opacity(2)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        themeManager.currentTheme.textSecondaryColor.opacity(
                            themeManager.currentTheme.type.isLight ? 0.2 : 0.1
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(
                    themeManager.currentTheme.type.isLight ? 0.08 : 0.15
                ),
                radius: 4,
                x: 0,
                y: 2
            )
            .frame(maxWidth: isSearchFocused ? .infinity : nil)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSearchFocused)

            // Filter buttons that hide when search is focused
            if !isSearchFocused {
                HStack(spacing: 8) {
                    // Date Range Filter Button with Menu
                    Menu {
                        ForEach(
                            [
                                DateRangeFilter.today, .yesterday, .thisWeek, .lastWeek, .thisMonth,
                                .lastMonth, .last30Days, .allTime,
                            ], id: \.self
                        ) { range in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    filterState.dateRange = range
                                }
                            }) {
                                Label {
                                    HStack {
                                        Text(range.rawValue)
                                        if filterState.dateRange == range {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                } icon: {
                                    Image(systemName: range.sfSymbolName)
                                }
                            }
                        }

                        Divider()

                        Button(action: {
                            showDateRangePopover = true
                        }) {
                            Label("Custom Range...", systemImage: "calendar.badge.plus")
                        }
                    } label: {
                        Image(
                            systemName: filterState.dateRange != .allTime
                                ? "calendar.badge.clock"
                                : "calendar"
                        )
                        .font(.system(size: 18))
                        .foregroundColor(
                            filterState.dateRange != .allTime
                                ? .white
                                : themeManager.currentTheme.textPrimaryColor
                        )
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    filterState.dateRange != .allTime
                                        ? themeManager.currentTheme.accentColor
                                        : themeManager.currentTheme.type.isLight
                                            ? Color.white
                                            : themeManager.currentTheme.surfaceColor.opacity(2)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    filterState.dateRange != .allTime
                                        ? Color.clear
                                        : themeManager.currentTheme.textSecondaryColor.opacity(
                                            themeManager.currentTheme.type.isLight ? 0.2 : 0.1
                                        ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(
                                themeManager.currentTheme.type.isLight ? 0.06 : 0.12
                            ),
                            radius: 3,
                            x: 0,
                            y: 1
                        )
                    }
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSearchFocused)
            }
        }
        .sheet(isPresented: $showDateRangePopover) {
            CustomDateRangePickerView(
                startDate: $filterState.customStartDate,
                endDate: $filterState.customEndDate,
                dateRange: $filterState.dateRange
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onDisappear {
            debounceTask?.cancel()
        }
        .onChange(of: filterState.searchText) { _, newValue in
            if newValue.isEmpty && !localSearchText.isEmpty {
                localSearchText = ""
            }
        }
    }
}

// MARK: - Custom Date Range Picker

struct CustomDateRangePickerView: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    @Binding var dateRange: DateRangeFilter

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager

    @State private var tempStartDate = Date()
    @State private var tempEndDate = Date()

    private var selectedDateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: tempStartDate)) - \(formatter.string(from: tempEndDate))"
    }

    private var isValidRange: Bool {
        tempStartDate <= tempEndDate
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "calendar")
                            .font(.system(size: 56, weight: .light))
                            .foregroundColor(themeManager.currentTheme.accentColor)
                            .padding(.top, 8)

                        VStack(spacing: 8) {
                            Text("Select Date Range")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                            Text(selectedDateText)
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 12)

                    // Date Pickers
                    VStack(spacing: 24) {
                        DatePicker(
                            "Start Date",
                            selection: $tempStartDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .accentColor(themeManager.currentTheme.accentColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(themeManager.currentTheme.surfaceColor.opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            themeManager.currentTheme.textSecondaryColor.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .onChange(of: tempStartDate) { _, newValue in
                            if newValue > tempEndDate {
                                tempEndDate = newValue
                            }
                        }

                        DatePicker(
                            "End Date",
                            selection: $tempEndDate,
                            in: tempStartDate...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .accentColor(themeManager.currentTheme.accentColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(themeManager.currentTheme.surfaceColor.opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            themeManager.currentTheme.textSecondaryColor.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
                .padding(.bottom, 20)
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("Custom Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        startDate = tempStartDate
                        endDate = tempEndDate
                        dateRange = .custom
                        dismiss()
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(
                                isValidRange
                                    ? themeManager.currentTheme.accentColor
                                    : themeManager.currentTheme.textSecondaryColor
                            )
                    }
                    .disabled(!isValidRange)
                }
            }
        }
        .onAppear {
            if let existingStart = startDate, let existingEnd = endDate {
                tempStartDate = existingStart
                tempEndDate = existingEnd
            } else {
                tempEndDate = Date()
                tempStartDate = Calendar.current.date(byAdding: .day, value: -7, to: tempEndDate) ?? tempEndDate
            }
        }
    }
}
