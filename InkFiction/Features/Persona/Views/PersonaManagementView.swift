//
//  PersonaManagementView.swift
//  InkFiction
//
//  Full-screen persona management view with animated gradient background
//

import SwiftUI

struct PersonaManagementView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(Router.self) private var router

    @State private var personaRepository = PersonaRepository.shared
    @State private var personaImages: [ImageContainer] = []
    @State private var imageUpdateID = UUID()
    @State private var showDeleteConfirmation = false
    @State private var styleToDelete: AvatarStyle?
    @State private var showCannotDeleteLastStyleAlert = false
    @State private var selectedAvatarIndex = 0
    @State private var scrollOffset: CGFloat = 0

    private var navigationTitle: String {
        subscriptionService.currentTier == .free ? "Personas" : "Your Persona"
    }

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                // Navigation header
                NavigationHeaderView(
                    config: NavigationHeaderConfig(
                        title: navigationTitle,
                        leftButton: .back(action: { router.pop() }),
                        rightButton: subscriptionService.currentTier != .free && personaRepository.currentPersona != nil
                            ? .icon("pencil", action: { /* Edit action */ })
                            : .none
                    ),
                    scrollOffset: scrollOffset
                )

                // Content
                ScrollView(showsIndicators: false) {
                    if subscriptionService.currentTier == .free {
                        freeTierShowcaseContent
                    } else {
                        paidTierManagementContent
                    }
                }
            }
        }
        .task {
            if personaRepository.hasPersona == false {
                try? await personaRepository.loadPersona()
            }
            loadPersonaImages()
        }
        .onChange(of: personaRepository.currentPersona) { _, _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                loadPersonaImages()
                imageUpdateID = UUID()
            }
        }
        .alert("Delete Avatar Style?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { styleToDelete = nil }
            Button("Delete", role: .destructive) {
                if let style = styleToDelete {
                    confirmDeleteAvatarStyle(style)
                }
                styleToDelete = nil
            }
        } message: {
            if let style = styleToDelete {
                Text("Are you sure you want to delete the \(style.displayName) style?")
            }
        }
        .alert("Cannot Delete", isPresented: $showCannotDeleteLastStyleAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You must keep at least one avatar style.")
        }
    }

    // MARK: - Free Tier Showcase

    private var freeTierShowcaseContent: some View {
        VStack(spacing: 32) {
            // Hero section
            freeHeroSection

            // What are personas
            whatArePersonasCard

            // Benefits
            benefitsSection

            // Upgrade CTA
            upgradeCTAButton

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var freeHeroSection: some View {
        VStack(spacing: 20) {
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
                            startRadius: 40,
                            endRadius: 120
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)

                // Icon
                Image(systemName: "person.crop.circle.badge.sparkles")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: themeManager.currentTheme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: 8) {
                Text("AI Personas")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Text("Create personalized visual companions for your journal")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }

    private var whatArePersonasCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What are Personas?", systemImage: "sparkles")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

            Text("Personas are AI-generated visual representations that appear in your journal entries. They learn from your writing style and emotions to create consistent, personalized imagery.")
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Why Use Personas?", systemImage: "star.fill")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

            VStack(spacing: 12) {
                benefitRow(
                    icon: "photo.on.rectangle.angled",
                    title: "Consistent Visuals",
                    description: "AI images with your personal style"
                )
                benefitRow(
                    icon: "person.3.fill",
                    title: "Multiple Moods",
                    description: "Different personas for different moments"
                )
                benefitRow(
                    icon: "sparkles",
                    title: "Evolves With You",
                    description: "Adapts to your changing emotions"
                )
                benefitRow(
                    icon: "paintbrush.fill",
                    title: "5 Art Styles",
                    description: "Artistic, Cartoon, Minimalist & more"
                )
            }
        }
    }

    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: themeManager.currentTheme.gradientColors.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            colors: themeManager.currentTheme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    private var upgradeCTAButton: some View {
        Button(action: {
            // Show paywall
        }) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                    Text("Unlock Personas")
                        .font(.headline)
                }

                Text("Available in Enhanced & Premium")
                    .font(.caption)
                    .opacity(0.9)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                LinearGradient(
                    colors: themeManager.currentTheme.gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: themeManager.currentTheme.accentColor.opacity(0.4),
                radius: 20,
                x: 0,
                y: 10
            )
        }
    }

    // MARK: - Paid Tier Management

    private var paidTierManagementContent: some View {
        VStack(spacing: 24) {
            // Hero avatar section
            paidHeroSection

            // Avatar styles carousel
            if !personaImages.isEmpty {
                avatarStylesCarousel
            }

            // Create new style button
            createNewStyleButton

            // Tips section
            tipsSection

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var paidHeroSection: some View {
        VStack(spacing: 20) {
            ZStack {
                // Gradient glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                subscriptionService.currentTier.primaryGradientColor.opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 60,
                            endRadius: 140
                        )
                    )
                    .frame(width: 240, height: 240)
                    .blur(radius: 40)

                // Avatar circle
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 160, height: 160)

                    if let persona = personaRepository.currentPersona,
                       let avatarImage = persona.activeAvatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 160)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: subscriptionService.currentTier.uiGradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    // Border
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: subscriptionService.currentTier.uiGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 160, height: 160)
                }
                .shadow(
                    color: subscriptionService.currentTier.primaryGradientColor.opacity(0.3),
                    radius: 20,
                    x: 0,
                    y: 10
                )

                // Tier badge
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 36, height: 36)

                            Image(systemName: subscriptionService.currentTier.badgeIcon)
                                .font(.system(size: 16))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: subscriptionService.currentTier.uiGradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    Spacer()
                }
                .frame(width: 160, height: 160)
            }

            // Persona info
            if let persona = personaRepository.currentPersona {
                VStack(spacing: 8) {
                    Text(persona.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    Text("\(persona.avatars?.count ?? 0) avatar styles")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                    Text("Created \(formatLastUpdate(persona.updatedAt))")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
            } else {
                VStack(spacing: 8) {
                    Text("No Persona Yet")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    Text("Create your first persona to get started")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
            }
        }
    }

    private var avatarStylesCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Styles")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Spacer()

                Text("\(personaImages.count) styles")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
            }

            TabView(selection: $selectedAvatarIndex) {
                ForEach(Array(personaImages.enumerated()), id: \.element.id) { index, container in
                    AvatarStyleCard(
                        container: container,
                        isActive: index == 0, // First is active
                        themeManager: themeManager,
                        onDelete: { handleDeleteAvatarStyle(container) },
                        onSelect: { selectAvatarStyle(container) }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(height: 200)
            .id(imageUpdateID)
        }
    }

    private var createNewStyleButton: some View {
        Button(action: { router.showPersonaCreation() }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: themeManager.currentTheme.gradientColors.map { $0.opacity(0.2) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: themeManager.currentTheme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(personaRepository.currentPersona != nil ? "Add New Style" : "Create Persona")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    Text("Generate a new avatar variation")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: themeManager.currentTheme.gradientColors.map { $0.opacity(0.3) },
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1.5
                    )
            )
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tips", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

            VStack(spacing: 8) {
                tipRow(icon: "clock.arrow.circlepath", text: "Update your persona regularly for fresh visuals")
                tipRow(icon: "sparkles", text: "Personas create consistent AI images across entries")
                tipRow(icon: "checkmark.circle.fill", text: "Keep the same style for 2-4 weeks for consistency")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.accentColor)
                .frame(width: 16)

            Text(text)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    // MARK: - Helper Methods

    private func loadPersonaImages() {
        guard let persona = personaRepository.currentPersona else {
            personaImages = []
            return
        }

        var containers: [ImageContainer] = []
        for avatar in persona.avatars ?? [] {
            if let imageData = avatar.imageData,
               let image = UIImage(data: imageData) {
                let container = ImageContainer(
                    id: avatar.id,
                    uiImage: image,
                    caption: "\(avatar.style.captionPrefix) \(persona.name)",
                    date: avatar.createdAt
                )
                containers.append(container)
            }
        }

        personaImages = containers.sorted {
            guard let date1 = $0.date, let date2 = $1.date else {
                return $0.date != nil
            }
            return date1 > date2
        }
    }

    private func findAvatarStyle(for container: ImageContainer) -> AvatarStyle? {
        guard let persona = personaRepository.currentPersona else { return nil }
        return persona.avatars?.first { $0.id == container.id }?.style
    }

    private func handleDeleteAvatarStyle(_ container: ImageContainer) {
        guard let style = findAvatarStyle(for: container) else { return }
        guard let persona = personaRepository.currentPersona else { return }

        if (persona.avatars?.count ?? 0) == 1 {
            showCannotDeleteLastStyleAlert = true
            return
        }

        styleToDelete = style
        showDeleteConfirmation = true
    }

    private func confirmDeleteAvatarStyle(_ style: AvatarStyle) {
        guard let persona = personaRepository.currentPersona,
              let avatar = persona.avatar(for: style) else { return }

        Task {
            do {
                try await personaRepository.removeAvatar(avatar)
                loadPersonaImages()
            } catch {
                Log.error("Failed to delete avatar style", error: error, category: .persona)
            }
        }
    }

    private func selectAvatarStyle(_ container: ImageContainer) {
        guard let persona = personaRepository.currentPersona,
              let avatar = persona.avatars?.first(where: { $0.id == container.id }) else { return }

        Task {
            try? await personaRepository.setActiveAvatar(avatar)
        }
    }

    private func formatLastUpdate(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        switch days {
        case 0: return "today"
        case 1: return "yesterday"
        case 2...7: return "\(days) days ago"
        case 8...30: return "\(days / 7) weeks ago"
        case 31...365: return "\(days / 30) months ago"
        default: return "over a year ago"
        }
    }
}

// MARK: - Avatar Style Card

struct AvatarStyleCard: View {
    let container: ImageContainer
    let isActive: Bool
    let themeManager: ThemeManager
    var onDelete: (() -> Void)?
    var onSelect: (() -> Void)?

    @State private var showActions = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Image
                Image(uiImage: container.uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isActive
                                    ? themeManager.currentTheme.accentColor
                                    : Color.clear,
                                lineWidth: 3
                            )
                    )
                    .shadow(
                        color: isActive
                            ? themeManager.currentTheme.accentColor.opacity(0.3)
                            : Color.black.opacity(0.1),
                        radius: isActive ? 12 : 6,
                        x: 0,
                        y: isActive ? 6 : 3
                    )

                // Active badge
                if isActive {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.currentTheme.accentColor)
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 18, height: 18)
                                )
                        }
                        Spacer()
                    }
                    .frame(width: 120, height: 120)
                    .padding(4)
                }

                // Delete button on long press
                if showActions, let onDelete = onDelete {
                    VStack {
                        HStack {
                            Button(action: onDelete) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                                    .background(
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 22, height: 22)
                                    )
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .frame(width: 120, height: 120)
                    .padding(4)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .onTapGesture {
                if showActions {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showActions = false
                    }
                } else {
                    onSelect?()
                }
            }
            .onLongPressGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showActions = true
                }
            }

            // Caption
            if let caption = container.caption {
                Text(caption.components(separatedBy: " ").first ?? "")
                    .font(.caption)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundColor(
                        isActive
                            ? themeManager.currentTheme.accentColor
                            : themeManager.currentTheme.textSecondaryColor
                    )
            }
        }
    }
}
