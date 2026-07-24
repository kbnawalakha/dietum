import SwiftUI

@main
struct DietumApp: App {
    let container = AppContainer.live

    var body: some Scene {
        WindowGroup {
            RootView(container: container, viewModel: container.makeRootViewModel())
        }
    }
}
