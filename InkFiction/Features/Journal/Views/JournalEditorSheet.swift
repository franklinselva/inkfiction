//
//  JournalEditorSheet.swift
//  InkFiction
//
//  Sheet view for creating and editing journal entries
//

import Combine
import PhotosUI
import SwiftData
import SwiftUI

struct JournalEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeManager) private var themeManager
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: JournalEditorViewModel
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isTextEditorFocused: Bool
    @State private var showingMoodPicker = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isImageContainerPressed = false

    init(existingEntry: JournalEntry? = nil) {
        _viewModel = State(initialValue: JournalEditorViewModel(existingEntry: existingEntry))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Text entry section
                        textEntrySection

                        // Image section
                        imageSection

                        // Enhanced content section (mood, tags)
                        if viewModel.canSave {
                            enhancedContentSection
                        }
                    }
                    .padding()
                    .padding(.bottom, keyboardHeight)
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Entry" : "New Entry")
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
                    if viewModel.canSave {
                        Button(action: saveEntry) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        }
                        .transition(.opacity.combined(with: .scale))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.canSave)
                    }
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(viewModel.isProcessing)
            .onReceive(keyboardPublisher) { height in
                withAnimation(.easeInOut(duration: 0.25)) {
                    keyboardHeight = height
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Add Tag", isPresented: $viewModel.showAddTag) {
                TextField("Enter tag", text: $viewModel.newTagText)
                Button("Cancel", role: .cancel) {
                    viewModel.newTagText = ""
                }
                Button("Add") {
                    viewModel.addTag(viewModel.newTagText)
                }
            } message: {
                Text("Add a tag to categorize your entry")
            }
            .alert("Photo Access Required", isPresented: $viewModel.showPhotoPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("InkFiction needs access to your photo library to attach photos to journal entries.")
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }

    // MARK: - Text Entry Section

    private var textEntrySection: some View {
        VStack(spacing: 16) {
            titleField
            textEditor
        }
    }

    private var titleField: some View {
        HStack {
            TextField("Title (optional)", text: $viewModel.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.surfaceColor)
        )
    }

    private var textEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $viewModel.content)
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

    // MARK: - Image Section

    private var imageSection: some View {
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
                                        viewModel.removeImage(at: index)
                                    }
                                }
                            )
                        }

                        // Add more photos button
                        addPhotosButton
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
                await viewModel.checkPhotoPermission()
                await viewModel.loadImages(from: newItems)
                selectedPhotoItems = []
            }
        }
    }

    private var addPhotosButton: some View {
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

    private var enhancedContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MoodSelectorView(
                selectedMood: $viewModel.mood,
                isExpanded: $showingMoodPicker
            )

            TagsSectionView(tags: $viewModel.tags)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.canSave)
    }

    // MARK: - Actions

    private func saveEntry() {
        guard viewModel.validate() else { return }

        Task {
            do {
                try await viewModel.save()
                dismiss()
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

// MARK: - Image Thumbnail View

struct ImageThumbnailView: View {
    let image: JournalImage
    let onRemove: () -> Void

    @Environment(\.themeManager) private var themeManager

    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = image.uiImage {
                ZStack(alignment: .bottomLeading) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    image.isAIGenerated
                                        ? LinearGradient(
                                            colors: themeManager.currentTheme.gradientColors,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            colors: [themeManager.currentTheme.surfaceColor],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                    lineWidth: image.isAIGenerated ? 2 : 1
                                )
                        )

                    // AI Badge
                    if image.isAIGenerated {
                        HStack(spacing: 2) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10, weight: .bold))
                            Text("AI")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: themeManager.currentTheme.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .padding(6)
                    }
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.surfaceColor)
                    .frame(width: 100, height: 100)
                    .overlay(
                        ProgressView()
                    )
            }

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 22, height: 22)
                    )
            }
            .offset(x: 8, y: -8)
        }
        .onLongPressGesture(
            minimumDuration: 0.1,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: { }
        )
    }
}
