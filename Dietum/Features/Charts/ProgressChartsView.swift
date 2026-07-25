import Charts
import SwiftUI

struct ProgressChartsView: View {
    @StateObject private var viewModel: ProgressChartsViewModel

    init(viewModel: ProgressChartsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Progress charts",
                    title: "Weight and nutrition trends together.",
                    message: viewModel.heroHeadline
                )

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Snapshot",
                            message: viewModel.chartNotes
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            AppMetricCard(
                                title: "Latest weight",
                                value: viewModel.currentWeightText,
                                detail: "Goal: \(viewModel.goalWeightText)",
                                symbolName: "scalemass"
                            )

                            AppMetricCard(
                                title: "Weight change",
                                value: viewModel.weightChangeText,
                                detail: viewModel.weightSummaryText,
                                symbolName: "chart.line.uptrend.xyaxis"
                            )

                            AppMetricCard(
                                title: "Latest calories",
                                value: viewModel.currentCaloriesText,
                                detail: "Current target",
                                symbolName: "flame.fill"
                            )

                            AppMetricCard(
                                title: "Calorie shift",
                                value: viewModel.caloriesDeltaText,
                                detail: viewModel.nutritionSummaryText,
                                symbolName: "slider.horizontal.3"
                            )
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Weight trend",
                            message: "The goal line helps show whether the trend is heading toward the target."
                        )

                        Chart {
                            ForEach(viewModel.weightPoints) { point in
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Weight", point.value)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(AppPalette.accent)
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                                PointMark(
                                    x: .value("Date", point.date),
                                    y: .value("Weight", point.value)
                                )
                                .foregroundStyle(AppPalette.accent)
                            }

                            if let _ = viewModel.weightPoints.first, let _ = viewModel.weightPoints.last {
                                RuleMark(y: .value("Goal", viewModel.goalWeightValue))
                                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                    .foregroundStyle(AppPalette.accent.opacity(0.5))
                                    .annotation(position: .topTrailing, alignment: .trailing) {
                                        Text("Goal \(viewModel.goalWeightText)")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(AppPalette.textSecondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(AppPalette.surface, in: Capsule())
                                    }
                            }
                        }
                        .frame(minHeight: 220)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4))
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Nutrition trend",
                            message: "This line shows the calorie recommendation evolving with the same local history."
                        )

                        Chart {
                            ForEach(viewModel.nutritionPoints) { point in
                                LineMark(
                                    x: .value("Date", point.date),
                                    y: .value("Calories", point.value)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(.secondary)
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                                PointMark(
                                    x: .value("Date", point.date),
                                    y: .value("Calories", point.value)
                                )
                                .foregroundStyle(.secondary)
                            }

                            if let latest = viewModel.nutritionPoints.last {
                                RuleMark(y: .value("Current target", 2_400))
                                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                    .foregroundStyle(AppPalette.accent.opacity(0.45))
                                    .annotation(position: .topTrailing, alignment: .trailing) {
                                        Text(viewModel.currentTargetText)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(AppPalette.textSecondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(AppPalette.surface, in: Capsule())
                                    }

                                PointMark(
                                    x: .value("Date", latest.date),
                                    y: .value("Calories", latest.value)
                                )
                                .foregroundStyle(AppPalette.accent)
                                .symbolSize(80)
                            }
                        }
                        .frame(minHeight: 220)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4))
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Supporting signals",
                            message: "These are the cues the chart view uses when explaining the trend."
                        )

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            ForEach(viewModel.supportingSignals, id: \.self) { signal in
                                AppChecklistItem(text: signal)
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
        .navigationTitle("Progress Charts")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadCharts()
        }
        .appScreenBackground()
    }
}
