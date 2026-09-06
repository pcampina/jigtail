import AppKit

/// Satisfied while a user-chosen app (by bundle identifier) is running.
struct AppRunningTrigger: JiggleTrigger {
    let kind = TriggerKind.appRunning
    var targetBundleIdentifier: String?

    var isSatisfied: Bool {
        get async {
            guard let targetBundleIdentifier, !targetBundleIdentifier.isEmpty else { return false }
            return NSWorkspace.shared.runningApplications.contains {
                $0.bundleIdentifier == targetBundleIdentifier
            }
        }
    }
}
