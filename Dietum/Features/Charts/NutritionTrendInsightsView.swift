import SwiftUI

struct NutritionTrendInsightsView: View {
    @StateObject private var viewModel: NutritionTrendInsightsViewModel

    init(viewModel: NutritionTrendInsightsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Nutrition insights",
                    title: "Notice the pattern, keep the context.",
                    message: viewModel.headline
                )

                HStack(spacing: AppSpacing.item) {
                    Button {
                        Task { await viewModel.retry() }
                    } label: {
                        Label("Refresh insights", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.appToolbar)

                    NavigationLink(value: AppRoute.mealLogging) {
                        Label("Log a meal", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.appToolbar)
                }

                content
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.screen)
            .padding(.bottom, AppSpacing.screen * 1.5)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Nutrition Insights")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .appScreenBackground()
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            AppSurfaceCard {
                HStack(spacing: AppSpacing.small) {
                    ProgressView()
                    Text("Building an estimate from local meal history...")
                        .foregroundStyle(AppPalette.textSecondary)
                }
            }
        case .empty:
            AppSurfaceCard {
                VStack(alignment: .leading, spacing: AppSpacing.item) {
                    AppSectionHeader(
                        title: "Not enough history",
                        message: "Nutrition insights appear after at least one meal day is logged in the recent window."
                    )

                    NavigationLink(value: AppRoute.mealLogging) {
                        Label("Log your first meal", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.appProminent)
                }
            }
        case .failed:
            AppSurfaceCard {
                VStack(alignment: .leading, spacing: AppSpacing.item) {
                    AppSectionHeader(title: "Could not refresh", message: viewModel.headline)
                    HStack(spacing: AppSpacing.item) {
                        Button("Try again") { Task { await viewModel.retry() } }
                        .buttonStyle(.appProminent)

                        NavigationLink(value: AppRoute.mealLogging) {
                            Label("Log a meal", systemImage: "camera.fill")
                        }
                        .buttonStyle(.appToolbar)
                    }
                }
            }
        case .loaded(let insights):
            loadedContent(insights)
        }
    }

    private func loadedContent(_ insights: NutritionTrendInsights) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.section) {
            AppSurfaceCard {
                VStack(alignment: .leading, spacing: AppSpacing.item) {
                    AppSectionHeader(title: "Recent averages", message: viewModel.estimateNote)
                    LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                        metric("Calories", value: "\(Int(insights.recentAverageCalories.rounded()))", detail: "kcal per logged day", symbol: "flame.fill")
                        metric("Protein", value: "\(Int(insights.recentAverageProteinGrams.rounded())) g", detail: "per logged day", symbol: "bolt.fill")
                        metric("Carbs", value: "\(Int(insights.recentAverageCarbohydrateGrams.rounded())) g", detail: "per logged day", symbol: "leaf.fill")
                        metric("Fiber", value: "\(Int(insights.recentAverageFiberGrams.rounded())) g", detail: "per logged day", symbol: "circle.grid.cross.fill")
                    }
                }
            }

            AppSurfaceCard {
                VStack(alignment: .leading, spacing: AppSpacing.item) {
                    AppSectionHeader(title: "What changed", message: comparisonText(for: insights))
                    Text("This is an observation of logged data, not a recommendation to change your target.")
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.textSecondary)
                }
            }
        }
    }

    private func metric(_ title: String, value: String, detail: String, symbol: String) -> some View {
        AppMetricCard(title: title, value: value, detail: detail, symbolName: symbol)
    }

    private func comparisonText(for insights: NutritionTrendInsights) -> String {
        guard let previous = insights.previousAverageCalories else {
            return "There is no earlier logged week to compare yet."
        }
        let delta = Int((insights.recentAverageCalories - previous).rounded())
        if insights.calorieDirection == .steady { return "Average calories look broadly steady versus the prior period." }
        return delta > 0
            ? "Average calories are about \(delta) kcal higher than the prior period."
            : "Average calories are about \(abs(delta)) kcal lower than the prior period."
    }
}
