import AppKit

/// LSUIElement already keeps JigTail out of the Dock; this is a belt-and-suspenders guard for
/// the (rare) case a menu-bar-only app briefly shows a Dock icon before its Info.plist is read.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
