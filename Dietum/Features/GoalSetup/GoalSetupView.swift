import SwiftUI

struct GoalSetupView: View {
    @StateObject private var viewModel: GoalSetupViewModel

    init(viewModel: GoalSetupViewModel = GoalSetupViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Goal setup",
                    title: "Shape the target weight and nutrition goals locally.",
                    message: "This is the focused goal setup lane that stays lightweight and reusable inside the app target."
                )

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Goal status",
                            message: "The view model owns the draft and validation so the screen stays easy to reason about."
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            AppMetricCard(
                                title: "Progress",
                                value: viewModel.draft.progressText,
                                detail: "Required fields filled",
                                symbolName: "target"
                            )

                            AppMetricCard(
                                title: "State",
                                value: viewModel.isDraftValid ? "Ready" : "Draft",
                                detail: "Local setup only",
                                symbolName: "checkmark.seal.fill"
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
                            title: "Goal targets",
                            message: "Keep the values editable so the next persistence pass can reuse the same draft."
                        )

                        VStack(alignment: .leading, spacing: AppSpacing.item) {
                            TextField("Goal weight (kg)", text: viewModel.binding(for: \.goalWeightKilograms))
                                .textFieldStyle(.roundedBorder)

                            DatePicker(
                                "Goal date",
                                selection: viewModel.binding(for: \.goalDate),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)

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
                            title: "Next handoff",
                            message: viewModel.completionMessage
                        )

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
        .navigationTitle("Goal Setup")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }
}
