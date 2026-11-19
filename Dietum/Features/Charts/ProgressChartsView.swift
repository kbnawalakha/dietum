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
                            title: "Time range",
                            message: "Compare saved weight and nutrition changes across a useful time window."
                        )

                        Picker("Time range", selection: Binding(
                            get: { viewModel.selectedRange },
                            set: { range in
                                viewModel.setRange(range)
                                Task { await viewModel.loadCharts() }
                            }
                        )) {
                            ForEach(ProgressChartRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Progress chart time range")
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Body measurement trend",
                            message: "Visual circumference estimates from saved progress photos, using the selected range."
                        )

                        if viewModel.measurementPoints.isEmpty {
                            ContentUnavailableView(
                                "No measurement history yet",
                                systemImage: "ruler",
                                description: Text("Save analyzed progress photos to build measurement trends.")
                            )
                            .frame(maxWidth: .infinity, minHeight: 220)
                        } else {
                            Chart {
                                ForEach(viewModel.measurementPoints) { point in
                                    LineMark(
                                        x: .value("Date", point.date),
                                        y: .value("Centimeters", point.value)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(by: .value("Measurement", point.metric))

                                    PointMark(
                                        x: .value("Date", point.date),
                                        y: .value("Centimeters", point.value)
                                    )
                                    .foregroundStyle(by: .value("Measurement", point.metric))
                                }
                            }
                            .frame(minHeight: 240)
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 4))
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .chartLegend(position: .bottom, alignment: .leading)
                        }
                    }
                }

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

                        if viewModel.weightPoints.isEmpty {
                            ContentUnavailableView(
                                "No weight history yet",
                                systemImage: "chart.line.uptrend.xyaxis",
                                description: Text("Add a weekly check-in to build a real weight trend.")
                            )
                            .frame(maxWidth: .infinity, minHeight: 220)
                        } else {
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
                            .frame(minHeight: 220)
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 4))
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Nutrition trend",
                            message: "This line shows the calorie recommendation evolving with the same local history."
                        )

                        if viewModel.nutritionPoints.isEmpty {
                            ContentUnavailableView(
                                "No nutrition trend yet",
                                systemImage: "flame",
                                description: Text("Nutrition trends appear after saved check-ins are available.")
                            )
                            .frame(maxWidth: .infinity, minHeight: 220)
                        } else {
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
                                    RuleMark(y: .value("Current target", viewModel.currentTargetCalories))
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
