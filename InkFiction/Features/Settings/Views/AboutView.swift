//
//  AboutView.swift
//  InkFiction
//
//  About app view with version info and links
//

import SwiftUI

struct AboutView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            VStack(spacing: 0) {
                // Navigation header
                NavigationHeaderView(
                    config: NavigationHeaderConfig(
                        title: "About",
                        leftButton: .back(action: { dismiss() }),
                        rightButton: .none
                    ),
                    scrollOffset: scrollOffset
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // App Info
                        appInfoSection

                        // Resources Section
                        resourcesSection

                        // Feedback Section
                        feedbackSection

                        // Credits
                        creditsSection

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
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        VStack(spacing: 20) {
            // App Icon and Name
            VStack(spacing: 16) {
                // App icon
                Image("inkfiction")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)

                VStack(spacing: 4) {
                    Text("InkFiction")
                        .font(.title.bold())
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    Text("Your thoughts, reimagined")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
            }

            // Version Info
            VStack(spacing: 8) {
                HStack {
                    Text("Version")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    Text(appVersion)
                        .font(.caption.weight(.medium))
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                }

                HStack {
                    Text("Build")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    Text(buildNumber)
                        .font(.caption.weight(.medium))
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                }
            }
        }
        .padding(.vertical)
    }

    // MARK: - Resources Section

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resources")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                Link(destination: URL(string: "https://inkfiction.app/privacy")!) {
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .font(.body)
                                .foregroundColor(.green)
                                .frame(width: 24)

                            Text("Privacy Policy")
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.forward")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    .padding()
                }

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                Link(destination: URL(string: "https://inkfiction.app/terms")!) {
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text.fill")
                                .font(.body)
                                .foregroundColor(.orange)
                                .frame(width: 24)

                            Text("Terms of Service")
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.forward")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    .padding()
                }
            }
            .gradientCard()
        }
    }

    // MARK: - Feedback Section

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Feedback")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                Button {
                    // Open App Store review
                    if let url = URL(string: "https://apps.apple.com/app/inkfiction/id123456789?action=write-review") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .font(.body)
                                .foregroundColor(.yellow)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rate InkFiction")
                                    .font(.body)
                                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                                Text("Share your experience on the App Store")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                            }
                        }

                        Spacer()

                        Image(systemName: "arrow.up.forward")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    .padding()
                }

                Divider()
                    .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                Button {
                    // Open email client
                    if let url = URL(string: "mailto:support@inkfiction.app?subject=InkFiction%20Feedback") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.body)
                                .foregroundColor(.indigo)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Contact Us")
                                    .font(.body)
                                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                                Text("support@inkfiction.app")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                            }
                        }

                        Spacer()

                        Image(systemName: "arrow.up.forward")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                    }
                    .padding()
                }
            }
            .gradientCard()
        }
    }

    // MARK: - Credits Section

    private var creditsSection: some View {
        VStack(spacing: 16) {
            Text("Made with love")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondaryColor)

            Text("\u{00A9} 2025 InkFiction")
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.textSecondaryColor.opacity(0.6))
        }
        .padding()
    }
}

#Preview {
    AboutView()
        .environment(\.themeManager, ThemeManager())
}
