import SwiftUI

struct MealLoggingView: View {
    @StateObject private var viewModel: MealLoggingViewModel

    init(viewModel: MealLoggingViewModel = MealLoggingViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Meal logging",
                    title: "Capture, detect, correct.",
                    message: "A local mock flow for testing meal photo entry before a production analysis service is chosen."
                )

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Photo analysis",
                            message: viewModel.headline
                        )

                        HStack(spacing: AppSpacing.item) {
                            AppStatusPill(text: viewModel.reviewPillText, systemImage: "fork.knife")
                            Spacer(minLength: 0)
                            Button {
                                Task {
                                    await viewModel.analyzeMockPhoto()
                                }
                            } label: {
                                Label("Run mock analysis", systemImage: "sparkles")
                            }
                            .buttonStyle(.appToolbar)
                            .disabled(viewModel.analysisState == .analyzing)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("Mock photo")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppPalette.textPrimary)

                            Text("Photo placeholder: \(viewModel.draft.photoDescription)")
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.textSecondary)
                        }

                        if viewModel.analysisState == .analyzing {
                            HStack(spacing: AppSpacing.item) {
                                ProgressView()
                                Text("Analyzing sample meal...")
                                    .font(.subheadline)
                                    .foregroundStyle(AppPalette.textSecondary)
                            }
                        }

                        if let notes = viewModel.analysisNotes {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(AppPalette.textSecondary)
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Meal summary",
                            message: "Quick scan of the current draft before you save it locally."
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            AppMetricCard(
                                title: "Meal type",
                                value: viewModel.summary.mealType.rawValue.capitalized,
                                detail: "Selected for this entry",
                                symbolName: "clock"
                            )

                            AppMetricCard(
                                title: "Foods",
                                value: "\(viewModel.summary.itemCount)",
                                detail: viewModel.summary.confidenceText,
                                symbolName: "list.bullet.clipboard"
                            )
                        }

                        Text(viewModel.summary.notes)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                }

                if !viewModel.detectedFoods.isEmpty {
                    AppSurfaceCard {
                        VStack(alignment: .leading, spacing: AppSpacing.item) {
                            AppSectionHeader(
                                title: "Detected foods",
                                message: "Edit or remove anything the mock analysis got wrong, then confirm each food."
                            )

                            Label(viewModel.reviewStatusText, systemImage: "checkmark.shield")
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.textSecondary)

                            VStack(alignment: .leading, spacing: AppSpacing.item) {
                                ForEach(viewModel.detectedFoods) { food in
                                    MealDetectedFoodRow(
                                        food: food,
                                        isExpanded: viewModel.selectedItemID == food.id,
                                        isReviewed: viewModel.isFoodReviewed(food.id),
                                        needsAttention: viewModel.foodNeedsAttention(food),
                                        onToggleReview: {
                                            viewModel.toggleItemReview(food.id)
                                        },
                                        onToggleReviewed: {
                                            viewModel.toggleFoodReviewed(food.id)
                                        },
                                        onUpdateName: { viewModel.updateFood(id: food.id, name: $0) },
                                        onUpdateConfidence: { viewModel.updateFoodConfidence(id: food.id, confidence: $0) },
                                        onRemove: {
                                            viewModel.removeFood(id: food.id)
                                        }
                                    )
                                }
                            }

                            Button {
                                viewModel.addFood()
                            } label: {
                                Label("Add food", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.appToolbar)
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Meal notes",
                            message: "Capture quick context before the entry is stored."
                        )

                        Picker("Meal type", selection: Binding(
                            get: { viewModel.draft.mealType },
                            set: { viewModel.updateMealType($0) }
                        )) {
                            Text("Breakfast").tag(MealType.breakfast)
                            Text("Lunch").tag(MealType.lunch)
                            Text("Dinner").tag(MealType.dinner)
                            Text("Snack").tag(MealType.snack)
                            Text("Custom").tag(MealType.custom)
                        }
                        .pickerStyle(.segmented)

                        TextField("Optional notes", text: Binding(
                            get: { viewModel.draft.notes },
                            set: { viewModel.updateNotes($0) }
                        ), axis: .vertical)
                        .textFieldStyle(.roundedBorder)

                        Text("Meal detection is a mock estimate. Review, correct, and confirm every food before saving.")
                            .font(.caption)
                            .foregroundStyle(AppPalette.textSecondary)

                        Button {
                            viewModel.saveDraft()
                        } label: {
                            Label("Save meal draft", systemImage: "tray.and.arrow.down.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appProminent)
                        .disabled(!viewModel.canSave)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.screen)
            .padding(.bottom, AppSpacing.screen * 1.5)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Log Meal")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }
}

private struct MealDetectedFoodRow: View {
    let food: DetectedMealFood
    let isExpanded: Bool
    let isReviewed: Bool
    let needsAttention: Bool
    let onToggleReview: () -> Void
    let onToggleReviewed: () -> Void
    let onUpdateName: (String) -> Void
    let onUpdateConfidence: (Double?) -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
                Button(action: onToggleReview) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .foregroundStyle(AppPalette.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Hide correction details" : "Show correction details")

                TextField(
                    "Food name",
                    text: Binding(
                        get: { food.name },
                        set: onUpdateName
                    )
                )
                .textFieldStyle(.roundedBorder)

                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                }
                .buttonStyle(.appToolbar)
            }

            HStack(spacing: AppSpacing.small) {
                Image(systemName: isReviewed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(isReviewed ? .green : (needsAttention ? .orange : AppPalette.accent))
                    .accessibilityHidden(true)

                Text(isReviewed ? "Confirmed" : (needsAttention ? "Needs attention" : "Not confirmed"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isReviewed ? .green : (needsAttention ? .orange : AppPalette.textSecondary))

                if let confidence = food.confidence {
                    Text("Confidence \(Int(confidence * 100))%")
                        .font(.caption)
                        .foregroundStyle(AppPalette.textSecondary)
                } else {
                    Text("Confidence not set")
                        .font(.caption)
                        .foregroundStyle(AppPalette.textSecondary)
                }

                Button("Low") { onUpdateConfidence(0.35) }
                    .buttonStyle(.borderless)
                    .font(.caption)

                Button("Med") { onUpdateConfidence(0.65) }
                    .buttonStyle(.borderless)
                    .font(.caption)

                Button("High") { onUpdateConfidence(0.9) }
                    .buttonStyle(.borderless)
                    .font(.caption)
            }

            if isExpanded {
                Text(needsAttention ? "This estimate is uncertain. Correct the name or confidence, then confirm it." : "Confirm this food once the detected name looks right.")
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary)

                Button(action: onToggleReviewed) {
                    Label(isReviewed ? "Mark as needing review" : "Confirm food", systemImage: isReviewed ? "arrow.uturn.backward" : "checkmark")
                }
                .buttonStyle(.appToolbar)
                .accessibilityHint("Confirmation is required before this meal draft can be saved.")
            }
        }
    }
}
