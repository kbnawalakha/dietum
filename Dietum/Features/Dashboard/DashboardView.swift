import SwiftUI

struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Local-first nutrition",
                    title: "Daily dashboard",
                    message: "Track meals, weight, and progress without leaving the flow of the app."
                )

                VStack(alignment: .leading, spacing: AppSpacing.item) {
                    AppSectionHeader(
                        title: "Today",
                        message: "A simple shell for targets, reminders, and quick actions."
                    )

                    LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                        AppMetricCard(
                            title: "Calories",
                            value: "2,400",
                            detail: "Target",
                            symbolName: "flame.fill"
                        )

                        AppMetricCard(
                            title: "Meals",
                            value: "4",
                            detail: "Planned today",
                            symbolName: "fork.knife"
                        )

                        AppMetricCard(
                            title: "Sleep",
                            value: "7.5 h",
                            detail: "Goal range",
                            symbolName: "bed.double.fill"
                        )
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Quick start",
                            message: "Jump into meal logging, weekly check-in, or open the setup flow from here."
                        )

                        NavigationLink(value: AppRoute.mealLogging) {
                            Label("Log a meal", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appProminent)

                        NavigationLink(value: AppRoute.weeklyCheckIn) {
                            Label("Start weekly check-in", systemImage: "calendar.badge.clock")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appProminent)

                        NavigationLink(value: AppRoute.progressPhotos) {
                            Label("Open progress photos", systemImage: "photo.on.rectangle.angled")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appProminent)

                        NavigationLink(value: AppRoute.nutritionAdjustment) {
                            Label("Review calorie adjustment", systemImage: "slider.horizontal.3")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appProminent)

                        NavigationLink(value: AppRoute.onboarding) {
                            Label("Open onboarding", systemImage: "arrow.right.circle.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appProminent)
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Weekly review",
                            message: "A lightweight snapshot of the latest body-weight trend and notes."
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            AppMetricCard(
                                title: "Latest weight",
                                value: "72.4 kg",
                                detail: "From the most recent check-in",
                                symbolName: "scalemass"
                            )

                            AppMetricCard(
                                title: "Trend",
                                value: "-0.3 kg",
                                detail: "Over the last 7 days",
                                symbolName: "chart.line.uptrend.xyaxis"
                            )
                        }

                        NavigationLink(value: AppRoute.weeklyCheckIn) {
                            Label("Review weekly check-in", systemImage: "checkmark.seal.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appToolbar)
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Progress photos",
                            message: "Track front, back, left, and right images over time."
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            AppMetricCard(
                                title: "Photos",
                                value: "12",
                                detail: "Stored locally",
                                symbolName: "photo.on.rectangle.angled"
                            )

                            AppMetricCard(
                                title: "Latest angle",
                                value: "Front",
                                detail: "Captured today",
                                symbolName: "camera.viewfinder"
                            )
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
                            message: "Preview a calorie change and require approval before it is applied."
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            AppMetricCard(
                                title: "Current target",
                                value: "2,400",
                                detail: "kcal per day",
                                symbolName: "flame.fill"
                            )

                            AppMetricCard(
                                title: "Suggested",
                                value: "2,300",
                                detail: "kcal per day",
                                symbolName: "slider.horizontal.3"
                            )
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
