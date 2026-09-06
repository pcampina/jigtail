import Foundation

enum TriggerKind: String, CaseIterable {
    case appRunning
    case cpuBusy
    case mediaPlaying
}

/// A single condition JigTail can gate conditional-mode jiggling on.
protocol JiggleTrigger {
    var kind: TriggerKind { get }
    var isSatisfied: Bool { get async }
}

/// Combines the user's enabled conditional triggers with OR logic: while in conditional
/// mode, jiggling continues only while idle AND at least one enabled trigger is satisfied.
/// An actor because CPUBusyTrigger holds mutable sample state that must only ever be
/// touched from one evaluation at a time.
actor TriggerEngine {
    private var triggers: [TriggerKind: JiggleTrigger] = [:]
    private(set) var enabledKinds: Set<TriggerKind> = []

    func setTrigger(_ trigger: JiggleTrigger) {
        triggers[trigger.kind] = trigger
    }

    func setEnabled(_ kind: TriggerKind, enabled: Bool) {
        if enabled {
            enabledKinds.insert(kind)
        } else {
            enabledKinds.remove(kind)
        }
    }

    /// No enabled triggers means conditional mode has nothing to gate on, so it's treated
    /// as "never satisfied" rather than "always" — callers shouldn't be in conditional mode
    /// with zero triggers enabled, but if they are, jiggling should stay off, not run wild.
    func isAnySatisfied() async -> Bool {
        guard !enabledKinds.isEmpty else { return false }
        for kind in enabledKinds {
            guard let trigger = triggers[kind] else { continue }
            if await trigger.isSatisfied { return true }
        }
        return false
    }
}
