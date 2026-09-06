import AppKit

/// LSUIElement already keeps JigTail out of the Dock; this is a belt-and-suspenders guard for
/// the (rare) case a menu-bar-only app briefly shows a Dock icon before its Info.plist is read.
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// The stable identifier SwiftUI assigns to the window backing a `Settings` scene.
    private static let settingsWindowIdentifier = "com_apple_SwiftUI_Settings_window"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    /// As a menu-bar-only (accessory) app, Settings otherwise opens at the normal window level,
    /// so clicking into another app can bury it behind that app's windows. Floating it keeps
    /// Settings visible on top instead of needing to be hunted down.
    @objc private func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window.identifier?.rawValue == Self.settingsWindowIdentifier else { return }
        window.level = .floating
    }
}
