//
//  PersonaCreationView.swift
//  InkFiction
//
//  Full-screen persona creation view with single-view flow
//

import Combine
import PhotosUI
import SwiftUI

struct PersonaCreationView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(Router.self) private var router
    @State private var viewModel = PersonaCreationViewModel()

    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var selectedStyles: Set<AvatarStyle> = []
    @State private var personaName = ""
    @State private var isGenerating = false
    @State private var generatedAvatars: [AvatarStyle: UIImage] = [:]
    @State private var failedStyles: Set<AvatarStyle> = []
    @State private var generationProgress: Double = 0
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var lastGenerationError: Error?
    @State private var saveCompleted = false
    @State private var showDeleteConfirmation = false
    @State private var containerToDelete: ImageContainer?
    @State private var scrollOffset: CGFloat = 0

    // Computed property to check if we have successfully generated content
    private var hasGeneratedContent: Bool {
        !generatedAvatars.isEmpty
    }

    // Convert generated avatars to ImageContainers for PolaroidCarousel
    private var generatedImageContainers: [ImageContainer] {
        generatedAvatars.keys.sorted(by: { $0.rawValue < $1.rawValue }).compactMap { style in
            guard let image = generatedAvatars[style] else { return nil }
            return ImageContainer(
                id: UUID(),
                uiImage: image,
                caption: "\(style.displayName) \(personaName)",
                date: Date()
            )
        }
    }

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()

            // Content
            VStack(spacing: 0) {
                // Navigation header
                NavigationHeaderView(
                    config: NavigationHeaderConfig(
                        title: isGenerating ? "Creating..." : (hasGeneratedContent ? personaName : "Create Persona"),
                        leftButton: isGenerating ? .none : .back(action: handleBackAction),
                        rightButton: .none
                    ),
                    scrollOffset: scrollOffset
                )

                // Main content - either input UI (with generation overlay) or generated avatars
                if hasGeneratedContent && !isGenerating {
                    // Generated avatars view (only after successful generation)
                    generatedAvatarsView
                } else {
                    // Input UI (shows generation overlay on photo when generating)
                    inputView
                }

                // Bottom action bar
                bottomActionBar
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .alert("Generation Failed", isPresented: $showErrorAlert) {
            Button("Retry") {
                retryFailedStyles()
            }
            Button("Continue Anyway", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Delete Avatar?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                containerToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let container = containerToDelete {
                    deleteAvatarByContainer(container)
                }
                containerToDelete = nil
            }
        } message: {
            if containerToDelete != nil {
                Text("Remove this avatar style?")
            }
        }
        .onAppear {
            resetState()
        }
    }

    // MARK: - Input View (Name, Photo, Styles)

    private var inputView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Name input (hide during generation)
                if !isGenerating {
                    nameInputSection
                }

                // Photo selection (with overlay during generation)
                photoSection

                // Style selection (show when photo selected, hide during generation)
                if selectedImage != nil && !isGenerating {
                    styleSelectionSection
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    // MARK: - Generated Avatars View

    private var generatedAvatarsView: some View {
        VStack(spacing: 24) {
            Spacer()

            if !generatedImageContainers.isEmpty {
                PolaroidCarousel(
                    images: generatedImageContainers,
                    onDelete: { container in
                        containerToDelete = container
                        showDeleteConfirmation = true
                    }
                )
                .frame(height: 420)
            }

            // Failed styles warning
            if !failedStyles.isEmpty {
                failedStylesWarning
                    .padding(.horizontal, 20)
            }

            Spacer()
        }
    }

    // MARK: - Name Input Section

    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Your Name", systemImage: "person.text.rectangle")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)

            TextField("How should we call you?", text: $personaName)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.vertical, 12)
                .padding(.horizontal, 4)
                .background(
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(
                                personaName.isEmpty
                                    ? themeManager.currentTheme.strokeColor.opacity(0.3)
                                    : themeManager.currentTheme.accentColor.opacity(0.6)
                            )
                            .frame(height: 2)
                    }
                )
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(spacing: 16) {
            if let image = selectedImage {
                // Selected image display with generation overlay
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: themeManager.currentTheme.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )

                    // Generation overlay (shown during generation)
                    if isGenerating {
                        GenerationProgressOverlay(
                            progress: generationProgress,
                            selectedStyles: Array(selectedStyles),
                            themeManager: themeManager
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Change photo button (hide during generation)
                if !isGenerating {
                    Button(action: {
                        selectedImage = nil
                        generatedAvatars = [:]
                        failedStyles = []
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14))
                            Text("Change Photo")
                                .font(.subheadline)
                        }
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(themeManager.currentTheme.surfaceColor.opacity(themeManager.currentTheme.isLight ? 0.8 : 0.3))
                        )
                    }
                }
            } else {
                // Photo picker card
                PhotoPickerCard(
                    themeManager: themeManager,
                    action: { showImagePicker = true }
                )
                .frame(height: 280)
            }
        }
    }

    // MARK: - Style Selection Section

    private var styleSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Avatar Styles", systemImage: "paintpalette")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                Spacer()

                Text("\(selectedStyles.count)/3 selected")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(themeManager.currentTheme.accentColor.opacity(0.15))
                    )
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AvatarStyle.allCases, id: \.self) { style in
                        StyleSelectionCard(
                            style: style,
                            isSelected: selectedStyles.contains(style),
                            themeManager: themeManager
                        ) {
                            toggleStyle(style)
                        }
                        .frame(width: 100)
                    }
                }
            }
        }
    }

    // MARK: - Failed Styles Warning

    private var failedStylesWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("\(failedStyles.count) style\(failedStyles.count == 1 ? "" : "s") failed to generate")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)

            Spacer()

            Button("Retry") {
                retryFailedStyles()
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(themeManager.currentTheme.accentColor)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(themeManager.currentTheme.dividerColor)
                .frame(height: 1)

            HStack(spacing: 12) {
                // Back button (only show when we have generated content)
                if hasGeneratedContent && !isGenerating && !saveCompleted {
                    Button(action: goBackToInput) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Edit")
                        }
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(themeManager.currentTheme.surfaceColor.opacity(themeManager.currentTheme.isLight ? 0.8 : 0.3))
                        )
                    }
                    .frame(maxWidth: 100)
                }

                // Main action button
                Button(action: handleMainAction) {
                    mainActionButtonContent
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            canPerformAction
                                ? LinearGradient(
                                    colors: themeManager.currentTheme.gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [themeManager.currentTheme.surfaceColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                )
                .disabled(!canPerformAction || viewModel.isCreating || isGenerating)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(themeManager.currentTheme.surfaceColor.opacity(themeManager.currentTheme.isLight ? 0.95 : 0.5))
        }
    }

    @ViewBuilder
    private var mainActionButtonContent: some View {
        if saveCompleted {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                Text("Persona Created!")
                    .font(.headline)
            }
            .foregroundColor(.white)
        } else if viewModel.isCreating {
            HStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.9)
                Text("Saving...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        } else if isGenerating {
            HStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.9)
                Text("Generating...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        } else if !generatedAvatars.isEmpty {
            // Have generated avatars - show save button
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                Text("Save Persona")
                    .font(.headline)
            }
            .foregroundColor(.white)
        } else if selectedImage != nil && !selectedStyles.isEmpty {
            // Ready to generate
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 18, weight: .semibold))
                Text("Generate Avatars")
                    .font(.headline)
            }
            .foregroundColor(.white)
        } else {
            Text("Select photo & styles")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
        }
    }

    // MARK: - State & Logic

    private var canPerformAction: Bool {
        let hasValidName = !personaName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if !generatedAvatars.isEmpty {
            return hasValidName
        } else {
            return selectedImage != nil && !selectedStyles.isEmpty && hasValidName
        }
    }

    private func resetState() {
        generatedAvatars = [:]
        failedStyles = []
        generationProgress = 0
        isGenerating = false
        saveCompleted = false
        lastGenerationError = nil
        Log.info("PersonaCreationView appeared - reset to initial state", category: .persona)
    }

    private func handleBackAction() {
        if hasGeneratedContent && !isGenerating {
            goBackToInput()
        } else {
            router.pop()
        }
    }

    private func goBackToInput() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            generatedAvatars = [:]
            failedStyles = []
        }
    }

    private func toggleStyle(_ style: AvatarStyle) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedStyles.contains(style) {
                selectedStyles.remove(style)
            } else if selectedStyles.count < 3 {
                selectedStyles.insert(style)
            }
        }
    }

    private func deleteAvatarByContainer(_ container: ImageContainer) {
        // Find the style by matching the caption
        guard let caption = container.caption else { return }

        for style in AvatarStyle.allCases {
            if caption.hasPrefix(style.displayName) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    generatedAvatars.removeValue(forKey: style)
                    selectedStyles.remove(style)
                    failedStyles.remove(style)
                }

                // If no avatars left, go back to input
                if generatedAvatars.isEmpty {
                    goBackToInput()
                }
                break
            }
        }
    }

    private func handleMainAction() {
        if !generatedAvatars.isEmpty {
            savePersona()
        } else {
            startGeneration()
        }
    }

    private func startGeneration() {
        guard let image = selectedImage, !selectedStyles.isEmpty else { return }

        isGenerating = true
        generationProgress = 0
        failedStyles = []
        generatedAvatars = [:]
        lastGenerationError = nil

        Task {
            await generateAvatars(image: image, styles: Array(selectedStyles))

            await MainActor.run {
                isGenerating = false

                // Show error if any styles failed
                if !failedStyles.isEmpty && generatedAvatars.isEmpty {
                    if let error = lastGenerationError {
                        errorMessage = error.localizedDescription
                    } else {
                        errorMessage = "Failed to generate avatars. The AI service may be temporarily unavailable."
                    }
                    showErrorAlert = true
                } else if !failedStyles.isEmpty {
                    if let error = lastGenerationError {
                        errorMessage = "\(failedStyles.count) avatar(s) failed: \(error.localizedDescription)"
                    } else {
                        errorMessage = "\(failedStyles.count) avatar(s) failed to generate. You can retry or continue with the successful ones."
                    }
                    showErrorAlert = true
                }
            }
        }
    }

    private func retryFailedStyles() {
        guard let image = selectedImage, !failedStyles.isEmpty else { return }

        let stylesToRetry = Array(failedStyles)
        failedStyles = []
        lastGenerationError = nil

        isGenerating = true
        generationProgress = 0

        Task {
            await generateAvatars(image: image, styles: stylesToRetry)

            await MainActor.run {
                isGenerating = false

                if !failedStyles.isEmpty {
                    if let error = lastGenerationError {
                        errorMessage = error.localizedDescription
                    } else {
                        errorMessage = "\(failedStyles.count) avatar(s) still failed. The AI service may be unavailable."
                    }
                    showErrorAlert = true
                }
            }
        }
    }

    private func generateAvatars(image: UIImage, styles: [AvatarStyle]) async {
        let imageGenerationService = ImageGenerationService.shared

        guard let referenceImageData = image.jpegData(compressionQuality: 0.8) else {
            await MainActor.run {
                failedStyles = Set(styles)
            }
            return
        }

        let displayName = personaName.trimmingCharacters(in: .whitespacesAndNewlines)
        let tempPersona = PersonaProfileModel(name: displayName)

        for (index, style) in styles.enumerated() {
            do {
                let generatedImageData = try await imageGenerationService.generatePersonaAvatar(
                    persona: tempPersona,
                    style: style,
                    referenceImage: referenceImageData
                ) { progress in
                    Task { @MainActor in
                        let baseProgress = Double(index) / Double(styles.count)
                        let styleProgress = progress / Double(styles.count)
                        self.generationProgress = baseProgress + styleProgress
                    }
                }

                guard let generatedImage = UIImage(data: generatedImageData) else {
                    Log.warning("Failed to convert generated image data for style: \(style.rawValue)", category: .persona)
                    _ = await MainActor.run { [style] in
                        self.failedStyles.insert(style)
                    }
                    continue
                }

                _ = await MainActor.run { [style, generatedImage, index, styles] in
                    self.generatedAvatars[style] = generatedImage
                    self.generationProgress = Double(index + 1) / Double(styles.count)
                }

            } catch {
                Log.error("Avatar generation failed for style \(style.rawValue)", error: error, category: .persona)
                _ = await MainActor.run { [style, error] in
                    self.failedStyles.insert(style)
                    self.lastGenerationError = error
                }
            }
        }
    }

    private func savePersona() {
        guard let image = selectedImage, !generatedAvatars.isEmpty else { return }

        Task {
            await viewModel.savePersona(
                name: personaName.trimmingCharacters(in: .whitespacesAndNewlines),
                photo: image,
                generatedAvatars: generatedAvatars
            )

            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    saveCompleted = true
                }
            }

            try? await Task.sleep(nanoseconds: 1_200_000_000)

            await MainActor.run {
                router.pop()
            }
        }
    }
}

