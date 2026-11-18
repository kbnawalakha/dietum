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
                    message: "Tell Dietum generally what is in the meal and review the Vision and USDA calorie and nutrition estimate in this window."
                )

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                    title: "Photo or ingredients",
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
                            onPhotoSelected: { image in
                                viewModel.setSelectedPhoto(image)
                                Task {
                                    await viewModel.analyzeMeal()
                                }
                            },
                            onPhotoSelectionFailed: { viewModel.photoSelectionFailed() }
                        )

                        if let photoSelectionError = viewModel.photoSelectionError {
                            Text(photoSelectionError)
                                .font(.caption)
                                .foregroundStyle(AppPalette.textSecondary)
                        }

                        Text(viewModel.hasSelectedPhoto ? "Photo analysis is ready to review. Add an ingredient list for a more specific lookup, or edit the detected foods below." : "Choose a photo or enter an ingredient list. USDA will look up each food and calculate the combined nutrition.")
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)

                        TextField(
                            "Ingredients or foods (comma, line, or semicolon separated)",
                            text: Binding(
                                get: { viewModel.draft.foodDescription },
                                set: { viewModel.updateFoodDescription($0) }
                            ),
                            axis: .vertical
                        )
                        .textFieldStyle(.appTextField)
                        .lineLimit(2...4)
                        .accessibilityLabel("Meal ingredients or foods")

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
                                message: "Edit or remove anything the estimate got wrong. Confirmation is optional before saving."
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
                                        onUpdateWeight: { viewModel.updateFoodWeight(id: food.id, grams: $0) },
                                        onUpdateServings: { viewModel.updateFoodServings(id: food.id, servings: $0) },
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

                        Text("USDA values are estimates per 100 g. Review portion size, cooking oils, and hidden ingredients before saving.")
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

                let todayPhotoEntries = viewModel.todaySavedMeals.filter { $0.photoMetadata != nil }
                if !todayPhotoEntries.isEmpty {
                    AppSurfaceCard {
                        VStack(alignment: .leading, spacing: AppSpacing.item) {
                            AppSectionHeader(
                                title: "Today's saved meal photos",
                                message: "Saved photos stay visible here for the rest of today. Older dates are in Settings → History → Meal Photos."
                            )

                            ForEach(todayPhotoEntries) { entry in
                                MealPhotoEntryRow(entry: entry)
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
        .navigationTitle("Log Meal")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
        .task {
            await viewModel.loadTodayMeals()
        }
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

            DisclosureGroup("Micronutrients") {
                let micros = nutrition.micronutrients
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    nutrientRow("Sugar", micros.sugarGrams, "g")
                    nutrientRow("Saturated fat", micros.saturatedFatGrams, "g")
                    nutrientRow("Cholesterol", micros.cholesterolMilligrams, "mg")
                    nutrientRow("Sodium", micros.sodiumMilligrams, "mg")
                    nutrientRow("Potassium", micros.potassiumMilligrams, "mg")
                    nutrientRow("Calcium", micros.calciumMilligrams, "mg")
                    nutrientRow("Iron", micros.ironMilligrams, "mg")
                    nutrientRow("Magnesium", micros.magnesiumMilligrams, "mg")
                    nutrientRow("Phosphorus", micros.phosphorusMilligrams, "mg")
                    nutrientRow("Zinc", micros.zincMilligrams, "mg")
                    nutrientRow("Vitamin A", micros.vitaminAMicrograms, "mcg")
                    nutrientRow("Vitamin C", micros.vitaminCMilligrams, "mg")
                    nutrientRow("Vitamin D", micros.vitaminDMicrograms, "mcg")
                    nutrientRow("Vitamin E", micros.vitaminEMilligrams, "mg")
                    nutrientRow("Vitamin K", micros.vitaminKMicrograms, "mcg")
                    nutrientRow("Thiamin", micros.thiaminMilligrams, "mg")
                    nutrientRow("Riboflavin", micros.riboflavinMilligrams, "mg")
                    nutrientRow("Niacin", micros.niacinMilligrams, "mg")
                    nutrientRow("Vitamin B6", micros.vitaminB6Milligrams, "mg")
                    nutrientRow("Folate", micros.folateMicrograms, "mcg")
                    nutrientRow("Vitamin B12", micros.vitaminB12Micrograms, "mcg")
                    nutrientRow("Choline", micros.cholineMilligrams, "mg")
                }
                .padding(.top, AppSpacing.small)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppPalette.textPrimary)
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

    private func nutrientRow(_ title: String, _ value: Double, _ unit: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppPalette.textSecondary)
            Spacer(minLength: AppSpacing.small)
            Text("\(value.formatted(.number.precision(.fractionLength(1)))) \(unit)")
                .foregroundStyle(AppPalette.textPrimary)
        }
        .font(.caption)
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
    let onUpdateWeight: (Double) -> Void
    let onUpdateServings: (Double) -> Void
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
                Text(needsAttention ? "This estimate is uncertain. Correct the name, portion, or confidence before saving." : "Review this food if the detected name and portion look right.")
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary)

                Text(food.servingSizeGrams == nil ? "Adjust the portion in grams when the serving looks different." : "This nutrition label was read per serving. Enter the number of servings and the totals will update before saving.")
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary)

                if food.servingSizeGrams != nil {
                    macroField(title: "Servings", value: food.servings, onChange: onUpdateServings)
                    Text("Total portion: \(food.estimatedWeightGrams.formatted(.number.precision(.fractionLength(0)))) g")
                        .font(.caption)
                        .foregroundStyle(AppPalette.textSecondary)
                } else {
                    macroField(title: "Portion g", value: food.estimatedWeightGrams, onChange: onUpdateWeight)
                }

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
                .accessibilityHint("Review the estimate before saving the meal.")
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

