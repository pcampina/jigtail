import AppKit

/// Satisfied while Music.app or Spotify is actively playing. Checks `NSWorkspace` first and
/// only scripts an app that's already running — targeting a non-running app via Apple
/// Events can silently auto-launch it, which would be a bug, not a feature.
final class MediaPlayingTrigger: JiggleTrigger {
    let kind = TriggerKind.mediaPlaying

    var isSatisfied: Bool {
        get async {
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .utility).async {
                    continuation.resume(returning: Self.isMusicOrSpotifyPlaying())
                }
            }
        }
    }

    private static func isMusicOrSpotifyPlaying() -> Bool {
        let running = NSWorkspace.shared.runningApplications
        let musicRunning = running.contains { $0.bundleIdentifier == "com.apple.Music" }
        let spotifyRunning = running.contains { $0.bundleIdentifier == "com.spotify.client" }

        if musicRunning, isPlaying(appName: "Music") { return true }
        if spotifyRunning, isPlaying(appName: "Spotify") { return true }
        return false
    }

    private static func isPlaying(appName: String) -> Bool {
        let source = "tell application \"\(appName)\" to player state as string"
        guard let script = NSAppleScript(source: source) else { return false }
        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)
        guard errorInfo == nil else { return false }
        return result.stringValue?.lowercased() == "playing"
    }
}
