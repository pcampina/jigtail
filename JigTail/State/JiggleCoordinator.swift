import Combine
import Foundation

/// Central orchestrator wiring idle detection, the jiggle mechanism, sleep prevention, the
/// timed auto-stop, and (in conditional mode) the trigger engine together, exposing a single
/// state enum the UI renders from.
@MainActor
final class JiggleCoordinator: ObservableObject {
    struct Countdown: Equatable {
        let deadline: Date
        let totalDuration: TimeInterval

        func remaining(at date: Date = .now) -> TimeInterval {
            max(0, deadline.timeIntervalSince(date))
        }

        func progress(at date: Date = .now) -> Double {
            guard totalDuration > 0 else { return 0 }
            return min(1, max(0, remaining(at: date) / totalDuration))
        }

        /// 0 at the start of the phase, 1 exactly at `deadline` — what the ring should fill
        /// *to*, since it reads as "how far along," not "how much is left."
        func elapsedProgress(at date: Date = .now) -> Double {
            1 - progress(at: date)
        }
    }

    enum AppState: Equatable {
        /// Master toggle is off.
        case off
        /// Master toggle is on, armed, waiting for idle (and, in conditional mode, a
        /// trigger) before jiggling starts.
        case idleWaiting
        /// Idle threshold (and, in conditional mode, an enabled trigger) satisfied — actively jiggling.
        case activeJiggling
    }

    @Published private(set) var state: AppState = .off
    /// A brief acknowledgement that a jiggle was actually sent. This is intentionally
    /// independent from `state`: being armed is not the same as having just acted.
    @Published private(set) var hasRecentJiggle = false
    /// The current phase's deadline. It is updated only when the phase changes, so SwiftUI
    /// can hand the perimeter animation to Core Animation instead of redrawing it every frame.
    @Published private(set) var idleDeadline: Date?
    @Published private(set) var nextJiggleDeadline: Date?

    /// True right after a toggle-on attempt is blocked for lack of Accessibility permission —
    /// the popover shows an explanatory alert while this is true.
    @Published var showPermissionAlert = false

    let settings: SettingsStore
    let launchAtLogin = LaunchAtLoginService()
    let permissions = PermissionsService()

    private let idleMonitor = IdleMonitorService()
    private let jiggleService = JiggleService()
    private let sleepPrevention = SleepPreventionService()
    private let triggerEngine = TriggerEngine()

    private var cancellables = Set<AnyCancellable>()
    private var isMasterOn = false
    private var isEvaluatingStartGate = false
    private var conditionMonitorTask: Task<Void, Never>?
    private var activityPulseTask: Task<Void, Never>?

