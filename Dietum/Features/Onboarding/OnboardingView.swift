import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss
    private let onComplete: () -> Void

    init(viewModel: OnboardingViewModel, onComplete: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onComplete = onComplete
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Onboarding draft",
                    title: "Build the profile now, keep the data local.",
                    message: "Fill the draft in whatever order feels natural. The screen stays editable until you continue into the app flow."
                )

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Draft status",
                            message: "The view model owns the onboarding draft and validation so the screen stays in sync with the real setup state."
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            AppMetricCard(
                                title: "Progress",
                                value: viewModel.draft.progressText,
                                detail: "Required fields filled",
                                symbolName: "checkmark.circle.fill"
                            )

                            AppMetricCard(
                                title: "State",
                                value: viewModel.isDraftValid ? "Ready" : "Draft",
                                detail: "Local to this setup session",
                                symbolName: "pencil.and.outline"
                            )
                        }

                        if let issue = viewModel.primaryValidationIssue {
                            Text(issue.message)
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.textSecondary)
                        } else {
                            Text(viewModel.draftReadinessText)
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.textSecondary)
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Identity and body metrics",
                            message: "Start with the minimum profile data the rest of the app depends on."
                        )

                        VStack(alignment: .leading, spacing: AppSpacing.item) {
                            TextField("Name or nickname", text: viewModel.binding(for: \.displayName))
                                .textFieldStyle(.roundedBorder)

                            HStack(spacing: AppSpacing.item) {
                                TextField("Height (cm)", text: viewModel.binding(for: \.heightCentimeters))
                                    .textFieldStyle(.roundedBorder)

                                TextField("Current weight (kg)", text: viewModel.binding(for: \.currentWeightKilograms))
                                    .textFieldStyle(.roundedBorder)
                            }

                            TextField("Goal weight (kg)", text: viewModel.binding(for: \.goalWeightKilograms))
                                .textFieldStyle(.roundedBorder)

                            DatePicker(
                                "Goal date",
                                selection: viewModel.binding(for: \.goalDate),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Lifestyle context",
                            message: "Workout patterns and sleep expectations help shape later guidance."
                        )

                        VStack(alignment: .leading, spacing: AppSpacing.section) {
                            VStack(alignment: .leading, spacing: AppSpacing.small) {
                                Text("Workout days")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppPalette.textPrimary)

                                LazyVGrid(
                                    columns: [GridItem(.adaptive(minimum: 82), spacing: AppSpacing.small, alignment: .leading)],
                                    spacing: AppSpacing.small
                                ) {
                                    ForEach(Weekday.allCases, id: \.self) { day in
                                        Button {
                                            toggleWorkoutDay(day)
                                        } label: {
                                            Text(day.shortLabel)
                                                .font(.caption.weight(.semibold))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, AppSpacing.small)
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundStyle(viewModel.draft.workoutDays.contains(day) ? .white : AppPalette.accent)
                                        .background(
                                            Capsule()
                                                .fill(viewModel.draft.workoutDays.contains(day) ? AppPalette.accent : AppPalette.accentSoft)
                                        )
                                    }
                                }
                            }

                            Picker("Workout intensity", selection: viewModel.binding(for: \.workoutIntensity)) {
                                Text("Low").tag(WorkoutIntensity.low)
                                Text("Moderate").tag(WorkoutIntensity.moderate)
                                Text("High").tag(WorkoutIntensity.high)
                            }
                            .pickerStyle(.segmented)

                            TextField("Average sleep hours", text: viewModel.binding(for: \.averageSleepHours))
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Meal rhythm and preferences",
                            message: "These inputs inform the future default meal spacing and reminder behavior."
                        )

                        VStack(alignment: .leading, spacing: AppSpacing.item) {
                            Stepper(
                                "Meal count: \(viewModel.draft.mealCount)",
                                value: Binding(
                                    get: { viewModel.draft.mealCount },
                                    set: { newValue in
                                        viewModel.updateDraft { draft in
                                            draft.mealCount = newValue
                                        }
                                    }
                                ),
                                in: 1 ... 8
                            )

                            TextField(
                                "Preferred meal times",
                                text: viewModel.binding(for: \.preferredMealTimes),
                                axis: .vertical
                            )
                            .textFieldStyle(.roundedBorder)

                            TextField(
                                "Heavy meal preference",
                                text: viewModel.binding(for: \.heavyMealPreference),
                                axis: .vertical
                            )
                            .textFieldStyle(.roundedBorder)

                            TextField(
                                "Light meal preference",
                                text: viewModel.binding(for: \.lightMealPreference),
                                axis: .vertical
                            )
                            .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Nutrition targets",
                            message: "The draft ends with daily calories and macros so the dashboard can pick them up later."
                        )

                        VStack(alignment: .leading, spacing: AppSpacing.item) {
                            HStack(spacing: AppSpacing.item) {
                                TextField("Calories", text: viewModel.binding(for: \.dailyCalories))
                                    .textFieldStyle(.roundedBorder)

                                TextField("Protein", text: viewModel.binding(for: \.proteinGrams))
                                    .textFieldStyle(.roundedBorder)
                            }

                            HStack(spacing: AppSpacing.item) {
                                TextField("Carbs", text: viewModel.binding(for: \.carbohydrateGrams))
                                    .textFieldStyle(.roundedBorder)

                                TextField("Fat", text: viewModel.binding(for: \.fatGrams))
                                    .textFieldStyle(.roundedBorder)
                            }

                            TextField("Fiber", text: viewModel.binding(for: \.fiberGrams))
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Field map",
                            message: "These groups still mirror the product spec and show what the next implementation pass will replace."
                        )

                        VStack(alignment: .leading, spacing: AppSpacing.section) {
                            ForEach(viewModel.fieldGroups) { group in
                                VStack(alignment: .leading, spacing: AppSpacing.small) {
                                    Text(group.title)
                                        .font(.headline)
                                        .foregroundStyle(AppPalette.textPrimary)

                                    Text(group.detail)
                                        .font(.subheadline)
                                        .foregroundStyle(AppPalette.textSecondary)

                                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                                        ForEach(group.fields, id: \.self) { field in
                                            AppChecklistItem(text: field)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, AppSpacing.small)
                                .padding(.bottom, AppSpacing.small)
                            }
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Next handoff",
                            message: viewModel.completionMessage
                        )

                        Button {
                            completeSetup()
                        } label: {
                            Label("Continue to dashboard", systemImage: "arrow.right.circle.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appProminent)

                        Text(viewModel.summary)
                            .font(.footnote)
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.screen)
            .padding(.bottom, AppSpacing.screen * 1.5)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Setup")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }

    private func toggleWorkoutDay(_ day: Weekday) {
        viewModel.updateDraft { draft in
            if draft.workoutDays.contains(day) {
                draft.workoutDays.remove(day)
            } else {
                draft.workoutDays.insert(day)
            }
        }
    }

    private func completeSetup() {
        onComplete()
        dismiss()
    }
}

private extension Weekday {
    var shortLabel: String {
        String(rawValue.prefix(3)).capitalized
    }
}
