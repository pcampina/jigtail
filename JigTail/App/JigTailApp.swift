import SwiftUI

@main
struct JigTailApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var coordinator = JiggleCoordinator()

    var body: some Scene {
        MenuBarExtra {
            PopoverContentView()
                .environmentObject(coordinator)
                .environmentObject(coordinator.settings)
                .environmentObject(coordinator.permissions)
        } label: {
            MenuBarLabelView()
                .environmentObject(coordinator)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsWindowView()
                .environmentObject(coordinator)
                .environmentObject(coordinator.settings)
                .environmentObject(coordinator.launchAtLogin)
        }
    }
}
