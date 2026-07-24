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
                            message: "Jump into meal logging or open the setup flow from here."
                        )

                        NavigationLink(value: AppRoute.mealLogging) {
                            Label("Log a meal", systemImage: "camera.fill")
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
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.screen)
            .padding(.bottom, AppSpacing.screen * 1.5)
        }
        .scrollIndicators(.hidden)
        .appScreenBackground()
    }
}