    init(settings: SettingsStore = SettingsStore()) {
        self.settings = settings

        jiggleService.onUserActivityDetected = { [weak self] in
            self?.state = .idleWaiting
        }
        jiggleService.onJiggle = { [weak self] in
            self?.recordJiggleActivity()
        }

        idleMonitor.$idleSeconds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] seconds in
                self?.handleIdleTick(seconds)
            }
            .store(in: &cancellables)
    }

    var isOn: Bool { isMasterOn }

    /// Recomputes the visible idle countdown immediately after a preset change. This also
    /// starts the session right away if the newly selected threshold has already elapsed.
    func refreshIdleCountdown() {
        guard isMasterOn, state == .idleWaiting else { return }
        // A live read, not the published `idleSeconds` — that only refreshes on the monitor's
        // polling cadence and can be stale by up to that long, which is negligible against a
        // 30-minute threshold but very visible against a 1-minute one (e.g. showing 0:55
        // instead of 0:60 right after picking "1m").
        handleIdleTick(idleMonitor.currentIdleSeconds())
    }

    var phaseCountdown: Countdown? {
        switch state {
        case .off:
            return nil
        case .idleWaiting:
            guard let idleDeadline else { return nil }
            return Countdown(
                deadline: idleDeadline,
                totalDuration: TimeInterval(settings.idleThresholdMinutes * 60)
            )
        case .activeJiggling:
            guard let nextJiggleDeadline else { return nil }
            return Countdown(
                deadline: nextJiggleDeadline,
                totalDuration: TimeInterval(settings.jiggleIntervalSeconds)
            )
        }
    }

    func toggle() {
        if !isMasterOn {
            permissions.refresh()
            guard permissions.isAccessibilityTrusted else {
                permissions.requestAccess()
                showPermissionAlert = true
                return
            }
        }

        isMasterOn.toggle()
        if isMasterOn {
            state = .idleWaiting
            refreshTriggerConfiguration()
            idleMonitor.start()
            sleepPrevention.start()
            startConditionMonitor()
        } else {
            turnOff()
        }
    }

    /// Call after changing any trigger-related setting (target app, CPU threshold, which
    /// triggers are enabled) so a running session picks up the change immediately.
    func refreshTriggerConfiguration() {
        let appTrigger = AppRunningTrigger(targetBundleIdentifier: settings.appRunningTargetBundleID)
        let cpuTrigger = CPUBusyTrigger(thresholdPercent: Double(settings.cpuBusyThresholdPercent))
        let mediaTrigger = MediaPlayingTrigger()

        let appEnabled = settings.appRunningTriggerEnabled
        let cpuEnabled = settings.cpuBusyTriggerEnabled
        let mediaEnabled = settings.mediaPlayingTriggerEnabled

        Task {
            await triggerEngine.setTrigger(appTrigger)
            await triggerEngine.setTrigger(cpuTrigger)
            await triggerEngine.setTrigger(mediaTrigger)
            await triggerEngine.setEnabled(.appRunning, enabled: appEnabled)
            await triggerEngine.setEnabled(.cpuBusy, enabled: cpuEnabled)
            await triggerEngine.setEnabled(.mediaPlaying, enabled: mediaEnabled)
        }
    }

    private func turnOff() {
        isMasterOn = false
        activityPulseTask?.cancel()
        hasRecentJiggle = false
        idleDeadline = nil
        nextJiggleDeadline = nil
        idleMonitor.stop()
        jiggleService.stop()
        sleepPrevention.stop()
        stopConditionMonitor()
        state = .off
    }

    private func recordJiggleActivity() {
        activityPulseTask?.cancel()
        hasRecentJiggle = true
        nextJiggleDeadline = Date().addingTimeInterval(TimeInterval(settings.jiggleIntervalSeconds))
        activityPulseTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            self?.hasRecentJiggle = false
        }
    }

    /// Only decides the idleWaiting -> activeJiggling transition. Once jiggling, two separate
    /// mechanisms are responsible for stopping it again: JiggleService's own tick loop detects
    /// real user activity (see JiggleService.tick), and the condition-monitor task below
    /// detects a conditional-mode trigger no longer being satisfied. Neither can use
    /// idleMonitor's polled idleSeconds directly while active, since our own synthetic jiggle
    /// events reset that same counter.
    private func handleIdleTick(_ idleSeconds: TimeInterval) {
        guard isMasterOn, state != .activeJiggling, !isEvaluatingStartGate else { return }
        let threshold = TimeInterval(settings.idleThresholdMinutes * 60)
        updateIdleDeadline(threshold: threshold, idleSeconds: idleSeconds)
        guard idleSeconds >= threshold else { return }

        isEvaluatingStartGate = true
        Task { @MainActor [weak self] in
            defer { self?.isEvaluatingStartGate = false }
            guard let self, self.isMasterOn, self.state != .activeJiggling else { return }

            let conditionsOK: Bool
            switch self.settings.triggerMode {
            case .manual:
                conditionsOK = true
            case .conditional:
                conditionsOK = await self.triggerEngine.isAnySatisfied()
            }
            guard conditionsOK else { return }

            self.idleDeadline = nil
            self.nextJiggleDeadline = Date().addingTimeInterval(TimeInterval(self.settings.jiggleIntervalSeconds))
            self.jiggleService.start(interval: TimeInterval(self.settings.jiggleIntervalSeconds))
            self.state = .activeJiggling
        }
    }

    /// The idle monitor updates on a low-frequency cadence. Keep the same deadline between
    /// polls so the on-screen ring remains one continuous Core Animation instead of restarting.
    private func updateIdleDeadline(threshold: TimeInterval, idleSeconds: TimeInterval) {
        let proposedDeadline = Date().addingTimeInterval(max(0, threshold - idleSeconds))
        guard let idleDeadline else {
            self.idleDeadline = proposedDeadline
            return
        }
        if abs(idleDeadline.timeIntervalSince(proposedDeadline)) > 1 {
            self.idleDeadline = proposedDeadline
        }
    }

    /// Runs only while conditional mode is active and jiggling is underway, periodically
    /// re-checking whether the enabled trigger(s) are still satisfied (independent of the
    /// idle counter, so it isn't fooled by our own synthetic events). If not, drops back to
    /// idleWaiting — since the user likely never returned, idleMonitor's polled idleSeconds
    /// is still past threshold, so jiggling resumes the moment the trigger is true again.
    private func startConditionMonitor() {
        conditionMonitorTask?.cancel()
        conditionMonitorTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                guard !Task.isCancelled else { return }
                await self.recheckTriggerCondition()
            }
        }
    }

    private func stopConditionMonitor() {
        conditionMonitorTask?.cancel()
        conditionMonitorTask = nil
    }

    private func recheckTriggerCondition() async {
        guard isMasterOn, state == .activeJiggling, settings.triggerMode == .conditional else { return }
        let satisfied = await triggerEngine.isAnySatisfied()
        if !satisfied {
            jiggleService.stop()
            nextJiggleDeadline = nil
            idleDeadline = nil
            state = .idleWaiting
        }
    }
}