// MARK: - Style Selection Card

struct StyleSelectionCard: View {
    let style: AvatarStyle
    let isSelected: Bool
    let themeManager: ThemeManager
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: themeManager.currentTheme.gradientColors.map { $0.opacity(0.2) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [themeManager.currentTheme.surfaceColor.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(height: 70)

                    Image(systemName: style.icon)
                        .font(.system(size: 24))
                        .foregroundColor(
                            isSelected
                                ? themeManager.currentTheme.accentColor
                                : style.previewColor
                        )

                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                            Spacer()
                        }
                        .padding(6)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected
                                ? themeManager.currentTheme.accentColor
                                : Color.clear,
                            lineWidth: 2
                        )
                )

                Text(style.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(
                        isSelected
                            ? themeManager.currentTheme.accentColor
                            : themeManager.currentTheme.textSecondaryColor
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Photo Picker Card

struct PhotoPickerCard: View {
    let themeManager: ThemeManager
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    themeManager.currentTheme.accentColor.opacity(0.2),
                                    themeManager.currentTheme.accentColor.opacity(0.05)
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)

                    Circle()
                        .fill(themeManager.currentTheme.surfaceColor.opacity(themeManager.currentTheme.isLight ? 0.9 : 0.3))
                        .frame(width: 100, height: 100)

                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: themeManager.currentTheme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(spacing: 6) {
                    Text("Choose a Photo")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    Text("Select from your library")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.currentTheme.surfaceColor.opacity(themeManager.currentTheme.isLight ? 0.8 : 0.25))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        themeManager.currentTheme.strokeColor.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Generation Progress Overlay

struct GenerationProgressOverlay: View {
    let progress: Double
    let selectedStyles: [AvatarStyle]
    let themeManager: ThemeManager

    @State private var currentStyleIndex = 0
    private let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    private var stylesToAnimate: [AvatarStyle] {
        selectedStyles.isEmpty
            ? [.artistic, .cartoon, .minimalist]
            : selectedStyles
    }

    private var currentStyle: AvatarStyle {
        stylesToAnimate[currentStyleIndex % stylesToAnimate.count]
    }

    var body: some View {
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: 24)
                .fill(themeManager.currentTheme.surfaceColor.opacity(themeManager.currentTheme.isLight ? 0.95 : 0.8))
                .shadow(color: themeManager.currentTheme.accentColor.opacity(0.2), radius: 20, y: 10)

            // Content
            VStack(spacing: 24) {
                // Morphing icon
                MorphSymbolView(
                    symbol: currentStyle.icon,
                    config: MorphSymbolConfiguration(
                        font: .system(size: 44, weight: .medium),
                        frame: CGSize(width: 80, height: 80),
                        radius: 15,
                        foregroundColor: themeManager.currentTheme.accentColor,
                        keyFrameDuration: 0.4
                    )
                )

                VStack(spacing: 8) {
                    Text("Creating")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                    Text(currentStyle.displayName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: themeManager.currentTheme.gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .contentTransition(.interpolate)
                        .animation(.easeInOut(duration: 0.3), value: currentStyleIndex)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(themeManager.currentTheme.surfaceColor)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: themeManager.currentTheme.gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.easeInOut, value: progress)
                    }
                }
                .frame(height: 8)
                .frame(width: 180)
            }
            .padding(32)
        }
        .onReceive(timer) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentStyleIndex = (currentStyleIndex + 1) % stylesToAnimate.count
            }
        }
    }
}
