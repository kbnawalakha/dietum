import SwiftUI

struct MealReminderView: View {
    @StateObject private var viewModel: MealReminderViewModel

    init(viewModel: MealReminderViewModel = MealReminderViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Meal reminders",
                    title: "Keep the meal plan on schedule.",
                    message: "A local-first reminder preview that recommends timing changes only when you explicitly choose them."
                )

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Reminder status",
                            message: viewModel.headline
                        )

                        AppStatusPill(
                            text: viewModel.status.title,
                            systemImage: viewModel.status.symbolName
                        )

                        Text(viewModel.status.detail)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            AppMetricCard(
                                title: "Enabled",
                                value: "\(viewModel.enabledScheduleCount)",
                                detail: "Active reminder slots",
                                symbolName: "bell.fill"
                            )

                            AppMetricCard(
                                title: "Pattern",
                                value: viewModel.patternLabelText,
                                detail: viewModel.patternScoreText,
                                symbolName: "chart.line.uptrend.xyaxis"
                            )
                        }

                        Text(viewModel.reminderSummaryText)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)

                        if let statusMessage = viewModel.statusMessage {
                            Text(statusMessage)
                                .font(.caption)
                                .foregroundStyle(AppPalette.textSecondary)
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Upcoming reminder",
                            message: "The next enabled reminder is derived locally from the current pattern."
                        )

                        Text(viewModel.nextReminderText)
                            .font(.headline)
                            .foregroundStyle(AppPalette.textPrimary)

                        Text(viewModel.controlNoteText)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Recommendation preview",
                            message: "The insight layer suggests a schedule, but it never applies anything silently."
                        )

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text(viewModel.recommendationTitleText)
                                .font(.headline)
                                .foregroundStyle(AppPalette.textPrimary)

                            Text(viewModel.recommendationDetailText)
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.textSecondary)
                        }

                        if viewModel.recommendationReasons.isEmpty {
                            Text("No timing changes are suggested right now.")
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.textSecondary)
                        } else {
                            VStack(alignment: .leading, spacing: AppSpacing.small) {
                                ForEach(viewModel.recommendationReasons, id: \.self) { reason in
                                    AppChecklistItem(text: reason)
                                }
                            }
                        }

                        HStack(spacing: AppSpacing.item) {
                            Button {
                                viewModel.keepCurrentTimes()
                            } label: {
                                Label("Keep current", systemImage: "hand.raised.fill")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.appToolbar)
                            .disabled(!viewModel.canApplyRecommendation)

                            Button {
                                viewModel.applyRecommendation()
                            } label: {
                                Label(viewModel.recommendationActionTitle, systemImage: "sparkles")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.appProminent)
                            .disabled(!viewModel.canApplyRecommendation)
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Meal schedule",
                            message: "Enable or disable individual meal reminders without leaving the module."
                        )

                        VStack(alignment: .leading, spacing: AppSpacing.item) {
                            ForEach(Array(viewModel.reminderSchedules.enumerated()), id: \.offset) { index, schedule in
                                MealReminderRow(
                                    schedule: schedule,
                                    onToggle: {
                                        viewModel.toggleReminder(at: index)
                                    }
                                )
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
        .navigationTitle("Meal Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }
}

private struct MealReminderRow: View {
    let schedule: MealReminderSchedule
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.item) {
            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.mealType.rawValue.capitalized)
                    .font(.headline)
                    .foregroundStyle(AppPalette.textPrimary)

                Text(schedule.displayTime)
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.textSecondary)

                Text(schedule.isEnabled ? "Reminder is enabled." : "Reminder is disabled.")
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary)
            }

            Spacer(minLength: 0)

            Button {
                onToggle()
            } label: {
                Image(systemName: schedule.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(schedule.isEnabled ? AppPalette.accent : AppPalette.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }
}
