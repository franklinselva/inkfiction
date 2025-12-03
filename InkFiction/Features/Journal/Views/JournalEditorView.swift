//
//  JournalEditorView.swift
//  InkFiction
//
//  Full screen view for creating and editing journal entries
//

import Combine
import PhotosUI
import SwiftData
import SwiftUI

struct JournalEditorView: View {
    @Environment(Router.self) private var router
    @Environment(\.themeManager) private var themeManager
    @Environment(\.modelContext) private var modelContext

    let entryId: UUID?

    @State private var viewModel: JournalEditorViewModel?
    @State private var keyboardHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @FocusState private var isTextEditorFocused: Bool
    @State private var showingMoodPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isImageContainerPressed = false

    init(entryId: UUID?) {
        self.entryId = entryId
    }

    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()

            if let viewModel = viewModel {
                VStack(spacing: 0) {
                    // Navigation Header
                    NavigationHeaderView(
                        config: NavigationHeaderConfig(
                            title: viewModel.isEditing ? "Edit Entry" : "New Entry",
                            leftButton: .back(action: { router.pop() }),
                            rightButton: viewModel.canSave
                                ? .icon("checkmark.circle.fill", action: { saveEntry() })
                                : .none
                        ),
                        scrollOffset: scrollOffset
                    )

                    // Content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Text entry section
                            textEntrySection(viewModel: viewModel)

                            // Image section
                            imageSection(viewModel: viewModel)

                            // Enhanced content section (mood, tags)
                            if viewModel.canSave {
                                enhancedContentSection(viewModel: viewModel)
                            }

                            // Bottom spacer
                            Spacer(minLength: 40)
                        }
                        .padding()
                        .padding(.bottom, keyboardHeight)
                    }
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentOffset.y
                    } action: { _, newValue in
                        scrollOffset = -newValue
                    }
                }
                .onReceive(keyboardPublisher) { height in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        keyboardHeight = height
                    }
                }
                .alert("Error", isPresented: Binding(
                    get: { viewModel.showError },
                    set: { self.viewModel?.showError = $0 }
                )) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.errorMessage)
                }
                .alert("Add Tag", isPresented: Binding(
                    get: { viewModel.showAddTag },
                    set: { self.viewModel?.showAddTag = $0 }
                )) {
                    TextField("Enter tag", text: Binding(
                        get: { viewModel.newTagText },
                        set: { self.viewModel?.newTagText = $0 }
                    ))
                    Button("Cancel", role: .cancel) {
                        self.viewModel?.newTagText = ""
                    }
                    Button("Add") {
                        self.viewModel?.addTag(viewModel.newTagText)
                    }
                } message: {
                    Text("Add a tag to categorize your entry")
                }
                .alert("Photo Access Required", isPresented: Binding(
                    get: { viewModel.showPhotoPermissionAlert },
                    set: { self.viewModel?.showPhotoPermissionAlert = $0 }
                )) {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("InkFiction needs access to your photo library to attach photos to journal entries.")
                }
            } else {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadEntry()
        }
    }

    // MARK: - Load Entry

    @MainActor
    private func loadEntry() async {
        if let entryId = entryId {
            // Edit existing entry
            do {
                if let model = try await JournalRepository.shared.getEntry(by: entryId) {
                    let entry = JournalEntry(from: model)
                    var vm = JournalEditorViewModel(existingEntry: entry)
                    vm.setModelContext(modelContext)
                    self.viewModel = vm
                } else {
                    // Entry not found, create new
                    var vm = JournalEditorViewModel()
                    vm.setModelContext(modelContext)
                    self.viewModel = vm
                }
            } catch {
                // Error loading, create new
                var vm = JournalEditorViewModel()
                vm.setModelContext(modelContext)
                self.viewModel = vm
            }
        } else {
            // Create new entry
            var vm = JournalEditorViewModel()
            vm.setModelContext(modelContext)
            self.viewModel = vm
        }
    }

    // MARK: - Text Entry Section

    @ViewBuilder
    private func textEntrySection(viewModel: JournalEditorViewModel) -> some View {
        VStack(spacing: 16) {
            // Title field
            HStack {
                TextField("Title (optional)", text: Binding(
                    get: { viewModel.title },
                    set: { self.viewModel?.title = $0 }
                ))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.surfaceColor)
            )

            // Text editor
            ZStack(alignment: .topLeading) {
                TextEditor(text: Binding(
                    get: { viewModel.content },
                    set: { self.viewModel?.content = $0 }
                ))
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                    .scrollContentBackground(.hidden)
                    .focused($isTextEditorFocused)

                if viewModel.content.isEmpty {
                    Text("What's on your mind?")
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.currentTheme.surfaceColor)
            )
            .frame(minHeight: 200)
        }
    }

    // MARK: - Image Section

    @ViewBuilder
    private func imageSection(viewModel: JournalEditorViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Images", systemImage: "photo.on.rectangle.angled")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

            if !viewModel.images.isEmpty {
                // Image carousel
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(viewModel.images.enumerated()), id: \.element.id) { index, image in
                            ImageThumbnailView(
                                image: image,
                                onRemove: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        self.viewModel?.removeImage(at: index)
                                    }
                                }
                            )
                        }

                        // Add more photos button
                        addPhotosButton(viewModel: viewModel)
                    }
                    .padding(.vertical, 8)
                }
                .frame(height: 120)
            } else {
                // Empty state - clickable photo picker
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 10,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "photo.stack.fill")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor.opacity(0.7))
                                .scaleEffect(isImageContainerPressed ? 0.9 : 1.0)
                                .rotationEffect(.degrees(isImageContainerPressed ? -5 : 0))

                            Text("Tap to add photos")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor.opacity(0.8))

                            Text("Up to 10 images per entry")
                                .font(.caption2)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor.opacity(0.6))
                        }
                        .padding(.vertical, 28)
                        Spacer()
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        themeManager.currentTheme.surfaceColor.opacity(0.3),
                                        themeManager.currentTheme.surfaceColor.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                themeManager.currentTheme.textSecondaryColor.opacity(0.4),
                                style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                            )
                    )
                    .scaleEffect(isImageContainerPressed ? 0.98 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isImageContainerPressed)
                }
                .onLongPressGesture(
                    minimumDuration: 0,
                    maximumDistance: .infinity,
                    pressing: { pressing in
                        isImageContainerPressed = pressing
                    },
                    perform: { }
                )
            }
        }
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task {
                await self.viewModel?.checkPhotoPermission()
                await self.viewModel?.loadImages(from: newItems)
                selectedPhotoItems = []
            }
        }
    }

    @ViewBuilder
    private func addPhotosButton(viewModel: JournalEditorViewModel) -> some View {
        PhotosPicker(
            selection: $selectedPhotoItems,
            maxSelectionCount: 10 - viewModel.images.count,
            matching: .images,
            photoLibrary: .shared()
        ) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.surfaceColor.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                themeManager.currentTheme.textSecondaryColor.opacity(0.3),
                                style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                            )
                    )

                VStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    Text("Add")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
            }
            .frame(width: 100, height: 100)
        }
    }

    // MARK: - Enhanced Content Section

    @ViewBuilder
    private func enhancedContentSection(viewModel: JournalEditorViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            MoodSelectorView(
                selectedMood: Binding(
                    get: { viewModel.mood },
                    set: { self.viewModel?.mood = $0 }
                ),
                isExpanded: $showingMoodPicker
            )

            TagsSectionView(tags: Binding(
                get: { viewModel.tags },
                set: { self.viewModel?.tags = $0 }
            ))
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.canSave)
    }

    // MARK: - Actions

    private func saveEntry() {
        guard let viewModel = viewModel, viewModel.validate() else { return }

        Task {
            do {
                try await viewModel.save()
                // Post notification to refresh journal list
                NotificationCenter.default.post(name: .journalEntryUpdated, object: nil)
                router.pop()
            } catch {
                // Error is handled by viewModel
            }
        }
    }

    // MARK: - Keyboard Publisher

    private var keyboardPublisher: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }

        let willHide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        return Publishers.Merge(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let journalEntryUpdated = Notification.Name("journalEntryUpdated")
}
