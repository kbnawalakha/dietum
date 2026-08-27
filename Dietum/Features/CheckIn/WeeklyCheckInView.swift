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
                                detail: viewModel.recentLogSummaryText,
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

                            TextField("72.4", text: $viewModel.draft.weeklyWeight)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("Energy")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.textSecondary)

                            TextField("How did your energy feel?", text: $viewModel.draft.energyNotes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("Hunger")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.textSecondary)

                            TextField("Any changes in appetite?", text: $viewModel.draft.hungerNotes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("Training")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.textSecondary)

                            TextField("Notes from training or recovery", text: $viewModel.draft.trainingNotes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                        }

                        Text(viewModel.validationMessage)
                            .font(.caption)
                            .foregroundStyle(AppPalette.textSecondary)

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
                            title: "Recent logs",
                            message: viewModel.headline
                        )

                        Text(viewModel.noteSummaryText)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)

                        VStack(alignment: .leading, spacing: AppSpacing.item) {
                            ForEach(viewModel.recentLogCards) { card in
                                HStack(alignment: .top, spacing: AppSpacing.small) {
                                    Image(systemName: card.symbolName)
                                        .foregroundStyle(AppPalette.accent)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(card.dateText)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppPalette.textPrimary)

                                        Text(card.weightText)
                                            .font(.subheadline)
                                            .foregroundStyle(AppPalette.textSecondary)

                                        Text(card.noteText)
                                            .font(.caption)
                                            .foregroundStyle(AppPalette.textSecondary)
                                    }

                                    Spacer(minLength: 0)
                                }
                                .accessibilityElement(children: .combine)
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
        .navigationTitle("Weekly Check-In")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSummary()
        }
        .appScreenBackground()
    }
}
