import SwiftUI
import PhotosUI
import UIKit

struct ProgressPhotosView: View {
    @StateObject private var viewModel: ProgressPhotosViewModel
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedAngle: ProgressPhotoAngle?
    @State private var isPhotoPickerPresented = false
    @State private var isCameraPresented = false
    @State private var dayPendingDeletion: Date?
    @State private var isDeleteConfirmationPresented = false

    init(viewModel: ProgressPhotosViewModel = ProgressPhotosViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Progress photos",
                    title: "Capture front, back, and one profile side locally.",
                    message: "A left or right profile is enough. Add both sides when you want a more complete comparison, while keeping photo data on this device."
                )

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Stage a set",
                            message: viewModel.headline
                        )

                        DatePicker(
                            "Photo date",
                            selection: $viewModel.photoDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            ForEach(ProgressPhotoAngle.allCases, id: \.self) { angle in
                                Menu {
                                    Button {
                                        selectedAngle = angle
                                        isPhotoPickerPresented = true
                                    } label: {
                                        Label("Choose from library", systemImage: "photo.on.rectangle")
                                    }

                                    Button {
                                        selectedAngle = angle
                                        isCameraPresented = true
                                    } label: {
                                        Label("Take photo", systemImage: "camera")
                                    }
                                } label: {
                                    ProgressPhotoAngleTile(
                                        angle: angle,
                                        stagedPhoto: viewModel.stagedPhoto(for: angle)
                                    )
                                }
                                .accessibilityLabel("\(angle.displayName) progress photo")
                                .accessibilityHint("Choose a real photo from your library or camera for the \(angle.caption.lowercased()) angle.")
                            }
                        }

                        Text(viewModel.stagedCountText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppPalette.textPrimary)

                        Text(viewModel.stagedSummaryText)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)

                        if let photoSelectionError = viewModel.photoSelectionError {
                            Text(photoSelectionError)
                                .font(.caption)
                                .foregroundStyle(AppPalette.textSecondary)
                        }

                        Button {
                            Task {
                                await viewModel.analyzeBodyPhotos()
                            }
                        } label: {
                            Label("Recalculate body estimate", systemImage: "figure.stand")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appToolbar)
                        .disabled(!viewModel.canAnalyzeBodyPhotos)

                        Text(viewModel.bodyAnalysisText)
                            .font(.caption)
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Save staged photos",
                            message: "Front, back, and either left or right profile are required."
                        )

                        TextField("Optional notes", text: $viewModel.notes, axis: .vertical)
                            .textFieldStyle(.appTextField)

                        TextField("Optional body-fat estimate (%)", text: $viewModel.bodyFatPercentageText)
                            .textFieldStyle(.appTextField)
                            .keyboardType(.decimalPad)
                            .accessibilityHint("Enter a measured or manually estimated percentage; it is not calculated from the photo.")

                        Text("Photos cannot provide a clinical measurement on their own. After uploading, choose the closest visual reference range; use a measured value for precise tracking.")
                            .font(.caption)
                            .foregroundStyle(AppPalette.textSecondary)

                        Text(viewModel.bodyFatEstimateText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppPalette.textPrimary)

                        AppSectionHeader(
                            title: "Regional estimates",
                            message: "Upload a photo to generate automatic, non-clinical estimates before saving. Visceral fat cannot be measured from a photo."
                        )

                        LazyVGrid(columns: AppGrid.columns, spacing: AppSpacing.item) {
                            bodyFatEstimateCard(title: "Chest", value: viewModel.chestBodyFatText)
                            bodyFatEstimateCard(title: "Arms", value: viewModel.armsBodyFatText)
                            bodyFatEstimateCard(title: "Legs", value: viewModel.legsBodyFatText)
                            bodyFatEstimateCard(title: "Back", value: viewModel.backBodyFatText)
                            bodyFatEstimateCard(title: "Visceral", value: viewModel.visceralBodyFatText)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("Reference guide")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppPalette.textPrimary)

                            ForEach(BodyFatReferenceBand.guide) { band in
                                Button {
                                    viewModel.selectBodyFatReference(band)
                                } label: {
                                    HStack(alignment: .top, spacing: AppSpacing.small) {
                                        Image(systemName: viewModel.selectedBodyFatReferenceID == band.id ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(viewModel.selectedBodyFatReferenceID == band.id ? AppPalette.accent : AppPalette.textSecondary)
                                        Text(band.range)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(AppPalette.accent)
                                            .frame(width: 72, alignment: .leading)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(band.title)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(AppPalette.textPrimary)
                                            Text(band.detail)
                                                .font(.caption2)
                                                .foregroundStyle(AppPalette.textSecondary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(viewModel.stagedPhotos.isEmpty)
                            }
                        }

                        if let statusMessage = viewModel.statusMessage {
                            Text(statusMessage)
                                .font(.caption)
                                .foregroundStyle(AppPalette.textSecondary)
                        }

                        HStack(spacing: AppSpacing.item) {
                            Button {
                                viewModel.clearStagedPhotos()
                            } label: {
                                Label("Clear staged", systemImage: "trash")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.appToolbar)
                            .disabled(viewModel.stagedPhotos.isEmpty)

                            Button {
                                Task {
                                    await viewModel.saveStagedPhotos()
                                }
                            } label: {
                                Label(viewModel.saveButtonTitle, systemImage: viewModel.saveButtonSystemImage)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.appProminent)
                            .disabled(viewModel.saveState == .saving)
                        }
                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Comparison summary",
                            message: viewModel.comparisonHeadline
                        )

                        Picker("Comparison angle", selection: Binding(
                            get: { viewModel.comparisonAngle },
                            set: { viewModel.setComparisonAngle($0) }
                        )) {
                            ForEach(ProgressPhotoAngle.allCases, id: \.self) { angle in
                                Text(angle.displayName).tag(angle)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Comparison angle")

                        if viewModel.comparisonCandidates.count >= 2 {
                            ComparisonDateMenu(
                                title: "Earlier photo",
                                selectedPhoto: viewModel.comparisonBaseline,
                                photos: viewModel.comparisonCandidates,
                                onSelect: viewModel.setComparisonBaseline
                            )

                            ComparisonDateMenu(
                                title: "Later photo",
                                selectedPhoto: viewModel.comparisonLatest,
                                photos: viewModel.comparisonCandidates,
                                onSelect: viewModel.setComparisonLatest
                            )

                            HStack(spacing: AppSpacing.item) {
                                ComparisonPhotoCard(title: "Earlier", photo: viewModel.comparisonBaseline)
                                ComparisonPhotoCard(title: "Later", photo: viewModel.comparisonLatest)
                            }

                            VStack(alignment: .leading, spacing: AppSpacing.small) {
                                Text("What looks different in the photos")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppPalette.textPrimary)

                                ForEach(viewModel.comparisonCompositionSignals) { signal in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(signal.title)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(AppPalette.textPrimary)
                                        Text(signal.detail)
                                            .font(.caption)
                                            .foregroundStyle(AppPalette.textSecondary)
                                    }
                                    .accessibilityElement(children: .combine)
                                }

                            }

                            VStack(alignment: .leading, spacing: AppSpacing.small) {
                                Text("Saved numeric context")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppPalette.textPrimary)

                                ForEach(viewModel.comparisonChanges) { change in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(change.title)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(AppPalette.textPrimary)
                                        Text(change.detail)
                                            .font(.caption)
                                            .foregroundStyle(AppPalette.textSecondary)
                                    }
                                    .accessibilityElement(children: .combine)
                                }

                            }
                        }

                        Text(viewModel.comparisonSelectionText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppPalette.textPrimary)

                    }
                }

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Saved photo dates",
                            message: viewModel.recentEntriesText
                        )

                        Text(viewModel.recentSummaryText)
                            .font(.caption)
                            .foregroundStyle(AppPalette.textSecondary)

                        if viewModel.loadState == .loading {
                            HStack(spacing: AppSpacing.item) {
                                ProgressView()
                                Text("Loading saved progress photos...")
                                    .font(.subheadline)
                                    .foregroundStyle(AppPalette.textSecondary)
                            }
                        } else if case .failed(let message) = viewModel.loadState {
                            Text(message)
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.textSecondary)
                        } else if viewModel.recentPhotos.isEmpty {
                            Text("No saved progress photos yet. Stage a local set above to begin tracking.")
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.textSecondary)
                        } else {
                            VStack(alignment: .leading, spacing: AppSpacing.item) {
                                ForEach(viewModel.recentPhotoGroups) { group in
                                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                                        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(group.day.formatted(date: .abbreviated, time: .omitted))
                                                    .font(.headline)
                                                    .foregroundStyle(AppPalette.textPrimary)
                                                Text("\(group.photos.count) saved photo\(group.photos.count == 1 ? "" : "s") with complete profile analysis")
                                                    .font(.caption)
                                                    .foregroundStyle(AppPalette.textSecondary)
                                            }

                                            Spacer(minLength: 0)

                                            Button(role: .destructive) {
                                                dayPendingDeletion = group.day
                                                isDeleteConfirmationPresented = true
                                            } label: {
                                                Image(systemName: "trash")
                                                    .accessibilityLabel("Delete all photos from \(group.day.formatted(date: .abbreviated, time: .omitted))")
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        ForEach(group.photos) { photo in
                                            ProgressPhotoRow(photo: photo)
                                        }
                                    }
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
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.screen)
            .padding(.bottom, AppSpacing.screen * 1.5)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Progress Photos")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete this day's photos?",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete all photos", role: .destructive) {
                guard let day = dayPendingDeletion else {
                    return
                }

                Task {
                    await viewModel.deletePhotoDay(day)
                    dayPendingDeletion = nil
                }
            }
            Button("Cancel", role: .cancel) {
                dayPendingDeletion = nil
            }
        } message: {
            if let day = dayPendingDeletion {
                Text("This removes every saved angle and its body-fat analysis from \(day.formatted(date: .abbreviated, time: .omitted)). Other dates stay on this device.")
            }
        }
        .task {
            await viewModel.loadRecentPhotos()
        }
        .photosPicker(
            isPresented: $isPhotoPickerPresented,
            selection: $pickerItem,
            matching: .images
        )
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem, let angle = selectedAngle else {
                return
            }

            Task {
                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    await MainActor.run {
                        viewModel.photoSelectionFailed()
                        isPhotoPickerPresented = false
                        selectedAngle = nil
                        pickerItem = nil
                    }
                    return
                }

                await MainActor.run {
                    isPhotoPickerPresented = false
                    pickerItem = nil
                }
                await viewModel.stagePhotoAndAnalyze(for: angle, image: image)
                await MainActor.run {
                    selectedAngle = nil
                }
            }
        }
        .sheet(isPresented: $isCameraPresented) {
            CameraImagePicker { image in
                if let selectedAngle {
                    Task {
                        await viewModel.stagePhotoAndAnalyze(for: selectedAngle, image: image)
                    }
                }
                self.selectedAngle = nil
                isCameraPresented = false
            }
        }
        .appScreenBackground()
    }

    private func bodyFatEstimateCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.textSecondary)

            Text(value.isEmpty ? "—" : "\(value)%")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.item)
        .background(AppPalette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card / 2, style: .continuous)
                .stroke(AppPalette.surfaceBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card / 2, style: .continuous))
    }
}

