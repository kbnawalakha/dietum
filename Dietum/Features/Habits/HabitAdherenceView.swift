import SwiftUI

struct HabitAdherenceView: View {
    @StateObject private var viewModel: HabitAdherenceViewModel

    init(viewModel: HabitAdherenceViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Habit streaks")
                .task {
                    await viewModel.load()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading habit summary")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding()
        case .empty:
            emptyState
        case .failed(let message):
            failureState(message: message)
        case .loaded(let summary):
            loadedState(summary: summary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("No habit data yet")
                .font(.title3.weight(.semibold))
            Text("Log a few meals and check-ins, then come back to see your streaks and adherence trend.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func failureState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.orange)
            Text("Couldn’t load habits")
                .font(.title3.weight(.semibold))
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Button("Try again") {
                Task { await viewModel.load() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func loadedState(summary: HabitAdherenceSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(viewModel.subtitle(for: summary))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(viewModel.cards(for: summary)) { card in
                        HabitSummaryCardView(card: card)
                    }
                }

                consistencySection(summary: summary)
            }
            .padding()
        }
    }

    private func consistencySection(summary: HabitAdherenceSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consistency snapshot")
                .font(.headline)

            HabitProgressRow(
                label: "Meals",
                value: "\(summary.mealDaysLogged)/\(summary.mealDaysExpected) days",
                progress: summary.mealCoverageRatio
            )

            HabitProgressRow(
                label: "Check-ins",
                value: "\(summary.checkInWeeksLogged)/\(summary.checkInWeeksExpected) weeks",
                progress: summary.checkInCoverageRatio
            )
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct HabitSummaryCardView: View {
    let card: HabitSummaryCard

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(card.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(card.value)
                .font(.title2.weight(.bold))
            Text(card.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }
}

private struct HabitProgressRow: View {
    let label: String
    let value: String
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: min(max(progress, 0), 1))
        }
    }
}
