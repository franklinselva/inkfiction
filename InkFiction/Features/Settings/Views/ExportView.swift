//
//  ExportView.swift
//  InkFiction
//
//  View for preparing and exporting journal data
//

import SwiftUI

struct ExportView: View {
    @Environment(\.themeManager) private var themeManager
    @Environment(Router.self) private var router
    @State private var viewModel = ExportViewModel()
    @State private var scrollOffset: CGFloat = 0
    @State private var showShareSheet = false
    @State private var showSuccessAnimation = false

    var body: some View {
        ZStack {
            AnimatedGradientBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation header
                NavigationHeaderView(
                    config: NavigationHeaderConfig(
                        title: "Export Data",
                        leftButton: .back(action: {
                            if !viewModel.isComplete {
                                viewModel.cancelExport()
                            }
                            router.pop()
                        }),
                        rightButton: .none
                    ),
                    scrollOffset: scrollOffset
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Main content based on state
                        if viewModel.stage == .idle {
                            idleStateView
                        } else if viewModel.isFailed {
                            errorStateView
                        } else if viewModel.isComplete {
                            completeStateView
                        } else {
                            progressStateView
                        }

                        // Bottom spacing for safe area
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
        .sheet(isPresented: $showShareSheet) {
            if let exportURL = viewModel.exportURL {
                ShareSheet(items: [exportURL])
            }
        }
        .navigationBarHidden(true)
        .task {
            if viewModel.stage == .idle {
                await viewModel.startExport()
            }
        }
    }

    // MARK: - Idle State

    private var idleStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: themeManager.currentTheme.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 40)

            VStack(spacing: 8) {
                Text("Preparing Export")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Text("Setting up your data for export")
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
            }

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Progress State

    private var progressStateView: some View {
        VStack(spacing: 32) {
            // Progress icon
            Image(systemName: "doc.badge.gearshape")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: themeManager.currentTheme.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 40)

            VStack(spacing: 8) {
                Text("Preparing Your Data")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Text("This may take a few moments")
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
            }

            // Progress stages
            VStack(spacing: 16) {
                ExportStageRow(
                    icon: "doc.text",
                    label: "Gathering journal entries",
                    isActive: viewModel.stage == .gatheringEntries,
                    isComplete: viewModel.stage.progress > ExportStage.gatheringEntries.progress
                )

                ExportStageRow(
                    icon: "photo",
                    label: "Collecting images",
                    isActive: viewModel.stage == .collectingImages,
                    isComplete: viewModel.stage.progress > ExportStage.collectingImages.progress
                )

                ExportStageRow(
                    icon: "archivebox",
                    label: "Creating archive",
                    isActive: viewModel.stage == .creatingArchive,
                    isComplete: viewModel.stage.progress > ExportStage.creatingArchive.progress
                )
            }
            .padding()
            .gradientCard()

            // Stats card
            if viewModel.entriesCount > 0 {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Entries")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                            Text("\(viewModel.entriesCount)")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Images")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                            Text("\(viewModel.imagesCount)")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        }
                    }

