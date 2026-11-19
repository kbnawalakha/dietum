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

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Daily check-in",
                            message: viewModel.dailyCheckInHeadline
                        )

                        NavigationLink(value: AppRoute.weeklyCheckIn) {
                            Label(
                                viewModel.hasCompletedDailyCheckIn ? "Update today's weight" : "Enter today's weight",
                                systemImage: "scalemass.fill"
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appProminent)
                    }
                }

                if !viewModel.hasCompletedDailyCheckIn {
                    AppSurfaceCard {
                        ContentUnavailableView(
                            "Daily check-in required",
                            systemImage: "lock.fill",
                            description: Text("Enter today's weight to unlock meal tracking, progress history, and insights.")
                        )
                    }
                }

                if viewModel.hasCompletedDailyCheckIn {

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

                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Track a meal",
                            message: "Log what you eat from the dashboard while it is top of mind."
                        )

                        NavigationLink(value: AppRoute.mealLogging) {
                            Label("Open meal tracker", systemImage: "fork.knife.circle.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appProminent)
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Sleep and phone signals",
                            message: viewModel.sleepInsightsHeadline
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            ForEach(viewModel.sleepInsightCards) { card in
                                AppMetricCard(
                                    title: card.title,
                                    value: card.value,
                                    detail: card.detail,
                                    symbolName: card.symbolName
                                )
                            }
                        }

                        HStack(spacing: AppSpacing.item) {
                            Button {
                                Task {
                                    await viewModel.loadSleepInsights()
                                }
                            } label: {
                                Label(
                                    viewModel.isLoadingSleepInsights ? "Refreshing..." : "Refresh sleep data",
                                    systemImage: "arrow.clockwise"
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.appToolbar)
                            .disabled(viewModel.isLoadingSleepInsights)

                            NavigationLink(value: AppRoute.sleepSetup) {
                                Label("Open Sleep Setup", systemImage: "bed.double.fill")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.appToolbar)
                        }

                        Text(viewModel.sleepInsightsStatus)
                            .font(.footnote)
                            .foregroundStyle(AppPalette.textSecondary)
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

                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.screen)
            .padding(.bottom, AppSpacing.screen * 1.5)
        }
        .scrollIndicators(.hidden)
        .appScreenBackground()
        .task {
            await viewModel.loadDailyCheckIn()
            await viewModel.loadSleepInsights()
        }
        .onAppear {
            Task { await viewModel.loadDailyCheckIn() }
        }
    }
}
