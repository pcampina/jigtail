import CoreGraphics
import Foundation

/// Polls how long it's been since any real HID input, so JigTailCoordinator knows when
/// the user has been away long enough to start jiggling.
final class IdleMonitorService: ObservableObject {
    @Published private(set) var idleSeconds: TimeInterval = 0

    private var timer: Timer?
    private let pollInterval: TimeInterval

    init(pollInterval: TimeInterval = 1) {
        self.pollInterval = pollInterval
    }

    /// A live, unbuffered read of system idle time — unlike `idleSeconds`, which only refreshes
    /// on `pollInterval`'s cadence and can be stale by up to that long. Callers that need an
    /// accurate value *right now* (e.g. recomputing the countdown the instant the user changes
    /// the idle threshold) should use this instead of the published property.
    func currentIdleSeconds() -> TimeInterval {
        CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .null)
    }

    func start() {
        stop()
        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
        timer.tolerance = pollInterval * 0.2
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        poll()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        idleSeconds = currentIdleSeconds()
    }
}
