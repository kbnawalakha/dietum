import Foundation
import SwiftUI

struct NutritionAdjustmentView: View {
    @StateObject private var viewModel: NutritionAdjustmentViewModel

    init(viewModel: NutritionAdjustmentViewModel = NutritionAdjustmentViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Nutrition review",
                    title: "Calorie adjustment",
                    message: viewModel.headline
                )

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Recommendation",
                            message: "The app keeps this as a preview until you explicitly approve it."
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            AppMetricCard(
                                title: "Current",
                                value: viewModel.currentCaloriesText,
                                detail: "Active target",
                                symbolName: "flame.fill"
                            )

                            AppMetricCard(
                                title: "Suggested",
                                value: viewModel.suggestedCaloriesText,
                                detail: "Proposed target",
                                symbolName: "arrow.up.arrow.down.circle.fill"
                            )
                        }

                        AppMetricCard(
                            title: "Adjustment",
                            value: viewModel.deltaText,
                            detail: "Compared with the current plan",
                            symbolName: "slider.horizontal.3"
                        )
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Why this change",
                            message: "The recommendation uses local trend context and stays intentionally conservative."
                        )

                        recommendationCard
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Approval",
                            message: "Nothing is applied until you tap approve."
                        )

                        TextField("Optional note", text: $viewModel.approvalNotes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Approval note")

                        Button {
                            viewModel.approveRecommendation()
                        } label: {
                            Label(viewModel.approvalButtonTitle, systemImage: "checkmark.seal.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appProminent)
                        .disabled(!viewModel.canApprove)

                        Button {
                            viewModel.declineRecommendation()
                        } label: {
                            Label("Keep current target", systemImage: "minus.circle.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appToolbar)

                        if let appliedCalories = viewModel.appliedCalories {
                            Text("Approved target: \(appliedCalories) kcal")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.screen)
            .padding(.bottom, AppSpacing.screen * 1.5)
        }
        .scrollIndicators(.hidden)
        .appScreenBackground()
        .task {
            await viewModel.loadRecommendation()
        }
    }

    @ViewBuilder
    private var recommendationCard: some View {
        if let recommendation = viewModel.recommendation {
            VStack(alignment: .leading, spacing: AppSpacing.item) {
                Label(viewModel.approvalBadgeText, systemImage: "sparkles")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(recommendation.reasonSummary)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(recommendation.expectedEffect)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    ForEach(recommendation.supportingReasons, id: \.self) { reason in
                        Label(reason, systemImage: "checkmark.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Label(
                        "Trend: \(String(format: "%.2f", recommendation.trendAnalysis.averageWeeklyWeightChangeKilograms)) kg per week",
                        systemImage: "chart.line.uptrend.xyaxis"
                    )
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                    Text(recommendation.trendAnalysis.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            ContentUnavailableView(
                "No recommendation yet",
                systemImage: "slider.horizontal.3",
                description: Text("The mock recommendation will appear after the local analysis finishes.")
            )
        }
    }
}
