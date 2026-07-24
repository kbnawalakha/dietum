import SwiftUI

struct WeeklyCheckInView: View {
    @StateObject private var viewModel: WeeklyCheckInViewModel

    init(viewModel: WeeklyCheckInViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Weekly check-in",
                    title: "Review the trend, confirm the weight, and note how the week felt.",
                    message: "A local-first checkpoint for body weight, energy, hunger, and training context."
                )

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Trend summary",
                            message: viewModel.headline
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            AppMetricCard(
                                title: "Latest weight",
                                value: viewModel.latestWeightText,
                                detail: "Stored locally",
                                symbolName: "scalemass"
                            )

                            AppMetricCard(
                                title: "Change",
                                value: viewModel.trendText,
                                detail: viewModel.summaryText,
                                symbolName: "chart.line.uptrend.xyaxis"
                            )
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Check-in notes",
                            message: "Capture the signals that help explain the trend."
                        )

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("Weekly weight")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.textSecondary)

                            TextField("72.4", text: $viewModel.weeklyWeight)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("Energy")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.textSecondary)

                            TextField("How did your energy feel?", text: $viewModel.energyNotes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("Hunger")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.textSecondary)

                            TextField("Any changes in appetite?", text: $viewModel.hungerNotes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("Training")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.textSecondary)

                            TextField("Notes from training or recovery", text: $viewModel.trainingNotes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                        }

                        if let status = viewModel.formattedStatus {
                            Text(status)
                                .font(.caption)
                                .foregroundStyle(AppPalette.textSecondary)
                        }

                        Button {
                            Task {
                                await viewModel.saveCheckIn()
                            }
                        } label: {
                            Label(viewModel.saveButtonTitle, systemImage: viewModel.saveButtonSystemImage)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appProminent)
                        .disabled(!viewModel.canSave)
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "What this check-in does",
                            message: "The flow keeps the data on-device and prepares the groundwork for future trend and adjustment logic."
                        )

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            AppChecklistItem(text: "Confirms a weekly weight entry locally")
                            AppChecklistItem(text: "Captures energy, hunger, and training notes")
                            AppChecklistItem(text: "Keeps the screen ready for adjustment logic later")
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.screen)
            .padding(.bottom, AppSpacing.screen * 1.5)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Weekly Check-In")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSummary()
        }
        .appScreenBackground()
    }
}
