import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel = DashboardViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Local-first nutrition",
                    title: "Daily dashboard",
                    message: viewModel.headline
                )

                VStack(alignment: .leading, spacing: AppSpacing.item) {
                    AppSectionHeader(
                        title: "Today",
                        message: viewModel.todaySummaryText
                    )

                    LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                        ForEach(viewModel.targetCards) { card in
                            AppMetricCard(
                                title: card.title,
                                value: card.value,
                                detail: card.detail,
                                symbolName: card.symbolName
                            )
                        }
                    }

                    Text(viewModel.reminderStatusText)
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.textSecondary)
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Quick start",
                            message: "Jump into the next step from a single place."
                        )

                        ForEach(viewModel.quickActions) { action in
                            NavigationLink(value: action.route) {
                                Label(action.title, systemImage: action.symbolName)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.appProminent)
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Readiness",
                            message: viewModel.readinessSummaryText
                        )

                        Text(viewModel.readinessDetailText)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            ForEach(viewModel.readinessItems) { item in
                                HStack(alignment: .top, spacing: AppSpacing.small) {
                                    Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.isComplete ? AppPalette.accent : AppPalette.textSecondary)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppPalette.textPrimary)

                                        Text(item.detail)
                                            .font(.caption)
                                            .foregroundStyle(AppPalette.textSecondary)
                                    }

                                    Spacer(minLength: 0)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel(item.title)
                                .accessibilityValue(item.isComplete ? "Complete" : "Needs attention")
                            }
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Progress charts",
                            message: viewModel.progressHeadline
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            ForEach(viewModel.trendCards) { card in
                                AppMetricCard(
                                    title: card.title,
                                    value: card.value,
                                    detail: card.detail,
                                    symbolName: card.symbolName
                                )
                            }
                        }

                        NavigationLink(value: AppRoute.progressCharts) {
                            Label("Open progress charts", systemImage: "chart.line.uptrend.xyaxis")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appToolbar)
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Progress photos",
                            message: viewModel.photosHeadline
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            ForEach(viewModel.photoCards) { card in
                                AppMetricCard(
                                    title: card.title,
                                    value: card.value,
                                    detail: card.detail,
                                    symbolName: card.symbolName
                                )
                            }
                        }

                        NavigationLink(value: AppRoute.progressPhotos) {
                            Label("Review progress photos", systemImage: "arrow.right.circle.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appToolbar)
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Nutrition adjustment",
                            message: viewModel.nutritionHeadline
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            ForEach(viewModel.nutritionCards) { card in
                                AppMetricCard(
                                    title: card.title,
                                    value: card.value,
                                    detail: card.detail,
                                    symbolName: card.symbolName
                                )
                            }
                        }

                        NavigationLink(value: AppRoute.nutritionAdjustment) {
                            Label("Open nutrition adjustment", systemImage: "arrow.right.circle.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appToolbar)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.screen)
            .padding(.bottom, AppSpacing.screen * 1.5)
        }
        .scrollIndicators(.hidden)
        .appScreenBackground()
    }
}