private struct ComparisonDateMenu: View {
    let title: String
    let selectedPhoto: ProgressPhotoMetadata?
    let photos: [ProgressPhotoMetadata]
    let onSelect: (UUID) -> Void

    var body: some View {
        Menu {
            ForEach(photos) { photo in
                Button {
                    onSelect(photo.id)
                } label: {
                    Text(photo.capturedAt.formatted(date: .abbreviated, time: .omitted))
                }
            }
        } label: {
            HStack {
                Label(title, systemImage: "calendar")
                Spacer()
                Text(selectedPhoto?.capturedAt.formatted(date: .abbreviated, time: .omitted) ?? "Choose date")
                    .foregroundStyle(AppPalette.textSecondary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppPalette.accent)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppPalette.textPrimary)
            .padding(.vertical, AppSpacing.small)
        }
        .accessibilityLabel("\(title) comparison date")
    }
}

private struct ComparisonPhotoCard: View {
    let title: String
    let photo: ProgressPhotoMetadata?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            if let photo {
                ProgressPhotoImage(photo: photo.photo, placeholderHeight: 84)
                    .frame(maxWidth: .infinity, minHeight: 84)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card / 2, style: .continuous))
            } else {
                ProgressPhotoImage(
                    photo: PhotoMetadata(storageIdentifier: "missing-progress-photo"),
                    placeholderHeight: 84
                )
                .frame(maxWidth: .infinity, minHeight: 84)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card / 2, style: .continuous))
            }

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.textPrimary)

            if let photo {
                Text(photo.capturedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(AppPalette.textSecondary)
                Text(photo.angle.displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppPalette.accent)
            } else {
                Text("Not available")
                    .font(.caption2)
                    .foregroundStyle(AppPalette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(photo.map { "\(title) \($0.angle.displayName) photo from \($0.capturedAt.formatted(date: .abbreviated, time: .omitted))" } ?? "\(title) photo not available")
    }
}

private struct ProgressPhotoAngleTile: View {
    let angle: ProgressPhotoAngle
    let stagedPhoto: PhotoMetadata?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                AppStatusPill(
                    text: angle.displayName,
                    systemImage: stagedPhoto == nil ? "camera.viewfinder" : "checkmark.circle.fill"
                )

                Spacer(minLength: 0)
            }

            Text(angle.caption)
                .font(.headline)
                .foregroundStyle(AppPalette.textPrimary)

            if let stagedPhoto, let imageData = stagedPhoto.imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card / 2, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: AppRadius.card / 2, style: .continuous)
                    .fill(AppPalette.accentSoft.opacity(0.45))
                    .frame(maxWidth: .infinity)
                    .frame(height: 92)
                    .overlay {
                        Image(systemName: "photo.on.rectangle")
                            .foregroundStyle(AppPalette.accent)
                    }
            }

            Text(stagedPhoto == nil ? "Choose a real photo." : stagedPhotoText)
                .font(.caption)
                .foregroundStyle(AppPalette.textSecondary)

            Spacer(minLength: 0)

            Label(
                stagedPhoto == nil ? "Choose photo" : "Replace photo",
                systemImage: stagedPhoto == nil ? "plus.circle.fill" : "arrow.clockwise"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppPalette.accent)
        }
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
        .padding(AppSpacing.item)
        .background(AppPalette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(stagedPhoto == nil ? AppPalette.surfaceBorder : AppPalette.accent.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    private var stagedPhotoText: String {
        guard let stagedPhoto else {
            return ""
        }

        let date = stagedPhoto.capturedAt.formatted(date: .abbreviated, time: .shortened)
        return "Staged locally at \(date)."
    }
}

private struct ProgressPhotoRow: View {
    let photo: ProgressPhotoMetadata

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.item) {
            ProgressPhotoImage(photo: photo.photo, placeholderHeight: 64)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card / 2, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(photo.capturedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.textPrimary)

                if let notes = photo.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(AppPalette.textSecondary)
                        .lineLimit(2)
                } else {
                    Text("No notes for this entry.")
                        .font(.caption)
                        .foregroundStyle(AppPalette.textSecondary)
                }

                if let bodyFatPercentage = photo.bodyFatPercentage {
                    Text("Body-fat estimate: \(bodyFatPercentage.formatted(.number.precision(.fractionLength(0))))%")
                        .font(.caption)
                        .foregroundStyle(AppPalette.accent)
                }

                if let breakdown = photo.bodyFatBreakdown {
                    Text("Chest \(format(breakdown.chestPercentage))% · Arms \(format(breakdown.armsPercentage))% · Legs \(format(breakdown.legsPercentage))%")
                        .font(.caption2)
                        .foregroundStyle(AppPalette.textSecondary)
                    Text("Back \(format(breakdown.backPercentage))% · Visceral \(format(breakdown.visceralPercentage))%")
                        .font(.caption2)
                        .foregroundStyle(AppPalette.textSecondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, AppSpacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            Divider()
                .offset(y: 24),
            alignment: .bottom
        )
    }

    private func format(_ value: Double?) -> String {
        value.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "—"
    }
}

private struct ProgressPhotoImage: View {
    let photo: PhotoMetadata
    let placeholderHeight: CGFloat

    var body: some View {
        Group {
            if let imageData = photo.imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: AppRadius.card / 2, style: .continuous)
                    .fill(AppPalette.accentSoft.opacity(0.45))
                    .overlay {
                        Image(systemName: "photo.on.rectangle")
                            .foregroundStyle(AppPalette.accent)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: placeholderHeight)
        .clipped()
        .accessibilityLabel("Progress photo")
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
