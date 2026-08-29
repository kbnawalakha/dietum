import SwiftUI

struct MealExportView: View {
    @StateObject private var viewModel: MealExportViewModel

    init(viewModel: MealExportViewModel = MealExportViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Local export",
                    title: "Create a privacy-preserving export file.",
                    message: "This export stays on the device until the user chooses to share or move the file. No cloud sync is involved."
                )

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Export status",
                            message: viewModel.exportHeadline
                        )

                        AppStatusPill(
                            text: viewModel.statusText,
                            systemImage: viewModel.statusSymbolName
                        )

                        Text(viewModel.statusDetail)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)

                        Text(viewModel.exportSummaryText)
                            .font(.caption)
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "What gets exported",
                            message: "Choose which meal-module data is included in the local JSON file."
                        )

                        MealExportOptionRow(
                            title: "Meal draft",
                            detail: "Current meal type, notes, and photo placeholder description.",
                            isOn: Binding(
                                get: { viewModel.includeMealDraft },
                                set: { viewModel.includeMealDraft = $0 }
                            )
                        )

                        MealExportOptionRow(
                            title: "Detected foods",
                            detail: "Mock detection results and confidence values.",
                            isOn: Binding(
                                get: { viewModel.includeDetectedFoods },
                                set: { viewModel.includeDetectedFoods = $0 }
                            )
                        )

                        MealExportOptionRow(
                            title: "Reminder schedules",
                            detail: "Local meal reminder timing and enable states.",
                            isOn: Binding(
                                get: { viewModel.includeReminderSchedules },
                                set: { viewModel.includeReminderSchedules = $0 }
                            )
                        )
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Privacy note",
                            message: "The export file is written locally and can be shared only if the user chooses to move it out of the device."
                        )

                        Text("Dietum does not upload export data. This file is for personal offline transfer, backup, or review.")
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)

                        Button {
                            viewModel.exportLocalData()
                        } label: {
                            Label("Create local export", systemImage: "square.and.arrow.up.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appProminent)
                        .disabled(viewModel.exportButtonDisabled)

                        if case .ready(let result) = viewModel.exportState {
                            VStack(alignment: .leading, spacing: AppSpacing.small) {
                                Text(result.summaryText)
                                    .font(.subheadline)
                                    .foregroundStyle(AppPalette.textSecondary)

                                Text(result.fileName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppPalette.textPrimary)

                                Text(result.fileURL.path)
                                    .font(.caption)
                                    .foregroundStyle(AppPalette.textSecondary)
                                    .textSelection(.enabled)
                            }
                        }

                        if case .failed(let message) = viewModel.exportState {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(AppPalette.textSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.screen)
            .padding(.bottom, AppSpacing.screen * 1.5)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }
}

private struct MealExportOptionRow: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Toggle(isOn: $isOn) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppPalette.textPrimary)
            }
            .toggleStyle(.switch)

            Text(detail)
                .font(.caption)
                .foregroundStyle(AppPalette.textSecondary)
        }
    }
}
