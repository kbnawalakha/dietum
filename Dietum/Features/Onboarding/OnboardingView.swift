import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Getting started",
                    title: "Build the profile once, then reuse it every day.",
                    message: "The setup flow will stay lightweight, local-only, and easy to revisit."
                )

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "What comes next",
                            message: "The onboarding flow will eventually capture goals, meals, and preferences."
                        )

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            AppChecklistItem(text: "Local profile and body metrics")
                            AppChecklistItem(text: "Goal weight and goal date")
                            AppChecklistItem(text: "Meal count and target macros")
                        }

                        Button {
                            dismiss()
                        } label: {
                            Label("Continue to dashboard", systemImage: "checkmark.circle.fill")
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
        .navigationTitle("Setup")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }
}
