//
//  NavigationHeaderView.swift
//  InkFiction
//
//  Reusable navigation header with avatar button and title
//

import SwiftUI

// MARK: - Navigation Header Configuration

struct NavigationHeaderConfig {
    enum LeftButtonType {
        case avatar(action: () -> Void)
        case back(action: () -> Void)
        case icon(String, action: () -> Void)
        case none
    }

    enum RightButtonType {
        case icon(String, action: () -> Void)
        case none
    }

    let title: String
    let subtitle: String?
    let leftButton: LeftButtonType
    let rightButton: RightButtonType

    init(
        title: String,
        subtitle: String? = nil,
        leftButton: LeftButtonType = .avatar(action: {}),
        rightButton: RightButtonType = .none
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leftButton = leftButton
        self.rightButton = rightButton
    }
}

// MARK: - Navigation Header View

struct NavigationHeaderView: View {
    @Environment(\.themeManager) private var themeManager

    let config: NavigationHeaderConfig
    let scrollOffset: CGFloat

    private let personaRepository = PersonaRepository.shared
    @State private var avatarImage: UIImage?
    @State private var showingPersonaSheet = false

    init(config: NavigationHeaderConfig, scrollOffset: CGFloat = 0) {
        self.config = config
        self.scrollOffset = scrollOffset
    }

    private var showBackground: Bool {
        scrollOffset < -10
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Left: Configurable button
            leftButtonView

            // Center: Title and subtitle
            Spacer()

            VStack(spacing: 2) {
                Text(config.title)
                    .font(.system(size: showBackground ? 18 : 24, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                    .animation(.easeInOut(duration: 0.2), value: showBackground)

                if let subtitle = config.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        .opacity(showBackground ? 0 : 1)
                        .animation(.easeInOut(duration: 0.2), value: showBackground)
                }
            }

            Spacer()

            // Right: Configurable button
            rightButtonView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        .animation(.easeInOut(duration: 0.2), value: showBackground)
    }

    // MARK: - Left Button

    @ViewBuilder
    private var leftButtonView: some View {
        switch config.leftButton {
        case .avatar(let action):
            avatarButton(action: action)
        case .back(let action):
            backButton(action: action)
        case .icon(let iconName, let action):
            iconButton(systemName: iconName, action: action)
        case .none:
            Color.clear.frame(width: 44, height: 44)
        }
    }

    private func avatarButton(action: @escaping () -> Void) -> some View {
        Button(action: {
            showingPersonaSheet = true
        }) {
            ZStack {
                Circle()
                    .fill(themeManager.currentTheme.surfaceColor)
                    .frame(width: 44, height: 44)

                if let image = avatarImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                }

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: themeManager.currentTheme.gradientColors.map {
                                $0.opacity(0.3)
                            },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 44, height: 44)
            }
        }
        .onAppear {
            loadAvatarImage()
        }
        .sheet(isPresented: $showingPersonaSheet) {
            PersonaDetailSheet()
        }
    }

    private func backButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(themeManager.currentTheme.surfaceColor)
                    .frame(width: 44, height: 44)

                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Circle()
                    .stroke(
                        themeManager.currentTheme.strokeColor.opacity(0.3),
                        lineWidth: 1.5
                    )
                    .frame(width: 44, height: 44)
            }
        }
    }

    private func iconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(themeManager.currentTheme.surfaceColor)
                    .frame(width: 44, height: 44)

                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Circle()
                    .stroke(
                        themeManager.currentTheme.strokeColor.opacity(0.3),
                        lineWidth: 1.5
                    )
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Right Button

    @ViewBuilder
    private var rightButtonView: some View {
        switch config.rightButton {
        case .icon(let iconName, let action):
            iconButton(systemName: iconName, action: action)
        case .none:
            Color.clear.frame(width: 44, height: 44)
        }
    }

    // MARK: - Helper Methods

    private func loadAvatarImage() {
        guard let persona = personaRepository.currentPersona,
              let activeAvatarId = persona.activeAvatarId,
              let avatar = persona.avatars?.first(where: { $0.id == activeAvatarId }),
              let imageData = avatar.imageData else {
            avatarImage = nil
            return
        }
        avatarImage = UIImage(data: imageData)
    }
}

// MARK: - Persona Detail Sheet (Placeholder)

struct PersonaDetailSheet: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss

    private let personaRepository = PersonaRepository.shared

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Avatar display
                    if let persona = personaRepository.currentPersona {
                        avatarView(for: persona)

                        Text(persona.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                        if let bio = persona.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Avatar styles carousel
                        if let avatars = persona.avatars, !avatars.isEmpty {
                            avatarStylesSection(persona: persona, avatars: avatars)
                        }
                    } else {
                        noPersonaView
                    }

                    Spacer()
                }
                .padding(.top, 32)
            }
            .navigationTitle("Your Persona")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
    }

    @ViewBuilder
    private func avatarView(for persona: PersonaProfileModel) -> some View {
        ZStack {
            Circle()
                .fill(themeManager.currentTheme.surfaceColor)
                .frame(width: 120, height: 120)

            if let activeAvatarId = persona.activeAvatarId,
               let avatar = persona.avatars?.first(where: { $0.id == activeAvatarId }),
               let imageData = avatar.imageData,
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 60))
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
            }

            Circle()
                .stroke(
                    LinearGradient(
                        colors: themeManager.currentTheme.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 120, height: 120)
        }
    }

    @ViewBuilder
    private func avatarStylesSection(persona: PersonaProfileModel, avatars: [PersonaAvatarModel]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Avatar Styles")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(avatars) { avatar in
                        avatarStyleCard(avatar: avatar, isActive: avatar.id == persona.activeAvatarId)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private func avatarStyleCard(avatar: PersonaAvatarModel, isActive: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                if let imageData = avatar.imageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.currentTheme.surfaceColor)
                        .frame(width: 70, height: 70)

                    Image(systemName: avatar.style.icon)
                        .font(.title2)
                        .foregroundColor(avatar.style.previewColor)
                }

                if isActive {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.currentTheme.accentColor, lineWidth: 2)
                        .frame(width: 70, height: 70)
                }
            }

            Text(avatar.style.displayName)
                .font(.caption)
                .foregroundColor(
                    isActive
                        ? themeManager.currentTheme.accentColor
                        : themeManager.currentTheme.textSecondaryColor
                )
        }
        .onTapGesture {
            Task {
                try? await PersonaRepository.shared.setActiveAvatar(avatar)
            }
        }
    }

    private var noPersonaView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)

            Text("No Persona Created")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

            Text("Create a persona to personalize your journal experience")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}
