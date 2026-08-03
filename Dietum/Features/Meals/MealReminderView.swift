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
                    message: "A self-contained reminder surface for meal timing, local schedule status, and quick enable or disable checks."
                )

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Reminder status",
                            message: viewModel.reminderSummaryText
                        )

                        AppStatusPill(
                            text: viewModel.status.title,
                            systemImage: viewModel.status.symbolName
                        )

                        Text(viewModel.status.detail)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)

                        HStack(spacing: AppSpacing.item) {
                            AppMetricCard(
                                title: "Enabled",
                                value: "\(viewModel.enabledScheduleCount)",
                                detail: "Active reminder slots",
                                symbolName: "bell.fill"
                            )

                            AppMetricCard(
                                title: "Total",
                                value: "\(viewModel.reminderSchedules.count)",
                                detail: "Configured meal reminders",
                                symbolName: "calendar"
                            )
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Upcoming reminder",
                            message: "The first enabled reminder is shown here so the user can quickly see what comes next."
                        )

                        Text(viewModel.nextReminderText)
                            .font(.headline)
                            .foregroundStyle(AppPalette.textPrimary)

                        Text("Reminder delivery stays local and can be adjusted from this surface later.")
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)
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
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(schedule.mealType.rawValue.capitalized)
                        .font(.headline)
                        .foregroundStyle(AppPalette.textPrimary)

                    Text(schedule.displayTime)
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.textSecondary)
                }

                Spacer(minLength: 0)

                Button {
                    onToggle()
                } label: {
                    Image(systemName: schedule.isEnabled ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(schedule.isEnabled ? AppPalette.accent : AppPalette.textSecondary)
                }
                .buttonStyle(.plain)
            }

            Text(schedule.isEnabled ? "Reminder is enabled." : "Reminder is disabled.")
                .font(.caption)
                .foregroundStyle(AppPalette.textSecondary)
        }
    }
}
