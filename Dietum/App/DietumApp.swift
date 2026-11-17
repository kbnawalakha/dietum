import SwiftUI
import BackgroundTasks

@main
struct DietumApp: App {
    let container = AppContainer.live

    init() {
        let container = AppContainer.live
        BGTaskScheduler.shared.register(forTaskWithIdentifier: WeeklyBackupScheduler.taskIdentifier, using: nil) { task in
            task.expirationHandler = {
                task.setTaskCompleted(success: false)
            }
            Task { @MainActor in
                let success = await container.makeAccountViewModel().performScheduledBackup()
                task.setTaskCompleted(success: success)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: container, viewModel: container.makeRootViewModel())
        }
    }
}
