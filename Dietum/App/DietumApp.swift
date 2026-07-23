import SwiftUI

@main
struct DietumApp: App {
    let container = AppContainer.live

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: RootViewModel(container: container))
        }
    }
}

