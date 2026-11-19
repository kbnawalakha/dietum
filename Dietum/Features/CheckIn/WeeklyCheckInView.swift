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
                    eyebrow: "Daily check-in",
                    title: "Record today's weight before you track.",
                    message: "A local-first checkpoint for today's body weight, with optional notes about energy, hunger, and training."
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
                            Text("Today's weight")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.textSecondary)

                            TextField("72.4", text: $viewModel.draft.weeklyWeight)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.appTextField)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("Energy")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.textSecondary)

                            TextField("How did your energy feel?", text: $viewModel.draft.energyNotes, axis: .vertical)
                                .textFieldStyle(.appTextField)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("Hunger")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.textSecondary)

                            TextField("Any changes in appetite?", text: $viewModel.draft.hungerNotes, axis: .vertical)
                                .textFieldStyle(.appTextField)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("Training")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.textSecondary)

                            TextField("Notes from training or recovery", text: $viewModel.draft.trainingNotes, axis: .vertical)
                                .textFieldStyle(.appTextField)
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
                        .disabled(viewModel.saveState == .loading)
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
        .navigationTitle("Daily Check-In")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSummary()
        }
        .appScreenBackground()
    }
}
