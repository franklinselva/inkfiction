//
//  PersonaCreationView.swift
//  InkFiction
//
//  Full-screen persona creation view with animated gradient background
//

import Combine
import PhotosUI
import SwiftUI

struct PersonaCreationView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(Router.self) private var router
    @State private var viewModel = PersonaCreationViewModel()

    @State private var currentStep: CreationStep = .photo
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var selectedStyles: Set<AvatarStyle> = []
    @State private var personaName = ""
    @State private var isGenerating = false
    @State private var generatedStyles: [AvatarStyle: UIImage] = [:]
    @State private var generationProgress: Double = 0
    @State private var selectedImageContainers: [ImageContainer] = []
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var saveCompleted = false
    @State private var showDeleteConfirmation = false
    @State private var containerToDelete: ImageContainer?
    @State private var scrollOffset: CGFloat = 0

    enum CreationStep: Int, CaseIterable {
        case photo = 0
        case style = 1

        var title: String {
            switch self {
            case .photo: return "Select Photo"
            case .style: return "Review Variations"
            }
        }

        var subtitle: String {
            switch self {
            case .photo: return "Pick a photo and choose up to 3 styles"
            case .style: return "Choose your favorite variation for your persona"
            }
        }

        var icon: String {
            switch self {
            case .photo: return "photo.on.rectangle"
            case .style: return "sparkles.rectangle.stack"
            }
        }
    }

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()

            // Glass overlay for content
            VStack(spacing: 0) {
                // Navigation header
                NavigationHeaderView(
                    config: NavigationHeaderConfig(
                        title: "Create Persona",
                        leftButton: .back(action: handleCloseAction),
                        rightButton: .none
                    ),
                    scrollOffset: scrollOffset
                )

                // Step indicators
                stepIndicators
                    .padding(.top, 8)

                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header with icon
                        headerSection

                        // Step content
                        Group {
                            switch currentStep {
                            case .photo:
                                photoSelectionStep
                            case .style:
                                styleSelectionStep
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 120)
                    }
                }

                // Bottom action
                bottomActionBar
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .alert("Generation Error", isPresented: $showErrorAlert) {
            Button("Retry") {
                startGeneration()
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Delete This Style?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                containerToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let container = containerToDelete {
                    confirmDeleteGeneratedStyle(container)
                }
                containerToDelete = nil
            }
        } message: {
            if let container = containerToDelete,
               let caption = container.caption {
                let styleName = caption.components(separatedBy: " ").first ?? "style"
                Text("Are you sure you want to delete this \(styleName) style?")
            }
        }
        .onAppear {
            resetState()
        }
    }

    // MARK: - Step Indicators

    private var stepIndicators: some View {
        HStack(spacing: 16) {
            ForEach(CreationStep.allCases, id: \.rawValue) { step in
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                step.rawValue <= currentStep.rawValue
                                    ? LinearGradient(
                                        colors: themeManager.currentTheme.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [themeManager.currentTheme.surfaceColor],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                            .frame(width: 32, height: 32)

                        Image(systemName: step.icon)
                            .font(.system(size: 14))
                            .foregroundColor(
                                step.rawValue <= currentStep.rawValue
                                    ? .white
                                    : themeManager.currentTheme.textSecondaryColor
                            )
                    }

                    if step != CreationStep.allCases.last {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                step.rawValue < currentStep.rawValue
                                    ? themeManager.currentTheme.accentColor
                                    : themeManager.currentTheme.surfaceColor
                            )
                            .frame(width: 40, height: 3)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: themeManager.currentTheme.gradientColors.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)

                Image(systemName: currentStep.icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: themeManager.currentTheme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, options: .repeating)
            }
            .padding(.top, 20)

            Text(currentStep.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

            Text(currentStep.subtitle)
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Photo Selection Step

    private var photoSelectionStep: some View {
        VStack(spacing: 20) {
            // Name input card
            VStack(alignment: .leading, spacing: 8) {
                Label("Your Name", systemImage: "person.text.rectangle")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                TextField("How should we call you?", text: $personaName)
                    .font(.body)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                personaName.isEmpty
                                    ? themeManager.currentTheme.strokeColor.opacity(0.3)
                                    : themeManager.currentTheme.accentColor.opacity(0.5),
                                lineWidth: 1
                            )
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )

            // Image selection
            PersonaImageCarouselView(
                selectedImage: $selectedImage,
                showImagePicker: $showImagePicker,
                isGenerating: $isGenerating,
                generationProgress: $generationProgress,
                selectedStyles: selectedStyles,
                themeManager: themeManager
            )

            // Style selection
            if selectedImage != nil && !isGenerating {
                styleSelectionCard
            }
        }
    }

    private var styleSelectionCard: some View {
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

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(AvatarStyle.allCases, id: \.self) { style in
                    StyleSelectionCard(
                        style: style,
                        isSelected: selectedStyles.contains(style),
                        themeManager: themeManager
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if selectedStyles.contains(style) {
                                selectedStyles.remove(style)
                            } else if selectedStyles.count < 3 {
                                selectedStyles.insert(style)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Style Selection Step

    private var styleSelectionStep: some View {
        VStack(spacing: 24) {
            if !selectedImageContainers.isEmpty {
                // Generated images carousel
                TabView {
                    ForEach(selectedImageContainers, id: \.id) { container in
                        GeneratedAvatarCard(
                            container: container,
                            themeManager: themeManager,
                            onDelete: { handleDeleteGeneratedStyle(container) }
                        )
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: 380)

                // Generated styles summary
                VStack(spacing: 12) {
                    Text("Your Personas")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    HStack(spacing: 8) {
                        ForEach(Array(selectedStyles), id: \.self) { style in
                            HStack(spacing: 4) {
                                Image(systemName: style.icon)
                                    .font(.system(size: 12))
                                Text(style.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: themeManager.currentTheme.gradientColors,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
            }
        }
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            // Glass divider
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: 1)

            HStack(spacing: 12) {
                if currentStep == .style && !saveCompleted {
                    Button(action: previousStep) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial)
                        )
                    }
                    .frame(maxWidth: 120)
                }

                Button(action: handleNextAction) {
                    nextActionButtonContent
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            canProceed
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
                .disabled(!canProceed || viewModel.isCreating)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private var nextActionButtonContent: some View {
        Group {
            if currentStep == .photo && selectedImage != nil {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Generate Avatars")
                        .font(.headline)
                }
                .foregroundColor(.white)
            } else if currentStep == .style {
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
                        Text("Creating...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                        Text("Bring to Life")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                }
            } else {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(
                        canProceed
                            ? .white
                            : themeManager.currentTheme.textSecondaryColor
                    )
            }
        }
    }

    // MARK: - State & Actions

    private var canProceed: Bool {
        switch currentStep {
        case .photo:
            return selectedImage != nil && !personaName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .style:
            return !selectedImageContainers.isEmpty
        }
    }

    private func resetState() {
        currentStep = .photo
        generatedStyles = [:]
        selectedImageContainers = []
        generationProgress = 0
        isGenerating = false
        saveCompleted = false
        Log.info("PersonaCreationView appeared - reset to initial state", category: .persona)
    }

    private func handleNextAction() {
        if currentStep == .photo && selectedImage != nil {
            startGeneration()
        } else if currentStep == .style {
            createPersona()
        }
    }

    private func handleCloseAction() {
        if currentStep == .style {
            previousStep()
        } else {
            router.pop()
        }
    }

    private func previousStep() {
        if let prevStep = CreationStep(rawValue: currentStep.rawValue - 1) {
            selectedImageContainers = []
            generatedStyles = [:]
            generationProgress = 0

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStep = prevStep
            }
        }
    }

    private func handleDeleteGeneratedStyle(_ container: ImageContainer) {
        containerToDelete = container
        showDeleteConfirmation = true
    }

    private func confirmDeleteGeneratedStyle(_ container: ImageContainer) {
        guard let caption = container.caption else { return }

        let prefix = caption.components(separatedBy: " ").first ?? ""
        guard let style = AvatarStyle.allCases.first(where: { $0.captionPrefix == prefix }) else { return }

        generatedStyles.removeValue(forKey: style)
        selectedImageContainers.removeAll { $0.id == container.id }
        selectedStyles.remove(style)

        if selectedImageContainers.isEmpty {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStep = .photo
            }
        }
    }

    private func startGeneration() {
        guard let image = selectedImage else { return }

        isGenerating = true
        generationProgress = 0
        selectedImageContainers = []
        generatedStyles = [:]

        Task {
            let stylesToGenerate = selectedStyles.isEmpty ? [AvatarStyle.artistic] : Array(selectedStyles)
            let displayName = personaName.trimmingCharacters(in: .whitespacesAndNewlines)

            do {
                try await simulateGeneration(image: image, styles: stylesToGenerate, name: displayName)

                await MainActor.run {
                    isGenerating = false
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .style
                    }
                }
            } catch {
                Log.error("Avatar generation error", error: error, category: .persona)
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }

    private func simulateGeneration(image: UIImage, styles: [AvatarStyle], name: String) async throws {
        for (index, style) in styles.enumerated() {
            try await Task.sleep(nanoseconds: 500_000_000)

            await MainActor.run {
                let progress = Double(index + 1) / Double(styles.count)
                generationProgress = progress

                generatedStyles[style] = image

                let caption = "\(style.captionPrefix) \(name)"
                let container = ImageContainer(
                    id: UUID(),
                    uiImage: image,
                    caption: caption,
                    date: Date()
                )
                selectedImageContainers.append(container)
            }
        }
    }

    private func createPersona() {
        guard let image = selectedImage else { return }

        Task {
            await viewModel.savePersona(
                name: personaName.trimmingCharacters(in: .whitespacesAndNewlines),
                photo: image,
                generatedAvatars: generatedStyles
            )

            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    saveCompleted = true
                }
            }

            try? await Task.sleep(nanoseconds: 1_200_000_000)

            await MainActor.run {
                router.popToRoot()
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

// MARK: - Generated Avatar Card

struct GeneratedAvatarCard: View {
    let container: ImageContainer
    let themeManager: ThemeManager
    var onDelete: (() -> Void)?

    @State private var showDelete = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                themeManager.currentTheme.accentColor.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 80,
                            endRadius: 180
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 30)

                // Avatar image
                Image(uiImage: container.uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 240, height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: themeManager.currentTheme.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )
                        .shadow(
                            color: themeManager.currentTheme.accentColor.opacity(0.3),
                            radius: 20,
                            x: 0,
                            y: 10
                        )

                // Delete button
                if showDelete, let onDelete = onDelete {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: onDelete) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 30, height: 30)
                                    )
                            }
                        }
                        Spacer()
                    }
                    .frame(width: 240, height: 240)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .onTapGesture {
                if onDelete != nil {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showDelete.toggle()
                    }
                }
            }

            // Caption
            if let caption = container.caption {
                Text(caption)
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Persona Image Carousel View

struct PersonaImageCarouselView: View {
    @Binding var selectedImage: UIImage?
    @Binding var showImagePicker: Bool
    @Binding var isGenerating: Bool
    @Binding var generationProgress: Double
    var selectedStyles: Set<AvatarStyle>
    let themeManager: ThemeManager

    private var carouselHeight: CGFloat {
        guard let image = selectedImage else { return 280 }
        let ratio = image.size.width / image.size.height
        let width = UIScreen.main.bounds.width - 40
        let height = width / ratio
        return min(400, max(200, height))
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                if let image = selectedImage {
                    // Selected image display
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: carouselHeight)
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

                        // Success badge
                        VStack {
                            Spacer()
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Photo Ready")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.green)
                                )
                                .shadow(radius: 4)

                                Spacer()
                            }
                            .padding(16)
                        }
                    }

                    // Generation overlay
                    if isGenerating {
                        GenerationProgressOverlay(
                            progress: generationProgress,
                            selectedStyles: Array(selectedStyles),
                            themeManager: themeManager
                        )
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

            // Change photo button
            if selectedImage != nil && !isGenerating {
                Button(action: { selectedImage = nil }) {
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
                            .fill(.ultraThinMaterial)
                    )
                }
            }
        }
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
                        .fill(.ultraThinMaterial)
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
                    .fill(.ultraThinMaterial)
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

    private var stylesToAnimate: [String] {
        selectedStyles.isEmpty
            ? ["Artistic", "Creative", "Unique"]
            : selectedStyles.map { $0.displayName }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay(
                VStack(spacing: 24) {
                    // Animated icon
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: themeManager.currentTheme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.variableColor.iterative.reversing)

                    VStack(spacing: 8) {
                        Text("Creating")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                        Text(stylesToAnimate[currentStyleIndex])
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: themeManager.currentTheme.gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .contentTransition(.numericText())
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
            )
            .onReceive(timer) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStyleIndex = (currentStyleIndex + 1) % stylesToAnimate.count
                }
            }
    }
}