private struct MealPhotoEntryRow: View {
    let entry: MealEntry

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.item) {
            MealPhotoImage(metadata: entry.photoMetadata, placeholderHeight: 72)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card / 2, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.mealType.rawValue.capitalized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                Text(entry.loggedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary)
                Text("\(entry.nutrition.calories) kcal · \(entry.nutrition.proteinGrams.formatted(.number.precision(.fractionLength(0)))) g protein")
                    .font(.caption)
                    .foregroundStyle(AppPalette.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, AppSpacing.small)
        .overlay(Divider(), alignment: .bottom)
    }
}

private struct MealPhotoImage: View {
    let metadata: PhotoMetadata?
    let placeholderHeight: CGFloat

    var body: some View {
        if let imageData = metadata?.imageData, let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: placeholderHeight)
        } else {
            RoundedRectangle(cornerRadius: AppRadius.card / 2, style: .continuous)
                .fill(AppPalette.accentSoft.opacity(0.45))
                .frame(maxWidth: .infinity)
                .frame(height: placeholderHeight)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(AppPalette.accent)
                }
        }
    }
}

struct MealHistoryView: View {
    @StateObject private var viewModel: MealHistoryViewModel
    @State private var dayPendingDeletion: Date?
    @State private var isDeleteConfirmationPresented = false

    init(viewModel: MealHistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Meal history",
                    title: "Review saved meal photos by date.",
                    message: "Tap a date to see every saved photo and that day's nutrition totals."
                )

                switch viewModel.loadState {
                case .idle, .loading:
                    HStack(spacing: AppSpacing.item) {
                        ProgressView()
                        Text("Loading saved meal photos...")
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                case .failed(let message):
                    AppSurfaceCard {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                case .loaded where viewModel.dayGroups.isEmpty:
                    AppSurfaceCard {
                        Text("No saved meal photos yet. Save a meal with a photo from the dashboard meal tracker.")
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                case .loaded:
                    ForEach(viewModel.dayGroups) { group in
                        NavigationLink {
                            MealPhotoDayDetailView(group: group)
                        } label: {
                            AppSurfaceCard {
                                VStack(alignment: .leading, spacing: AppSpacing.item) {
                                    HStack {
                                        Text(group.day.formatted(date: .abbreviated, time: .omitted))
                                            .font(.headline)
                                            .foregroundStyle(AppPalette.textPrimary)
                                        Spacer(minLength: 0)
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(AppPalette.accent)
                                    }

                                    Text("\(group.photoEntries.count) meal photo\(group.photoEntries.count == 1 ? "" : "s")")
                                        .font(.subheadline)
                                        .foregroundStyle(AppPalette.textSecondary)

                                    NutritionBreakdownView(nutrition: group.nutrition)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                dayPendingDeletion = group.day
                                isDeleteConfirmationPresented = true
                            } label: {
                                Label("Delete day", systemImage: "trash")
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
        .navigationTitle("Meal Photos")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
        .confirmationDialog(
            "Delete this day's meal photos?",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete all meal photos", role: .destructive) {
                guard let day = dayPendingDeletion else {
                    return
                }

                Task {
                    await viewModel.deleteMealPhotoDay(day)
                    dayPendingDeletion = nil
                }
            }
            Button("Cancel", role: .cancel) {
                dayPendingDeletion = nil
            }
        } message: {
            if let day = dayPendingDeletion {
                Text("This removes every saved meal photo from \(day.formatted(date: .abbreviated, time: .omitted)). Other dates stay on this device.")
            }
        }
        .task {
            await viewModel.loadHistory()
        }
    }
}

private struct MealPhotoDayDetailView: View {
    let group: MealPhotoDayGroup

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Meal photos",
                    title: group.day.formatted(date: .abbreviated, time: .omitted),
                    message: "All saved meal photos from this date, with the complete daily nutrition total."
                )

                AppSurfaceCard {
                    NutritionBreakdownView(nutrition: group.nutrition)
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Saved photos",
                            message: "Photos remain stored locally with their meal entries."
                        )

                        ForEach(group.photoEntries) { entry in
                            MealPhotoEntryRow(entry: entry)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.screen)
            .padding(.bottom, AppSpacing.screen * 1.5)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Meal Photos")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }
}
