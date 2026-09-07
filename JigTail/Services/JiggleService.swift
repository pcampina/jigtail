import AppKit
import CoreGraphics
import Foundation

/// Makes a tiny out-and-back cursor movement on a fixed cadence so the OS sees "not idle,"
/// resetting both the screensaver timer and (paired with SleepPreventionService) sleep.
/// The displacement is deliberately only a couple of points and is immediately restored, so
/// it provides perceptible feedback without leaving the pointer somewhere unexpected.
final class JiggleService {
    /// Called when real user input is detected between ticks, so the coordinator can drop
    /// back to waiting for the idle threshold instead of fighting the user.
    var onUserActivityDetected: (() -> Void)?
    /// Called only after a synthetic jiggle has been posted, allowing the UI to acknowledge
    /// real work rather than merely showing that the feature is armed.
    var onJiggle: (() -> Void)?

    private var timer: Timer?
    private var interval: TimeInterval = 0
    private var shakeDirection: CGFloat = 1

    var isRunning: Bool { timer != nil }

    func start(interval: TimeInterval) {
        stop()
        self.interval = interval
        // Fire right away: the idle threshold (or trigger) has just been satisfied, so the
        // first jiggle shouldn't wait a further full interval — it should land the instant
        // jigging becomes active, which is also what tells the UI to switch to its green,
        // "actively jiggling" look.
        fire()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        timer.tolerance = interval * 0.1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        // Anything that has touched input more recently than our own last synthetic jiggle
        // is genuine activity (the user came back) — back off rather than keep firing.
        let idleSeconds = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .null)
        if idleSeconds < interval * 0.9 {
            stop()
            onUserActivityDetected?()
            return
        }
        fire()
    }

    private func fire() {
        guard let currentEvent = CGEvent(source: nil) else { return }
        let origin = currentEvent.location
        let destination = CGPoint(x: origin.x + (2 * shakeDirection), y: origin.y)
        shakeDirection *= -1

        flashCursor()
        postMouseMove(to: destination)
        onJiggle?()

        // A short delay keeps the movement observable instead of allowing the window server
        // to coalesce the two events into an apparent no-op.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.045) { [weak self] in
            self?.postMouseMove(to: origin)
        }
    }

    /// Briefly swaps the system cursor to a distinct shape so a jiggle reads as "JigTail just
    /// did something" rather than an unexplained pointer twitch — purely cosmetic feedback,
    /// separate from the synthetic move itself.
    private func flashCursor() {
        NSCursor.pointingHand.push()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            NSCursor.pop()
        }
    }

    private func postMouseMove(to location: CGPoint) {
        guard let move = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: location,
            mouseButton: .left
        ) else { return }
        move.post(tap: .cghidEventTap)
    }
}
