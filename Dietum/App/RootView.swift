import SwiftUI

struct RootView: View {
    @StateObject private var viewModel: RootViewModel

    init(viewModel: RootViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            DashboardView()
                .navigationTitle("Dietum")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.showOnboarding()
                        } label: {
                            Label("Setup", systemImage: "sparkles")
                        }
                        .buttonStyle(.appToolbar)
                    }
                }
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .onboarding:
                        OnboardingView()
                    case .dashboard:
                        DashboardView()
                    }
                }
        }
    }
}

final class RootViewModel: ObservableObject {
    @Published var path: [AppRoute] = []

    func showOnboarding() {
        path.append(.onboarding)
    }
}
