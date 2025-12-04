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

    // MARK: - AI Button State
    @State private var enhanceSymbol: String = "wand.and.sparkles"
    @State private var isEnhanceButtonPressed = false

    init(entryId: UUID?) {
        self.entryId = entryId
    }

    var body: some View {
        ZStack {
            AnimatedGradientBackground()
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

            // Text editor with integrated AI buttons
            ZStack(alignment: .bottomTrailing) {
                // Text editor background and content
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
                .padding(.bottom, 40) // Space for floating buttons

                // AI buttons inside text editor
                textEditorAIButtons(viewModel: viewModel)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.currentTheme.surfaceColor)
            )
            .frame(minHeight: viewModel.hasEnhanced ? 200 : 280)
        }
    }

    // MARK: - Text Editor AI Buttons

    @ViewBuilder
    private func textEditorAIButtons(viewModel: JournalEditorViewModel) -> some View {
        Group {
            // Only show AI features if user has enhanced or premium tier
            if !viewModel.canShowEnhancementFeatures {
                EmptyView()
            } else if viewModel.isProcessing || viewModel.isEnhancing {
                // Processing indicator
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                    Text("Enhancing...")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
                .padding(16)
                .transition(.scale.combined(with: .opacity))
            } else if !viewModel.hasEnhanced && viewModel.canEnhance {
                // Enhance button (before enhancement)
                Button(action: {
                    triggerEnhancement()
                }) {
                    MorphSymbolView(
                        symbol: enhanceSymbol,
                        config: MorphSymbolConfiguration(
                            font: .system(size: 22, weight: .medium),
                            frame: CGSize(width: 30, height: 30),
                            radius: 8,
                            foregroundColor: themeManager.currentTheme.accentColor,
                            keyFrameDuration: 0.3
                        )
                    )
                }
                .shadow(
                    color: themeManager.currentTheme.accentColor.opacity(0.3),
                    radius: 10,
                    y: 2
                )
                .padding(16)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.canEnhance)
            } else if viewModel.hasEnhanced {
                // Floating action buttons (after enhancement)
                HStack(spacing: 12) {
                    // Undo button
                    if viewModel.canUndo {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                self.viewModel?.undoEnhancement()
                            }
                        }) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [themeManager.currentTheme.accentColor, themeManager.currentTheme.accentColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Regenerate button
                    Button(action: {
                        Task {
                            await self.viewModel?.processJournalEntry()
                        }
                    }) {
                        MorphSymbolView(
                            symbol: "sparkles",
                            config: MorphSymbolConfiguration(
                                font: .system(size: 20, weight: .medium),
                                frame: CGSize(width: 26, height: 26),
                                radius: 8,
                                foregroundColor: themeManager.currentTheme.accentColor,
                                keyFrameDuration: 0.3
                            )
                        )
                    }
                }
                .padding(16)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isProcessing)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.hasEnhanced)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.canEnhance)
    }

    // MARK: - Image Section

    @ViewBuilder
    private func imageSection(viewModel: JournalEditorViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Images", systemImage: "photo.on.rectangle.angled")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

            if !viewModel.images.isEmpty || (viewModel.canGenerateAIImage && viewModel.canShowEnhancementFeatures) {
                // Image carousel
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // AI Image Generate Button (appears after enhancement, only for enhanced/premium users)
                        if viewModel.canGenerateAIImage && viewModel.canShowEnhancementFeatures {
                            aiImageGenerateButton(viewModel: viewModel)
                                .transition(.scale.combined(with: .opacity))
                        }

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
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.canGenerateAIImage)
                }
                .frame(height: 120)
            } else if !viewModel.canGenerateAIImage {
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

    // MARK: - Floating AI Action Buttons

    @ViewBuilder
    private func floatingActionButtons(viewModel: JournalEditorViewModel) -> some View {
        VStack {
            Spacer()

            HStack(spacing: 12) {
                Spacer()

                // Undo button (appears after enhancement)
                if viewModel.hasEnhanced && viewModel.canUndo {
                    FloatingAIButton(
                        symbol: "arrow.uturn.backward",
                        isProcessing: false,
                        action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                self.viewModel?.undoEnhancement()
                            }
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                // Regenerate button (appears after enhancement)
                if viewModel.hasEnhanced {
                    FloatingAIButton(
                        symbol: "arrow.trianglehead.2.clockwise.rotate.90",
                        isProcessing: viewModel.isProcessing,
                        action: {
                            Task {
                                await self.viewModel?.processJournalEntry()
                            }
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                // Main enhance button
                if viewModel.canEnhance && !viewModel.hasEnhanced {
                    FloatingAIButton(
                        symbol: enhanceSymbol,
                        isProcessing: viewModel.isProcessing,
                        isPrimary: true,
                        action: {
                            triggerEnhancement()
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, keyboardHeight > 0 ? keyboardHeight + 10 : 100)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.hasEnhanced)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.canUndo)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.canEnhance)
        }
    }

    // MARK: - AI Image Generate Button

    @ViewBuilder
    private func aiImageGenerateButton(viewModel: JournalEditorViewModel) -> some View {
        Button {
            Task {
                await self.viewModel?.generateAIImage()
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.currentTheme.accentColor.opacity(0.3),
                                themeManager.currentTheme.accentColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        themeManager.currentTheme.accentColor.opacity(0.6),
                                        themeManager.currentTheme.accentColor.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )

                VStack(spacing: 6) {
                    if viewModel.isGeneratingImage {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                    } else {
                        MorphSymbolView(
                            symbol: "sparkles",
                            config: MorphSymbolConfiguration(
                                font: .system(size: 24, weight: .medium),
                                frame: CGSize(width: 30, height: 30),
                                radius: 8,
                                foregroundColor: themeManager.currentTheme.accentColor,
                                keyFrameDuration: 0.3
                            )
                        )
                    }

                    Text("AI")
                        .font(.caption2.bold())
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
            .frame(width: 100, height: 100)
        }
        .disabled(viewModel.isGeneratingImage)
        .opacity(viewModel.isGeneratingImage ? 0.7 : 1.0)
    }

    // MARK: - Actions

    private func triggerEnhancement() {
        Task {
            // Update symbol to processing state with smooth animation
            enhanceSymbol = "sparkles"

            // Small delay to let the morph animation complete
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

            await self.viewModel?.processJournalEntry()

            // After processing completes, briefly show checkmark if still visible
            if !(self.viewModel?.hasEnhanced ?? false) {
                enhanceSymbol = "checkmark.circle"

                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                enhanceSymbol = "wand.and.sparkles"
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

// MARK: - Floating AI Button Component

private struct FloatingAIButton: View {
    let symbol: String
    let isProcessing: Bool
    var isPrimary: Bool = false
    let action: () -> Void

    @Environment(\.themeManager) private var themeManager
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background
                Circle()
                    .fill(
                        isPrimary
                            ? LinearGradient(
                                colors: [
                                    themeManager.currentTheme.accentColor,
                                    themeManager.currentTheme.accentColor.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [
                                    themeManager.currentTheme.surfaceColor,
                                    themeManager.currentTheme.surfaceColor.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                    )
                    .shadow(
                        color: isPrimary
                            ? themeManager.currentTheme.accentColor.opacity(0.4)
                            : Color.black.opacity(0.2),
                        radius: isPressed ? 4 : 8,
                        x: 0,
                        y: isPressed ? 2 : 4
                    )

                // Icon
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(
                            tint: isPrimary ? .white : themeManager.currentTheme.accentColor
                        ))
                } else {
                    MorphSymbolView(
                        symbol: symbol,
                        config: MorphSymbolConfiguration(
                            font: .system(size: isPrimary ? 22 : 18, weight: .semibold),
                            frame: CGSize(width: 28, height: 28),
                            radius: 8,
                            foregroundColor: isPrimary ? .white : themeManager.currentTheme.textPrimaryColor,
                            keyFrameDuration: 0.3
                        )
                    )
                }
            }
            .frame(width: isPrimary ? 56 : 44, height: isPrimary ? 56 : 44)
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .disabled(isProcessing)
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = pressing
                }
            },
            perform: { }
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let journalEntryUpdated = Notification.Name("journalEntryUpdated")
}
