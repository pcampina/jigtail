import Foundation

extension TimeInterval {
    /// A compact, rounded-up countdown for a small status badge, e.g. "0:40".
    /// Rounding up avoids displaying 0:39 immediately after a fresh 40-second cycle starts.
    var minutesSecondsRemaining: String {
        let totalSeconds = max(0, Int(self.rounded(.up)))
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    /// "HH:MM:SS remaining" — used by the timed auto-stop countdown in both the popover and
    /// the Settings window.
    var hhmmssRemaining: String {
        let totalSeconds = max(0, Int(self))
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d:%02d remaining", h, m, s)
    }
}
