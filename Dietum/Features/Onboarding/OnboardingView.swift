import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: OnboardingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Onboarding plan",
                    title: "Shape the profile flow before the editable form lands.",
                    message: viewModel.headline
                )

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Milestone summary",
                            message: viewModel.summary
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            AppMetricCard(
                                title: "Fields",
                                value: viewModel.fieldCountText,
                                detail: "Planned for the profile draft",
                                symbolName: "square.grid.2x2.fill"
                            )

                            AppMetricCard(
                                title: "Phases",
                                value: viewModel.phaseCountText,
                                detail: "From scaffold to handoff",
                                symbolName: "map.fill"
                            )
                        }

                        Text(viewModel.completionMessage)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Profile fields to scaffold",
                            message: "These groups mirror the product spec and help keep the flow in a practical order."
                        )

                        VStack(alignment: .leading, spacing: AppSpacing.section) {
                            ForEach(viewModel.fieldGroups) { group in
                                VStack(alignment: .leading, spacing: AppSpacing.small) {
                                    Text(group.title)
                                        .font(.headline)
                                        .foregroundStyle(AppPalette.textPrimary)

                                    Text(group.detail)
                                        .font(.subheadline)
                                        .foregroundStyle(AppPalette.textSecondary)

                                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                                        ForEach(group.fields, id: \.self) { field in
                                            AppChecklistItem(text: field)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, AppSpacing.small)
                                .padding(.bottom, AppSpacing.small)
                            }
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Implementation phases",
                            message: "Break the work into a scaffold, a draft model, persistence, and the completion path."
                        )

                        VStack(alignment: .leading, spacing: AppSpacing.section) {
                            ForEach(viewModel.implementationPhases) { phase in
                                VStack(alignment: .leading, spacing: AppSpacing.small) {
                                    AppStatusPill(text: phase.title, systemImage: "checkmark.seal.fill")

                                    Text(phase.detail)
                                        .font(.subheadline)
                                        .foregroundStyle(AppPalette.textSecondary)

                                    Text(phase.deliverable)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppPalette.textPrimary)

                                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                                        ForEach(phase.checkpoints, id: \.self) { checkpoint in
                                            AppChecklistItem(text: checkpoint)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, AppSpacing.small)
                                .padding(.bottom, AppSpacing.small)
                            }
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Next handoff",
                            message: "The milestone is intentionally incomplete so the next pass can replace the plan with a working profile form."
                        )

                        Button {
                            dismiss()
                        } label: {
                            Label("Return to dashboard", systemImage: "arrow.left.circle.fill")
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
