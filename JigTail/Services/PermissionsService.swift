import ApplicationServices
import AppKit
import Combine

/// Tracks and requests Accessibility permission, required for `CGEventPost` to actually
/// synthesize input once JigTail is signed/notarized rather than run via `swift file.swift`
/// in Terminal (see TESTING.md's Phase 0 caveat — unsigned CLI runs didn't need this, but a
/// real app bundle does).
///
/// Re-checks whenever any app activates (including JigTail itself regaining focus after the
/// user visits System Settings) so a permission revoked mid-session is noticed promptly,
/// not just once at launch.
final class PermissionsService: ObservableObject {
    @Published private(set) var isAccessibilityTrusted: Bool

    private var cancellable: AnyCancellable?

    init() {
        isAccessibilityTrusted = AXIsProcessTrusted()
        cancellable = NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .sink { [weak self] _ in self?.refresh() }
    }

    func refresh() {
        let trusted = AXIsProcessTrusted()
        if trusted != isAccessibilityTrusted {
            isAccessibilityTrusted = trusted
        }
    }

    /// Triggers macOS's own "JigTail would like to control this computer" system prompt,
    /// which adds JigTail (unchecked) to the Accessibility list the first time it's called.
    /// Calling it again while already listed but unchecked just re-surfaces that same prompt
    /// on some macOS versions — `openSystemSettings()` below is the reliable fallback.
    func requestAccess() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        refresh()
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }
}
