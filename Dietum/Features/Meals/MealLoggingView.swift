import SwiftUI
import PhotosUI
import UIKit

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
                    title: "Describe, analyze, correct.",
                    message: "Tell Dietum generally what is in the meal and review the complete local calorie and nutrition estimate in this window."
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
                                    await viewModel.analyzeMeal()
                                }
                            } label: {
                                Label("Analyze meal", systemImage: "sparkles")
                            }
                            .buttonStyle(.appToolbar)
                            .disabled(viewModel.analysisState == .analyzing || !viewModel.canAnalyze)
                        }

                        MealPhotoInput(
                            selectedImage: viewModel.selectedPhoto,
                            onPhotoSelected: { viewModel.setSelectedPhoto($0) },
                            onPhotoSelectionFailed: { viewModel.photoSelectionFailed() }
                        )

                        if let photoSelectionError = viewModel.photoSelectionError {
                            Text(photoSelectionError)
                                .font(.caption)
                                .foregroundStyle(AppPalette.textSecondary)
                        }

                        Text(viewModel.hasSelectedPhoto ? "Selected local photo. Add a description for a more specific analysis." : "No photo selected. A general food description is enough for the local estimate.")
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)

                        TextField(
                            "What is in this meal? (for example: chicken, rice, broccoli)",
                            text: Binding(
                                get: { viewModel.draft.foodDescription },
                                set: { viewModel.updateFoodDescription($0) }
                            ),
                            axis: .vertical
                        )
                        .textFieldStyle(.appTextField)
                        .lineLimit(2...4)
                        .accessibilityLabel("General meal description")

                        if viewModel.analysisState == .analyzing {
                            HStack(spacing: AppSpacing.item) {
                                ProgressView()
                                Text("Calculating calories and nutrition...")
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

                        NutritionBreakdownView(nutrition: viewModel.summary.nutrition)
                    }
                }

                if !viewModel.detectedFoods.isEmpty {
                    AppSurfaceCard {
                        VStack(alignment: .leading, spacing: AppSpacing.item) {
                            AppSectionHeader(
                                title: "Detected foods",
                                message: "Edit or remove anything the estimate got wrong, then confirm each food."
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
                                        onUpdateMacros: { viewModel.updateFoodMacros(id: food.id, protein: $0.protein, carbohydrates: $0.carbohydrates, fat: $0.fat) },
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
                        .pickerStyle(.menu)
                        .accessibilityLabel("Meal type")

                        TextField("Optional notes", text: Binding(
                            get: { viewModel.draft.notes },
                            set: { viewModel.updateNotes($0) }
                        ), axis: .vertical)
                        .textFieldStyle(.appTextField)

                        Text("This is a local estimate based on the general description. Review, correct, and confirm every food before saving.")
                            .font(.caption)
                            .foregroundStyle(AppPalette.textSecondary)

                        Button {
                            Task {
                                await viewModel.saveDraft()
                            }
                        } label: {
                            Label("Save meal draft", systemImage: "tray.and.arrow.down.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appProminent)
                        .disabled(viewModel.analysisState == .analyzing)
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

private struct NutritionBreakdownView: View {
    let nutrition: NutritionAmounts

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("Complete nutrition estimate")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)

            HStack(spacing: AppSpacing.item) {
                nutritionMetric("Calories", "\(nutrition.calories) kcal")
                nutritionMetric("Protein", "\(nutrition.proteinGrams.formatted(.number.precision(.fractionLength(0)))) g")
            }
            HStack(spacing: AppSpacing.item) {
                nutritionMetric("Carbs", "\(nutrition.carbohydrateGrams.formatted(.number.precision(.fractionLength(0)))) g")
                nutritionMetric("Fat", "\(nutrition.fatGrams.formatted(.number.precision(.fractionLength(0)))) g")
            }
            nutritionMetric("Fiber", "\(nutrition.fiberGrams.formatted(.number.precision(.fractionLength(0)))) g")
        }
        .padding(.top, AppSpacing.small)
    }

    private func nutritionMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppPalette.textSecondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MealPhotoInput: View {
    let selectedImage: UIImage?
    let onPhotoSelected: (UIImage) -> Void
    let onPhotoSelectionFailed: () -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var isCameraPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.item) {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel("Selected meal photo")
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppPalette.accentSoft)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .overlay {
                        Label("Choose a meal photo", systemImage: "photo.on.rectangle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("No meal photo selected")
            }

            HStack(spacing: AppSpacing.item) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Choose photo", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.appToolbar)

                Button {
                    isCameraPresented = true
                } label: {
                    Label("Take photo", systemImage: "camera")
                }
                .buttonStyle(.appToolbar)
                .disabled(!cameraCaptureIsAvailable)
                .accessibilityHint("Camera capture is unavailable in the simulator or on devices without a camera.")
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else {
                return
            }

            Task {
                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    await MainActor.run {
                        onPhotoSelectionFailed()
                        pickerItem = nil
                    }
                    return
                }

                await MainActor.run {
                    onPhotoSelected(image)
                    pickerItem = nil
                }
            }
        }
        .sheet(isPresented: $isCameraPresented) {
            CameraImagePicker { image in
                onPhotoSelected(image)
                isCameraPresented = false
            }
        }
    }

    private var cameraCaptureIsAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
            && Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil
    }
}

private struct CameraImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage) -> Void

        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {}
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
    let onUpdateMacros: (MealMacroValues) -> Void
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
                .textFieldStyle(.appTextField)

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

                Text("Adjust the estimate if the portion looks different. Calories update from protein, carbs, and fat.")
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary)

                HStack(spacing: AppSpacing.small) {
                    macroField(title: "Protein g", value: food.nutrition.proteinGrams) { newValue in
                        onUpdateMacros(MealMacroValues(
                            protein: newValue,
                            carbohydrates: food.nutrition.carbohydrateGrams,
                            fat: food.nutrition.fatGrams
                        ))
                    }
                    macroField(title: "Carbs g", value: food.nutrition.carbohydrateGrams) { newValue in
                        onUpdateMacros(MealMacroValues(
                            protein: food.nutrition.proteinGrams,
                            carbohydrates: newValue,
                            fat: food.nutrition.fatGrams
                        ))
                    }
                    macroField(title: "Fat g", value: food.nutrition.fatGrams) { newValue in
                        onUpdateMacros(MealMacroValues(
                            protein: food.nutrition.proteinGrams,
                            carbohydrates: food.nutrition.carbohydrateGrams,
                            fat: newValue
                        ))
                    }
                }

                Text("Estimated calories: \(food.nutrition.calories) kcal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)

                Button(action: onToggleReviewed) {
                    Label(isReviewed ? "Mark as needing review" : "Confirm food", systemImage: isReviewed ? "arrow.uturn.backward" : "checkmark")
                }
                .buttonStyle(.appToolbar)
                .accessibilityHint("Confirmation is required before this meal draft can be saved.")
            }
        }
    }

    private func macroField(title: String, value: Double, onChange: @escaping (Double) -> Void) -> some View {
        TextField(
            title,
            value: Binding(
                get: { value },
                set: onChange
            ),
            format: .number.precision(.fractionLength(1))
        )
        .textFieldStyle(.appTextField)
        .keyboardType(.decimalPad)
    }
}

private struct MealMacroValues {
    let protein: Double
    let carbohydrates: Double
    let fat: Double
}
