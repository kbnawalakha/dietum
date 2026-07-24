import Foundation

struct AppContainer {
    static let live = AppContainer()

    func makeRootViewModel() -> RootViewModel {
        RootViewModel()
    }
}
