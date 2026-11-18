import SwiftUI
import DeviceActivity

private extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

struct SleepSetupView: View {
    @StateObject private var viewModel: SleepSetupViewModel

    init(viewModel: SleepSetupViewModel = SleepSetupViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Sleep setup",
                    title: "Capture the sleep baseline before the rest of the profile builds on it.",
                    message: "Keep this step local, simple, and quick to scan so the setup flow stays lightweight."
                )

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Sleep status",
                            message: "The view model keeps the sleep inputs and validation in one place."
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            AppMetricCard(
                                title: "Fields",
                                value: "\(viewModel.profileFieldCount)",
                                detail: "Sleep inputs tracked",
                                symbolName: "moon.stars.fill"
                            )

                            AppMetricCard(
                                title: "State",
                                value: viewModel.isReady ? "Ready" : "Draft",
                                detail: "Local setup only",
                                symbolName: "bed.double.fill"
                            )
                        }

                        Text(viewModel.readinessText)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Import from Apple Health",
                            message: "Sleep and wake timing can be read from HealthKit after you approve access."
                        )

                        Button {
                            Task {
                                await viewModel.importSleepFromHealthKit()
                            }
                        } label: {
                            Label("Import latest sleep", systemImage: "heart.text.square.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appToolbar)
                        .disabled(viewModel.healthImportState == .importing)

                        Text(viewModel.healthImportStatusText)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Phone-use time",
                            message: "Request Apple Screen Time access for this device."
                        )

                        Button {
                            Task {
                                await viewModel.requestScreenTimeAccess()
                            }
                        } label: {
                            Label("Allow Screen Time access", systemImage: "hourglass")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appToolbar)
                        .disabled(viewModel.screenTimeAuthorizationState == .requesting)

                        Text(viewModel.screenTimeAuthorizationStatusText)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)

                        Text("Authorization is the first step. Apple requires a separate Device Activity report extension and approved Family Controls capability before Dietum can show actual usage totals.")
                            .font(.caption)
                            .foregroundStyle(AppPalette.textSecondary)

                        if viewModel.screenTimeAuthorizationState == .authorized {
                            DeviceActivityReport(
                                .totalActivity,
                                filter: DeviceActivityFilter(
                                    segment: .daily(during: DateInterval(
                                        start: Calendar.current.startOfDay(for: .now),
                                        end: .now
                                    ))
                                )
                            )
                            .frame(minHeight: 72)
                            .accessibilityLabel("Today's Screen Time usage report")
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Sleep baseline",
                            message: "Start with the amount of sleep and the current rhythm you want the app to remember."
                        )

                        VStack(alignment: .leading, spacing: AppSpacing.item) {
                            TextField(
                                "Average sleep hours",
                                text: Binding(
                                    get: { viewModel.averageSleepHours },
                                    set: { viewModel.updateAverageSleepHours($0) }
                                )
                            )
                            .textFieldStyle(.appTextField)

                            TextField(
                                "Sleep schedule",
                                text: Binding(
                                    get: { viewModel.sleepSchedule },
                                    set: { viewModel.updateSleepSchedule($0) }
                                ),
                                axis: .vertical
                            )
                            .textFieldStyle(.appTextField)

                            TextField(
                                "Sleep notes",
                                text: Binding(
                                    get: { viewModel.sleepNotes },
                                    set: { viewModel.updateSleepNotes($0) }
                                ),
                                axis: .vertical
                            )
                            .textFieldStyle(.appTextField)
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Field map",
                            message: "This mirrors the sleep setup slice of the onboarding spec."
                        )

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
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
        .navigationTitle("Sleep")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }
}
