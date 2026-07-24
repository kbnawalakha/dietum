import SwiftUI

struct ProgressPhotosView: View {
    @StateObject private var viewModel: ProgressPhotosViewModel

    init(viewModel: ProgressPhotosViewModel = ProgressPhotosViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Progress photos",
                    title: "Capture a front, back, left, and right set locally.",
                    message: "A polished local-first shell for staging progress photos before a future comparison workflow."
                )

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Stage a set",
                            message: viewModel.headline
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            ForEach(ProgressPhotoAngle.allCases, id: \.self) { angle in
                                Button {
                                    viewModel.stageMockPhoto(for: angle)
                                } label: {
                                    ProgressPhotoAngleTile(
                                        angle: angle,
                                        stagedPhoto: viewModel.stagedPhoto(for: angle)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(angle.displayName) progress photo")
                                .accessibilityHint("Stages a deterministic mock photo for the \(angle.caption.lowercased()) angle.")
                            }
                        }

                        Text(viewModel.stagedCountText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppPalette.textPrimary)

                        Text(viewModel.stagedSummaryText)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Save staged photos",
                            message: "Add a short note, then store the staged set locally."
                        )

                        TextField("Optional notes", text: $viewModel.notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)

                        if let statusMessage = viewModel.statusMessage {
                            Text(statusMessage)
                                .font(.caption)
                                .foregroundStyle(AppPalette.textSecondary)
                        }

                        HStack(spacing: AppSpacing.item) {
                            Button {
                                viewModel.clearStagedPhotos()
                            } label: {
                                Label("Clear staged", systemImage: "trash")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.appToolbar)
                            .disabled(viewModel.stagedPhotos.isEmpty)

                            Button {
                                Task {
                                    await viewModel.saveStagedPhotos()
                                }
                            } label: {
                                Label(viewModel.saveButtonTitle, systemImage: viewModel.saveButtonSystemImage)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.appProminent)
                            .disabled(!viewModel.canSave)
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Comparison summary",
                            message: viewModel.comparisonHeadline
                        )

                        Text(viewModel.comparisonDetail)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Recent saved photos",
                            message: viewModel.recentEntriesText
                        )

                        Text(viewModel.recentSummaryText)
                            .font(.caption)
                            .foregroundStyle(AppPalette.textSecondary)

                        if viewModel.loadState == .loading {
                            HStack(spacing: AppSpacing.item) {
                                ProgressView()
                                Text("Loading saved progress photos...")
                                    .font(.subheadline)
                                    .foregroundStyle(AppPalette.textSecondary)
                            }
                        } else if case .failed(let message) = viewModel.loadState {
                            Text(message)
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.textSecondary)
                        } else if viewModel.recentPhotos.isEmpty {
                            Text("No saved progress photos yet. Stage a local set above to begin tracking.")
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.textSecondary)
                        } else {
                            VStack(alignment: .leading, spacing: AppSpacing.item) {
                                ForEach(viewModel.recentPhotos.prefix(8)) { photo in
                                    ProgressPhotoRow(photo: photo)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.screen)
            .padding(.bottom, AppSpacing.screen * 1.5)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Progress Photos")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadRecentPhotos()
        }
        .appScreenBackground()
    }
}

private struct ProgressPhotoAngleTile: View {
    let angle: ProgressPhotoAngle
    let stagedPhoto: PhotoMetadata?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                AppStatusPill(
                    text: angle.displayName,
                    systemImage: stagedPhoto == nil ? "camera.viewfinder" : "checkmark.circle.fill"
                )

                Spacer(minLength: 0)
            }

            Text(angle.caption)
                .font(.headline)
                .foregroundStyle(AppPalette.textPrimary)

            Text(stagedPhoto == nil ? "Tap to stage a mock photo." : stagedPhotoText)
                .font(.caption)
                .foregroundStyle(AppPalette.textSecondary)

            Spacer(minLength: 0)

            Label(
                stagedPhoto == nil ? "Stage mock photo" : "Retake mock photo",
                systemImage: stagedPhoto == nil ? "plus.circle.fill" : "arrow.clockwise"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppPalette.accent)
        }
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
        .padding(AppSpacing.item)
        .background(AppPalette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(stagedPhoto == nil ? AppPalette.surfaceBorder : AppPalette.accent.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    private var stagedPhotoText: String {
        guard let stagedPhoto else {
            return ""
        }

        let date = stagedPhoto.capturedAt.formatted(date: .abbreviated, time: .shortened)
        return "Staged locally at \(date)."
    }
}

private struct ProgressPhotoRow: View {
    let photo: ProgressPhotoMetadata

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.item) {
            AppStatusPill(text: photo.angle.displayName, systemImage: "photo")

            VStack(alignment: .leading, spacing: 4) {
                Text(photo.capturedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)

                if let notes = photo.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(AppPalette.textSecondary)
                        .lineLimit(2)
                } else {
                    Text("No notes for this entry.")
                        .font(.caption)
                        .foregroundStyle(AppPalette.textSecondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, AppSpacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            Divider()
                .offset(y: 24),
            alignment: .bottom
        )
    }
}