                    Divider()
                        .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                    HStack {
                        Text("Estimated Size")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                        Spacer()

                        Text(viewModel.estimatedSize)
                            .font(.body.weight(.medium))
                            .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                    }
                }
                .padding()
                .gradientCard()
            }
        }
    }

    // MARK: - Error State

    private var errorStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.red)
                .padding(.top, 40)

            VStack(spacing: 8) {
                Text("Export Failed")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            Button {
                viewModel.reset()
                Task {
                    await viewModel.startExport()
                }
            } label: {
                Text("Try Again")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: themeManager.currentTheme.gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 60)
    }

    // MARK: - Complete State

    private var completeStateView: some View {
        VStack(spacing: 32) {
            // Success animation
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showSuccessAnimation ? 1.0 : 0.5)
                        .opacity(showSuccessAnimation ? 1.0 : 0.0)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(.green)
                        .scaleEffect(showSuccessAnimation ? 1.0 : 0.5)
                        .opacity(showSuccessAnimation ? 1.0 : 0.0)
                }
                .padding(.top, 40)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                        showSuccessAnimation = true
                    }
                }

                VStack(spacing: 8) {
                    Text("Export Ready!")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                    Text("Your journal data has been prepared")
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                }
            }

            // File info card
            if let exportURL = viewModel.exportURL {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "folder.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.currentTheme.accentColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(exportURL.lastPathComponent)
                                .font(.body.weight(.medium))
                                .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                                .lineLimit(2)

                            Text(viewModel.formattedExportSize)
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondaryColor)
                        }

                        Spacer()
                    }

                    Divider()
                        .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                    HStack(spacing: 16) {
                        ExportStatBadge(
                            icon: "doc.text",
                            label: "Entries",
                            value: "\(viewModel.entriesCount)"
                        )

                        Spacer()

                        ExportStatBadge(
                            icon: "photo",
                            label: "Images",
                            value: "\(viewModel.imagesCount)"
                        )
                    }
                }
                .padding()
                .gradientCard()

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        viewModel.prepareForShare()
                        showShareSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            if viewModel.isPreparingShare {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.body)
                            }

                            Text(viewModel.isPreparingShare ? "Preparing..." : "Share Export")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: themeManager.currentTheme.gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .opacity(viewModel.isPreparingShare ? 0.8 : 1.0)
                    }
                    .disabled(viewModel.isPreparingShare || viewModel.isPreparingSave)

                    Button {
                        viewModel.prepareForSave()
                        let documentPicker = UIDocumentPickerViewController(
                            forExporting: [exportURL],
                            asCopy: true
                        )
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootVC = window.rootViewController {
                            rootVC.present(documentPicker, animated: true)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            if viewModel.isPreparingSave {
                                ProgressView()
                                    .progressViewStyle(
                                        CircularProgressViewStyle(tint: themeManager.currentTheme.textPrimaryColor)
                                    )
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "arrow.down.doc")
                                    .font(.body)
                            }

                            Text(viewModel.isPreparingSave ? "Preparing..." : "Save to Files")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    themeManager.currentTheme.textSecondaryColor.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                        .opacity(viewModel.isPreparingSave ? 0.6 : 1.0)
                    }
                    .disabled(viewModel.isPreparingShare || viewModel.isPreparingSave)
                }
                .padding(.horizontal)

                // What's included section
                VStack(alignment: .leading, spacing: 16) {
                    Text("What's Included")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimaryColor)
                        .padding(.horizontal, 4)

                    VStack(spacing: 12) {
                        ExportIncludedFileRow(
                            icon: "tablecells",
                            filename: "journal_entries.csv",
                            description: "All journal entries in CSV format"
                        )

                        Divider()
                            .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                        ExportIncludedFileRow(
                            icon: "photo.on.rectangle",
                            filename: "images/",
                            description: "\(viewModel.imagesCount) images organized by entry"
                        )

                        Divider()
                            .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                        ExportIncludedFileRow(
                            icon: "doc.text",
                            filename: "metadata.json",
                            description: "Export metadata and structure"
                        )

                        Divider()
                            .background(themeManager.currentTheme.textSecondaryColor.opacity(0.2))

                        ExportIncludedFileRow(
                            icon: "info.circle",
                            filename: "README.txt",
                            description: "Documentation and file guide"
                        )
                    }
                    .padding()
                    .gradientCard()
                }
            }
        }
    }
}

// MARK: - Export Stage Row Component

private struct ExportStageRow: View {
    let icon: String
    let label: String
    let isActive: Bool
    let isComplete: Bool

    @Environment(\.themeManager) private var themeManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(statusColor)
                .frame(width: 24)

            Text(label)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.textPrimaryColor)

            Spacer()

            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
            } else if isActive {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor.opacity(0.3))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isActive)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isComplete)
    }

    private var statusColor: Color {
        if isComplete {
            return .green
        } else if isActive {
            return themeManager.currentTheme.accentColor
        } else {
            return themeManager.currentTheme.textSecondaryColor.opacity(0.5)
        }
    }
}

// MARK: - Export Stat Badge Component

private struct ExportStatBadge: View {
    let icon: String
    let label: String
    let value: String

    @Environment(\.themeManager) private var themeManager

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)

                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)
            }
        }
    }
}

// MARK: - Export Included File Row Component

private struct ExportIncludedFileRow: View {
    let icon: String
    let filename: String
    let description: String

    @Environment(\.themeManager) private var themeManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(filename)
                    .font(.body.weight(.medium))
                    .foregroundColor(themeManager.currentTheme.textPrimaryColor)

                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondaryColor)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ExportView()
        .environment(\.themeManager, ThemeManager())
        .environment(Router())
}
